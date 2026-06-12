// Generado del refactor de ui_screens.dart.
// CooperativoScreen + Game + Success + helpers.
part of '../ui_screens.dart';

class CooperativoScreen extends StatefulWidget {
  const CooperativoScreen({super.key});

  @override
  State<CooperativoScreen> createState() => _CooperativoScreenState();
}

class _CooperativoScreenState extends State<CooperativoScreen> {
  CoopService? _coop;
  CoopRoomState? _state;
  StreamSubscription<CoopRoomState>? _sub;
  StreamSubscription<CoopMessage>? _msgSub;
  final _joinCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _initialized = false;
  String? _currentUserId;

  bool _isPublic = true;
  List<dynamic> _publicRooms = [];
  bool _loadingRooms = false;
  bool _creatingDeckInline = false;
  String? _selectedCreationType;

  int _detailPage = 1;
  final int _detailLimit = 4;
  int _detailTotal = 0;
  int _detailTotalPages = 0;
  List<dynamic> _detailedRooms = [];
  bool _loadingDetailedRooms = false;
  int? _filterDifficulty;
  String? _filterMode;
  bool _filterHideFull = false;
  final _searchQueryCtrl = TextEditingController();
  Timer? _debounceTimer;

  int? _countdownSeconds;
  Timer? _countdownTimer;
  bool _guestCountdownFinished = false;
  bool _countdownStarted = false;
  String? _pendingStartDeckId;
  String? _pendingStartSlug;
  int? _pendingStartDailyTarget;
  int? _pendingStartDifficulty;
  bool _hasPromptedDeck = false;


  void _loadPublicRooms() async {
    final coop = _coop;
    if (coop == null) return;
    setState(() => _loadingRooms = true);
    try {
      final rooms = await coop.listPublicRooms();
      if (mounted) {
        setState(() {
          _publicRooms = rooms;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[coop] failed to load rooms: $e');
    } finally {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  Future<void> _joinPublic(String code) async {
    final store = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _coop!.joinRoom(
        code: code,
        userId: store.effectiveUser.id,
        name: store.effectiveUser.effectiveName,
      );
      CoopService.active = _coop;
      CoopService.activeUserId = store.effectiveUser.id;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final store = AppScope.of(context);
      _currentUserId = store.effectiveUser.id;
      _coop = CoopService(client: store.api);
      _loadPublicRooms();
      _sub = _coop!.stateStream.listen((s) {
        if (!mounted) return;
        final wasInGame = _state?.currentDeckId != null;

        // Sincronizar deck localmente si cambió en el lobby
        if (s.lobbyDeckId != null && s.lobbyDeckId!.isNotEmpty) {
          if (store.activeDeck.id != s.lobbyDeckId) {
            final hasDeck = store.decks.any((d) => d.id == s.lobbyDeckId);
            if (hasDeck) {
              store.setActiveDeck(s.lobbyDeckId!);
            }
          }
        }

        final wasInLobby = _state != null;
        setState(() => _state = s);

        // Auto-prompt deck selection/creation for Host upon entering lobby
        final isHost = s.hostId == _currentUserId;
        final noDeckSelected = s.lobbyDeckId == null || s.lobbyDeckId!.isEmpty;
        if (isHost && noDeckSelected && !wasInLobby && !_hasPromptedDeck) {
          _hasPromptedDeck = true;
          if (store.decks.isEmpty) {
            setState(() {
              _creatingDeckInline = true;
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showDeckSelectorFromPrompt();
              }
            });
          }
        }

        // Cuando el host empuja la primera tarjeta y el invitado todavía
        // está en el lobby, lo llevamos automáticamente al game screen.
        final nowInGame = s.currentDeckId != null;
        final iAmHost = _currentUserId == s.hostId;
        debugPrint('[coop] stateStream.listen: nowInGame=$nowInGame, wasInGame=$wasInGame, iAmHost=$iAmHost, currentDeckId=${s.currentDeckId}');
        if (!iAmHost && nowInGame && !wasInGame) {
          final target = s.sessionDailyTarget == 0 ? 3 : s.sessionDailyTarget;
          _pendingStartDeckId = s.currentDeckId;
          _pendingStartSlug = s.currentSlug?.isNotEmpty == true ? s.currentSlug! : '00-solo-lectura';
          _pendingStartDailyTarget = target;
          _pendingStartDifficulty = s.sessionDifficulty;
          debugPrint('[coop] Guest: game started by host, pending setup stored: deckId=$_pendingStartDeckId, slug=$_pendingStartSlug');
          _checkGuestCanStartGame(store);
        }
      });
      _msgSub = _coop!.messages.listen((msg) async {
        debugPrint('[coop] Received message: type=${msg.type}');
        if (msg.type == 'deck' && mounted) {
          final deckId = msg.payload?['deckId'] as String?;
          final title = msg.payload?['deckName'] as String?;
          final isBible = (msg.payload?['isBible'] as bool?) ?? false;
          final rawCards = msg.payload?['cards'] as List?;
          debugPrint('[coop] Received deck message: deckId=$deckId, isBible=$isBible, cards count=${rawCards?.length}');
          if (deckId != null && deckId.isNotEmpty && title != null && rawCards != null) {
            final store = AppScope.of(context);
            final cardsList = <MemoryCardData>[];
            for (var i = 0; i < rawCards.length; i++) {
              final c = rawCards[i];
              if (c is Map) {
                final map = Map<String, dynamic>.from(c);
                final cId = map['id'] as String? ?? 'cd_${deckId}_$i';
                cardsList.add(MemoryCardData(
                  id: cId,
                  front: map['front'] as String? ?? '',
                  back: map['back'] as String? ?? '',
                  source: map['source'] as String? ?? 'coop_room',
                  icon: map['icon'] as String? ?? '🎯',
                  retention: (map['retention'] as int?) ?? 100,
                  lapses: (map['lapses'] as int?) ?? 0,
                ));
              }
            }
            final deck = MemoryDeckData(
              id: deckId,
              title: title,
              subtitle: 'Mazo cooperativo compartido',
              icon: '🎯',
              createdAt: DateTime.now(),
              cards: cardsList,
              isBible: isBible,
            );
            store.addOrUpdateCoopDeck(deck);
            store.setActiveDeck(deckId);
            debugPrint('[coop] Deck processed and loaded into AppStore in memory, active deck set to $deckId');
            _checkGuestCanStartGame(store);
          }
        } else if (msg.type == 'join' && mounted) {
          final iAmHost = _currentUserId == _state?.hostId;
          if (iAmHost && _state?.lobbyDeckId != null && _state!.lobbyDeckId!.isNotEmpty) {
            final store = AppScope.of(context);
            final selectedDeckId = _state!.lobbyDeckId!;
            final d = store.decks.firstWhere((dk) => dk.id == selectedDeckId, orElse: () => store.activeDeck);
            if (d.id == selectedDeckId && d.cards.isNotEmpty) {
              final cardsList = d.cards.map((c) => {
                'id': c.id,
                'front': c.front,
                'back': c.back,
                'source': c.source,
                'icon': c.icon,
                'retention': c.retention,
                'lapses': c.lapses,
              }).toList();
              debugPrint('[coop] Host re-broadcasting deck $selectedDeckId to newly joined member');
              _coop!.broadcastLobbyDeck(
                deckId: selectedDeckId,
                deckName: d.title,
                isBible: d.isBible,
                cards: cardsList,
              );
            }
          }
        } else if (msg.type == 'countdown' && mounted) {
          final iAmHost = _currentUserId == _state?.hostId;
          if (iAmHost) {
            debugPrint('[coop] Host ignoring broadcasted countdown message');
          } else {
            final store = AppScope.of(context);
            debugPrint('[coop] Guest starting local countdown in response to countdown message');
            setState(() {
              _countdownStarted = true;
              _guestCountdownFinished = false;
            });
            _startLocalCountdown(() {
              _guestCountdownFinished = true;
              debugPrint('[coop] Guest local countdown finished');
              _checkGuestCanStartGame(store);
            });
          }
        }
      });
    }
  }

  String _deckCreationTab = 'manual'; // 'manual' | 'biblia' | 'texto'
  final _rawContentCtrl = TextEditingController();
  final _bibleSearchCtrl = TextEditingController();
  List<BibleVerseData> _bibleSearchResults = [];
  final List<BibleVerseData> _inlineSelectedVerses = [];

  final _deckTitleCtrl = TextEditingController();
  final List<(TextEditingController, TextEditingController)> _cardCtrls = [];

  void _addEmptyCardRow() {
    setState(() {
      _cardCtrls.add((TextEditingController(), TextEditingController()));
    });
  }

  void _removeCardRow(int index) {
    if (_cardCtrls.length <= 1) return;
    setState(() {
      final pair = _cardCtrls.removeAt(index);
      pair.$1.dispose();
      pair.$2.dispose();
    });
  }

  void _clearInlineDeckForm() {
    _deckTitleCtrl.clear();
    for (final c in _cardCtrls) {
      c.$1.dispose();
      c.$2.dispose();
    }
    _cardCtrls.clear();
    _creatingDeckInline = false;
    _selectedCreationType = null;
  }

  Future<void> _saveDeckInline(AppStore store, CoopRoomState roomState) async {
    final title = _deckTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un título para el mazo.')),
      );
      return;
    }

    final validCards = _cardCtrls.where((c) => c.$1.text.trim().isNotEmpty && c.$2.text.trim().isNotEmpty).toList();
    if (validCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa al menos 1 tarjeta completa (Frente y Dorso).')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final deckId = 'dk_${DateTime.now().millisecondsSinceEpoch}';
      
      // Inserción en Drift
      final companion = DecksCompanion(
        id: drift.Value(deckId),
        title: drift.Value(title),
        subtitle: drift.Value('${validCards.length} tarjetas creadas en sala'),
        icon: drift.Value('✨'),
        isBible: drift.Value(false),
        createdAt: drift.Value(DateTime.now()),
      );
      await store.db!.upsertDeck(companion);

      for (var i = 0; i < validCards.length; i++) {
        final front = validCards[i].$1.text.trim();
        final back = validCards[i].$2.text.trim();
        final cardId = 'cd_${deckId}_$i';

        await store.db!.upsertCard(CardsCompanion(
          id: drift.Value(cardId),
          deckId: drift.Value(deckId),
          front: drift.Value(front),
          back: drift.Value(back),
          source: drift.Value('coop_room'),
          icon: drift.Value('🎯'),
          retention: drift.Value(100),
          lapses: drift.Value(0),
        ));
      }

      // Recargar mazos locales
      await store.loadDecksFromDatabase();
      store.setActiveDeck(deckId);

      // Sincronizar por websocket la sala
      final cardsList = validCards.asMap().entries.map((entry) {
        final i = entry.key;
        final front = entry.value.$1.text.trim();
        final back = entry.value.$2.text.trim();
        return {
          'id': 'cd_${deckId}_$i',
          'front': front,
          'back': back,
          'source': 'coop_room',
          'icon': '🎯',
          'retention': 100,
          'lapses': 0,
        };
      }).toList();
      if (_coop != null) {
        _coop!.broadcastLobbyDeck(deckId: deckId, deckName: title, cards: cardsList);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F0C1B),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: RefColors.lime),
              const SizedBox(width: 8),
              Text(
                '¡Mazo "$title" creado y asignado a la sala! 🎉',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      _clearInlineDeckForm();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CooperativoConfigScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el mazo: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveBibleDeckInline(AppStore store, CoopRoomState roomState) async {
    if (_inlineSelectedVerses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona al menos un versículo de la Biblia.')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final deckId = 'dk_bible_${DateTime.now().millisecondsSinceEpoch}';
      final first = _inlineSelectedVerses.first;
      final title = '${first.book} ${first.chapter} (Coop)';
      
      // Inserción en Drift
      final companion = DecksCompanion(
        id: drift.Value(deckId),
        title: drift.Value(title),
        subtitle: drift.Value('${_inlineSelectedVerses.length} versículos seleccionados'),
        icon: drift.Value('✝️'),
        isBible: drift.Value(true),
        createdAt: drift.Value(DateTime.now()),
      );
      await store.db!.upsertDeck(companion);

      for (var i = 0; i < _inlineSelectedVerses.length; i++) {
        final verse = _inlineSelectedVerses[i];
        final cardId = 'cd_${deckId}_$i';

        await store.db!.upsertCard(CardsCompanion(
          id: drift.Value(cardId),
          deckId: drift.Value(deckId),
          front: drift.Value(verse.ref),
          back: drift.Value(verse.text),
          source: drift.Value(store.bibleVersion.toUpperCase()),
          icon: drift.Value('✝️'),
          retention: drift.Value(74),
          lapses: drift.Value(0),
        ));
      }

      // Recargar mazos locales
      await store.loadDecksFromDatabase();
      store.setActiveDeck(deckId);

      // Sincronizar por websocket la sala
      final cardsList = _inlineSelectedVerses.asMap().entries.map((entry) {
        final i = entry.key;
        final verse = entry.value;
        return {
          'id': 'cd_${deckId}_$i',
          'front': verse.ref,
          'back': verse.text,
          'source': store.bibleVersion.toUpperCase(),
          'icon': '✝️',
          'retention': 74,
          'lapses': 0,
        };
      }).toList();
      if (_coop != null) {
        _coop!.broadcastLobbyDeck(deckId: deckId, deckName: title, cards: cardsList);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F0C1B),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: RefColors.lime),
              const SizedBox(width: 8),
              Text(
                '¡Mazo Bíblico "$title" creado y asignado a la sala! 🎉',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _inlineSelectedVerses.clear();
        _bibleSearchResults.clear();
        _bibleSearchCtrl.clear();
        _creatingDeckInline = false;
      });
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CooperativoConfigScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el mazo: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveRawContentDeckInline(AppStore store, CoopRoomState roomState) async {
    final title = _deckTitleCtrl.text.trim();
    final text = _rawContentCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un título para el mazo.')),
      );
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa o pega el contenido de texto.')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final cards = store.segmentContent(text, icon: '🧠', title: title);
      if (cards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos extraer ninguna tarjeta de este contenido.')),
        );
        return;
      }

      final deckId = 'dk_raw_${DateTime.now().millisecondsSinceEpoch}';
      
      // Inserción en Drift
      final companion = DecksCompanion(
        id: drift.Value(deckId),
        title: drift.Value(title),
        subtitle: drift.Value('${cards.length} tarjetas segmentadas'),
        icon: drift.Value('🧠'),
        isBible: drift.Value(false),
        createdAt: drift.Value(DateTime.now()),
      );
      await store.db!.upsertDeck(companion);

      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final cardId = 'cd_${deckId}_$i';

        await store.db!.upsertCard(CardsCompanion(
          id: drift.Value(cardId),
          deckId: drift.Value(deckId),
          front: drift.Value(card.front),
          back: drift.Value(card.back),
          source: drift.Value('coop_segmented'),
          icon: drift.Value('🧠'),
          retention: drift.Value(100),
          lapses: drift.Value(0),
        ));
      }

      // Recargar mazos locales
      await store.loadDecksFromDatabase();
      store.setActiveDeck(deckId);

      // Sincronizar por websocket la sala
      final cardsList = cards.asMap().entries.map((entry) {
        final i = entry.key;
        final card = entry.value;
        return {
          'id': 'cd_${deckId}_$i',
          'front': card.front,
          'back': card.back,
          'source': 'coop_segmented',
          'icon': '🧠',
          'retention': 100,
          'lapses': 0,
        };
      }).toList();
      if (_coop != null) {
        _coop!.broadcastLobbyDeck(deckId: deckId, deckName: title, cards: cardsList);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F0C1B),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: RefColors.lime),
              const SizedBox(width: 8),
              Text(
                '¡Mazo segmentado "$title" creado y asignado a la sala! 🎉',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _rawContentCtrl.clear();
        _deckTitleCtrl.clear();
        _creatingDeckInline = false;
      });
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CooperativoConfigScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el mazo: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showDeckSelectorFromPrompt() {
    final store = AppScope.of(context);
    final coop = _coop;
    if (coop == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F0C1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Selecciona un mazo para la sala',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _creatingDeckInline = true;
                  });
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RefColors.lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: RefColors.lime),
                ),
                title: const Text(
                  'Crear nuevo mazo desde cero',
                  style: TextStyle(color: RefColors.lime, fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  'Si prefieres no usar un mazo de tu colección',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
              const Divider(color: Colors.white10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: store.decks.length,
                  itemBuilder: (context, idx) {
                    final d = store.decks[idx];
                    return ListTile(
                      onTap: () {
                        store.setActiveDeck(d.id);
                        final cardsList = d.cards.map((c) => {
                          'id': c.id,
                          'front': c.front,
                          'back': c.back,
                          'source': c.source,
                          'icon': c.icon,
                          'retention': c.retention,
                          'lapses': c.lapses,
                        }).toList();
                        coop.broadcastLobbyDeck(deckId: d.id, deckName: d.title, cards: cardsList);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mazo configurado a: ${d.title} 🎯'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CooperativoConfigScreen(),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(d.icon.isNotEmpty ? d.icon : '🎯'),
                      ),
                      title: Text(
                        d.title.isNotEmpty ? d.title : 'Mazo sin título',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${d.cards.length} tarjetas',
                        style: const TextStyle(color: RefColors.muted, fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _startLocalCountdown(void Function() onFinished) {
    debugPrint('[coop] Starting local countdown');
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        debugPrint('[coop] Local countdown timer canceled - not mounted');
        timer.cancel();
        return;
      }
      bool finished = false;
      setState(() {
        if (_countdownSeconds! > 1) {
          _countdownSeconds = _countdownSeconds! - 1;
          debugPrint('[coop] Local countdown at $_countdownSeconds');
        } else {
          debugPrint('[coop] Local countdown finished, triggering callback');
          _countdownSeconds = null;
          timer.cancel();
          finished = true;
        }
      });
      if (finished) {
        onFinished();
      }
    });
  }

  void _checkGuestCanStartGame(AppStore store) {
    final canStart = !_countdownStarted || _guestCountdownFinished;
    debugPrint('[coop] _checkGuestCanStartGame: canStart=$canStart, countdownStarted=$_countdownStarted, guestCountdownFinished=$_guestCountdownFinished, pendingStartDeckId=$_pendingStartDeckId, pendingStartSlug=$_pendingStartSlug');
    if (canStart && _pendingStartDeckId != null && _pendingStartSlug != null) {
      store.configureSession(
        difficulty: _pendingStartDifficulty ?? 0,
        dailyTarget: _pendingStartDailyTarget ?? 3,
      );
      final deckId = _pendingStartDeckId!;
      final slug = _pendingStartSlug!;
      
      _pendingStartDeckId = null;
      _pendingStartSlug = null;
      _pendingStartDailyTarget = null;
      _pendingStartDifficulty = null;
      _guestCountdownFinished = false;
      _countdownStarted = false;

      debugPrint('[coop] Redirecting guest to flow, calling _navigateWhenDeckReady');
      _navigateWhenDeckReady(store, deckId, slug);
    }
  }

  void _navigateWhenDeckReady(AppStore store, String deckId, String targetSlug) async {
    debugPrint('[coop] _navigateWhenDeckReady: checking deck availability in store');
    int attempts = 0;
    while (attempts < 15) {
      final hasDeck = store.decks.any((d) => d.id == deckId && d.cards.isNotEmpty);
      debugPrint('[coop] _navigateWhenDeckReady attempt $attempts: hasDeck=$hasDeck');
      if (hasDeck) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 150));
      attempts++;
    }
    if (mounted) {
      store.setActiveDeck(deckId);
      final finalPath = '${AppRoutes.flow}/$targetSlug';
      debugPrint('[coop] Guest navigating to route: $finalPath');
      Navigator.pushNamed(context, finalPath);
    } else {
      debugPrint('[coop] Guest navigation skipped: context not mounted');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgSub?.cancel();
    
    final state = _state;
    final gameStarted = state != null && state.currentDeckId != null;
    if (!gameStarted || CoopService.active != _coop) {
      _coop?.dispose();
    }

    _joinCtrl.dispose();
    _deckTitleCtrl.dispose();
    _rawContentCtrl.dispose();
    _bibleSearchCtrl.dispose();
    _countdownTimer?.cancel();
    for (final c in _cardCtrls) {
      c.$1.dispose();
      c.$2.dispose();
    }
    super.dispose();
  }

  Widget _buildCountdownOverlay() {
    final seconds = _countdownSeconds;
    if (seconds == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                    'PREPARADOS',
                    style: TextStyle(
                      color: RefColors.lime.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.6, end: 1.2).animate(
                          CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      '$seconds',
                      key: ValueKey(seconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: RefColors.lime,
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡La partida cooperativa va a comenzar! 🚀',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Future<void> _create() async {
    final store = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _coop!.createRoom(
        userId: store.effectiveUser.id,
        name: store.effectiveUser.effectiveName,
        isPublic: _isPublic,
        deckId: '',
        deckName: '',
      );
      CoopService.active = _coop;
      CoopService.activeUserId = store.effectiveUser.id;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final store = AppScope.of(context);
    final code = _joinCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _coop!.joinRoom(
        code: code,
        userId: store.effectiveUser.id,
        name: store.effectiveUser.effectiveName,
      );
      CoopService.active = _coop;
      CoopService.activeUserId = store.effectiveUser.id;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Stack(
      children: [
        ReferencePage(
          active: AppRoutes.amigos,
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state == null)
            _CoopTopBar(center: 'Modo cooperativo')
          else if (!_creatingDeckInline)
            _CoopTopBar(center: 'Sala cooperativa')
          else
            _CoopMinimizedHeader(
              roomState: state,
              onBack: () {
                setState(() {
                  _clearInlineDeckForm();
                });
              },
            ),
          if (state == null) ...[
            Glass(
              padding: const EdgeInsets.all(14),
              gradient: LinearGradient(
                colors: [
                  RefColors.violet.withValues(alpha: .24),
                  RefColors.pink.withValues(alpha: .24),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crear una sala',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Genera un código de 6 letras y compártelo con tus amigos.',
                    style: TextStyle(color: RefColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Cta('+ Crear sala', onTap: _busy ? null : _create, disabled: _busy),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Unirse con código',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HtmlRefColors.glassSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HtmlRefColors.glassBorder),
                    ),
                    child: TextField(
                      controller: _joinCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        color: RefColors.ink,
                        fontSize: 18,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'ABC123',
                        hintStyle: TextStyle(
                          color: RefColors.dim,
                          fontSize: 18,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Cta('Unirme →', onTap: _busy ? null : _join, disabled: _busy),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              padding: const EdgeInsets.all(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: .06),
                  Colors.white.withValues(alpha: .02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.explore_outlined, color: RefColors.lime, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Explorador de Salas Activas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -.3),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _loadPublicRooms,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: RefColors.lime,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Salas públicas creadas por tus amigos en este momento.',
                    style: TextStyle(color: RefColors.muted, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingRooms)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: RefColors.lime, strokeWidth: 2),
                      ),
                    )
                  else if (_publicRooms.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.grid_view_rounded, color: RefColors.muted, size: 28),
                          SizedBox(height: 8),
                          Text(
                            'No hay salas activas en este momento. ¡Sé el primero en crear una! 🌐',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: RefColors.dim, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 136,
                      ),
                      itemCount: _publicRooms.length > 4 ? 4 : _publicRooms.length,
                      itemBuilder: (context, idx) {
                        final room = _publicRooms[idx];
                        final deckName = room['deckName']?.toString().isNotEmpty == true
                            ? room['deckName'].toString()
                            : 'Mazo Personalizado';
                        final code = room['code'].toString();
                        final count = room['memberCount'] ?? 1;
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: RefColors.lime.withValues(alpha: .2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: RefColors.lime.withValues(alpha: .12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          code,
                                          style: const TextStyle(
                                            color: RefColors.lime,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: RefColors.lime,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: RefColors.lime,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    deckName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '👥 $count / 4',
                                    style: const TextStyle(
                                      color: RefColors.muted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _busy ? null : () => _joinPublic(code),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        gradient: RefColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Unirse',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (_publicRooms.length > 4) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showLobbyDetailsModal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: RefColors.lime.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: RefColors.lime.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.explore_outlined, color: RefColors.lime, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Explorar salas avanzadas con filtros 🔍',
                                style: TextStyle(
                                  color: RefColors.lime,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: RefColors.urgent, fontSize: 12),
              ),
            ],
          ] else ...[
            if (_creatingDeckInline) ...[
              if (_selectedCreationType == null)
                _CoopDeckTypeSelector(
                  onSelectBible: () {
                    setState(() {
                      _selectedCreationType = 'biblia';
                    });
                  },
                  onSelectSpecify: () {
                    setState(() {
                      _selectedCreationType = 'especificar';
                    });
                  },
                )
              else if (_selectedCreationType == 'biblia')
                BibliaScreen(
                  embedded: true,
                  onDeckCreated: (deckId, title) {
                    final store = AppScope.of(context);
                    final d = store.decks.firstWhere(
                      (dk) => dk.id == deckId,
                      orElse: () => store.activeDeck,
                    );
                    final cardsList = d.cards.map((c) => {
                      'id': c.id,
                      'front': c.front,
                      'back': c.back,
                      'source': c.source,
                      'icon': c.icon,
                      'retention': c.retention,
                      'lapses': c.lapses,
                    }).toList();
                    if (_coop != null) {
                      _coop!.broadcastLobbyDeck(deckId: deckId, deckName: title, cards: cardsList);
                    }
                    setState(() {
                      _clearInlineDeckForm();
                    });
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CooperativoConfigScreen(),
                        ),
                      );
                    }
                  },
                  onCancel: () {
                    setState(() {
                      _selectedCreationType = null;
                    });
                  },
                )
              else if (_selectedCreationType == 'especificar')
                EspecificarScreen(
                  embedded: true,
                  onDeckCreated: (deckId, title) {
                    final store = AppScope.of(context);
                    final d = store.decks.firstWhere(
                      (dk) => dk.id == deckId,
                      orElse: () => store.activeDeck,
                    );
                    final cardsList = d.cards.map((c) => {
                      'id': c.id,
                      'front': c.front,
                      'back': c.back,
                      'source': c.source,
                      'icon': c.icon,
                      'retention': c.retention,
                      'lapses': c.lapses,
                    }).toList();
                    if (_coop != null) {
                      _coop!.broadcastLobbyDeck(deckId: deckId, deckName: title, cards: cardsList);
                    }
                    setState(() {
                      _clearInlineDeckForm();
                    });
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CooperativoConfigScreen(),
                        ),
                      );
                    }
                  },
                  onCancel: () {
                    setState(() {
                      _selectedCreationType = null;
                    });
                  },
                )
            ] else ...[
              _CoopLobbyCard(
                roomState: state,
                onInviteTap: () => AmigosScreen.showAddFriendModal(context),
              ),
              const SizedBox(height: 12),
              _CoopSettingsCard(
                roomState: state,
                onCreateDeckTap: () {
                  setState(() {
                    _creatingDeckInline = true;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (state.hostId == AppScope.of(context).effectiveUser.id) ...[
                Cta(
                  'Iniciar partida →',
                  disabled: (state.lobbyDeckId == null || state.lobbyDeckId!.isEmpty) || (state.memberIds.length <= 1),
                  onTap: (state.lobbyDeckId == null || state.lobbyDeckId!.isEmpty) || (state.memberIds.length <= 1)
                      ? null
                      : () async {
                          final selectedDeckId = state.lobbyDeckId!;
                          final target = state.sessionDailyTarget == 0 ? 3 : state.sessionDailyTarget;
                          final store = AppScope.of(context);
                          debugPrint('[coop] Host clicked start game. selectedDeckId=$selectedDeckId, target=$target');
                          store.configureSession(
                            difficulty: state.sessionDifficulty,
                            dailyTarget: target,
                          );
                          final d = store.decks.firstWhere((dk) => dk.id == selectedDeckId, orElse: () => store.activeDeck);
                          final cardsList = d.cards.map((c) => {
                            'id': c.id,
                            'front': c.front,
                            'back': c.back,
                            'source': c.source,
                            'icon': c.icon,
                            'retention': c.retention,
                            'lapses': c.lapses,
                          }).toList();
                          _coop!.broadcastLobbyDeck(
                            deckId: selectedDeckId,
                            deckName: d.title,
                            isBible: d.isBible,
                            cards: cardsList,
                          );
                          
                          // Broadcast countdown so guests also start their local countdowns
                          debugPrint('[coop] Host broadcasting countdown');
                          _coop!.broadcastCountdown();
                          
                          _startLocalCountdown(() {
                            debugPrint('[coop] Host countdown finished. Broadcasting first card and navigating.');
                            _coop!.updateLocalCardState(deckId: selectedDeckId, cardIndex: 0, slug: '00-solo-lectura');
                            _coop!.broadcastCard(deckId: selectedDeckId, cardIndex: 0, slug: '00-solo-lectura');
                            if (context.mounted) {
                              Navigator.pushNamed(context, '${AppRoutes.flow}/00-solo-lectura');
                            } else {
                              debugPrint('[coop] Host navigation failed: context not mounted');
                            }
                          });
                        },
                ),
                if (state.lobbyDeckId == null || state.lobbyDeckId!.isEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '⚠️ Selecciona un mazo en la configuración antes de iniciar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RefColors.pink, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ] else if (state.memberIds.length <= 1) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '👥 Esperando a que se una al menos otro jugador...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RefColors.lime, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ]
              else
                const Glass(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Esperando a que el host inicie la partida…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RefColors.muted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              GhostButton(
                'Salir de la sala',
                onTap: () async {
                  await _coop!.disconnect();
                  CoopService.active = null;
                  CoopService.activeUserId = null;
                  if (mounted) {
                    setState(() {
                      _state = null;
                      _hasPromptedDeck = false;
                    });
                  }
                },
              ),
            ],
          ],
        ],
      ),
    ),
    _buildCountdownOverlay(),
  ],
);
}

  void _showLobbyDetailsModal(BuildContext context) {
    _detailPage = 1;
    _filterDifficulty = null;
    _filterMode = null;
    _filterHideFull = false;
    _searchQueryCtrl.clear();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void reloadDetailedRooms() async {
              setModalState(() => _loadingDetailedRooms = true);
              try {
                final res = await _coop!.client.listPublicRoomsPaged(
                  difficulty: _filterDifficulty,
                  mode: _filterMode,
                  query: _searchQueryCtrl.text.trim(),
                  hideFull: _filterHideFull,
                  page: _detailPage,
                  limit: _detailLimit,
                );
                setModalState(() {
                  _detailedRooms = res['rooms'] as List? ?? [];
                  _detailTotal = res['total'] ?? 0;
                  _detailTotalPages = res['totalPages'] ?? 0;
                });
              } catch (e) {
                if (kDebugMode) debugPrint('[coop] failed: $e');
              } finally {
                setModalState(() => _loadingDetailedRooms = false);
              }
            }

            if (_detailedRooms.isEmpty && !_loadingDetailedRooms && _searchQueryCtrl.text.isEmpty && _filterDifficulty == null && _filterMode == null && !_filterHideFull) {
              Future.microtask(() => reloadDetailedRooms());
            }

            return Dialog(
              backgroundColor: const Color(0xFF0F0C1B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: 650,
                    height: 580,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0C1B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.explore_outlined, color: RefColors.lime, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Explorador de Salas Avanzado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.4,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: reloadDetailedRooms,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.refresh_rounded, color: RefColors.lime, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchQueryCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre de mazo o código...',
                            hintStyle: const TextStyle(color: RefColors.muted),
                            prefixIcon: const Icon(Icons.search_rounded, color: RefColors.muted, size: 18),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: .25),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: RefColors.lime),
                            ),
                          ),
                          onChanged: (val) {
                            if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                            _debounceTimer = Timer(const Duration(milliseconds: 380), () {
                              _detailPage = 1;
                              reloadDetailedRooms();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Dificultad:',
                              style: TextStyle(color: RefColors.dim, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      label: 'Todas',
                                      selected: _filterDifficulty == null,
                                      onTap: () {
                                        setModalState(() {
                                          _filterDifficulty = null;
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Fácil',
                                      selected: _filterDifficulty == 1,
                                      onTap: () {
                                        setModalState(() {
                                          _filterDifficulty = 1;
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Medio',
                                      selected: _filterDifficulty == 2,
                                      onTap: () {
                                        setModalState(() {
                                          _filterDifficulty = 2;
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Difícil',
                                      selected: _filterDifficulty == 3,
                                      onTap: () {
                                        setModalState(() {
                                          _filterDifficulty = 3;
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Modo de juego:',
                              style: TextStyle(color: RefColors.dim, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      label: 'Todos',
                                      selected: _filterMode == null,
                                      onTap: () {
                                        setModalState(() {
                                          _filterMode = null;
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Grupal',
                                      selected: _filterMode == 'grupal',
                                      onTap: () {
                                        setModalState(() {
                                          _filterMode = 'grupal';
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Versus',
                                      selected: _filterMode == 'versus',
                                      onTap: () {
                                        setModalState(() {
                                          _filterMode = 'versus';
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Libre',
                                      selected: _filterMode == 'libre',
                                      onTap: () {
                                        setModalState(() {
                                          _filterMode = 'libre';
                                          _detailPage = 1;
                                        });
                                        reloadDetailedRooms();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _filterHideFull,
                              activeColor: RefColors.lime,
                              side: const BorderSide(color: Colors.white24),
                              onChanged: (val) {
                                setModalState(() {
                                  _filterHideFull = val ?? false;
                                  _detailPage = 1;
                                });
                                reloadDetailedRooms();
                              },
                            ),
                            const Text(
                              'Ocultar salas llenas o completas',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _loadingDetailedRooms
                              ? const Center(child: CircularProgressIndicator(color: RefColors.lime, strokeWidth: 2))
                              : _detailedRooms.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.grid_view_rounded, color: Colors.white24, size: 36),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'No se encontraron salas con los filtros aplicados.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: RefColors.muted, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _detailedRooms.length,
                                      separatorBuilder: (c, i) => const SizedBox(height: 10),
                                      itemBuilder: (c, idx) {
                                        final room = _detailedRooms[idx];
                                        final code = room['code']?.toString() ?? '';
                                        final deckName = room['deckName']?.toString().isNotEmpty == true
                                            ? room['deckName'].toString()
                                            : 'Mazo Personalizado';
                                        final count = room['memberCount'] ?? 1;
                                        final maxP = room['maxPlayers'] ?? 4;
                                        final diff = room['difficulty'] ?? 1;
                                        final mode = room['mode']?.toString() ?? 'grupal';

                                        String diffLabel = 'Fácil';
                                        Color diffColor = RefColors.lime;
                                        if (diff == 2) {
                                          diffLabel = 'Medio';
                                          diffColor = Colors.orange;
                                        } else if (diff == 3) {
                                          diffLabel = 'Difícil';
                                          diffColor = RefColors.urgent;
                                        }

                                        return Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: .03),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: RefColors.lime.withValues(alpha: .12),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            code,
                                                            style: const TextStyle(
                                                              color: RefColors.lime,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w900,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: diffColor.withValues(alpha: .12),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            diffLabel.toUpperCase(),
                                                            style: TextStyle(
                                                              color: diffColor,
                                                              fontSize: 8,
                                                              fontWeight: FontWeight.w900,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white12,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            mode.toUpperCase(),
                                                            style: const TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 8,
                                                              fontWeight: FontWeight.w900,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      deckName,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '👥 $count / $maxP jugadores activos',
                                                      style: const TextStyle(color: RefColors.muted, fontSize: 10, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.pop(ctx);
                                                  _joinPublic(code);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    gradient: RefColors.primary,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text(
                                                    'Unirse →',
                                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                        ),
                        const SizedBox(height: 14),
                        if (_detailTotalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _detailPage <= 1
                                    ? null
                                    : () {
                                        setModalState(() => _detailPage--);
                                        reloadDetailedRooms();
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _detailPage <= 1 ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                  ),
                                  child: Text(
                                    '← Anterior',
                                    style: TextStyle(
                                      color: _detailPage <= 1 ? Colors.white24 : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                'Página $_detailPage de $_detailTotalPages',
                                style: const TextStyle(color: RefColors.muted, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: _detailPage >= _detailTotalPages
                                    ? null
                                    : () {
                                        setModalState(() => _detailPage++);
                                        reloadDetailedRooms();
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _detailPage >= _detailTotalPages ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                  ),
                                  child: Text(
                                    'Siguiente →',
                                    style: TextStyle(
                                      color: _detailPage >= _detailTotalPages ? Colors.white24 : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? RefColors.lime.withValues(alpha: .15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? RefColors.lime.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? RefColors.lime : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Mock de cards usadas por la partida cooperativa. En Fase 2 esto se
/// reemplaza por un fetch real al deck compartido del usuario o un
/// catálogo de "preguntas trivia" del backend. Por ahora cabe en memoria
/// y permite probar el sync end-to-end.
const List<_CoopCard> _kCoopCards = [
  _CoopCard(
    question: '¿Cuál es la función principal de los pulmones?',
    options: [
      'Filtrar impurezas del aire',
      'Intercambio de gases con la sangre',
      'Producir mucosidad protectora',
      'Regular la temperatura corporal',
    ],
    correct: 1,
  ),
  _CoopCard(
    question: '¿En qué libro inicia el Nuevo Testamento?',
    options: ['Mateo', 'Marcos', 'Génesis', 'Hechos'],
    correct: 0,
  ),
  _CoopCard(
    question: '¿Cuántos discípulos tuvo Jesús?',
    options: ['7', '12', '10', '24'],
    correct: 1,
  ),
  _CoopCard(
    question: '¿Quién escribió la mayor parte de los Salmos?',
    options: ['Salomón', 'Moisés', 'David', 'Pablo'],
    correct: 2,
  ),
];

class _CoopCard {
  final String question;
  final List<String> options;
  final int correct;
  /// Id de la tarjeta del deck que originó esta pregunta; vacío para las
  /// tarjetas creadas en caliente (no actualizan SRS).
  final String sourceCardId;
  const _CoopCard({
    required this.question,
    required this.options,
    required this.correct,
    this.sourceCardId = '',
  });
}

class CooperativoGameScreen extends StatefulWidget {
  const CooperativoGameScreen({super.key});

  @override
  State<CooperativoGameScreen> createState() => _CooperativoGameScreenState();
}

class _CooperativoGameScreenState extends State<CooperativoGameScreen> {
  CoopService? _coop;
  CoopRoomState? _state;
  StreamSubscription<CoopRoomState>? _sub;
  StreamSubscription<CoopMessage>? _msgSub;
  final Set<String> _answeredUsers = {};
  Map<String, String>? _activeHint;
  int? _selectedOption; // selección local del usuario (no aún confirmada)
  bool _answered = false; // ya contestó esta tarjeta
  String? _lastResult; // 'correct' | 'wrong'
  List<_CoopCard>? _dynamicCards;

  @override
  void initState() {
    super.initState();
    _coop = CoopService.active;
    _state = _coop?.state;
    
    _sub = _coop?.stateStream.listen((s) {
      if (!mounted) return;
      final movedCard = s.currentCardIndex != _state?.currentCardIndex;
      setState(() {
        _state = s;
        if (movedCard) {
          _selectedOption = null;
          _answered = false;
          _lastResult = null;
          _answeredUsers.clear();
          _activeHint = null;
        }
      });
    });

    _msgSub = _coop?.messages.listen((msg) {
      if (!mounted) return;
      if (msg.type == 'score') {
        setState(() {
          _answeredUsers.add(msg.userId);
        });
      } else if (msg.type == 'hint') {
        final senderName = msg.payload?['senderName'] ?? msg.userId;
        final text = msg.payload?['text'] ?? '';
        setState(() {
          _activeHint = {'sender': senderName, 'text': text};
        });
      } else if (msg.type == 'add_card') {
        final front = msg.payload?['front'] ?? '';
        final back = msg.payload?['back'] ?? '';
        if (front.isNotEmpty && back.isNotEmpty) {
          _addDynamicCardLocal(front, back);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Nueva tarjeta en caliente! 🎯'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (msg.type == 'session_end') {
        // El host terminó la partida: todos pasan a resultados. El host ya
        // navegó localmente; su pantalla desmontada ignora este mensaje.
        Navigator.pushReplacementNamed(context, AppRoutes.cooperativoLogrado);
      } else if (msg.type == 'room_closed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El host cerró la sala.'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.cooperativo);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }

  bool get _isHost {
    final me = CoopService.activeUserId;
    return me != null && _state?.hostId == me;
  }

  void _showCreateCardDialog() {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0C1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Nueva Tarjeta en Caliente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'La tarjeta se transmitirá a todos los miembros de la sala al instante.',
              style: TextStyle(color: RefColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: frontCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Pregunta / Frente',
                labelStyle: const TextStyle(color: RefColors.muted, fontSize: 12),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: RefColors.pink)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: backCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Respuesta / Dorso',
                labelStyle: const TextStyle(color: RefColors.muted, fontSize: 12),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: RefColors.pink)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: RefColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RefColors.pink),
            onPressed: () {
              final front = frontCtrl.text.trim();
              final back = backCtrl.text.trim();
              if (front.isEmpty || back.isEmpty) return;
              
              // Broadcast a la sala
              _coop?.send(CoopMessage(
                type: 'add_card',
                userId: CoopService.activeUserId ?? '',
                payload: {
                  'front': front,
                  'back': back,
                },
              ));
              
              // Agregar localmente
              _addDynamicCardLocal(front, back);
              
              Navigator.pop(ctx);
            },
            child: const Text('Agregar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addDynamicCardLocal(String front, String back) {
    final wrongOptions = [
      'Jesús lloró.',
      'En el principio creó Dios los cielos y la tierra.',
      'Jehová es mi pastor; nada me faltará.',
      'Porque de tal manera amó Dios al mundo...',
      'El amor es sufrido, es benigno...',
    ]..shuffle();
    final options = [back, wrongOptions[0], wrongOptions[1], wrongOptions[2]];
    options.shuffle();
    final correctIdx = options.indexOf(back);
    
    setState(() {
      _dynamicCards ??= [];
      _dynamicCards!.add(_CoopCard(
        question: '¿Cuál es la respuesta para: "$front"?',
        options: options,
        correct: correctIdx,
      ));
    });
  }

  List<_CoopCard> _getGameCards(BuildContext context) {
    if (_dynamicCards != null) return _dynamicCards!;
    
    final store = AppScope.of(context);
    final deck = store.decks.firstWhere(
      (d) => d.id == _state?.currentDeckId,
      orElse: () => store.activeDeck,
    );
    
    if (deck.cards.isEmpty) {
      _dynamicCards ??= [];
      return _dynamicCards!;
    }
    
    final List<_CoopCard> generated = [];
    final roomCode = _state?.code ?? 'COOP12';
    
    int targetLength = deck.cards.length;
    if (_state != null && _state!.sessionDailyTarget > 0) {
      targetLength = math.min(_state!.sessionDailyTarget, deck.cards.length);
    }
    
    for (int i = 0; i < targetLength; i++) {
      final card = deck.cards[i];
      final questionText = deck.isBible 
          ? 'Completa el versículo de ${card.source}: "${card.front}"'
          : '¿Cuál es la respuesta correcta para: "${card.front}"?';
      
      final correctAns = card.back.trim();

      final otherCards = deck.cards.where((c) => c.id != card.id).toList();
      final shuffledOthers = _deterministicShuffle(otherCards, '${card.id}_$roomCode');
      final wrongOptions = shuffledOthers.map((c) => c.back.trim()).toSet().toList();

      // Relleno solo para decks con menos de 4 tarjetas: opciones acordes
      // al tipo de deck para no mezclar versículos en mazos de otro tema.
      final fallbacks = deck.isBible
          ? const [
              'Jesús lloró.',
              'En el principio creó Dios los cielos y la tierra.',
              'Jehová es mi pastor; nada me faltará.',
              'Porque de tal manera amó Dios al mundo...',
              'El amor es sufrido, es benigno...',
            ]
          : const [
              'Ninguna de las otras opciones es correcta.',
              'Es un concepto que no pertenece a este mazo.',
              'La definición corresponde a otra tarjeta.',
              'No aplica para esta pregunta.',
              'Es lo contrario de la respuesta correcta.',
            ];
      final shuffledFallbacks = _deterministicShuffle(fallbacks, '${card.id}_fallbacks_$roomCode');

      int fallbackIdx = 0;
      while (wrongOptions.length < 3) {
        final dist = shuffledFallbacks[fallbackIdx % shuffledFallbacks.length];
        fallbackIdx++;
        if (dist != correctAns && !wrongOptions.contains(dist)) {
          wrongOptions.add(dist);
        }
      }

      final wrong3 = wrongOptions.take(3).toList();
      final allOptions = [correctAns, ...wrong3];
      final shuffledOptions = _deterministicShuffle(allOptions, '${card.id}_options_$roomCode');
      final correctIdx = shuffledOptions.indexOf(correctAns);

      generated.add(_CoopCard(
        question: questionText,
        options: shuffledOptions,
        correct: correctIdx,
        sourceCardId: card.id,
      ));
    }
    
    _dynamicCards = generated;
    return generated;
  }

  void _confirm() {
    if (_answered || _selectedOption == null) return;
    final gameCards = _getGameCards(context);
    final cardIndex = _state!.currentCardIndex % gameCards.length;
    final currentCard = gameCards[cardIndex];
    final correct = _selectedOption == currentCard.correct;
    setState(() {
      _answered = true;
      _lastResult = correct ? 'correct' : 'wrong';
      _answeredUsers.add(CoopService.activeUserId ?? '');
    });
    // Reportar puntos al server: +10 acierto, +0 fallo.
    _coop?.reportScore(correct ? 10 : 0);

    // Bitácora local para el recap real de la pantalla de resultados.
    _coop?.answerLog.add(CoopAnswerRecord(
      cardIndex: cardIndex,
      question: currentCard.question,
      correctAnswer: currentCard.options[currentCard.correct],
      wasCorrect: correct,
    ));

    // Paridad con el solitario: el repaso cooperativo también alimenta el SRS.
    final sourceCardId = currentCard.sourceCardId;
    final deckId = _state?.currentDeckId;
    if (sourceCardId.isNotEmpty && deckId != null && deckId.isNotEmpty) {
      AppScope.of(context).recordCoopAnswer(
        deckId: deckId,
        cardId: sourceCardId,
        correct: correct,
      );
    }
  }

  void _next() {
    if (!_isHost) return;
    final gameCards = _getGameCards(context);
    final next = (_state?.currentCardIndex ?? 0) + 1;
    if (next >= gameCards.length) {
      // Notificar a TODOS (incluido este host, vía relay) que terminó la
      // partida; los guests navegan al recibir 'session_end'.
      _coop?.broadcastSessionEnd();
      Navigator.pushReplacementNamed(context, AppRoutes.cooperativoLogrado);
      return;
    }
    _coop?.broadcastCard(deckId: _state?.currentDeckId ?? 'mock-deck', cardIndex: next);
  }

  /// Salida limpia de la partida: el host cierra la sala para todos; el
  /// invitado solo se desconecta. Siempre vuelve al lobby cooperativo.
  Future<void> _leaveRoom() async {
    final exitConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0C1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isHost ? '¿Cerrar la sala?' : '¿Salir de la partida?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Text(
          _isHost
              ? 'Eres el host: la sala se cerrará para todos los jugadores.'
              : 'Saldrás de la partida; el resto puede seguir jugando.',
          style: const TextStyle(color: RefColors.muted, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: RefColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RefColors.urgent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (exitConfirmed != true || !mounted) return;
    if (_isHost) {
      _coop?.broadcastRoomClosed();
    }
    await _coop?.disconnect();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.cooperativo);
  }

  void _shareHint() {
    final coop = _coop;
    if (coop == null || _state == null) return;
    final gameCards = _getGameCards(context);
    final currentCard = gameCards[_state!.currentCardIndex % gameCards.length];
    final correctAnsText = currentCard.options[currentCard.correct];
    
    final firstChar = correctAnsText.isNotEmpty ? correctAnsText[0].toUpperCase() : '';
    final hintText = 'La respuesta empieza con "$firstChar" y tiene ${correctAnsText.length} letras.';
    
    final me = CoopService.activeUserId ?? 'Yo';
    coop.send(CoopMessage(
      type: 'hint',
      userId: me,
      payload: {
        'text': hintText,
        'senderName': me,
      },
    ));
    coop.hintsShared++;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Pista compartida con el equipo! 💡'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (_coop == null || state == null) {
      return ReferencePage(
        showBottomNav: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CoopTopBar(center: 'Sala desconectada'),
            const SizedBox(height: 24),
            const Text(
              'Perdiste conexión con la sala. Vuelve al lobby para crear o unirte de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: RefColors.muted),
            ),
            const SizedBox(height: 24),
            Cta(
              'Volver al lobby',
              onTap: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.cooperativo,
              ),
            ),
          ],
        ),
      );
    }
    final gameCards = _getGameCards(context);
    
    if (gameCards.isEmpty) {
      return ReferencePage(
        showBottomNav: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CoopTopBar(
              center: 'SALA · ESPERANDO TARJETAS',
              live: true,
            ),
            const SizedBox(height: 14),
            _CoopTeamRow(state: state, answeredUsers: _answeredUsers),
            const SizedBox(height: 24),
            
            // Mazo vacío panel
            Glass(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.style_outlined,
                    color: RefColors.pink,
                    size: 48,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Mazo vacío en tiempo real',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '¡Creen tarjetas en vivo con sus amigos y jueguen al instante!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Cta(
                    '+ Crear Tarjeta en Caliente',
                    onTap: _showCreateCardDialog,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    '← Salir de sala',
                    onTap: _leaveRoom,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final card = gameCards[state.currentCardIndex % gameCards.length];
    final progress = (state.currentCardIndex + 1) / gameCards.length;

    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoopTopBar(
            center: 'EN JUEGO · ${state.currentCardIndex + 1}/${gameCards.length}',
            live: true,
          ),
          const SizedBox(height: 8),
          _CoopTeamRow(state: state, answeredUsers: _answeredUsers),
          const SizedBox(height: 14),
          RefProgress(progress.clamp(0.0, 1.0)),
          const SizedBox(height: 14),
          _CoopQuestionCard(
            index: state.currentCardIndex,
            total: gameCards.length,
            question: card.question,
            difficulty: state.sessionDifficulty,
          ),
          if (_activeHint != null) ...[
            const SizedBox(height: 10),
            _SharedHint(
              sender: _activeHint!['sender']!,
              text: _activeHint!['text']!,
            ),
          ],
          const SizedBox(height: 14),
          for (var i = 0; i < card.options.length; i++) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _answered ? null : () => setState(() => _selectedOption = i),
              child: _CoopOption(
                letter: String.fromCharCode(65 + i),
                text: card.options[i],
                selected: _selectedOption == i,
                voter: _answered && i == card.correct ? '✓' : null,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          if (_lastResult == 'correct')
            const _ResultBanner(
              text: '✓ Correcto · +10 puntos',
              color: RefColors.lime,
            )
          else if (_lastResult == 'wrong')
            _ResultBanner(
              text: '✗ Falló — la respuesta era ${card.options[card.correct]}',
              color: RefColors.urgent,
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  '← Salir',
                  onTap: _leaveRoom,
                ),
              ),
              const SizedBox(width: 8),
              if (!_answered) ...[
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: RefColors.pink),
                  onPressed: _showCreateCardDialog,
                  tooltip: 'Crear tarjeta en caliente',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.lightbulb_outline, color: RefColors.sun),
                  onPressed: _shareHint,
                  tooltip: 'Compartir pista con el grupo',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Cta(
                    'Confirmar →',
                    onTap: _selectedOption == null ? null : _confirm,
                    disabled: _selectedOption == null,
                  ),
                ),
              ] else if (_isHost)
                Expanded(
                  child: Cta(
                    state.currentCardIndex + 1 >= gameCards.length
                        ? 'Finalizar →'
                        : 'Siguiente →',
                    onTap: _next,
                  ),
                )
              else
                const Expanded(
                  child: Glass(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Esperando al host…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: RefColors.muted, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _CoopGameChat(),
        ],
      ),
    );
  }
}



class _ResultBanner extends StatelessWidget {
  final String text;
  final Color color;
  const _ResultBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class CooperativoSuccessScreen extends StatelessWidget {
  const CooperativoSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CoopTopBar(center: 'Sala cerrada'),
          const _CoopCelebrateCard(),
          const SizedBox(height: 14),
          const _CoopScoreCard(),
          const SizedBox(height: 14),
          const _CoopShareCard(),
          const SizedBox(height: 14),
          const _CoopRecapCard(),
          const SizedBox(height: 14),
          const _CoopAchievements(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Salir',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.amigos),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Cta(
                  'Otra ronda →',
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.cooperativo,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoopTopBar extends StatelessWidget {
  final String center;
  final bool live;
  final VoidCallback? onBack;

  const _CoopTopBar({required this.center, this.live = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          RefBackButton(onTap: onBack),
          Expanded(
            child: Center(
              child: RefChip(
                center,
                dense: true,
                color: live
                    ? RefColors.lime.withValues(alpha: .16)
                    : RefColors.glassStrong,
                textColor: live ? RefColors.lime : RefColors.ink,
              ),
            ),
          ),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}



class _CoopLobbyCard extends StatefulWidget {
  final CoopRoomState roomState;
  final VoidCallback onInviteTap;
  const _CoopLobbyCard({
    required this.roomState,
    required this.onInviteTap,
  });

  @override
  State<_CoopLobbyCard> createState() => _CoopLobbyCardState();
}

class _CoopLobbyCardState extends State<_CoopLobbyCard> {
  final List<(String, String, String)> _chatMessages = [];
  StreamSubscription<CoopMessage>? _msgSub;
  final _textController = TextEditingController();
  List<RemoteUser> _myFriends = [];
  List<Friendship> _pendingRequests = [];
  bool _loadingFriends = false;

  @override
  void initState() {
    super.initState();
    final coop = CoopService.active;
    if (coop != null) {
      _msgSub = coop.messages.listen((msg) {
        if (msg.type == 'chat' && mounted) {
          final senderName = msg.payload?['senderName'] ?? msg.userId;
          final text = msg.payload?['text'] ?? '';
          final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
          setState(() {
            _chatMessages.add((initial, '$senderName:', text));
          });
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFriends());
  }

  Future<void> _fetchFriends() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    setState(() => _loadingFriends = true);
    try {
      final res = await store.api.listFriends();
      if (mounted) {
        setState(() {
          _myFriends = res.friends;
          _pendingRequests = res.pendingRequests;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final coop = CoopService.active;
    if (coop == null) return;
    
    final me = CoopService.activeUserId ?? 'Yo';
    coop.send(CoopMessage(
      type: 'chat',
      userId: me,
      payload: {
        'text': text,
        'senderName': me,
      },
    ));
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final memberIds = widget.roomState.memberIds.toList();
    final hostId = widget.roomState.hostId;
    final me = AppScope.of(context).effectiveUser.id;

    return Glass(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .34),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '✨ Sala Cooperativa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              RefChip(
                '${memberIds.length} / 4 Jugadores',
                dense: true,
                color: RefColors.lime.withValues(alpha: .15),
                textColor: RefColors.lime,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Giant copiable Room Code Box
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.roomState.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0F0C1B),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: RefColors.lime),
                      const SizedBox(width: 8),
                      Text(
                        '¡Código de sala ${widget.roomState.code} copiado! 📋',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: RefColors.lime.withValues(alpha: .4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: RefColors.lime.withValues(alpha: .1),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text(
                        'CÓDIGO DE LA SALA',
                        style: TextStyle(
                          color: RefColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.roomState.code,
                        style: const TextStyle(
                          color: RefColors.lime,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.copy_all_rounded,
                    color: RefColors.lime,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Participantes Dinámicos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < memberIds.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _showMemberProfile(memberIds[i]),
                  child: Builder(
                    builder: (context) {
                      final displayName = widget.roomState.memberNames[memberIds[i]] ?? memberIds[i];
                      return _CoopParticipant(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        memberIds[i] == me ? '$displayName (tú)' : displayName,
                        memberIds[i] == hostId ? 'Host' : 'Listo',
                        host: memberIds[i] == hostId,
                        ready: true,
                        gradient: memberIds[i] == me
                            ? RefColors.cool
                            : (i % 2 == 0 ? RefColors.primary : RefColors.purple),
                      );
                    }
                  ),
                ),
              ],
              if (memberIds.length < 4) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: widget.onInviteTap,
                  child: const _CoopParticipant(
                    '+',
                    'Invitar',
                    '1 libre',
                    empty: true,
                  ),
                ),
              ],
            ],
          ),
          
          // Listado de Amigos Integrado
          if (_myFriends.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TUS AMIGOS (TOCA PARA INVITAR):',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myFriends.length,
                itemBuilder: (context, idx) {
                  final f = _myFriends[idx];
                  final name = f.displayName.isNotEmpty ? f.displayName : f.email;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () async {
                        Clipboard.setData(ClipboardData(text: widget.roomState.code));
                        final store = AppScope.of(context);
                        
                        try {
                          await store.api.sendCoopInvite(
                            friendUserId: f.id,
                            roomCode: widget.roomState.code,
                            hostName: store.effectiveUser.effectiveName,
                          );
                        } catch (e) {
                          debugPrint('Error sending coop invite: $e');
                        }

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0F0C1B),
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: RefColors.lime),
                                const SizedBox(width: 8),
                                Text(
                                  '¡Invitación enviada a $name! ✉️ (Código copiado) 📋',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: .1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Fav(f.initial, size: 20, gradient: RefColors.cool),
                                if (f.isOnline)
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: RefColors.lime,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF0F0C1B), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: RefColors.lime.withValues(alpha: 0.6),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: RefColors.lime,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 18),
          
          // Chat dinámico
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: RefColors.inner)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_chatMessages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '¡Di algo en la sala para empezar el chat! 💬',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: RefColors.dim, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, idx) {
                        final message = _chatMessages[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Fav(
                                message.$1,
                                size: 24,
                                gradient: message.$1 == 'Y' || message.$2.startsWith(me)
                                    ? RefColors.primary
                                    : RefColors.purple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: RefColors.muted,
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${message.$2} ',
                                        style: const TextStyle(
                                          color: RefColors.ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(text: message.$3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                  decoration: BoxDecoration(
                    color: RefColors.glassSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RefColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                            color: RefColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Escribe un mensaje...',
                            hintStyle: TextStyle(
                              color: RefColors.dim,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: RefColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_forward, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberProfile(String targetUserId) {
    final store = AppScope.of(context);
    final me = store.effectiveUser.id;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .5),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: FutureBuilder<UserProfileResult>(
              future: store.api.getUser(targetUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: RefColors.lime),
                  );
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return Glass(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: RefColors.urgent, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'No se pudo cargar el perfil',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error?.toString() ?? 'Error desconocido',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: RefColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Cta(
                          'Cerrar',
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
                
                final profile = snapshot.data!;
                final user = profile.user;
                final achievements = profile.achievements;
                final sharedCount = profile.sharedCount;
                final achievementsCount = profile.achievementsCount;
                
                final displayName = user.displayName.isNotEmpty ? user.displayName : user.email;
                final email = user.email.isNotEmpty ? user.email : 'Sin correo';
                final isMe = user.id == me;
                
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    final isFriend = _myFriends.any((f) => f.id == user.id);
                    final isPending = _pendingRequests.any((f) =>
                        (f.requesterId == me && f.addresseeId == user.id) ||
                        (f.requesterId == user.id && f.addresseeId == me));
                    
                    bool requesting = false;
                    
                    return Glass(
                      padding: const EdgeInsets.all(24),
                      gradient: LinearGradient(
                        colors: [
                          RefColors.violet.withValues(alpha: .24),
                          RefColors.pink.withValues(alpha: .24),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: RefColors.dim,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Fav(
                            user.initial,
                            size: 80,
                            gradient: isMe
                                ? RefColors.cool
                                : (user.id.hashCode % 2 == 0 ? RefColors.primary : RefColors.purple),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: RefColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${user.id}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: RefColors.dim,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Bento style Row for user stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Shared decks count
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: .05)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'COMPARTIDOS',
                                        style: TextStyle(
                                          color: RefColors.dim,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '📚 $sharedCount ${sharedCount == 1 ? "Mazo" : "Mazos"}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Achievements count
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: .05)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'LOGROS',
                                        style: TextStyle(
                                          color: RefColors.dim,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '🏆 $achievementsCount ${achievementsCount == 1 ? "Insignia" : "Insignias"}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Recents achievements
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'LOGROS Y MEDALLAS RECIENTES:',
                              style: TextStyle(
                                color: RefColors.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (achievements.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: .03)),
                              ),
                              child: const Text(
                                'Aún no ha desbloqueado insignias de estudio. ⏳',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: RefColors.dim,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: achievements.length,
                                itemBuilder: (context, idx) {
                                  final ach = achievements[idx];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .06),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: .08)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          ach.emoji.isNotEmpty ? ach.emoji : '🏆',
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              ach.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ach.description,
                                              style: const TextStyle(
                                                color: RefColors.dim,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          if (isMe)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: RefColors.cool.colors.first.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: RefColors.cool.colors.first.withValues(alpha: .3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_pin_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Este eres tú ♕',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isFriend)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: RefColors.lime.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: RefColors.lime.withValues(alpha: .3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_alt_rounded, color: RefColors.lime, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    '¡Ya son amigos! 👥',
                                    style: TextStyle(
                                      color: RefColors.lime,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: RefColors.sun.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: RefColors.sun.withValues(alpha: .3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.hourglass_empty_rounded, color: RefColors.sun, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Solicitud pendiente ⏳',
                                    style: TextStyle(
                                      color: RefColors.sun,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Cta(
                              requesting ? 'Enviando...' : 'Agregar como amigo ＋',
                              disabled: requesting,
                              onTap: () async {
                                setModalState(() {
                                  requesting = true;
                                });
                                try {
                                  await store.api.requestFriend(user.id);
                                  await _fetchFriends();
                                  
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF0F0C1B),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: RefColors.lime),
                                          const SizedBox(width: 8),
                                          Text(
                                            '¡Solicitud de amistad enviada a $displayName! 🎉',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() {
                                    requesting = false;
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF0F0C1B),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: RefColors.urgent),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Error: ${e.toString()}',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CoopParticipant extends StatelessWidget {
  final String initials;
  final String name;
  final String status;
  final bool host;
  final bool ready;
  final bool empty;
  final bool loading;
  final Gradient gradient;

  const _CoopParticipant(
    this.initials,
    this.name,
    this.status, {
    this.host = false,
    this.ready = false,
    this.empty = false,
    this.loading = false,
    this.gradient = RefColors.cool,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: empty ? Colors.transparent : null,
        gradient: empty ? null : gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: host ? RefColors.sun : RefColors.border,
          width: host ? 2 : 1,
          style: empty ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: host
            ? [
                BoxShadow(
                  color: RefColors.sun.withValues(alpha: .36),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: empty ? RefColors.dim : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              if (ready)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: RefColors.lime,
                      shape: BoxShape.circle,
                      border: Border.all(color: RefColors.bg, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: RefColors.successInk,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            host ? '$name ♕' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: empty ? RefColors.dim : RefColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: loading ? RefColors.sun : RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}



List<T> _deterministicShuffle<T>(List<T> list, String seedString) {
  final copy = List<T>.from(list);
  int hash = 0;
  for (int i = 0; i < seedString.length; i++) {
    hash = 31 * hash + seedString.codeUnitAt(i);
  }
  final rand = math.Random(hash);
  for (int i = copy.length - 1; i > 0; i--) {
    final j = rand.nextInt(i + 1);
    final temp = copy[i];
    copy[i] = copy[j];
    copy[j] = temp;
  }
  return copy;
}

class _CoopSettingsCard extends StatelessWidget {
  final CoopRoomState roomState;
  final VoidCallback onCreateDeckTap;

  const _CoopSettingsCard({
    required this.roomState,
    required this.onCreateDeckTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final isHost = roomState.hostId == store.effectiveUser.id;
    final coop = CoopService.active;
    
    // Find the deck based on lobbyDeckId (no fallback to activeDeck)
    final deck = (roomState.lobbyDeckId != null && roomState.lobbyDeckId!.isNotEmpty)
        ? store.decks.firstWhere(
            (d) => d.id == roomState.lobbyDeckId,
            orElse: () => store.activeDeck,
          )
        : null;

    final String deckTitle = isHost 
        ? (store.decks.isEmpty 
            ? 'Sin mazos todavía' 
            : (deck == null ? 'Ninguno seleccionado (toca para elegir)' : (deck.title.isEmpty ? 'Mazo sin título' : deck.title)))
        : (roomState.lobbyDeckName?.isNotEmpty == true ? roomState.lobbyDeckName! : 'Esperando a que el Host elija mazo…');

    final String actionText = store.decks.isEmpty
        ? 'Crear'
        : (roomState.lobbyDeckId == null || roomState.lobbyDeckId!.isEmpty ? 'Elegir' : 'Cambiar →');

    // Mapear modo cooperativo a descripción
    String modeDesc = '1x1 van respondiendo ordenadamente';
    String modeLabel = 'Prueba por Turno';
    if (roomState.mode == 'libre') {
      modeDesc = 'Cualquiera responde · 8s cooldown si fallas';
      modeLabel = 'Estudio Libre';
    }

    final totalCards = deck?.cards.length ?? 0;
    final recommended = totalCards <= 0 ? 3 : ((totalCards / 12).ceil()).clamp(2, 3);
    final currentTarget = roomState.sessionDailyTarget == 0 ? recommended : roomState.sessionDailyTarget;

    String limitStr = 'de $currentTarget en $currentTarget';
    if (currentTarget == 1) {
      limitStr = 'de 1 en 1 (Breve)';
    } else if (currentTarget == recommended) {
      limitStr = 'de $recommended en $recommended (Recomendado)';
    } else if (currentTarget == 4) {
      limitStr = 'de 4 en 4 (Intenso)';
    }

    final diffLabels = {0: 'Fácil', 1: 'Media', 2: 'Difícil'};
    final diffStr = diffLabels[roomState.sessionDifficulty] ?? 'Media';
    
    // Si no hay mazo, advertir en subtítulo
    final cardsSubtitle = deck == null 
        ? 'Dificultad: $diffStr · Selecciona un mazo primero'
        : 'Dificultad: $diffStr · Aprender: $limitStr';

    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONFIGURACIÓN DE LA SALA',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _CoopSettingRow(
            'Mazo',
            deckTitle,
            isHost ? actionText : 'Activo',
            onTap: isHost
                ? () {
                    if (store.decks.isEmpty) {
                      onCreateDeckTap();
                    } else {
                      _showDeckSelector(context);
                    }
                  }
                : null,
          ),
          _CoopSettingRow(
            'Modo',
            modeDesc,
            isHost ? '$modeLabel ⚙' : modeLabel,
            onTap: isHost ? () => _showModeSelector(context) : null,
          ),
          _CoopSettingRow(
            'Visibilidad',
            roomState.isPublic 
                ? 'Pública · visible para tus amigos y activa'
                : 'Privada · solo acceso directo con código',
            isHost 
                ? (roomState.isPublic ? 'Pública 🔓' : 'Privada 🔒')
                : (roomState.isPublic ? 'Pública' : 'Privada'),
            onTap: isHost 
                ? () {
                    if (coop != null) {
                      coop.broadcastVisibility(!roomState.isPublic);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0F0C1B),
                          content: Text(
                            roomState.isPublic 
                                ? 'Sala configurada como PRIVADA 🔒'
                                : 'Sala configurada como PÚBLICA 🔓',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
          ),
          _CoopSettingRow(
            'Sesión',
            cardsSubtitle,
            isHost ? 'Configurar ⚙' : 'Configurado',
            onTap: isHost
                ? () {
                    if (deck == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0F0C1B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: RefColors.pink),
                              SizedBox(width: 10),
                              Text(
                                'Selecciona un mazo primero',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CooperativoConfigScreen(),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showModeSelector(BuildContext context) {
    final coop = CoopService.active;
    if (coop == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F0C1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Selecciona el modo cooperativo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.groups_rounded, color: RefColors.lime),
                title: const Text('Prueba por Turno', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('1x1 van respondiendo ordenadamente', style: TextStyle(color: RefColors.muted, fontSize: 11)),
                trailing: roomState.mode == 'turnos' ? const Icon(Icons.check_circle, color: RefColors.lime) : null,
                onTap: () {
                  coop.broadcastMode('turnos');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bolt_rounded, color: RefColors.cyan),
                title: const Text('Estudio Libre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Cualquiera responde · 8s cooldown si fallas', style: TextStyle(color: RefColors.muted, fontSize: 11)),
                trailing: roomState.mode == 'libre' ? const Icon(Icons.check_circle, color: RefColors.cyan) : null,
                onTap: () {
                  coop.broadcastMode('libre');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDeckSelector(BuildContext context) {
    final store = AppScope.of(context);
    final coop = CoopService.active;
    if (coop == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F0C1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Selecciona un mazo para la sala',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (store.decks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No tienes mazos creados todavía.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RefColors.muted),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: store.decks.length,
                    itemBuilder: (context, idx) {
                      final d = store.decks[idx];
                      final isSelected = d.id == roomState.lobbyDeckId;
                      return ListTile(
                        onTap: () {
                          store.setActiveDeck(d.id);
                          final cardsList = d.cards.map((c) => {
                            'id': c.id,
                            'front': c.front,
                            'back': c.back,
                            'source': c.source,
                            'icon': c.icon,
                            'retention': c.retention,
                            'lapses': c.lapses,
                          }).toList();
                          coop.broadcastLobbyDeck(deckId: d.id, deckName: d.title, cards: cardsList);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mazo configurado a: ${d.title} 🎯'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CooperativoConfigScreen(),
                            ),
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? RefColors.lime.withValues(alpha: .15)
                                : Colors.white.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.style_outlined,
                            color: RefColors.lime,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          d.title.isEmpty ? 'Mazo sin título' : d.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${d.cards.length} tarjetas',
                          style: const TextStyle(color: RefColors.muted, fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_outline, color: RefColors.lime)
                            : null,
                      );
                    },
                  ),
                ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  onCreateDeckTap();
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RefColors.pink.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: RefColors.pink,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Crear mazo nuevo...',
                  style: TextStyle(
                    color: RefColors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Crea un mazo bíblico o de texto para esta sala',
                  style: TextStyle(color: RefColors.muted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }


}

class _CoopSettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onTap;

  const _CoopSettingRow(this.title, this.subtitle, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: RefColors.inner)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            RefChip(
              value,
              dense: true,
              color: onTap != null ? RefColors.lime.withValues(alpha: .15) : null,
              textColor: onTap != null ? RefColors.lime : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoopTeamRow extends StatelessWidget {
  final CoopRoomState state;
  final Set<String> answeredUsers;
  final String? activeTurnUserId;
  final Set<String> failedUserIds;

  const _CoopTeamRow({
    required this.state,
    required this.answeredUsers,
    this.activeTurnUserId,
    this.failedUserIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    final entries = state.memberIds.toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildMate(entries[i], context),
          ],
        ],
      ),
    );
  }

  Widget _buildMate(String userId, BuildContext context) {
    final isMe = userId == CoopService.activeUserId;
    final rawName = state.memberNames[userId];
    final displayName = isMe ? 'Tú' : (rawName == null || rawName.isEmpty ? userId : rawName);
    
    final hasFailed = failedUserIds.contains(userId);
    final isActive = activeTurnUserId == userId;
    
    final String statusText;
    if (hasFailed) {
      statusText = '❌ Inhabilitado';
    } else if (isActive) {
      statusText = isMe ? '⚡ ¡TU TURNO!' : '⚡ Su turno';
    } else {
      statusText = 'Espera';
    }

    final gradients = [
      RefColors.primary,
      RefColors.purple,
      RefColors.cool,
      RefColors.success,
    ];
    final gradient = gradients[userId.hashCode % gradients.length];

    final avatarLetter = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

    return _CoopMate(
      avatarLetter,
      displayName,
      statusText,
      done: isActive,
      answering: !hasFailed && !isActive,
      failed: hasFailed,
      isMe: isMe,
      gradient: gradient,
    );
  }
}

class _CoopMate extends StatelessWidget {
  final String avatar;
  final String name;
  final String status;
  final bool done;
  final bool answering;
  final bool failed;
  final bool isMe;
  final Gradient gradient;

  const _CoopMate(
    this.avatar,
    this.name,
    this.status, {
    this.done = false,
    this.answering = false,
    this.failed = false,
    this.isMe = false,
    this.gradient = RefColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white.withValues(alpha: 0.05);
    Color statusColor = RefColors.muted;
    
    if (failed) {
      borderColor = RefColors.pink.withValues(alpha: 0.3);
      statusColor = RefColors.pink;
    } else if (done) {
      borderColor = RefColors.lime.withValues(alpha: 0.5);
      statusColor = RefColors.lime;
    } else if (answering) {
      statusColor = RefColors.muted;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isMe ? 2 : 1.5,
        ),
        boxShadow: done ? [
          BoxShadow(
            color: RefColors.lime.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 0,
          )
        ] : null,
      ),
      child: Glass(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Fav(avatar, size: 30, gradient: gradient),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoopQuestionCard extends StatelessWidget {
  final int index;
  final int total;
  final String question;
  final int difficulty;

  const _CoopQuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PREGUNTA ${index + 1} / $total',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              RefChip(
                difficulty == 0 ? '🌿 FÁCIL' : difficulty == 1 ? '🌳 MEDIA' : '🔥 DIFÍCIL',
                dense: true,
                color: difficulty == 0
                    ? RefColors.lime.withValues(alpha: .15)
                    : difficulty == 1
                        ? RefColors.cyan.withValues(alpha: .15)
                        : RefColors.pink.withValues(alpha: .15),
                textColor: difficulty == 0
                    ? RefColors.lime
                    : difficulty == 1
                        ? RefColors.cyan
                        : RefColors.pink,
              ),
              const SizedBox(width: 8),
              const Text(
                'Turno grupal',
                style: TextStyle(
                  color: RefColors.sun,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: const TextStyle(
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedHint extends StatelessWidget {
  final String sender;
  final String text;

  const _SharedHint({required this.sender, required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.sun.withValues(alpha: .12),
      border: Border.all(color: RefColors.sun.withValues(alpha: .34)),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$sender compartió una pista',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  '"$text"',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopOption extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final String? voter;

  const _CoopOption({
    required this.letter,
    required this.text,
    this.selected = false,
    this.voter,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: selected ? RefColors.cyan.withValues(alpha: .14) : RefColors.glass,
      border: Border.all(
        color: selected
            ? RefColors.cyan.withValues(alpha: .52)
            : RefColors.border,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? RefColors.cyan : RefColors.glassSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.transparent : RefColors.border,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? const Color(0xFF003A4A) : RefColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          if (voter != null) Fav(voter!, size: 22),
        ],
      ),
    );
  }
}

class _CoopGameChat extends StatefulWidget {
  const _CoopGameChat();

  @override
  State<_CoopGameChat> createState() => _CoopGameChatState();
}

class _CoopGameChatState extends State<_CoopGameChat> {
  final List<(String, String, String)> _chatMessages = [];
  StreamSubscription<CoopMessage>? _msgSub;
  final _textController = TextEditingController();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final coop = CoopService.active;
    if (coop != null) {
      _msgSub = coop.messages.listen((msg) {
        if (msg.type == 'chat' && mounted) {
          final senderName = msg.payload?['senderName'] ?? msg.userId;
          final text = msg.payload?['text'] ?? '';
          final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
          setState(() {
            _chatMessages.add((initial, '$senderName:', text));
            // Si el chat está colapsado y llega un mensaje nuevo, podemos decidir
            // dejarlo colapsado pero la vista previa se actualizará automáticamente.
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final coop = CoopService.active;
    if (coop == null) return;
    
    final me = CoopService.activeUserId ?? 'Yo';
    coop.send(CoopMessage(
      type: 'chat',
      userId: me,
      payload: {
        'text': text,
        'senderName': me,
      },
    ));
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      final lastMsg = _chatMessages.isNotEmpty ? _chatMessages.last : null;
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Glass(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: RefColors.lime,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lastMsg != null
                        ? '${lastMsg.$2} ${lastMsg.$3}'
                        : 'Chat de la sala · toca para expandir... 💬',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: lastMsg != null ? Colors.white70 : RefColors.dim,
                      fontSize: 11,
                      fontWeight: lastMsg != null ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: RefColors.muted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          color: RefColors.lime,
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CHAT DE LA SALA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_chatMessages.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: RefColors.lime.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_chatMessages.length}',
                              style: const TextStyle(
                                color: RefColors.lime,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: RefColors.muted,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: RefColors.border, height: 1, thickness: 1),
          const SizedBox(height: 8),
          if (_chatMessages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '¡Di algo para empezar el chat! 💬',
                style: TextStyle(color: RefColors.dim, fontSize: 11),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _chatMessages.length,
                itemBuilder: (context, idx) {
                  final message = _chatMessages[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Fav(
                          message.$1,
                          size: 24,
                          gradient: message.$1 == 'L'
                              ? RefColors.purple
                              : RefColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: RefColors.muted,
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: '${message.$2} ',
                                  style: const TextStyle(
                                    color: RefColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(text: message.$3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RefColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(
                      color: RefColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                        color: RefColors.dim,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: RefColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopCelebrateCard extends StatelessWidget {
  const _CoopCelebrateCard();

  /// Resumen real de la partida: jugadores de la sala y aciertos del
  /// scoreboard. Sin números fingidos.
  String _buildSummary() {
    final coop = CoopService.active;
    final state = coop?.state;
    if (state == null) return 'Sesión cooperativa completada';
    final playerCount = state.memberIds.length;
    final totalCorrect = state.scores.values
        .fold<int>(0, (sum, score) => sum + score ~/ 10);
    final parts = <String>[
      '$playerCount ${playerCount == 1 ? 'jugador' : 'jugadores'}',
      '$totalCorrect ${totalCorrect == 1 ? 'acierto' : 'aciertos'} del equipo',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      gradient: RefColors.success,
      border: const Border(),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 6),
          const Text(
            '¡Lo lograron juntos!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.successInk,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _buildSummary(),
            style: const TextStyle(
              color: RefColors.successInk,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopScoreCard extends StatelessWidget {
  const _CoopScoreCard();

  @override
  Widget build(BuildContext context) {
    final coop = CoopService.active;
    final state = coop?.state;
    
    if (state == null) {
      return Glass(
        padding: const EdgeInsets.all(18),
        child: const Center(
          child: Text(
            'No hay datos de sesión disponibles',
            style: TextStyle(color: RefColors.muted),
          ),
        ),
      );
    }

    final members = state.memberIds.toList()..sort();
    final scores = state.scores;
    
    int totalCorrect = 0;
    for (final m in members) {
      final score = scores[m] ?? 0;
      totalCorrect += score ~/ 10;
    }
    
    final target = state.sessionDailyTarget > 0 ? state.sessionDailyTarget : 1;
    final percent = ((totalCorrect / (target * members.length)) * 100).clamp(0.0, 100.0).round();

    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [RefColors.lime, RefColors.lime, RefColors.glassSoft],
                    stops: [0, .85, .85],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: RefColors.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percent%',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'COMPLETADO',
                        style: TextStyle(
                          color: RefColors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _CoopScoreRow('Total correctas', '$totalCorrect'),
                    _CoopScoreRow('Objetivo sala', '$target por jugador'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          const Text(
            'RESPUESTAS CORRECTAS POR MIEMBRO (ORDEN NEUTRAL)',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          for (final m in members) ...[
            _buildMemberScoreRow(m, scores[m] ?? 0),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberScoreRow(String userId, int score) {
    final state = CoopService.active?.state;
    final isMe = userId == CoopService.activeUserId;
    final rawName = state?.memberNames[userId];
    final displayName = isMe ? 'Tú' : (rawName == null || rawName.isEmpty ? userId : rawName);
    final name = isMe ? '$displayName ($userId)' : displayName;
    final correct = score ~/ 10;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: RefColors.lime,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isMe ? Colors.white : RefColors.muted,
                fontSize: 13,
                fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$correct correctas',
            style: const TextStyle(
              color: RefColors.lime,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopScoreRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoopScoreRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CoopShareCard extends StatelessWidget {
  const _CoopShareCard();

  String _buildShareSummary() {
    final coop = CoopService.active;
    final state = coop?.state;
    final answerLog = coop?.answerLog ?? const <CoopAnswerRecord>[];
    final correctCount = answerLog.where((record) => record.wasCorrect).length;
    final buffer = StringBuffer('🎉 ¡Sesión cooperativa completada en Memorizar!\n');
    if (state != null) {
      buffer.writeln('Mazo: ${state.lobbyDeckName ?? 'sin nombre'} · Sala ${state.code}');
      buffer.writeln('Jugadores: ${state.memberIds.length}');
    }
    if (answerLog.isNotEmpty) {
      buffer.writeln('Mis aciertos: $correctCount/${answerLog.length}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Text('📸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparte el logro del grupo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Copia el resumen · sin cuenta necesaria',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: _buildShareSummary()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resumen copiado al portapapeles 📋'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Compartir',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopRecapCard extends StatelessWidget {
  const _CoopRecapCard();

  @override
  Widget build(BuildContext context) {
    final answerLog = CoopService.active?.answerLog ?? const <CoopAnswerRecord>[];

    return Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📖 TU RECORRIDO PREGUNTA A PREGUNTA',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (answerLog.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No respondiste preguntas en esta partida.',
                style: TextStyle(color: RefColors.muted, fontSize: 12),
              ),
            )
          else
            for (final record in answerLog)
              _CoopRecapItem(
                '${record.cardIndex + 1}',
                record.question,
                record.wasCorrect
                    ? 'Correcta'
                    : 'Fallada · era: ${record.correctAnswer}',
                record.wasCorrect ? 1 : 0,
                record.wasCorrect ? '✓' : '✗',
                warn: !record.wasCorrect,
              ),
        ],
      ),
    );
  }
}

class _CoopRecapItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final double progress;
  final String score;
  final bool warn;

  const _CoopRecapItem(
    this.number,
    this.title,
    this.subtitle,
    this.progress,
    this.score, {
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RefColors.border),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                RefProgress(
                  progress,
                  gradient: warn
                      ? const LinearGradient(
                          colors: [RefColors.sun, RefColors.urgent],
                        )
                      : RefColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(
            score,
            color: (warn ? RefColors.sun : RefColors.lime).withValues(
              alpha: .14,
            ),
            borderColor: (warn ? RefColors.sun : RefColors.lime).withValues(
              alpha: .38,
            ),
            textColor: warn ? RefColors.sun : RefColors.lime,
          ),
        ],
      ),
    );
  }
}

class _CoopAchievements extends StatelessWidget {
  const _CoopAchievements();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 LOGROS DESBLOQUEADOS HOY',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          _CoopEarnedAchievements(),
        ],
      ),
    );
  }
}

/// Logros calculados con los datos reales de la partida que acaba de
/// terminar (bitácora local + scoreboard de la sala). Sin datos fingidos.
class _CoopEarnedAchievements extends StatelessWidget {
  const _CoopEarnedAchievements();

  @override
  Widget build(BuildContext context) {
    final coop = CoopService.active;
    final answerLog = coop?.answerLog ?? const <CoopAnswerRecord>[];
    final memberCount = coop?.state?.memberIds.length ?? 0;
    final hintsShared = coop?.hintsShared ?? 0;

    final correctCount =
        answerLog.where((record) => record.wasCorrect).length;
    final answeredAll = answerLog.isNotEmpty;
    final perfectRun = answeredAll && correctCount == answerLog.length;
    final solidAccuracy =
        answeredAll && !perfectRun && correctCount * 10 >= answerLog.length * 7;

    var bestStreak = 0;
    var currentStreak = 0;
    for (final record in answerLog) {
      currentStreak = record.wasCorrect ? currentStreak + 1 : 0;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    }

    final earned = <Widget>[
      if (memberCount >= 2)
        _CoopAchievement('🤝', 'En equipo', '$memberCount jugadores', warm: true),
      if (perfectRun)
        _CoopAchievement('🌟', 'Perfecto', '$correctCount/${answerLog.length} aciertos', warm: true),
      if (solidAccuracy)
        _CoopAchievement('🎯', 'Precisión', '$correctCount/${answerLog.length} aciertos'),
      if (bestStreak >= 3)
        _CoopAchievement('🔥', 'Racha $bestStreak', 'aciertos seguidos'),
      if (hintsShared > 0)
        _CoopAchievement('💡', 'Buena pista', 'Ayudaste ${hintsShared}x', warm: true),
    ];

    if (earned.isEmpty) {
      return const Text(
        'Sin logros esta vez. ¡La próxima partida es tuya!',
        style: TextStyle(color: RefColors.muted, fontSize: 12),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < earned.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            earned[i],
          ],
        ],
      ),
    );
  }
}

class _CoopAchievement extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool warm;

  const _CoopAchievement(
    this.icon,
    this.title,
    this.subtitle, {
    this.warm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: warm ? null : RefColors.glassSoft,
        gradient: warm
            ? LinearGradient(
                colors: [
                  RefColors.sun.withValues(alpha: .18),
                  RefColors.pink.withValues(alpha: .12),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warm ? RefColors.sun.withValues(alpha: .38) : RefColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopMinimizedHeader extends StatelessWidget {
  final CoopRoomState roomState;
  final VoidCallback onBack;

  const _CoopMinimizedHeader({
    required this.roomState,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final memberIds = roomState.memberIds.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .18),
            RefColors.sun.withValues(alpha: .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: RefColors.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'SALA · ${roomState.code}',
                        style: const TextStyle(
                          color: RefColors.lime,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Creando mazo grupal...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                for (int i = 0; i < memberIds.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                      gradient: i == 0 
                          ? RefColors.primary 
                          : (i % 2 == 0 ? RefColors.purple : RefColors.cool),
                    ),
                    child: Center(
                      child: Text(
                        memberIds[i].isNotEmpty ? memberIds[i][0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoopDeckTypeSelector extends StatelessWidget {
  final VoidCallback onSelectBible;
  final VoidCallback onSelectSpecify;

  const _CoopDeckTypeSelector({
    required this.onSelectBible,
    required this.onSelectSpecify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Elige cómo quieres crear el mazo para tu sala:',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CoopBentoCard(
                title: 'Biblia',
                subtitle: 'Elige libros, capítulos o versículos.',
                emoji: '✝️',
                color: RefColors.sun,
                onTap: onSelectBible,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CoopBentoCard(
                title: 'Especificar',
                subtitle: 'Pega tu propio texto o contenido.',
                emoji: '✨',
                color: RefColors.violet,
                onTap: onSelectSpecify,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoopBentoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _CoopBentoCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        padding: const EdgeInsets.all(16),
        height: 150,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: .24),
            color.withValues(alpha: .06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -8,
              right: -8,
              child: Opacity(
                opacity: 0.25,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.4),
                        color.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RefColors.muted,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CooperativoConfigScreen extends StatefulWidget {
  const CooperativoConfigScreen({super.key});

  @override
  State<CooperativoConfigScreen> createState() => _CooperativoConfigScreenState();
}

class _CooperativoConfigScreenState extends State<CooperativoConfigScreen> {
  late int _difficulty;
  late int _dailyTarget;
  late int _maxPlayers;
  late _DailyQuickPick _quickPick;
  StreamSubscription<CoopRoomState>? _sub;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final coop = CoopService.active;
    final state = coop?.state;
    _difficulty = state?.sessionDifficulty ?? 1;
    _dailyTarget = state?.sessionDailyTarget ?? 0;
    _maxPlayers = state?.sessionMaxPlayers ?? 4;
    _quickPick = _DailyQuickPick.none;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final store = AppScope.of(context);
      final coop = CoopService.active;
      final state = coop?.state;
      final deck = (state?.lobbyDeckId != null && state!.lobbyDeckId!.isNotEmpty)
          ? store.decks.firstWhere(
              (d) => d.id == state.lobbyDeckId,
              orElse: () => store.activeDeck,
            )
          : store.activeDeck;
      final totalCards = deck.cards.length;

      // If initial target is 0, default to recommended target
      if (_dailyTarget == 0) {
        _dailyTarget = _recommendedTarget(totalCards);
      }
      _quickPick = _pickForValue(_dailyTarget, totalCards);

      if (coop != null) {
        _sub = coop.stateStream.listen((s) {
          if (!mounted) return;
          setState(() {
            _difficulty = s.sessionDifficulty;
            _maxPlayers = s.sessionMaxPlayers;
            final target = s.sessionDailyTarget == 0 ? _recommendedTarget(totalCards) : s.sessionDailyTarget;
            _dailyTarget = target.clamp(totalCards == 0 ? 0 : 1, totalCards == 0 ? 0 : totalCards);
            _quickPick = _pickForValue(_dailyTarget, totalCards);
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  int _recommendedTarget(int total) {
    if (total <= 0) return 0;
    if (total <= 1) return 1;
    return ((total / 12).ceil()).clamp(2, 3);
  }

  _DailyQuickPick _pickForValue(int value, int total) {
    final rec = _recommendedTarget(total);
    if (value == rec && total > 1) return _DailyQuickPick.recomendado;
    if (value == 1) return _DailyQuickPick.breve;
    if (value == 4) return _DailyQuickPick.intenso;
    return _DailyQuickPick.none;
  }

  void _stepTarget(int delta, int total) {
    if (total <= 0) return;
    final next = (_dailyTarget + delta).clamp(1, total);
    setState(() {
      _dailyTarget = next;
      _quickPick = _pickForValue(next, total);
    });
    _broadcast();
  }

  void _setDailyTarget(int value, int total, _DailyQuickPick pick) {
    if (total <= 0) return;
    setState(() {
      _dailyTarget = value.clamp(1, total);
      _quickPick = pick;
    });
    _broadcast();
  }

  void _stepMaxPlayers(int delta) {
    final next = (_maxPlayers + delta).clamp(2, 8);
    setState(() {
      _maxPlayers = next;
    });
    _broadcast();
  }

  int _difficultyMinutes(int difficulty, int dailyTarget) {
    final perCard = switch (difficulty) {
      0 => 4,
      1 => 5,
      _ => 6,
    };
    if (dailyTarget <= 0) return 0;
    return (dailyTarget * perCard).clamp(perCard, 45);
  }

  void _broadcast() {
    final coop = CoopService.active;
    if (coop == null) return;
    coop.broadcastSessionConfig(
      difficulty: _difficulty,
      dailyTarget: _dailyTarget,
      maxPlayers: _maxPlayers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final coop = CoopService.active;
    final state = coop?.state;
    
    final deck = (state?.lobbyDeckId != null && state!.lobbyDeckId!.isNotEmpty)
        ? store.decks.firstWhere(
            (d) => d.id == state.lobbyDeckId,
            orElse: () => store.activeDeck,
          )
        : store.activeDeck;

    final totalCards = deck.cards.length;
    final estimatedDays = totalCards == 0
        ? 0
        : (totalCards / _dailyTarget).ceil().clamp(1, 30);

    return ReferencePage(
      active: AppRoutes.amigos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Configurar sesión cooperativa'),
          Glass(
            color: Colors.transparent,
            gradient: const LinearGradient(
              colors: [Color(0x1AFFFFFF), Color(0x4DFFB400)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        RefColors.pink.withValues(alpha: .4),
                        RefColors.violet.withValues(alpha: .2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: HtmlRefColors.glassBorder,
                    ),
                  ),
                  child: Center(child: GlyphIcon(deck.icon, size: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title.isEmpty ? 'Mazo sin título' : deck.title,
                        style: const TextStyle(
                          color: RefColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        totalCards == 0
                            ? 'Agrega tarjetas para estimar la sesión'
                            : '${deck.cards.length} tarjetas · dominarás en ~$estimatedDays días',
                        style: const TextStyle(
                          fontSize: 11,
                          color: RefColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OptionGroup(
            title: 'Dificultad',
            options: [
              (
                Icons.spa_rounded,
                'Fácil',
                '~${_difficultyMinutes(0, _dailyTarget)} min · con pistas',
              ),
              (
                Icons.psychology_alt_rounded,
                'Intermedio',
                '~${_difficultyMinutes(1, _dailyTarget)} min · balanceado',
              ),
              (
                Icons.timer_rounded,
                'Experto',
                '~${_difficultyMinutes(2, _dailyTarget)} min · intenso',
              ),
            ],
            active: _difficulty,
            onSelect: (index) {
              setState(() => _difficulty = index);
              _broadcast();
            },
          ),
          const SizedBox(height: 12),
          Glass(
            color: HtmlRefColors.glassBg,
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'CANTIDAD A MEMORIZAR',
                    style: TextStyle(
                      fontSize: 10,
                      color: RefColors.cyan,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    totalCards == 0
                        ? 'Sin tarjetas'
                        : 'Finalizaría en $estimatedDays ${estimatedDays == 1 ? "día" : "días"}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: RefColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RoundStep(
                                '−',
                                onTap: () => _stepTarget(-1, totalCards),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '$_dailyTarget',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _RoundStep(
                                '+',
                                onTap: () => _stepTarget(1, totalCards),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          SizedBox(
                            width: 190,
                            child: RefProgress(
                              totalCards == 0
                                  ? 0
                                  : (_dailyTarget / totalCards).clamp(.12, 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 138,
                      child: Column(
                        children: [
                          if (totalCards >= 1)
                            GestureDetector(
                              onTap: () => _setDailyTarget(
                                1,
                                totalCards,
                                _DailyQuickPick.breve,
                              ),
                              child: RefChip(
                                '1 · breve',
                                dense: true,
                                color: _quickPick == _DailyQuickPick.breve
                                    ? RefColors.lime
                                    : null,
                                textColor: _quickPick == _DailyQuickPick.breve
                                    ? RefColors.successInk
                                    : RefColors.ink,
                              ),
                            ),
                          if (_recommendedTarget(totalCards) > 1 &&
                              _recommendedTarget(totalCards) <= totalCards &&
                              _recommendedTarget(totalCards) != 1) ...[
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: () => _setDailyTarget(
                                _recommendedTarget(totalCards),
                                totalCards,
                                _DailyQuickPick.recomendado,
                              ),
                              child: RefChip(
                                '${_recommendedTarget(totalCards)} · recomendado',
                                dense: true,
                                color: _quickPick == _DailyQuickPick.recomendado
                                    ? RefColors.lime
                                    : null,
                                textColor:
                                    _quickPick == _DailyQuickPick.recomendado
                                    ? RefColors.successInk
                                    : RefColors.ink,
                              ),
                            ),
                          ],
                          if (totalCards >= 4) ...[
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: () => _setDailyTarget(
                                4,
                                totalCards,
                                _DailyQuickPick.intenso,
                              ),
                              child: RefChip(
                                '4 · intenso',
                                dense: true,
                                color: _quickPick == _DailyQuickPick.intenso
                                    ? RefColors.lime
                                    : null,
                                textColor: _quickPick == _DailyQuickPick.intenso
                                    ? RefColors.successInk
                                    : RefColors.ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            color: HtmlRefColors.glassBg,
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'LÍMITE DE JUGADORES',
                    style: TextStyle(
                      fontSize: 10,
                      color: RefColors.pink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Hasta 8 jugadores en la misma sesión',
                    style: TextStyle(
                      fontSize: 10,
                      color: RefColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundStep(
                      '−',
                      onTap: () => _stepMaxPlayers(-1),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$_maxPlayers',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _RoundStep(
                      '+',
                      onTap: () => _stepMaxPlayers(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 8; i++) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= _maxPlayers
                              ? RefColors.cyan
                              : Colors.white.withValues(alpha: .15),
                          boxShadow: i <= _maxPlayers
                              ? [
                                  BoxShadow(
                                    color: RefColors.cyan.withValues(alpha: .3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      if (i < 8) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Cta(
            'Guardar y volver',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}


