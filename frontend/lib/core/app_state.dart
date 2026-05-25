import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/moderation/data/report_models.dart';
import 'api/memorizar_client.dart';
import 'api/models.dart';

/// Visibility level for a memory deck. Defaults to [private] — going to
/// [friends] or [public] requires the user to acknowledge they have rights
/// over the content (see ConsentDialog).
enum DeckVisibility { private, friends, public }

class BibleBookData {
  final String name;
  final String shortName;
  final int chapters;

  const BibleBookData(this.name, this.shortName, this.chapters);
}

class BibleVerseData {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  const BibleVerseData({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerseData.fromJson(Map<String, dynamic> json) {
    return BibleVerseData(
      book: json['b'] as String,
      chapter: json['c'] as int,
      verse: json['v'] as int,
      text: json['t'] as String,
    );
  }

  String get ref => '$book $chapter:$verse';
}

class MemoryCardData {
  final String id;
  final String front;
  final String back;
  final String source;
  final String icon;
  final int retention;
  final int lapses;

  const MemoryCardData({
    required this.id,
    required this.front,
    required this.back,
    required this.source,
    required this.icon,
    this.retention = 82,
    this.lapses = 0,
  });

  MemoryCardData copyWith({
    String? id,
    String? front,
    String? back,
    String? source,
    String? icon,
    int? retention,
    int? lapses,
  }) {
    return MemoryCardData(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      source: source ?? this.source,
      icon: icon ?? this.icon,
      retention: retention ?? this.retention,
      lapses: lapses ?? this.lapses,
    );
  }
}

class MemoryDeckData {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<MemoryCardData> cards;
  final bool isBible;
  final DateTime createdAt;
  /// Visibilidad: privado (default), compartido con amigos, o público en
  /// la comunidad. Los dos últimos requieren consentimiento explícito.
  final DeckVisibility visibility;
  /// True después de que el creador aceptó la cláusula "tengo derechos sobre
  /// este contenido". Necesario para visibility != private.
  final bool rightsAcknowledged;

  const MemoryDeckData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cards,
    required this.createdAt,
    this.isBible = false,
    this.visibility = DeckVisibility.private,
    this.rightsAcknowledged = false,
  });

  int get retention {
    if (cards.isEmpty) return 0;
    final total = cards.fold<int>(0, (sum, card) => sum + card.retention);
    return (total / cards.length).round();
  }

  int get weakCount => cards.where((card) => card.retention < 60).length;

  MemoryDeckData copyWith({
    String? title,
    String? subtitle,
    String? icon,
    DeckVisibility? visibility,
    bool? rightsAcknowledged,
  }) {
    return MemoryDeckData(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      cards: cards,
      createdAt: createdAt,
      isBible: isBible,
      visibility: visibility ?? this.visibility,
      rightsAcknowledged: rightsAcknowledged ?? this.rightsAcknowledged,
    );
  }
}

const emptyCard = MemoryCardData(
  id: 'empty-card',
  front: 'Sin tarjetas todavía',
  back: 'Crea un mazo desde Biblia o Especificar para empezar.',
  source: 'Vacío',
  icon: '✨',
  retention: 0,
);

final emptyDeck = MemoryDeckData(
  id: 'empty-deck',
  title: 'Sin mazos todavía',
  subtitle: 'Crea tu primer contenido',
  icon: '✨',
  createdAt: DateTime(2026, 4, 29),
  cards: const [],
);

class AppStore extends ChangeNotifier {
  AppStore({MemorizarClient? api}) : api = api ?? MemorizarClient();

  /// Cliente HTTP del backend Go. Lo expongo público para que features que
  /// hablan directo con la API (Amigos, Feed) lo reusen sin duplicarlo.
  final MemorizarClient api;

  // ─── Auth ───────────────────────────────────────────────────────────────

  static const _kSessionTokenKey = 'memorizar.session.token';
  static const _kSessionUserKey = 'memorizar.session.user';

  RemoteUser? _currentUser;
  String? _sessionToken;

  RemoteUser? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _sessionToken != null && _sessionToken!.isNotEmpty;
  /// Modo invitado: el usuario decide no iniciar sesión todavía pero sigue
  /// usando la app. La diferencia con "no logueado" es semántica solamente —
  /// hoy ambos se comportan igual.
  bool get isGuest => !isLoggedIn;

  /// Conteo de invitaciones de amistad pendientes (donde YO soy el
  /// destinatario). Se refresca con [refreshPendingCount] al loguearse y
  /// tras aceptar/enviar una invitación.
  int _pendingFriendInvites = 0;
  /// Conteo de mazos compartidos conmigo que aún no he importado. Mismo
  /// disparo de refresh.
  int _unreadShares = 0;
  int get pendingFriendInvites => _pendingFriendInvites;
  int get unreadShares => _unreadShares;
  int get totalNotifications => _pendingFriendInvites + _unreadShares;

  Future<void> refreshPendingCount() async {
    if (!isLoggedIn) {
      _pendingFriendInvites = 0;
      _unreadShares = 0;
      notifyListeners();
      return;
    }
    try {
      final friends = await api.listFriends();
      final me = _currentUser?.id ?? '';
      _pendingFriendInvites =
          friends.pendingRequests.where((f) => f.addresseeId == me).length;
    } catch (_) {}
    try {
      final shares = await api.listShares();
      final me = _currentUser?.id ?? '';
      _unreadShares =
          shares.where((s) => (s['targetUserId'] as String?) == me).length;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> bootstrapSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kSessionTokenKey);
    final userJson = prefs.getString(_kSessionUserKey);
    if (token == null || token.isEmpty || userJson == null) return;
    try {
      _sessionToken = token;
      _currentUser =
          RemoteUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      api.setSessionToken(token);
      notifyListeners();
    } catch (_) {
      await prefs.remove(_kSessionTokenKey);
      await prefs.remove(_kSessionUserKey);
    }
  }

  Future<void> _persistSession(String token, RemoteUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionTokenKey, token);
    await prefs.setString(_kSessionUserKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionTokenKey);
    await prefs.remove(_kSessionUserKey);
  }

  /// Login social (provider = 'google' | 'apple' | 'facebook'). En Fase 1
  /// el frontend no integra los SDK reales — el provider valida en el lado
  /// app y pasa los datos del perfil al backend, que es quien crea/recupera
  /// el usuario y emite el token de sesión.
  Future<void> socialLogin({
    required String provider,
    required String providerUserId,
    required String email,
    required String displayName,
    String avatarUrl = '',
  }) async {
    final result = await api.socialLogin(
      provider: provider,
      providerUserId: providerUserId,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    _currentUser = result.user;
    _sessionToken = result.session.token;
    api.setSessionToken(_sessionToken);
    await _persistSession(result.session.token, result.user);
    notifyListeners();
    // Bajar snapshot remoto en background (best-effort, no bloquea login).
    unawaited(pullProgressSnapshot());
    unawaited(refreshPendingCount());
  }

  Future<void> logout() async {
    _currentUser = null;
    _sessionToken = null;
    api.setSessionToken(null);
    await _clearPersistedSession();
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await api.registerEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    _currentUser = result.user;
    _sessionToken = result.session.token;
    api.setSessionToken(_sessionToken);
    await _persistSession(result.session.token, result.user);
    notifyListeners();
    unawaited(pullProgressSnapshot());
    unawaited(refreshPendingCount());
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await api.loginEmail(email: email, password: password);
    _currentUser = result.user;
    _sessionToken = result.session.token;
    api.setSessionToken(_sessionToken);
    await _persistSession(result.session.token, result.user);
    notifyListeners();
    unawaited(pullProgressSnapshot());
    unawaited(refreshPendingCount());
  }

  /// Setter directo para refrescar el user en memoria sin re-autenticar
  /// (ej. tras verificar email).
  void overwriteCurrentUser(RemoteUser user) {
    _currentUser = user;
    if (_sessionToken != null) {
      // Persistencia best-effort. Lo hacemos sync sin await para no bloquear.
      // El siguiente bootstrapSession leerá el cambio.
      // ignore: discarded_futures
      _persistSession(_sessionToken!, user);
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? locale,
  }) async {
    if (!isLoggedIn) return;
    final updated = await api.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
      locale: locale,
    );
    _currentUser = updated;
    if (_sessionToken != null) {
      await _persistSession(_sessionToken!, updated);
    }
    if (locale != null) {
      await setLocale(locale);
    }
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (!isLoggedIn) return;
    await api.deleteAccount();
    await logout();
    // Limpieza adicional: borra mazos locales, no hay forma de recuperar
    // sin la cuenta.
    _decks.clear();
    _selectedBibleVerses.clear();
    _completedExerciseSteps.clear();
    notifyListeners();
  }

  // ─── Theme + Locale ────────────────────────────────────────────────────

  static const _kThemeModeKey = 'memorizar.theme.mode';
  static const _kLocaleKey = 'memorizar.locale';

  ThemeMode _themeMode = ThemeMode.dark;
  String _locale = 'es';

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;

  Future<void> bootstrapPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final tm = prefs.getString(_kThemeModeKey);
    if (tm == 'light') _themeMode = ThemeMode.light;
    if (tm == 'system') _themeMode = ThemeMode.system;
    if (tm == 'dark') _themeMode = ThemeMode.dark;
    final loc = prefs.getString(_kLocaleKey);
    if (loc != null && loc.isNotEmpty) _locale = loc;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kThemeModeKey,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.system
              ? 'system'
              : 'dark',
    );
    notifyListeners();
  }

  Future<void> setLocale(String value) async {
    _locale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, value);
    notifyListeners();
  }

  // ─── Sync de progreso ─────────────────────────────────────────────────

  static const _kDeviceIdKey = 'memorizar.device.id';
  String? _deviceId;
  bool _syncing = false;

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kDeviceIdKey);
    if (id == null || id.isEmpty) {
      id = 'dev-${DateTime.now().microsecondsSinceEpoch}';
      await prefs.setString(_kDeviceIdKey, id);
    }
    _deviceId = id;
    return id;
  }

  /// Serializa el estado relevante (decks + progreso) en JSON para enviar al
  /// backend. Mantiene el formato simple para que un cliente nuevo pueda
  /// reconstruirlo sin depender de versiones de Drift.
  String _buildProgressPayload() {
    return jsonEncode({
      'version': 1,
      'sessionDifficulty': _sessionDifficulty,
      'sessionDailyTarget': _sessionDailyTarget,
      'sessionCardsCompleted': _sessionCardsCompleted,
      'currentCardIndex': _currentCardIndex,
      'correctAnswers': _correctAnswers,
      'wrongAnswers': _wrongAnswers,
      'completedSteps': _completedExerciseSteps.toList(),
      'decks': [
        for (final d in _decks)
          {
            'id': d.id,
            'title': d.title,
            'subtitle': d.subtitle,
            'icon': d.icon,
            'isBible': d.isBible,
            'createdAt': d.createdAt.toIso8601String(),
            'visibility': d.visibility.name,
            'cards': [
              for (final c in d.cards)
                {
                  'id': c.id,
                  'front': c.front,
                  'back': c.back,
                  'source': c.source,
                  'icon': c.icon,
                  'retention': c.retention,
                  'lapses': c.lapses,
                },
            ],
          },
      ],
    });
  }

  /// Empuja el snapshot al backend. No-op si no hay sesión. Se llama
  /// implícitamente al cerrar una sesión de estudio y manualmente desde el
  /// menú "Sincronizar ahora".
  Future<bool> pushProgressSnapshot() async {
    if (!isLoggedIn || _syncing) return false;
    _syncing = true;
    try {
      final deviceId = await _getDeviceId();
      await api.saveProgressSnapshot(
        deviceId: deviceId,
        payloadJson: _buildProgressPayload(),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _syncing = false;
    }
  }

  /// Baja el último snapshot del backend. Hoy NO sobreescribe el estado
  /// local (merge real es un siguiente paso) — sólo lo expone vía
  /// [latestRemoteSnapshot] para que el usuario pueda decidir importar.
  Map<String, dynamic>? _latestRemoteSnapshot;
  Map<String, dynamic>? get latestRemoteSnapshot => _latestRemoteSnapshot;

  Future<void> pullProgressSnapshot({bool autoApply = true}) async {
    if (!isLoggedIn) return;
    try {
      final raw = await api.getProgressSnapshot();
      if (raw == null) {
        _latestRemoteSnapshot = null;
        return;
      }
      final payload = raw['payloadJson'];
      Map<String, dynamic>? snap;
      if (payload is String && payload.isNotEmpty) {
        snap = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map<String, dynamic>) {
        snap = payload;
      }
      _latestRemoteSnapshot = snap;
      if (snap != null && autoApply) {
        applyRemoteSnapshot(snap);
      }
      notifyListeners();
    } catch (_) {
      // Silencioso — sync es best-effort.
    }
  }

  /// Mergea el snapshot remoto con el estado local. Estrategia simple:
  /// - Por cada deck remoto que NO existe local → lo añade.
  /// - Por cada deck que existe en ambos → gana el de `cards.length` mayor
  ///   (heurística para "el más completo"). Para retention/lapses, hace
  ///   max() por card.id.
  /// Nada se borra del local — el merge es aditivo.
  void applyRemoteSnapshot(Map<String, dynamic> snap) {
    final remoteDecks = (snap['decks'] as List? ?? const []).cast<dynamic>();
    final byId = {for (final d in _decks) d.id: d};

    for (final r in remoteDecks) {
      if (r is! Map<String, dynamic>) continue;
      final id = (r['id'] as String?) ?? '';
      if (id.isEmpty) continue;
      final remoteCards = (r['cards'] as List? ?? const [])
          .cast<dynamic>()
          .whereType<Map<String, dynamic>>()
          .toList();
      final cards = remoteCards
          .map((c) => MemoryCardData(
                id: (c['id'] as String?) ?? '',
                front: (c['front'] as String?) ?? '',
                back: (c['back'] as String?) ?? '',
                source: (c['source'] as String?) ?? '',
                icon: (c['icon'] as String?) ?? '✨',
                retention: (c['retention'] as int?) ?? 70,
                lapses: (c['lapses'] as int?) ?? 0,
              ))
          .toList();
      if (!byId.containsKey(id)) {
        // Deck nuevo del remoto.
        _decks.add(MemoryDeckData(
          id: id,
          title: (r['title'] as String?) ?? 'Deck',
          subtitle: (r['subtitle'] as String?) ?? '',
          icon: (r['icon'] as String?) ?? '✨',
          isBible: (r['isBible'] as bool?) ?? false,
          createdAt:
              DateTime.tryParse((r['createdAt'] as String?) ?? '') ??
                  DateTime.now(),
          cards: cards,
        ));
        continue;
      }
      // Deck existente: merge tarjeta por id, queda el de mayor retention.
      final local = byId[id]!;
      final merged = <String, MemoryCardData>{
        for (final c in local.cards) c.id: c,
      };
      for (final rc in cards) {
        final existing = merged[rc.id];
        if (existing == null) {
          merged[rc.id] = rc;
        } else {
          merged[rc.id] = existing.copyWith(
            retention: rc.retention > existing.retention
                ? rc.retention
                : existing.retention,
            lapses: rc.lapses > existing.lapses ? rc.lapses : existing.lapses,
          );
        }
      }
      final updated = MemoryDeckData(
        id: local.id,
        title: local.title,
        subtitle: local.subtitle,
        icon: local.icon,
        cards: merged.values.toList(),
        createdAt: local.createdAt,
        isBible: local.isBible,
        visibility: local.visibility,
        rightsAcknowledged: local.rightsAcknowledged,
      );
      final idx = _decks.indexWhere((d) => d.id == id);
      if (idx >= 0) _decks[idx] = updated;
    }
    notifyListeners();
  }

  final List<MemoryDeckData> _decks = [];
  final List<BibleVerseData> _bibleVerses = [];
  final List<BibleVerseData> _selectedBibleVerses = [];
  final Set<String> _completedExerciseSteps = {};
  final Map<String, String> _exerciseVoiceReads = {};
  final Map<String, String> _exerciseVoiceAudioPaths = {};
  // Mock in-memory queue for community reports. Cuando exista el backend (Fase
  // 3+) esto vivirá del lado servidor con permisos reales de moderador.
  final List<DeckReport> _deckReports = [];
  String? _activeDeckId;
  int _currentCardIndex = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _sessionDifficulty = 1;
  /// Cantidad de tarjetas que el usuario configuró para esta sesión.
  /// `configureSession` lo establece, `_sessionCardsCompleted` lo va alcanzando.
  int _sessionDailyTarget = 1;
  int _sessionCardsCompleted = 0;
  int _sessionFlowSeed = DateTime.now().microsecondsSinceEpoch;
  bool _isPremium = false;

  List<MemoryDeckData> get decks => List.unmodifiable(_decks);
  List<BibleVerseData> get bibleVerses => List.unmodifiable(_bibleVerses);
  List<BibleVerseData> get selectedBibleVerses =>
      List.unmodifiable(_selectedBibleVerses);
  Set<String> get loadedBibleBooks =>
      _bibleVerses.map((verse) => verse.book).toSet();
  bool get hasDecks => _decks.isNotEmpty;
  MemoryDeckData get activeDeck {
    if (_decks.isEmpty) return emptyDeck;
    return _decks.firstWhere(
      (deck) => deck.id == _activeDeckId,
      orElse: () => _decks.first,
    );
  }

  MemoryCardData get activeCard {
    if (activeDeck.cards.isEmpty) return emptyCard;
    final deck = activeDeck;
    if (deck.isBible && deck.cards.length > 1) {
      final combinedFront = deck.cards.map((c) => c.front).join('; ');
      final combinedBack = deck.cards.map((c) => c.back.trim()).join(' ');
      return MemoryCardData(
        id: 'combined-${deck.id}',
        front: combinedFront,
        back: combinedBack,
        source: deck.cards.first.source,
        icon: deck.cards.first.icon,
        retention: deck.cards.first.retention,
      );
    }
    return activeDeck.cards[_currentCardIndex.clamp(
      0,
      activeDeck.cards.length - 1,
    )];
  }

  int get currentCardIndex => _currentCardIndex;
  int get correctAnswers => _correctAnswers;
  int get wrongAnswers => _wrongAnswers;
  int get sessionDifficulty => _sessionDifficulty;
  int get sessionFlowSeed => _sessionFlowSeed;
  int get sessionDailyTarget => _sessionDailyTarget;
  int get sessionCardsCompleted => _sessionCardsCompleted;
  int get sessionCardsRemaining =>
      (_sessionDailyTarget - _sessionCardsCompleted).clamp(0, 99999);
  bool get sessionFinished => _sessionCardsCompleted >= _sessionDailyTarget;
  bool get isPremium => _isPremium;

  void setPremiumPreview(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    _sessionFlowSeed = DateTime.now().microsecondsSinceEpoch;
    notifyListeners();
  }

  int get completedCards => _correctAnswers + _wrongAnswers;
  int get streakDays => _decks.isEmpty ? 0 : 1;
  int get totalCards =>
      _decks.fold(0, (total, deck) => total + deck.cards.length);
  int get averageRetention {
    if (_decks.isEmpty) return 0;
    final total = _decks.fold(0, (sum, deck) => sum + deck.retention);
    return (total / _decks.length).round();
  }

  int get dominatedCards => _decks.fold(
    0,
    (total, deck) =>
        total + deck.cards.where((card) => card.retention >= 80).length,
  );

  int get weakCards => _decks.fold(0, (total, deck) => total + deck.weakCount);

  int get estimatedPendingMinutes =>
      weakCards == 0 ? 0 : (weakCards * 2).clamp(4, 24);

  MemoryDeckData? deckForCard(MemoryCardData target) {
    for (final deck in _decks) {
      if (deck.cards.any((card) => card.id == target.id)) return deck;
    }
    return null;
  }

  List<MemoryCardData> get dueCards {
    final cards = [
      for (final deck in _decks)
        for (final card in deck.cards) card,
    ];
    cards.sort((a, b) => a.retention.compareTo(b.retention));
    return cards.take(5).toList();
  }

  /// Catálogo de versiones empacadas localmente. Cada entrada apunta a su
  /// asset JSON. Versiones bajo licencia (RV1960, NBLA, etc.) se cargarán
  /// vía API en una capa aparte cuando exista — esta lista es solo offline.
  static const Map<String, ({String asset, String name, String license})>
      bundledBibles = {
    'rv1909': (
      asset: 'assets/bible/rv1909.json',
      name: 'Reina-Valera 1909',
      license: 'Dominio público',
    ),
    'rvg': (
      asset: 'assets/bible/rvg.json',
      name: 'Reina-Valera Gómez',
      license: 'Distribución libre · Comité RVG',
    ),
  };

  /// Versículos de cada versión cargada. Se llena al iniciar la app vía
  /// [loadBible].
  final Map<String, List<BibleVerseData>> _bibleByVersion = {};

  /// Versión activa que se usa para `versesFor`, búsqueda y selección.
  String _bibleVersion = 'rv1909';

  String get bibleVersion => _bibleVersion;

  void setBibleVersion(String version) {
    if (!_bibleByVersion.containsKey(version)) return;
    if (_bibleVersion == version) return;
    _bibleVersion = version;
    _bibleVerses
      ..clear()
      ..addAll(_bibleByVersion[version]!);
    notifyListeners();
  }

  Future<void> loadBible() async {
    if (_bibleByVersion.isNotEmpty) return;
    for (final entry in bundledBibles.entries) {
      try {
        final raw = await rootBundle.loadString(entry.value.asset);
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        final verses = (payload['verses'] as List<dynamic>)
            .map((item) => BibleVerseData.fromJson(item as Map<String, dynamic>))
            .toList(growable: false);
        _bibleByVersion[entry.key] = verses;
      } catch (e) {
        // Asset opcional no encontrado — saltar y continuar.
        // La UI debe ofrecer solo las versiones que sí cargaron.
      }
    }
    final initial = _bibleByVersion.containsKey(_bibleVersion)
        ? _bibleVersion
        : (_bibleByVersion.keys.isNotEmpty
            ? _bibleByVersion.keys.first
            : _bibleVersion);
    _bibleVersion = initial;
    _bibleVerses
      ..clear()
      ..addAll(_bibleByVersion[initial] ?? const []);
  }

  List<BibleVerseData> versesFor(String book, int chapter) {
    final canonicalBook = _canonicalBookName(book);
    return _bibleVerses
        .where(
          (verse) => verse.book == canonicalBook && verse.chapter == chapter,
        )
        .toList();
  }

  List<BibleVerseData> searchBible(String rawQuery) {
    final query = rawQuery.toLowerCase().trim();
    if (query.isEmpty) return const [];
    final normalized = query
        .replaceAll('rom ', 'romanos ')
        .replaceAll('sal ', 'salmos ')
        .replaceAll('jn ', 'juan ')
        .replaceAll('gen ', 'génesis ')
        .replaceAll('exo ', 'éxodo ');
    final range = RegExp(
      r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$',
    ).firstMatch(normalized);
    if (range != null) {
      final book = _canonicalBookName(range.group(1)!);
      final chapter = int.parse(range.group(2)!);
      final firstVerse = int.parse(range.group(3)!);
      final lastVerse = int.parse(range.group(4) ?? range.group(3)!);
      return _bibleVerses
          .where(
            (verse) =>
                verse.book.toLowerCase() == book.toLowerCase() &&
                verse.chapter == chapter &&
                verse.verse >= firstVerse &&
                verse.verse <= lastVerse,
          )
          .toList();
    }
    final compact = normalized.replaceAll(RegExp(r'\s+'), '');
    return _bibleVerses
        .where((verse) {
          final ref = verse.ref.toLowerCase();
          final bookChapter = '${verse.book} ${verse.chapter}'.toLowerCase();
          final text = verse.text.toLowerCase();
          if (ref.contains(normalized) ||
              bookChapter == normalized ||
              text.contains(normalized)) {
            return true;
          }
          final refCompact = ref.replaceAll(RegExp(r'\s+'), '');
          return refCompact.contains(compact);
        })
        .take(80)
        .toList();
  }

  String _canonicalBookName(String rawBook) {
    final normalized = _bookKey(rawBook);
    const aliases = {
      'gen': 'Génesis',
      'exo': 'Éxodo',
      'num': 'Números',
      'deut': 'Deuteronomio',
      '1sam': '1 Samuel',
      '2sam': '2 Samuel',
      '1re': '1 Reyes',
      '2re': '2 Reyes',
      '1cr': '1 Crónicas',
      '2cr': '2 Crónicas',
      'prov': 'Proverbios',
      'ecl': 'Eclesiastés',
      'cant': 'Cantares',
      'isa': 'Isaías',
      'jer': 'Jeremías',
      'lam': 'Lamentaciones',
      'eze': 'Ezequiel',
      'ose': 'Oseas',
      'miq': 'Miqueas',
      'zac': 'Zacarías',
      'mat': 'Mateo',
      'mar': 'Marcos',
      'luc': 'Lucas',
      'hech': 'Hechos',
      'rom': 'Romanos',
      '1cor': '1 Corintios',
      '2cor': '2 Corintios',
      'gal': 'Gálatas',
      'ef': 'Efesios',
      'fil': 'Filipenses',
      'col': 'Colosenses',
      '1tes': '1 Tesalonicenses',
      '2tes': '2 Tesalonicenses',
      '1tim': '1 Timoteo',
      '2tim': '2 Timoteo',
      'tit': 'Tito',
      'flm': 'Filemón',
      'heb': 'Hebreos',
      'stg': 'Santiago',
      '1pe': '1 Pedro',
      '2pe': '2 Pedro',
      '1jn': '1 Juan',
      '2jn': '2 Juan',
      '3jn': '3 Juan',
      'jud': 'Judas',
      'apoc': 'Apocalipsis',
    };
    final alias = aliases[normalized];
    if (alias != null) return alias;
    return bibleBooks
        .firstWhere(
          (book) =>
              _bookKey(book.name) == normalized ||
              _bookKey(book.shortName) == normalized,
          orElse: () => BibleBookData(rawBook.trim(), rawBook.trim(), 0),
        )
        .name;
  }

  String _bookKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'\s+'), '');
  }

  void setActiveDeck(String id) {
    if (_activeDeckId == id) return;
    _activeDeckId = id;
    _currentCardIndex = 0;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    _sessionFlowSeed = DateTime.now().microsecondsSinceEpoch;
    notifyListeners();
  }

  void configureSession({
    required int difficulty,
    required int dailyTarget,
  }) {
    _sessionDifficulty = difficulty.clamp(0, 2);
    final isCombinedBible = activeDeck.isBible && activeDeck.cards.length > 1;
    final total = isCombinedBible ? 1 : activeDeck.cards.length;
    _sessionDailyTarget = dailyTarget.clamp(1, total <= 0 ? 1 : total);
    _sessionCardsCompleted = 0;
    _sessionFlowSeed = DateTime.now().microsecondsSinceEpoch;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    final deckId = activeDeck.id;
    _completedExerciseSteps.removeWhere((key) => key.startsWith('$deckId:'));
    notifyListeners();
  }

  /// Llamar al terminar el último paso (voz final / quiz final) de una tarjeta.
  /// Retorna `true` si todavía queda otra tarjeta dentro del target diario;
  /// `false` cuando la sesión ya completó su cuota y debe ir al review final.
  bool advanceToNextSessionCard({required bool correct}) {
    final isCombinedBible = activeDeck.isBible && activeDeck.cards.length > 1;
    answerCurrentCard(correct);
    if (isCombinedBible) {
      _sessionCardsCompleted = _sessionDailyTarget;
    } else {
      _sessionCardsCompleted += 1;
    }
    if (sessionFinished) {
      notifyListeners();
      return false;
    }
    // Limpia los pasos completados del deck para que la próxima tarjeta
    // arranque con el árbol fresco. Las claves usan deck:card:slug, así que
    // basta con quitar los del deck activo.
    final deckId = activeDeck.id;
    _completedExerciseSteps.removeWhere((key) => key.startsWith('$deckId:'));
    notifyListeners();
    return true;
  }

  void updateActiveDeck({String? title, String? icon}) {
    if (_decks.isEmpty) return;
    final index = _decks.indexWhere((deck) => deck.id == activeDeck.id);
    if (index < 0) return;
    _decks[index] = _decks[index].copyWith(title: title, icon: icon);
    notifyListeners();
  }

  String _exerciseStepKey(String slug) {
    final deck = activeDeck;
    final card = activeCard;
    return '${deck.id}:${card.id}:$slug';
  }

  bool isExerciseStepCompleted(String slug) {
    return _completedExerciseSteps.contains(_exerciseStepKey(slug));
  }

  void markExerciseStepCompleted(String slug) {
    final key = _exerciseStepKey(slug);
    if (_completedExerciseSteps.add(key)) notifyListeners();
  }

  String voiceReadForCurrentCard() {
    return _exerciseVoiceReads['${activeDeck.id}:${activeCard.id}'] ?? '';
  }

  void saveVoiceReadForCurrentCard(String text) {
    _exerciseVoiceReads['${activeDeck.id}:${activeCard.id}'] = text;
    notifyListeners();
  }

  String voiceAudioPathForCurrentCard() {
    return _exerciseVoiceAudioPaths['${activeDeck.id}:${activeCard.id}'] ?? '';
  }

  void saveVoiceAudioPathForCurrentCard(String path) {
    _exerciseVoiceAudioPaths['${activeDeck.id}:${activeCard.id}'] = path;
    notifyListeners();
  }

  void toggleBibleVerse(BibleVerseData verse) {
    final index = _selectedBibleVerses.indexWhere(
      (item) =>
          item.book == verse.book &&
          item.chapter == verse.chapter &&
          item.verse == verse.verse,
    );
    if (index >= 0) {
      _selectedBibleVerses.removeAt(index);
    } else {
      _selectedBibleVerses.add(verse);
    }
    notifyListeners();
  }

  void clearBibleSelection() {
    _selectedBibleVerses.clear();
    notifyListeners();
  }

  // ─────── Visibilidad de mazos ──────────────────────────────────────────

  /// Cambia la visibilidad de un mazo. Para algo distinto a [private] el
  /// caller DEBE haber recogido `rightsAcknowledged: true` desde un
  /// consent dialog.
  bool setDeckVisibility(
    String deckId, {
    required DeckVisibility visibility,
    required bool rightsAcknowledged,
  }) {
    if (visibility != DeckVisibility.private && !rightsAcknowledged) {
      return false;
    }
    final index = _decks.indexWhere((d) => d.id == deckId);
    if (index < 0) return false;
    _decks[index] = _decks[index].copyWith(
      visibility: visibility,
      rightsAcknowledged: rightsAcknowledged,
    );
    notifyListeners();
    return true;
  }

  // ─────── Reportes de moderación ────────────────────────────────────────

  List<DeckReport> get deckReports => List.unmodifiable(_deckReports);

  void fileDeckReport({
    required String deckId,
    required String deckTitle,
    required ReportReason reason,
    String note = '',
    String reporterId = 'me',
  }) {
    final report = DeckReport(
      id: 'rep-${DateTime.now().microsecondsSinceEpoch}',
      deckId: deckId,
      deckTitle: deckTitle,
      reporterId: reporterId,
      reason: reason,
      note: note,
      createdAt: DateTime.now(),
    );
    _deckReports.insert(0, report);
    // Auto-bajar visibilidad mientras se revisa.
    final index = _decks.indexWhere((d) => d.id == deckId);
    if (index >= 0 && _decks[index].visibility == DeckVisibility.public) {
      _decks[index] = _decks[index].copyWith(
        visibility: DeckVisibility.friends,
      );
    }
    notifyListeners();
  }

  void resolveDeckReport(String reportId, ReportStatus status) {
    final i = _deckReports.indexWhere((r) => r.id == reportId);
    if (i < 0) return;
    final r = _deckReports[i];
    _deckReports[i] = r.copyWith(status: status);
    // Aplicar la decisión al deck reportado.
    if (status == ReportStatus.resolvedRemoved) {
      _decks.removeWhere((d) => d.id == r.deckId);
    } else if (status == ReportStatus.resolvedHidden) {
      final idx = _decks.indexWhere((d) => d.id == r.deckId);
      if (idx >= 0) {
        _decks[idx] = _decks[idx].copyWith(
          visibility: DeckVisibility.private,
        );
      }
    }
    // resolvedKept: dejar como esté.
    notifyListeners();
  }

  /// Remove every verse in [verses] from the selection. Single notify.
  int removeBibleVerses(Iterable<BibleVerseData> verses) {
    final keys = verses
        .map((v) => '${v.book}:${v.chapter}:${v.verse}')
        .toSet();
    final before = _selectedBibleVerses.length;
    _selectedBibleVerses.removeWhere(
      (v) => keys.contains('${v.book}:${v.chapter}:${v.verse}'),
    );
    final removed = before - _selectedBibleVerses.length;
    if (removed > 0) notifyListeners();
    return removed;
  }

  void addBibleVerse(BibleVerseData verse) {
    final exists = _selectedBibleVerses.any(
      (item) =>
          item.book == verse.book &&
          item.chapter == verse.chapter &&
          item.verse == verse.verse,
    );
    if (!exists) {
      _selectedBibleVerses.add(verse);
      notifyListeners();
    }
  }

  /// Batch-add many verses with a single notification. Skips duplicates.
  /// Returns how many new verses were actually added.
  int addBibleVerses(Iterable<BibleVerseData> verses) {
    var added = 0;
    final existing = _selectedBibleVerses
        .map((v) => '${v.book}:${v.chapter}:${v.verse}')
        .toSet();
    for (final verse in verses) {
      final key = '${verse.book}:${verse.chapter}:${verse.verse}';
      if (existing.add(key)) {
        _selectedBibleVerses.add(verse);
        added++;
      }
    }
    if (added > 0) notifyListeners();
    return added;
  }

  /// Add every verse of [book]/[chapter] to the selection.
  int addAllVersesInChapter(String book, int chapter) {
    return addBibleVerses(versesFor(book, chapter));
  }

  /// Add every verse of every chapter of [book] to the selection.
  int addAllVersesInBook(String book) {
    final canonical = _canonicalBookName(book);
    return addBibleVerses(
      _bibleVerses.where((v) => v.book == canonical),
    );
  }

  /// Add every verse of the loaded bible to the selection.
  int addAllVersesInBible() {
    return addBibleVerses(_bibleVerses);
  }

  /// True when every verse of [book]/[chapter] is already selected.
  bool isWholeChapterSelected(String book, int chapter) {
    final all = versesFor(book, chapter);
    if (all.isEmpty) return false;
    final selectedKeys = _selectedBibleVerses
        .where((v) => v.book == all.first.book && v.chapter == chapter)
        .map((v) => v.verse)
        .toSet();
    return all.every((v) => selectedKeys.contains(v.verse));
  }

  /// True when every chapter of [book] is fully selected.
  bool isWholeBookSelected(String book) {
    final canonical = _canonicalBookName(book);
    final chapters = _bibleVerses
        .where((v) => v.book == canonical)
        .map((v) => v.chapter)
        .toSet();
    if (chapters.isEmpty) return false;
    return chapters.every((c) => isWholeChapterSelected(canonical, c));
  }

  bool createBibleDeckFromSelection() {
    if (_selectedBibleVerses.isEmpty) return false;
    final grouped = _selectedBibleVerses.first;
    final title = '${grouped.book} ${grouped.chapter}';
    final deck = MemoryDeckData(
      id: 'bible-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      subtitle: '${_selectedBibleVerses.length} versículos seleccionados',
      icon: '✝️',
      isBible: true,
      createdAt: DateTime.now(),
      cards: [
        for (final verse in _selectedBibleVerses)
          MemoryCardData(
            id: '${verse.book}-${verse.chapter}-${verse.verse}',
            front: verse.ref,
            back: verse.text,
            source: 'RV1909',
            icon: '✝️',
            retention: 74,
          ),
      ],
    );
    _decks.insert(0, deck);
    setActiveDeck(deck.id);
    return true;
  }

  MemoryDeckData? createDeckFromRawContent({
    required String title,
    required String icon,
    required String content,
  }) {
    final cards = segmentContent(content, icon: icon, title: title);
    return createDeckFromCards(title: title, icon: icon, cards: cards);
  }

  MemoryDeckData? createDeckFromCards({
    required String title,
    required String icon,
    required List<MemoryCardData> cards,
  }) {
    final cleanCards = cards
        .where(
          (card) => card.front.trim().isNotEmpty || card.back.trim().isNotEmpty,
        )
        .map(
          (card) => card.copyWith(
            front: card.front.trim().isEmpty ? 'Tarjeta' : card.front.trim(),
            back: card.back.trim(),
            icon: icon,
          ),
        )
        .where((card) => card.back.isNotEmpty)
        .toList();
    if (cleanCards.isEmpty) return null;
    final deck = MemoryDeckData(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Contenido nuevo' : title.trim(),
      subtitle: '${cleanCards.length} tarjetas generadas',
      icon: icon,
      createdAt: DateTime.now(),
      cards: cleanCards,
    );
    _decks.insert(0, deck);
    setActiveDeck(deck.id);
    return deck;
  }

  List<MemoryCardData> segmentContent(
    String content, {
    String icon = '🧠',
    String? title,
  }) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    var segments = normalized
        .split('\n')
        .map(_normalizeSegment)
        .where((line) => line.isNotEmpty)
        .toList();
    if (segments.isEmpty) return const [];
    final verseCards = _segmentBibleVerseLines(
      segments,
      icon: icon,
      title: title,
    );
    if (verseCards.isNotEmpty) return verseCards;
    if (segments.length == 1) {
      final sentences = _splitSentences(segments.single);
      if (sentences.length > 1) segments = sentences;
    }
    return [
      for (var i = 0; i < segments.length; i++)
        _cardFromLine(segments[i], index: i, icon: icon),
    ];
  }

  void answerCurrentCard(bool correct) {
    if (_decks.isEmpty || activeDeck.cards.isEmpty) return;
    final deckIndex = _decks.indexWhere((deck) => deck.id == activeDeck.id);
    if (deckIndex < 0) return;
    final deck = activeDeck;
    final cards = [...deck.cards];
    if (deck.isBible && deck.cards.length > 1) {
      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        cards[i] = card.copyWith(
          retention: (card.retention + (correct ? 8 : -14)).clamp(18, 100),
          lapses: card.lapses + (correct ? 0 : 1),
        );
      }
      _decks[deckIndex] = MemoryDeckData(
        id: deck.id,
        title: deck.title,
        subtitle: deck.subtitle,
        icon: deck.icon,
        cards: cards,
        createdAt: deck.createdAt,
        isBible: deck.isBible,
      );
      if (correct) {
        _correctAnswers += cards.length;
      } else {
        _wrongAnswers += cards.length;
      }
      _currentCardIndex = 0;
      notifyListeners();
      return;
    }
    final card = cards[_currentCardIndex];
    cards[_currentCardIndex] = card.copyWith(
      retention: (card.retention + (correct ? 8 : -14)).clamp(18, 100),
      lapses: card.lapses + (correct ? 0 : 1),
    );
    _decks[deckIndex] = MemoryDeckData(
      id: deck.id,
      title: deck.title,
      subtitle: deck.subtitle,
      icon: deck.icon,
      cards: cards,
      createdAt: deck.createdAt,
      isBible: deck.isBible,
    );
    if (correct) {
      _correctAnswers++;
    } else {
      _wrongAnswers++;
    }
    _currentCardIndex = (_currentCardIndex + 1) % cards.length;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}

List<MemoryCardData> _segmentBibleVerseLines(
  List<String> lines, {
  required String icon,
  required String? title,
}) {
  final seed = _BibleReferenceSeed.tryParse(title ?? '');
  final cards = <MemoryCardData>[];
  final buffer = StringBuffer();
  var foundVerseMarker = false;
  var foundFullReference = false;
  var verseMarkerCount = 0;
  int? firstVerseMarker;
  var front = seed?.frontFor(seed.startVerse) ?? 'Tarjeta 1';

  void flush() {
    final text = _normalizeSegment(buffer.toString());
    if (text.isEmpty) return;
    cards.add(
      MemoryCardData(
        id: 'card-${DateTime.now().microsecondsSinceEpoch}-${cards.length}',
        front: front,
        back: text,
        source: 'Contenido propio',
        icon: icon,
        retention: 68,
      ),
    );
    buffer.clear();
  }

  for (final line in lines) {
    final fullRef = _parseFullBibleReference(line);
    if (fullRef != null) {
      foundVerseMarker = true;
      foundFullReference = true;
      flush();
      front = fullRef.$1;
      buffer.write(fullRef.$2);
      continue;
    }

    final numbered = RegExp(r'^(\d{1,3})(?:[\).])?\s*(.+)$').firstMatch(line);
    if (numbered != null) {
      foundVerseMarker = true;
      verseMarkerCount++;
      flush();
      final verse = int.parse(numbered.group(1)!);
      firstVerseMarker ??= verse;
      front = seed?.frontFor(verse) ?? 'Versículo $verse';
      buffer.write(numbered.group(2)!.trim());
      continue;
    }

    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(line);
  }

  flush();
  final looksLikeVerseBlock =
      seed != null ||
      foundFullReference ||
      verseMarkerCount > 1 ||
      firstVerseMarker == 1;
  return foundVerseMarker && looksLikeVerseBlock ? cards : const [];
}

MemoryCardData _cardFromLine(
  String line, {
  required int index,
  required String icon,
}) {
  final cleaned = _stripLeadingMarker(line);
  final parsed = _parseFrontBack(cleaned);
  final front = parsed.$1.isEmpty ? 'Tarjeta ${index + 1}' : parsed.$1;
  final back = parsed.$2.isEmpty ? cleaned : parsed.$2;
  return MemoryCardData(
    id: 'card-${DateTime.now().microsecondsSinceEpoch}-$index',
    front: front,
    back: back,
    source: 'Contenido propio',
    icon: icon,
    retention: 68,
  );
}

String _normalizeSegment(String value) {
  return value.replaceAll('\t', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _stripLeadingMarker(String value) {
  return value.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[\).])\s+'), '').trim();
}

List<String> _splitSentences(String value) {
  return value
      .split(RegExp(r'(?<=[.!?;])\s+'))
      .map(_normalizeSegment)
      .where((sentence) => sentence.length > 12)
      .toList();
}

(String, String) _parseFrontBack(String line) {
  final bibleMatch = RegExp(
    r'^((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*\s+\d+:\d+(?:-\d+)?)\s*[:\-–—]?\s+(.+)$',
  ).firstMatch(line);
  if (bibleMatch != null) {
    return (bibleMatch.group(1)!.trim(), bibleMatch.group(2)!.trim());
  }

  final separatorMatch = RegExp(
    r'^(.{1,80}?)(?:\s+[-–—|=]\s+|:\s+)(.+)$',
  ).firstMatch(line);
  if (separatorMatch != null) {
    return (separatorMatch.group(1)!.trim(), separatorMatch.group(2)!.trim());
  }

  return ('', line.trim());
}

(String, String)? _parseFullBibleReference(String line) {
  final match = RegExp(
    r'^((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*\s+\d+:\d+(?:-\d+)?)\s+(.+)$',
  ).firstMatch(line);
  if (match == null) return null;
  return (match.group(1)!.trim(), match.group(2)!.trim());
}

class _BibleReferenceSeed {
  final String book;
  final int chapter;
  final int startVerse;

  const _BibleReferenceSeed({
    required this.book,
    required this.chapter,
    required this.startVerse,
  });

  static _BibleReferenceSeed? tryParse(String text) {
    final match = RegExp(
      r'^\s*((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*)\s+(\d+):(\d+)(?:-\d+)?',
    ).firstMatch(text);
    if (match == null) return null;
    return _BibleReferenceSeed(
      book: match.group(1)!.trim(),
      chapter: int.parse(match.group(2)!),
      startVerse: int.parse(match.group(3)!),
    );
  }

  String frontFor(int verse) => '$book $chapter:$verse';
}

const bibleBooks = [
  BibleBookData('Génesis', 'Gén', 50),
  BibleBookData('Éxodo', 'Éxo', 40),
  BibleBookData('Levítico', 'Lev', 27),
  BibleBookData('Números', 'Núm', 36),
  BibleBookData('Deuteronomio', 'Deut', 34),
  BibleBookData('Josué', 'Jos', 24),
  BibleBookData('Jueces', 'Jue', 21),
  BibleBookData('Rut', 'Rut', 4),
  BibleBookData('1 Samuel', '1 Sam', 31),
  BibleBookData('2 Samuel', '2 Sam', 24),
  BibleBookData('1 Reyes', '1 Rey', 22),
  BibleBookData('2 Reyes', '2 Rey', 25),
  BibleBookData('1 Crónicas', '1 Cró', 29),
  BibleBookData('2 Crónicas', '2 Cró', 36),
  BibleBookData('Esdras', 'Esd', 10),
  BibleBookData('Nehemías', 'Neh', 13),
  BibleBookData('Ester', 'Est', 10),
  BibleBookData('Job', 'Job', 42),
  BibleBookData('Salmos', 'Sal', 150),
  BibleBookData('Proverbios', 'Prov', 31),
  BibleBookData('Eclesiastés', 'Ecl', 12),
  BibleBookData('Cantares', 'Cant', 8),
  BibleBookData('Isaías', 'Isa', 66),
  BibleBookData('Jeremías', 'Jer', 52),
  BibleBookData('Lamentaciones', 'Lam', 5),
  BibleBookData('Ezequiel', 'Eze', 48),
  BibleBookData('Daniel', 'Dan', 12),
  BibleBookData('Oseas', 'Os', 14),
  BibleBookData('Joel', 'Joel', 3),
  BibleBookData('Amós', 'Am', 9),
  BibleBookData('Abdías', 'Abd', 1),
  BibleBookData('Jonás', 'Jon', 4),
  BibleBookData('Miqueas', 'Miq', 7),
  BibleBookData('Nahúm', 'Nah', 3),
  BibleBookData('Habacuc', 'Hab', 3),
  BibleBookData('Sofonías', 'Sof', 3),
  BibleBookData('Hageo', 'Hag', 2),
  BibleBookData('Zacarías', 'Zac', 14),
  BibleBookData('Malaquías', 'Mal', 4),
  BibleBookData('Mateo', 'Mat', 28),
  BibleBookData('Marcos', 'Mar', 16),
  BibleBookData('Lucas', 'Luc', 24),
  BibleBookData('Juan', 'Juan', 21),
  BibleBookData('Hechos', 'Hech', 28),
  BibleBookData('Romanos', 'Rom', 16),
  BibleBookData('1 Corintios', '1 Cor', 16),
  BibleBookData('2 Corintios', '2 Cor', 13),
  BibleBookData('Gálatas', 'Gál', 6),
  BibleBookData('Efesios', 'Efe', 6),
  BibleBookData('Filipenses', 'Fil', 4),
  BibleBookData('Colosenses', 'Col', 4),
  BibleBookData('1 Tesalonicenses', '1 Tes', 5),
  BibleBookData('2 Tesalonicenses', '2 Tes', 3),
  BibleBookData('1 Timoteo', '1 Tim', 6),
  BibleBookData('2 Timoteo', '2 Tim', 4),
  BibleBookData('Tito', 'Tit', 3),
  BibleBookData('Filemón', 'Flm', 1),
  BibleBookData('Hebreos', 'Heb', 13),
  BibleBookData('Santiago', 'Stg', 5),
  BibleBookData('1 Pedro', '1 Ped', 5),
  BibleBookData('2 Pedro', '2 Ped', 3),
  BibleBookData('1 Juan', '1 Jn', 5),
  BibleBookData('2 Juan', '2 Jn', 1),
  BibleBookData('3 Juan', '3 Jn', 1),
  BibleBookData('Judas', 'Jud', 1),
  BibleBookData('Apocalipsis', 'Apoc', 22),
];
