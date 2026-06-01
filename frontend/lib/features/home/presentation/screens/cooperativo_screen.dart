// Generado del refactor de ui_screens.dart.
// CooperativoScreen + Game + Success + helpers.
part of '../ui_screens.dart';

class CooperativoScreen extends StatefulWidget {
  const CooperativoScreen({super.key});

  @override
  State<CooperativoScreen> createState() => _CooperativoScreenState();
}

class _CooperativoScreenState extends State<CooperativoScreen> {
  late final CoopService _coop;
  CoopRoomState? _state;
  StreamSubscription<CoopRoomState>? _sub;
  final _joinCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _initialized = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final store = AppScope.of(context);
      _currentUserId = store.currentUser?.id;
      _coop = CoopService(client: store.api);
      _sub = _coop.stateStream.listen((s) {
        if (!mounted) return;
        final wasInGame = _state?.currentDeckId != null;
        setState(() => _state = s);
        // Cuando el host empuja la primera tarjeta y el invitado todavía
        // está en el lobby, lo llevamos automáticamente al game screen.
        final nowInGame = s.currentDeckId != null;
        final iAmHost = _currentUserId == s.hostId;
        if (!iAmHost && nowInGame && !wasInGame) {
          Navigator.pushNamed(context, AppRoutes.cooperativoJuego);
        }
      });
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _coop.dispose();
    _joinCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _coop.createRoom(
        userId: store.currentUser!.id,
        name: store.currentUser!.displayName,
      );
      CoopService.active = _coop;
      CoopService.activeUserId = store.currentUser!.id;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final code = _joinCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _coop.joinRoom(
        code: code,
        userId: store.currentUser!.id,
        name: store.currentUser!.displayName,
      );
      CoopService.active = _coop;
      CoopService.activeUserId = store.currentUser!.id;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return ReferencePage(
      active: AppRoutes.amigos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoopTopBar(center: state == null ? 'Cooperativo' : '🔒 SALA · ${state.code}'),
          if (state == null) ...[
            const _CoopLobbyHero(),
            const SizedBox(height: 14),
            Glass(
              padding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 10),
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
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: RefColors.urgent, fontSize: 12),
              ),
            ],
          ] else ...[
            Glass(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'CÓDIGO DE SALA',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.code,
                    style: const TextStyle(
                      fontSize: 38,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w900,
                      color: RefColors.lime,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${state.memberIds.length} ${state.memberIds.length == 1 ? "miembro" : "miembros"} en la sala',
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _CoopSettingsCard(),
            const SizedBox(height: 12),
            for (final id in state.memberIds)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HtmlRefColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Fav('?', size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        id,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (id == state.hostId)
                      const RefChip(
                        'HOST',
                        dense: true,
                        color: Color(0x33FF3EA5),
                        textColor: RefColors.pink,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Solo el host arranca la partida — el resto espera el primer
            // mensaje "card" via websocket.
            if (state.hostId == AppScope.of(context).currentUser?.id)
              Cta(
                'Iniciar partida →',
                onTap: () {
                  // Host empuja la primera tarjeta a la sala antes de
                  // navegar para que los miembros se enteren.
                  final activeDeck = AppScope.of(context).activeDeck;
                  _coop.broadcastCard(deckId: activeDeck.id, cardIndex: 0);
                  Navigator.pushNamed(context, AppRoutes.cooperativoJuego);
                },
              )
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
                await _coop.disconnect();
                CoopService.active = null;
                CoopService.activeUserId = null;
                if (mounted) setState(() => _state = null);
              },
            ),
          ],
        ],
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
  const _CoopCard({
    required this.question,
    required this.options,
    required this.correct,
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

  List<_CoopCard> _getGameCards(BuildContext context) {
    if (_dynamicCards != null) return _dynamicCards!;
    
    final store = AppScope.of(context);
    final deck = store.decks.firstWhere(
      (d) => d.id == _state?.currentDeckId,
      orElse: () => store.activeDeck,
    );
    
    if (deck.cards.isEmpty) {
      _dynamicCards = _kCoopCards;
      return _kCoopCards;
    }
    
    final List<_CoopCard> generated = [];
    final roomCode = _state?.code ?? 'COOP12';
    
    for (int i = 0; i < deck.cards.length; i++) {
      final card = deck.cards[i];
      final questionText = deck.isBible 
          ? 'Completa el versículo de ${card.source}: "${card.front}"'
          : '¿Cuál es la respuesta correcta para: "${card.front}"?';
      
      final correctAns = card.back.trim();
      
      final otherCards = deck.cards.where((c) => c.id != card.id).toList();
      final shuffledOthers = _deterministicShuffle(otherCards, '${card.id}_$roomCode');
      final wrongOptions = shuffledOthers.map((c) => c.back.trim()).toSet().toList();
      
      final fallbacks = [
        'Jesús lloró.',
        'En el principio creó Dios los cielos y la tierra.',
        'Jehová es mi pastor; nada me faltará.',
        'Porque de tal manera amó Dios al mundo...',
        'El amor es sufrido, es benigno...',
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
      ));
    }
    
    _dynamicCards = generated;
    return generated;
  }

  void _confirm() {
    if (_answered || _selectedOption == null) return;
    final gameCards = _getGameCards(context);
    final currentCard = gameCards[_state!.currentCardIndex % gameCards.length];
    final correct = _selectedOption == currentCard.correct;
    setState(() {
      _answered = true;
      _lastResult = correct ? 'correct' : 'wrong';
      _answeredUsers.add(CoopService.activeUserId ?? '');
    });
    // Reportar puntos al server: +10 acierto, +0 fallo.
    _coop?.reportScore(correct ? 10 : 0);
  }

  void _next() {
    if (!_isHost) return;
    final gameCards = _getGameCards(context);
    final next = (_state?.currentCardIndex ?? 0) + 1;
    if (next >= gameCards.length) {
      Navigator.pushReplacementNamed(context, AppRoutes.cooperativoLogrado);
      return;
    }
    _coop?.broadcastCard(deckId: _state?.currentDeckId ?? 'mock-deck', cardIndex: next);
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
          _CoopLiveScoreboard(state: state),
          const SizedBox(height: 14),
          _CoopTeamRow(state: state, answeredUsers: _answeredUsers),
          const SizedBox(height: 14),
          RefProgress(progress.clamp(0.0, 1.0)),
          const SizedBox(height: 14),
          _CoopQuestionCard(
            index: state.currentCardIndex,
            total: gameCards.length,
            question: card.question,
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
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              if (!_answered) ...[
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

class _CoopLiveScoreboard extends StatelessWidget {
  final CoopRoomState state;
  const _CoopLiveScoreboard({required this.state});

  @override
  Widget build(BuildContext context) {
    final entries = state.memberIds.toList()
      ..sort((a, b) => (state.scores[b] ?? 0).compareTo(state.scores[a] ?? 0));
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final id in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Fav(id.substring(0, 1).toUpperCase(), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      id == CoopService.activeUserId ? 'Tú' : id,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (id == state.hostId)
                    const RefChip(
                      'HOST',
                      dense: true,
                      color: Color(0x33FF3EA5),
                      textColor: RefColors.pink,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.scores[id] ?? 0}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: RefColors.lime,
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

  const _CoopTopBar({required this.center, this.live = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
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

class _CoopLobbyHero extends StatelessWidget {
  const _CoopLobbyHero();

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
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
          RefChip(
            'SALA COOPERATIVA · ${deck.subtitle.toUpperCase()}',
            dense: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlyphIcon(deck.icon, size: 27),
              const SizedBox(width: 7),
              Text(
                deck.title.replaceAll(' · ', '\n'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Turnos rotativos · ${deck.cards.length} tarjetas · ~${(deck.cards.length * 2).clamp(6, 20)} min',
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CoopParticipant('M', 'Marco', 'Listo', host: true, ready: true),
              SizedBox(width: 14),
              _CoopParticipant('A', 'Ana (tú)', 'Listo', ready: true),
              SizedBox(width: 14),
              _CoopParticipant(
                'L',
                'Lucía',
                'Cargando...',
                loading: true,
                gradient: RefColors.purple,
              ),
              SizedBox(width: 14),
              _CoopParticipant('+', 'Invitar', '1 libre', empty: true),
            ],
          ),
          const SizedBox(height: 16),
          const _CoopChat(
            messages: [
              ('M', 'Marco:', '¡Empezamos en 1 min! preparen café ☕'),
              ('L', 'Lucía:', 'lista en 30 seg'),
            ],
          ),
        ],
      ),
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

class _CoopChat extends StatelessWidget {
  final List<(String, String, String)> messages;

  const _CoopChat({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: RefColors.inner)),
      ),
      child: Column(
        children: [
          for (final message in messages) ...[
            Row(
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
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RefColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Escribe un mensaje...',
                    style: TextStyle(
                      color: RefColors.dim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: RefColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 16),
                ),
              ],
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
  const _CoopSettingsCard();

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
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
          _CoopSettingRow('Mazo', deck.title.isEmpty ? 'Mazo sin título' : deck.title, 'Activo'),
          const _CoopSettingRow(
            'Modo',
            'Todos responden · el grupo avanza junto',
            'Grupal',
          ),
          _CoopSettingRow(
            'Tarjetas',
            '${deck.cards.length} tarjetas seleccionadas',
            '${deck.cards.length}',
          ),
        ],
      ),
    );
  }
}

class _CoopSettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _CoopSettingRow(this.title, this.subtitle, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          RefChip(value, dense: true),
        ],
      ),
    );
  }
}

class _CoopTeamRow extends StatelessWidget {
  final CoopRoomState state;
  final Set<String> answeredUsers;

  const _CoopTeamRow({
    required this.state,
    required this.answeredUsers,
  });

  @override
  Widget build(BuildContext context) {
    final entries = state.memberIds.toList();
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
    final displayName = isMe ? 'Tú' : userId;
    
    final hasAnswered = answeredUsers.contains(userId);
    
    final String statusText;
    if (hasAnswered) {
      statusText = '✓ Respondió';
    } else {
      statusText = isMe ? 'Tu turno...' : 'Esperando';
    }

    final gradients = [
      RefColors.primary,
      RefColors.purple,
      RefColors.cool,
      RefColors.success,
    ];
    final gradient = gradients[userId.hashCode % gradients.length];

    return _CoopMate(
      userId.substring(0, 1).toUpperCase(),
      displayName,
      statusText,
      done: hasAnswered,
      answering: !hasAnswered,
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
  final Gradient gradient;

  const _CoopMate(
    this.avatar,
    this.name,
    this.status, {
    this.done = false,
    this.answering = false,
    this.gradient = RefColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
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
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: done
                      ? RefColors.lime
                      : answering
                      ? RefColors.sun
                      : RefColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoopQuestionCard extends StatelessWidget {
  final int index;
  final int total;
  final String question;

  const _CoopQuestionCard({
    required this.index,
    required this.total,
    required this.question,
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
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
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

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.fromLTRB(22, 24, 22, 22),
      gradient: RefColors.success,
      border: Border(),
      child: Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 52)),
          SizedBox(height: 6),
          Text(
            '¡Lo lograron juntos!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.successInk,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '20 tarjetas · 12 min · 85% aciertos',
            style: TextStyle(
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
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(5),
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
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '85%',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'ACIERTO',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              children: [
                _CoopScoreRow('Correctas', '17 / 20'),
                _CoopScoreRow('Incorrectas', '3'),
                _CoopScoreRow('Tiempo', '12 min'),
              ],
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
                  'Imagen o texto · sin cuenta necesaria',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
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
        ],
      ),
    );
  }
}

class _CoopRecapCard extends StatelessWidget {
  const _CoopRecapCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 CÓMO LES FUE A LAS TARJETAS',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          _CoopRecapItem(
            '1',
            'Alvéolos · función',
            'Marco · sin errores',
            1,
            '✓ 100%',
          ),
          _CoopRecapItem(
            '2',
            'Bronquios principales',
            'Ana · 1 error',
            .92,
            '✓ 92%',
          ),
          _CoopRecapItem(
            '3',
            'Diafragma · función',
            'Lucía · 2 errores',
            .85,
            '⚡ 85%',
            warn: true,
          ),
          _CoopRecapItem(
            '4',
            'Tráquea · anillos',
            'Marco · sin errores',
            .98,
            '✓ 98%',
          ),
          _CoopRecapItem(
            '5',
            'Intercambio gaseoso',
            'Ana · 3 errores',
            .78,
            '⚡ 78%',
            warn: true,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CoopAchievement(
                  '🤝',
                  'En equipo',
                  '3 sesiones co-op',
                  warm: true,
                ),
                SizedBox(width: 8),
                _CoopAchievement(
                  '💡',
                  'Buena pista',
                  'Ayudaste 2x',
                  warm: true,
                ),
                SizedBox(width: 8),
                _CoopAchievement('🔥', 'Racha 10', '3 días restantes'),
                SizedBox(width: 8),
                _CoopAchievement('🌟', 'Precisión', '90% en 3 sesiones'),
              ],
            ),
          ),
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

