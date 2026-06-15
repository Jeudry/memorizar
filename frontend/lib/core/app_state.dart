import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/moderation/data/report_models.dart';
import 'api/memorizar_client.dart';
import 'api/models.dart';
import 'db/app_database.dart';
import 'services/push_service.dart';
import 'services/secure_store.dart';
import 'srs/sm2.dart';
import '../features/cooperativo/data/coop_service.dart';
import 'package:drift/drift.dart' as drift;

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
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;

  const MemoryCardData({
    required this.id,
    required this.front,
    required this.back,
    required this.source,
    required this.icon,
    this.retention = 82,
    this.lapses = 0,
    this.easeFactor = Sm2State.defaultEaseFactor,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.nextReviewAt,
  });

  /// Estado SM-2 de la tarjeta para alimentar el algoritmo.
  Sm2State get srsState => Sm2State(
        easeFactor: easeFactor,
        intervalDays: intervalDays,
        repetitions: repetitions,
        nextReviewAt: nextReviewAt,
      );

  /// Due = nunca repasada o con la fecha de repaso vencida.
  bool get isDueForReview => isDue(srsState);

  MemoryCardData copyWith({
    String? id,
    String? front,
    String? back,
    String? source,
    String? icon,
    int? retention,
    int? lapses,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewAt,
  }) {
    return MemoryCardData(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      source: source ?? this.source,
      icon: icon ?? this.icon,
      retention: retention ?? this.retention,
      lapses: lapses ?? this.lapses,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
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
  /// Grupo (carpeta) al que pertenece el mazo. null = sin grupo.
  final String? groupId;

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
    this.groupId,
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
    // Sentinel para poder asignar groupId a null ("sin grupo") explícitamente.
    Object? groupId = _noChange,
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
      groupId: groupId == _noChange ? this.groupId : groupId as String?,
    );
  }
}

const Object _noChange = Object();

/// Grupo/carpeta para organizar mazos en la pestaña Mazos.
class MemoryGroupData {
  final String id;
  final String name;
  final String icon;
  final DateTime createdAt;

  const MemoryGroupData({
    required this.id,
    required this.name,
    this.icon = '📁',
    required this.createdAt,
  });
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
  String? pendingReferrerId;

  AppStore({
    MemorizarClient? api,
    AppDatabase? db,
    this.enableDatabasePersistence = true,
  })  : api = api ?? MemorizarClient(),
        db = db ?? (enableDatabasePersistence ? AppDatabase() : null) {
    if (kIsWeb) {
      final ref = Uri.base.queryParameters['ref'];
      if (ref != null && ref.isNotEmpty) {
        pendingReferrerId = ref;
      }
    }
  }

  /// Cliente HTTP del backend Go. Lo expongo público para que features que
  /// hablan directo con la API (Amigos, Feed) lo reusen sin duplicarlo.
  final MemorizarClient api;
  final AppDatabase? db;
  final bool enableDatabasePersistence;

  /// Código de sala pendiente de un deeplink memorizar://coop/{code}.
  /// El lobby cooperativo lo consume en su init y se une automáticamente.
  String? pendingCoopJoinCode;

  /// Historial de actividad diaria (día 'YYYY-MM-DD' → totales), ordenado
  /// del más reciente. Fuente de la racha real y de los filtros de Stats.
  List<DailyActivityData> _dailyActivity = [];
  List<DailyActivityData> get dailyActivity =>
      List.unmodifiable(_dailyActivity);

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadDailyActivity() async {
    if (db == null) return;
    _dailyActivity = await db!.getAllDailyActivity();
  }

  /// Registra una respuesta en la actividad de HOY (memoria + Drift).
  void _recordAnswerActivity({required bool correct, int count = 1}) {
    final today = _dayKey(DateTime.now());
    final index = _dailyActivity.indexWhere((entry) => entry.day == today);
    if (index >= 0) {
      final current = _dailyActivity[index];
      _dailyActivity[index] = current.copyWith(
        correct: current.correct + (correct ? count : 0),
        wrong: current.wrong + (correct ? 0 : count),
        cardsReviewed: current.cardsReviewed + count,
      );
    } else {
      _dailyActivity.insert(
        0,
        DailyActivityData(
          day: today,
          correct: correct ? count : 0,
          wrong: correct ? 0 : count,
          cardsReviewed: count,
        ),
      );
    }
    if (enableDatabasePersistence) {
      unawaited(db!.recordDailyActivity(
        day: today,
        correctDelta: correct ? count : 0,
        wrongDelta: correct ? 0 : count,
        reviewedDelta: count,
      ));
    }
  }

  /// Suma de actividad de los últimos [days] días (incluyendo hoy).
  ({int correct, int wrong, int reviewed}) activityInLastDays(int days) {
    final cutoff = _dayKey(DateTime.now().subtract(Duration(days: days - 1)));
    var correct = 0;
    var wrong = 0;
    var reviewed = 0;
    for (final entry in _dailyActivity) {
      if (entry.day.compareTo(cutoff) < 0) break;
      correct += entry.correct;
      wrong += entry.wrong;
      reviewed += entry.cardsReviewed;
    }
    return (correct: correct, wrong: wrong, reviewed: reviewed);
  }

  Future<void> loadDecksFromDatabase() async {
    if (db == null) return;
    await _loadDailyActivity();
    final dbDecks = await db!.getAllDecks();
    if (dbDecks.isEmpty) {
      // Pre-cargar mazo de demostración de Filipenses 4
      final demoDeck = DecksCompanion(
        id: const drift.Value('demo-filipenses-4'),
        title: const drift.Value('Filipenses 4'),
        subtitle: const drift.Value('2 versículos de demostración'),
        icon: const drift.Value('✝️'),
        isBible: const drift.Value(true),
        createdAt: drift.Value(DateTime.now()),
      );
      await db!.upsertDeck(demoDeck);

      final demoCards = [
        CardsCompanion(
          id: const drift.Value('fil-4-13'),
          deckId: const drift.Value('demo-filipenses-4'),
          front: const drift.Value('Filipenses 4:13'),
          back: const drift.Value('Todo lo puedo en Cristo que me fortalece.'),
          source: const drift.Value('RV1909'),
          icon: const drift.Value('✝️'),
          retention: const drift.Value(74),
          lapses: const drift.Value(0),
        ),
        CardsCompanion(
          id: const drift.Value('fil-4-19'),
          deckId: const drift.Value('demo-filipenses-4'),
          front: const drift.Value('Filipenses 4:19'),
          back: const drift.Value('Mi Dios, pues, suplirá todo lo que os falta conforme a sus riquezas en gloria en Cristo Jesús.'),
          source: const drift.Value('RV1909'),
          icon: const drift.Value('✝️'),
          retention: const drift.Value(74),
          lapses: const drift.Value(0),
        ),
      ];

      for (final card in demoCards) {
        await db!.upsertCard(card);
      }
      
      return loadDecksFromDatabase();
    }

    final loadedDecks = <MemoryDeckData>[];
    for (final d in dbDecks) {
      final dbCards = await db!.getCardsForDeck(d.id);
      final cards = dbCards.map((c) => MemoryCardData(
        id: c.id,
        front: c.front,
        back: c.back,
        source: c.source,
        icon: c.icon,
        retention: c.retention,
        lapses: c.lapses,
        easeFactor: c.easeFactor,
        intervalDays: c.intervalDays,
        repetitions: c.repetitions,
        nextReviewAt: c.nextReviewAt,
      )).toList();

      loadedDecks.add(MemoryDeckData(
        id: d.id,
        title: d.title,
        subtitle: d.subtitle,
        icon: d.icon,
        createdAt: d.createdAt,
        isBible: d.isBible,
        groupId: d.groupId,
        cards: cards,
      ));
    }

    final dbGroups = await db!.getAllGroups();
    _groups
      ..clear()
      ..addAll(dbGroups.map((g) => MemoryGroupData(
            id: g.id,
            name: g.name,
            icon: g.icon,
            createdAt: g.createdAt,
          )));

    _decks.clear();
    _decks.addAll(loadedDecks);
    if (_decks.isNotEmpty && _activeDeckId == null) {
      _activeDeckId = _decks.first.id;
    }
    notifyListeners();
  }

  // ─── Auth ───────────────────────────────────────────────────────────────

  static const _kSessionTokenKey = 'memorizar.session.token';
  static const _kSessionUserKey = 'memorizar.session.user';

  /// Identificador de instancia derivado del mismo dart-define que aísla la
  /// base de datos. Las SharedPreferences son por bundle (compartidas entre
  /// instancias), así que el usuario invitado debe claver por instancia: si
  /// no, dos ventanas comparten guest id y el hub coop las pisa entre sí.
  static const String _instanceId =
      String.fromEnvironment('DB_NAME', defaultValue: 'memorizar.sqlite');
  static const _kGuestUserKey =
      'memorizar.session.guest_user.$_instanceId';

  RemoteUser? _currentUser;
  RemoteUser? _guestUser;
  String? _sessionToken;

  RemoteUser? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _sessionToken != null && _sessionToken!.isNotEmpty;

  /// Solo los moderadores ven la cola de moderación. El backend es la fuente
  /// de verdad (gate 403); este flag decide si se ofrece la UI.
  bool get isModerator => _currentUser?.isModerator ?? false;
  
  RemoteUser get effectiveUser {
    if (_currentUser != null) {
      return _currentUser!;
    }
    if (_guestUser == null) {
      final nowStr = DateTime.now().millisecondsSinceEpoch.toString();
      final num = nowStr.substring(nowStr.length - 4);
      _guestUser = RemoteUser(
        id: 'guest_$nowStr',
        email: 'guest_$nowStr@memorizar.local',
        displayName: 'Invitado #$num',
        username: 'guest_$nowStr',
        emailVerified: false,
      );
      // Persist asynchronously
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_kGuestUserKey, jsonEncode(_guestUser!.toJson()));
      });
    }
    return _guestUser!;
  }

  /// Modo invitado: el usuario decide no iniciar sesión todavía pero sigue
  /// usando la app. La diferencia con "no logueado" es semántica solamente —
  /// hoy ambos se comportan igual.
  bool get isGuest => !isLoggedIn;

  Timer? _inviteTimer;
  final List<Map<String, dynamic>> _pendingCoopInvites = [];
  List<Map<String, dynamic>> get pendingCoopInvites => List.unmodifiable(_pendingCoopInvites);
  final Set<String> _notifiedFriendRequests = {};

  void clearPendingCoopInvite(String roomCode) {
    _pendingCoopInvites.removeWhere((i) => i['roomCode'] == roomCode);
    notifyListeners();
  }

  void _startInviteTimer() {
    _inviteTimer?.cancel();
    _inviteTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!isLoggedIn) return;
      
      // 1. Detección de invitaciones cooperativas pendientes
      try {
        final invites = await api.getPendingCoopInvites();
        if (invites.isNotEmpty) {
          bool updated = false;
          for (final invite in invites) {
            if (invite is Map) {
              final inviteMap = Map<String, dynamic>.from(invite);
              final code = inviteMap['roomCode'] as String? ?? '';
              final alreadyHas = _pendingCoopInvites.any((i) => i['roomCode'] == code);
              if (!alreadyHas && code.isNotEmpty) {
                _pendingCoopInvites.add(inviteMap);
                updated = true;
                
                final hostName = inviteMap['hostName'] as String? ?? 'Tu amigo';
                unawaited(PushService.instance.showLocalNow(
                  id: code.hashCode,
                  title: '¡Invitación Cooperativa! 🎮',
                  body: '$hostName te invita a unirte a su sala $code.',
                ));
              }
            }
          }
          if (updated) {
            notifyListeners();
          }
        }
      } catch (_) {}

      // 2. Detección de solicitudes de amistad pendientes nuevas
      try {
        final friends = await api.listFriends();
        final me = _currentUser?.id ?? '';
        final pending = friends.pendingRequests.where((f) => f.addresseeId == me).toList();
        
        bool socialUpdated = false;
        for (final req in pending) {
          if (!_notifiedFriendRequests.contains(req.id)) {
            _notifiedFriendRequests.add(req.id);
            socialUpdated = true;
            
            // Buscar nombre del solicitante de forma asíncrona
            unawaited(() async {
              try {
                final requester = await api.getUser(req.requesterId);
                final name = requester.user.displayName.isNotEmpty ? requester.user.displayName : requester.user.email;
                await PushService.instance.showLocalNow(
                  id: req.id.hashCode,
                  title: '¡Solicitud de Amistad! 👥',
                  body: '$name quiere conectar contigo en Memorizar.',
                );
              } catch (_) {
                await PushService.instance.showLocalNow(
                  id: req.id.hashCode,
                  title: '¡Solicitud de Amistad! 👥',
                  body: 'Alguien quiere conectar contigo en Memorizar.',
                );
              }
            }());
          }
        }
        if (socialUpdated) {
          unawaited(refreshPendingCount());
        }
      } catch (_) {}
    });
  }

  void _stopInviteTimer() {
    _inviteTimer?.cancel();
    _inviteTimer = null;
    _pendingCoopInvites.clear();
  }

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
    if (enableDatabasePersistence) {
      await loadDecksFromDatabase();
    }
    final prefs = await SharedPreferences.getInstance();
    final guestUserJson = prefs.getString(_kGuestUserKey);
    if (guestUserJson != null) {
      try {
        _guestUser = RemoteUser.fromJson(jsonDecode(guestUserJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    // Secreto de sesión: vive en almacenamiento cifrado. Si todavía está en
    // SharedPreferences (versiones previas), se migra una sola vez y se borra
    // el rastro en texto plano.
    var token = await SecureStore.instance.read(_kSessionTokenKey);
    var userJson = await SecureStore.instance.read(_kSessionUserKey);
    if (token == null || token.isEmpty || userJson == null) {
      final legacyToken = prefs.getString(_kSessionTokenKey);
      final legacyUser = prefs.getString(_kSessionUserKey);
      if (legacyToken != null && legacyToken.isNotEmpty && legacyUser != null) {
        token = legacyToken;
        userJson = legacyUser;
        await SecureStore.instance.write(_kSessionTokenKey, legacyToken);
        await SecureStore.instance.write(_kSessionUserKey, legacyUser);
        await prefs.remove(_kSessionTokenKey);
        await prefs.remove(_kSessionUserKey);
      }
    }
    if (token == null || token.isEmpty || userJson == null) return;
    try {
      _sessionToken = token;
      _currentUser =
          RemoteUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      api.setSessionToken(token);
      notifyListeners();
      _startInviteTimer();
      unawaited(checkAndApplyPendingReferrer());
    } catch (_) {
      await SecureStore.instance.delete(_kSessionTokenKey);
      await SecureStore.instance.delete(_kSessionUserKey);
    }
  }

  Future<void> checkAndApplyPendingReferrer() async {
    final ref = pendingReferrerId;
    if (ref != null && ref.isNotEmpty && isLoggedIn) {
      try {
        await api.acceptFriendInvite(ref);
        pendingReferrerId = null;
        unawaited(refreshPendingCount());
      } catch (e) {
        debugPrint('Error auto-accepting friend invite: $e');
      }
    }
  }

  Future<void> _persistSession(String token, RemoteUser user) async {
    await SecureStore.instance.write(_kSessionTokenKey, token);
    await SecureStore.instance
        .write(_kSessionUserKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearPersistedSession() async {
    await SecureStore.instance.delete(_kSessionTokenKey);
    await SecureStore.instance.delete(_kSessionUserKey);
    // Limpia también cualquier rastro legado en texto plano.
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
    _startInviteTimer();
    unawaited(checkAndApplyPendingReferrer());
    // Bajar snapshot remoto en background (best-effort, no bloquea login).
    unawaited(pullProgressSnapshot());
    unawaited(refreshPremiumStatus());
    unawaited(refreshPendingCount());
  }

  Future<void> logout() async {
    _currentUser = null;
    _sessionToken = null;
    api.setSessionToken(null);
    await _clearPersistedSession();
    _stopInviteTimer();
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
    required int age,
  }) async {
    final result = await api.registerEmail(
      email: email,
      password: password,
      displayName: displayName,
      username: username,
      age: age,
    );
    _currentUser = result.user;
    _sessionToken = result.session.token;
    api.setSessionToken(_sessionToken);
    await _persistSession(result.session.token, result.user);
    notifyListeners();
    _startInviteTimer();
    unawaited(checkAndApplyPendingReferrer());
    unawaited(pullProgressSnapshot());
    unawaited(refreshPremiumStatus());
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
    _startInviteTimer();
    unawaited(checkAndApplyPendingReferrer());
    unawaited(pullProgressSnapshot());
    unawaited(refreshPremiumStatus());
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
    String? username,
    int? age,
  }) async {
    if (!isLoggedIn) return;
    final updated = await api.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
      locale: locale,
      username: username,
      age: age,
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
  static const _kDyslexiaModeKey = 'memorizar.dyslexia.mode';
  static const _kBigFontKey = 'memorizar.big.font';
  static const _kReminderEnabledKey = 'memorizar.reminder.enabled';
  static const _kReminderHourKey = 'memorizar.reminder.hour';

  ThemeMode _themeMode = ThemeMode.dark;
  String _locale = 'es';
  bool _dyslexiaMode = false;
  bool _bigFont = false;
  bool _reminderEnabled = false;
  int _reminderHour = 20;

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  bool get dyslexiaMode => _dyslexiaMode;
  bool get bigFont => _bigFont;
  bool get reminderEnabled => _reminderEnabled;
  int get reminderHour => _reminderHour;

  Future<void> bootstrapPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final tm = prefs.getString(_kThemeModeKey);
    if (tm == 'light') _themeMode = ThemeMode.light;
    if (tm == 'system') _themeMode = ThemeMode.system;
    if (tm == 'dark') _themeMode = ThemeMode.dark;
    final loc = prefs.getString(_kLocaleKey);
    if (loc != null && loc.isNotEmpty) _locale = loc;
    
    _dyslexiaMode = prefs.getBool(_kDyslexiaModeKey) ?? false;
    _bigFont = prefs.getBool(_kBigFontKey) ?? false;
    _reminderEnabled = prefs.getBool(_kReminderEnabledKey) ?? false;
    _reminderHour = prefs.getInt(_kReminderHourKey) ?? 20;
    // Re-programar al arrancar mantiene el recordatorio vigente aunque el
    // sistema lo haya purgado (reinicios, actualizaciones de la app).
    if (_reminderEnabled) {
      unawaited(PushService.instance.scheduleDailyReminder(hour: _reminderHour));
    }

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

  Future<void> setDyslexiaMode(bool value) async {
    _dyslexiaMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDyslexiaModeKey, value);
    notifyListeners();
  }

  Future<void> setBigFont(bool value) async {
    _bigFont = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBigFontKey, value);
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool value) async {
    _reminderEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReminderEnabledKey, value);
    if (value) {
      unawaited(PushService.instance.scheduleDailyReminder(hour: _reminderHour));
    } else {
      unawaited(PushService.instance.cancelDailyReminder());
    }
    notifyListeners();
  }

  Future<void> setReminderHour(int value) async {
    _reminderHour = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHourKey, value);
    if (_reminderEnabled) {
      unawaited(PushService.instance.scheduleDailyReminder(hour: value));
    }
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
      } else if (payload is Map) {
        snap = Map<String, dynamic>.from(payload);
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
  final Set<String> _loadedBibleBooks = {};
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
  /// Toggle experimental: cuando está activo, cada tarjeta corre su flujo de
  /// ejercicios DOS veces antes de avanzar (más práctica por versículo). Es
  /// solo de sesión (no se persiste). `_currentCardPass` distingue 0 vs 1.
  bool _doubleExercises = false;
  int _currentCardPass = 0;

  List<MemoryDeckData> get decks => List.unmodifiable(_decks);
  final List<MemoryGroupData> _groups = [];
  List<MemoryGroupData> get groups => List.unmodifiable(_groups);

  /// Mazos que pertenecen a [groupId] (o sin grupo si es null).
  List<MemoryDeckData> decksInGroup(String? groupId) =>
      _decks.where((d) => d.groupId == groupId).toList();

  MemoryGroupData? groupById(String? id) {
    if (id == null) return null;
    for (final g in _groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Crea un grupo nuevo y lo persiste. Devuelve su id.
  Future<String> createGroup(String name, {String icon = '📁'}) async {
    final clean = name.trim();
    final id = 'grp-${DateTime.now().microsecondsSinceEpoch}';
    final group = MemoryGroupData(
      id: id,
      name: clean.isEmpty ? 'Grupo' : clean,
      icon: icon,
      createdAt: DateTime.now(),
    );
    _groups.add(group);
    notifyListeners();
    if (enableDatabasePersistence && db != null) {
      await db!.upsertGroup(DeckGroupsCompanion(
        id: drift.Value(group.id),
        name: drift.Value(group.name),
        icon: drift.Value(group.icon),
        createdAt: drift.Value(group.createdAt),
      ));
    }
    return id;
  }

  /// Asigna (o quita, con null) el grupo de un mazo y lo persiste.
  Future<void> assignDeckToGroup(String deckId, String? groupId) async {
    final index = _decks.indexWhere((d) => d.id == deckId);
    if (index < 0) return;
    final updated = _decks[index].copyWith(groupId: groupId);
    _decks[index] = updated;
    notifyListeners();
    if (enableDatabasePersistence && db != null) {
      await _persistDeckToDatabase(updated);
    }
  }

  /// Borra un grupo; sus mazos quedan sin grupo (no se borran).
  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    for (var i = 0; i < _decks.length; i++) {
      if (_decks[i].groupId == groupId) {
        _decks[i] = _decks[i].copyWith(groupId: null);
      }
    }
    notifyListeners();
    if (enableDatabasePersistence && db != null) {
      await db!.deleteGroup(groupId);
    }
  }

  List<BibleVerseData> get bibleVerses => List.unmodifiable(_bibleVerses);
  List<BibleVerseData> get selectedBibleVerses =>
      List.unmodifiable(_selectedBibleVerses);
  Set<String> get loadedBibleBooks => _loadedBibleBooks;
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
    // Si es Biblia, hay más de un versículo, y el usuario configuró estudiar más de 1 a la vez, se combinan.
    if (false) {
      final count = _sessionDailyTarget.clamp(1, deck.cards.length);
      final subList = deck.cards.take(count).toList();
      final combinedFront = _collapseBibleReferences(subList.map((c) => c.front).toList());
      final combinedBack = subList.map((c) => c.back.trim()).join(' ');
      return MemoryCardData(
        id: 'combined-${deck.id}-$count',
        front: combinedFront,
        back: combinedBack,
        source: subList.first.source,
        icon: subList.first.icon,
        retention: subList.first.retention,
      );
    }
    // De lo contrario (target = 1 o no es Biblia), estudiamos de a 1 por 1.
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
  bool get doubleExercises => _doubleExercises;

  void setPremiumPreview(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    _sessionFlowSeed = DateTime.now().microsecondsSinceEpoch;
    notifyListeners();
  }

  static const List<int> _streakMilestones = [3, 7, 14, 30, 100];

  /// Registra logros reales en el backend al terminar una sesión: la sesión
  /// completada siempre, y el hito de racha la primera vez que se alcanza.
  /// Best-effort: sin sesión o sin red no interrumpe el flujo.
  Future<void> _recordSessionAchievements() async {
    if (!isLoggedIn) return;
    try {
      await api.recordAchievement(
        code: 'session_completed',
        title: 'Sesión completada',
        description:
            'Completó una sesión de $_sessionDailyTarget ${_sessionDailyTarget == 1 ? 'tarjeta' : 'tarjetas'} en "${activeDeck.title}"',
        deckName: activeDeck.title,
        emoji: '🎯',
      );

      final streak = streakDays;
      if (_streakMilestones.contains(streak)) {
        final prefs = await SharedPreferences.getInstance();
        const milestoneKey = 'memorizar.achievements.lastStreakMilestone';
        final lastRecorded = prefs.getInt(milestoneKey) ?? 0;
        if (streak > lastRecorded) {
          await api.recordAchievement(
            code: 'streak_$streak',
            title: 'Racha de $streak días',
            description: 'Practicó $streak días seguidos',
            emoji: '🔥',
          );
          await prefs.setInt(milestoneKey, streak);
        }
      }
    } catch (e) {
      debugPrint('No se pudieron registrar logros: $e');
    }
  }

  /// Sincroniza el estado premium persistido en el backend. Se llama al
  /// iniciar sesión; sin sesión es no-op (el preview local de invitado se
  /// pierde al reinstalar, a propósito).
  Future<void> refreshPremiumStatus() async {
    if (!isLoggedIn) return;
    try {
      final status = await api.getPremiumStatus();
      final active = (status['active'] as bool?) ?? false;
      if (_isPremium != active) {
        _isPremium = active;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('No se pudo refrescar el estado premium: $e');
    }
  }

  /// Activa el trial premium real (server-side). Devuelve un mensaje de
  /// error amigable, o null si quedó activo.
  Future<String?> activatePremiumTrial() async {
    if (!isLoggedIn) {
      // Invitado: preview local explícito, sin persistencia.
      setPremiumPreview(true);
      return null;
    }
    try {
      await api.activatePremiumTrial();
      _isPremium = true;
      notifyListeners();
      return null;
    } catch (e) {
      final message = e.toString();
      if (message.contains('trial already used')) {
        return 'Tu período de prueba ya fue utilizado.';
      }
      debugPrint('Error activando trial premium: $e');
      return 'No se pudo activar la prueba premium. Inténtalo de nuevo.';
    }
  }

  int get completedCards => _correctAnswers + _wrongAnswers;

  /// Racha real: días consecutivos con actividad registrada, contando hacia
  /// atrás desde hoy (o desde ayer, para no romper la racha antes de
  /// practicar hoy).
  int get streakDays {
    if (_dailyActivity.isEmpty) return 0;
    final activeDays = _dailyActivity.map((entry) => entry.day).toSet();
    var cursor = DateTime.now();
    if (!activeDays.contains(_dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!activeDays.contains(_dayKey(cursor))) return 0;
    }
    var streak = 0;
    while (activeDays.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
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

  /// Tarjetas vencidas según SM-2 (nextReviewAt en el pasado o nunca
  /// repasadas), las más débiles primero. Limitadas a 5 para la sesión de
  /// rescate rápida.
  List<MemoryCardData> get dueCards {
    final cards = [
      for (final deck in _decks)
        for (final card in deck.cards)
          if (card.isDueForReview) card,
    ];
    cards.sort((a, b) => a.retention.compareTo(b.retention));
    return cards.take(5).toList();
  }

  /// Total de tarjetas con repaso vencido hoy (sin límite).
  int get dueTodayCount => _decks.fold(
        0,
        (total, deck) =>
            total + deck.cards.where((card) => card.isDueForReview).length,
      );

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
  String _bibleVersion = 'rvg';

  String get bibleVersion => _bibleVersion;

  /// Indexación rápida O(1) de versículos por libro y capítulo para la versión activa.
  final Map<String, Map<int, List<BibleVerseData>>> _versesCache = {};

  void _rebuildVersesCache() {
    _versesCache.clear();
    _loadedBibleBooks.clear();
    for (final verse in _bibleVerses) {
      _loadedBibleBooks.add(verse.book);
      final bookCache = _versesCache.putIfAbsent(verse.book, () => {});
      final chapterList = bookCache.putIfAbsent(verse.chapter, () => []);
      chapterList.add(verse);
    }
  }

  void setBibleVersion(String version) {
    if (!_bibleByVersion.containsKey(version)) return;
    if (_bibleVersion == version) return;
    _bibleVersion = version;
    _bibleVerses
      ..clear()
      ..addAll(_bibleByVersion[version]!);
    _rebuildVersesCache();
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
    _rebuildVersesCache();
  }

  List<BibleVerseData> versesFor(String book, int chapter) {
    final canonicalBook = _canonicalBookName(book);
    final bookCache = _versesCache[canonicalBook];
    if (bookCache == null) return const [];
    return bookCache[chapter] ?? const [];
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
    bool doubleExercises = false,
  }) {
    _sessionDifficulty = difficulty.clamp(0, 2);
    // El total configurable siempre es el número real de tarjetas en el mazo.
    final total = activeDeck.cards.length;
    _sessionDailyTarget = dailyTarget.clamp(1, total <= 0 ? 1 : total);
    _sessionCardsCompleted = 0;
    _sessionFlowSeed = DateTime.now().microsecondsSinceEpoch;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    _doubleExercises = doubleExercises;
    _currentCardPass = 0;
    final deckId = activeDeck.id;
    _completedExerciseSteps.removeWhere((key) => key.startsWith('$deckId:'));
    notifyListeners();
  }

  /// Con "duplicar ejercicios" activo, una tarjeta debe repetir su flujo si
  /// todavía está en la primera pasada. El árbol de progreso lo consulta al
  /// finalizar para decidir entre repetir o avanzar de tarjeta.
  bool shouldRepeatCardForDouble() =>
      _doubleExercises && _currentCardPass == 0;

  /// Arranca la segunda pasada de la tarjeta actual: cambia el namespace de
  /// pasos completados (vía `_currentCardPass`) para que el árbol los muestre
  /// frescos sin tocar rutas ni slugs.
  void startSecondPass() {
    _currentCardPass = 1;
    notifyListeners();
  }

  /// Llamar al terminar el último paso (voz final / quiz final) de una tarjeta.
  /// Retorna `true` si todavía queda otra tarjeta dentro del target diario;
  /// `false` cuando la sesión ya completó su cuota y debe ir al review final.
  bool advanceToNextSessionCard({required bool correct}) {
    final isCombinedBible = false;
    answerCurrentCard(correct);
    if (isCombinedBible) {
      _sessionCardsCompleted = _sessionDailyTarget;
    } else {
      _sessionCardsCompleted += 1;
    }
    if (sessionFinished) {
      unawaited(_recordSessionAchievements());
      notifyListeners();
      return false;
    }
    // Nueva tarjeta → vuelve a la primera pasada.
    _currentCardPass = 0;
    // Limpia los pasos completados del deck para que la próxima tarjeta
    // arranque con el árbol fresco. Las claves usan deck:card:slug, así que
    // basta con quitar los del deck activo.
    final deckId = activeDeck.id;
    _completedExerciseSteps.removeWhere((key) => key.startsWith('$deckId:'));
    notifyListeners();
    return true;
  }

  void setSessionCardsCompleted(int value) {
    _sessionCardsCompleted = value;
    final deckId = activeDeck.id;
    _completedExerciseSteps.removeWhere((key) => key.startsWith('$deckId:'));
    notifyListeners();
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
    // `_currentCardPass` namespacea la segunda pasada del modo "duplicar".
    return '${deck.id}:${card.id}:p$_currentCardPass:$slug';
  }

  bool isExerciseStepCompleted(String slug) {
    return _completedExerciseSteps.contains(_exerciseStepKey(slug));
  }

  void markExerciseStepCompleted(String slug) {
    final key = _exerciseStepKey(slug);
    if (_completedExerciseSteps.add(key)) {
      if (CoopService.active != null) {
        CoopService.active!.reportScore(10);
        // Sincroniza el paso completado a todos los miembros para que el árbol
        // de progreso sea idéntico en host e invitados.
        CoopService.active!.broadcastStepDone(key);
      }
      notifyListeners();
    }
  }

  /// Marca un paso como completado a partir de un evento de red (otro jugador
  /// lo terminó). No re-emite para evitar bucles.
  void applyRemoteStepDone(String key) {
    if (_completedExerciseSteps.add(key)) notifyListeners();
  }

  void resetExerciseStepCompleted(String slug) {
    final key = _exerciseStepKey(slug);
    if (_completedExerciseSteps.remove(key)) notifyListeners();
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
    // Persistir en la cola de moderación del backend (best-effort: la copia
    // local mantiene la UX si no hay sesión o falla la red).
    if (isLoggedIn) {
      unawaited(api
          .fileDeckReport(
            deckId: deckId,
            deckTitle: deckTitle,
            reason: reason.serverKey,
            note: note,
          )
          .catchError((e) {
        debugPrint('No se pudo persistir el reporte en backend: $e');
        return <String, dynamic>{};
      }));
    }
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

  Future<void> _persistDeckToDatabase(MemoryDeckData deck) async {
    if (!enableDatabasePersistence) return;
    final companion = DecksCompanion(
      id: drift.Value(deck.id),
      title: drift.Value(deck.title),
      subtitle: drift.Value(deck.subtitle),
      icon: drift.Value(deck.icon),
      isBible: drift.Value(deck.isBible),
      createdAt: drift.Value(deck.createdAt),
      groupId: drift.Value(deck.groupId),
    );
    await db!.upsertDeck(companion);
    for (final card in deck.cards) {
      await db!.upsertCard(CardsCompanion(
        id: drift.Value(card.id),
        deckId: drift.Value(deck.id),
        front: drift.Value(card.front),
        back: drift.Value(card.back),
        source: drift.Value(card.source),
        icon: drift.Value(card.icon),
        retention: drift.Value(card.retention),
        lapses: drift.Value(card.lapses),
      ));
    }
  }

  String? createBibleDeckFromSelection() {
    if (_selectedBibleVerses.isEmpty) return null;
    
    String title;
    String subtitle;
    
    if (_selectedBibleVerses.length == _bibleVerses.length) {
      title = 'Toda la Biblia';
      subtitle = '31,102 versículos';
    } else {
      final refs = _selectedBibleVerses.map((v) => v.ref).toList();
      title = _collapseBibleReferences(refs);
      if (title.length > 32) {
        final uniqueBooks = _selectedBibleVerses.map((v) => v.book).toSet();
        if (uniqueBooks.length == 1) {
          final book = uniqueBooks.first;
          if (isWholeBookSelected(book)) {
            title = '$book (Completo)';
          } else {
            title = '$book (Selección)';
          }
        } else {
          title = 'Selección Bíblica';
        }
      }
      subtitle = '${_selectedBibleVerses.length} versículos';
    }
    final deck = MemoryDeckData(
      id: 'bible-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      icon: '✝️',
      isBible: true,
      createdAt: DateTime.now(),
      cards: [
        for (final verse in _selectedBibleVerses)
          MemoryCardData(
            id: '${verse.book}-${verse.chapter}-${verse.verse}',
            front: verse.ref,
            back: verse.text,
            source: bibleVersion.toUpperCase(),
            icon: '✝️',
            retention: 74,
          ),
      ],
    );
    _decks.insert(0, deck);
    setActiveDeck(deck.id);
    unawaited(_persistDeckToDatabase(deck));
    return deck.id;
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
    String? groupId,
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
    final looksLikeBible = _BibleReferenceSeed.tryParse(title) != null ||
        (cleanCards.isNotEmpty && (
           cleanCards.first.front.contains('Versículo') ||
           RegExp(r'^((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*\s+\d+:\d+(?:-\d+)?)$').hasMatch(cleanCards.first.front)
        ));
    final deck = MemoryDeckData(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Contenido nuevo' : title.trim(),
      subtitle: '${cleanCards.length} tarjetas generadas',
      icon: icon,
      createdAt: DateTime.now(),
      cards: cleanCards,
      isBible: looksLikeBible,
      groupId: groupId,
    );
    _decks.insert(0, deck);
    setActiveDeck(deck.id);
    unawaited(_persistDeckToDatabase(deck));
    return deck;
  }

  void addOrUpdateCoopDeck(MemoryDeckData deck) {
    _decks.removeWhere((d) => d.id == deck.id);
    _decks.insert(0, deck);
    notifyListeners();
    if (enableDatabasePersistence && db != null) {
      unawaited(_persistDeckToDatabase(deck));
    }
  }

  List<MemoryCardData> segmentContent(
    String content, {
    String icon = '🧠',
    String? title,
  }) {
    // 1. Clean URLs
    var cleaned = content.replaceAll(RegExp(r'https?://\S+|www\.\S+'), '');

    // 2. Split same-line verse markers like [2], (3), v4, 5. into newlines
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=\s|[.,;!?]|^)(?:\[(\d+)\]|\((\d+)\)|v\.?(\d+)|(\d+)(?=[\s).]))(?=\s|$)'),
      (match) {
        final numVal = match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4);
        return '\n[$numVal] ';
      },
    );

    final normalized = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    var lines = normalized
        .split('\n')
        .map((l) => l.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const [];

    // 3. Auto-detect title from the first line
    String? finalTitle = title?.trim();
    final firstLine = lines.first;
    final bibleRefRegExp = RegExp(
      r'^((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*\s+\d+:\d+(?:-\d+)?)(?:\s+[A-Za-z0-9]+)?$'
    );
    if (bibleRefRegExp.hasMatch(firstLine)) {
      if (finalTitle == null || finalTitle.isEmpty) {
        finalTitle = firstLine;
      }
      lines.removeAt(0); // Exclude from cards
    }

    if (lines.isEmpty) return const [];

    // 4. Try segmenting as Bible verses
    final verseCards = _segmentBibleVerseLines(
      lines,
      icon: icon,
      title: finalTitle,
    );
    if (verseCards.isNotEmpty) return verseCards;

    // Fallback to sentences or plain lines
    var segments = lines;
    if (!_looksLikeList(lines)) {
      final joined = lines.join(' ');
      final sentences = _splitSentences(joined);
      if (sentences.isNotEmpty) {
        segments = sentences;
      } else {
        segments = [joined];
      }
    } else {
      if (segments.length == 1) {
        final sentences = _splitSentences(segments.single);
        if (sentences.length > 1) segments = sentences;
      }
    }
    return [
      for (var i = 0; i < segments.length; i++)
        _cardFromLine(segments[i], index: i, icon: icon),
    ];
  }

  /// Aplica un repaso a la tarjeta: SM-2 (intervalos reales) + la señal
  /// visual de retención existente, y persiste todo el estado SRS.
  MemoryCardData _applySrsAnswer(MemoryCardData card, {required bool correct}) {
    final next = applySm2(card.srsState, correct: correct);
    final updated = card.copyWith(
      retention: (card.retention + (correct ? 8 : -14)).clamp(18, 100),
      lapses: card.lapses + (correct ? 0 : 1),
      easeFactor: next.easeFactor,
      intervalDays: next.intervalDays,
      repetitions: next.repetitions,
      nextReviewAt: next.nextReviewAt,
    );
    if (enableDatabasePersistence) {
      unawaited(db!.updateCardSrs(
        updated.id,
        retention: updated.retention,
        lapses: updated.lapses,
        easeFactor: updated.easeFactor,
        intervalDays: updated.intervalDays,
        repetitions: updated.repetitions,
        nextReviewAt: updated.nextReviewAt,
      ));
    }
    return updated;
  }

  /// Registra el resultado de una tarjeta jugada en modo cooperativo sobre
  /// el SRS local, con la misma curva que el modo solitario.
  void recordCoopAnswer({
    required String deckId,
    required String cardId,
    required bool correct,
  }) {
    final deckIndex = _decks.indexWhere((deck) => deck.id == deckId);
    if (deckIndex < 0) return;
    final deck = _decks[deckIndex];
    final cardIndex = deck.cards.indexWhere((card) => card.id == cardId);
    if (cardIndex < 0) return;
    final cards = [...deck.cards];
    cards[cardIndex] = _applySrsAnswer(cards[cardIndex], correct: correct);
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
    _recordAnswerActivity(correct: correct);
    notifyListeners();
  }

  void answerCurrentCard(bool correct) {
    if (_decks.isEmpty || activeDeck.cards.isEmpty) return;
    final deckIndex = _decks.indexWhere((deck) => deck.id == activeDeck.id);
    if (deckIndex < 0) return;
    final deck = activeDeck;
    final cards = [...deck.cards];
    final isCombinedBible = false;
    if (isCombinedBible) {
      for (var i = 0; i < cards.length; i++) {
        cards[i] = _applySrsAnswer(cards[i], correct: correct);
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
      _recordAnswerActivity(correct: correct, count: cards.length);
      _currentCardIndex = 0;
      notifyListeners();
      return;
    }
    cards[_currentCardIndex] =
        _applySrsAnswer(cards[_currentCardIndex], correct: correct);
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
    _recordAnswerActivity(correct: correct);
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

    final numbered = RegExp(r'^\s*[\[\(]?(\d{1,3})[\]\)]?(?:[\).])?\s*(.+)$').firstMatch(line);
    if (numbered != null) {
      final verse = int.parse(numbered.group(1)!);
      if (cards.isEmpty && firstVerseMarker == null) {
        // First buffered lines represent the preceding verse (e.g. verse - 1)
        final prevVerse = verse > 1 ? verse - 1 : 1;
        front = seed?.frontFor(prevVerse) ?? 'Versículo $prevVerse';
      }
      foundVerseMarker = true;
      verseMarkerCount++;
      flush();
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
      verseMarkerCount > 0;
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

bool _looksLikeList(List<String> lines) {
  if (lines.isEmpty) return false;
  var listMarkerLines = 0;
  var keyValueLines = 0;
  final listMarkerRegExp = RegExp(r'^\s*(?:[-*•+]|[\[\(]?\d+[\]\)]?(?:[\).])?)\s+');
  for (final line in lines) {
    if (listMarkerRegExp.hasMatch(line)) {
      listMarkerLines++;
    }
    final parsed = _parseFrontBack(_stripLeadingMarker(line));
    if (parsed.$1.isNotEmpty) {
      keyValueLines++;
    }
  }
  if (listMarkerLines > 0) return true;
  if (keyValueLines >= (lines.length / 2)) return true;
  return false;
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

String _collapseBibleReferences(List<String> references) {
  if (references.isEmpty) return '';
  if (references.length == 1) return references.first;

  final groups = <String, List<int>>{};
  final order = <String>[];

  final regex = RegExp(
    r'^((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*)\s+(\d+):(\d+)$'
  );

  var hasUnparsed = false;

  for (final ref in references) {
    final cleanRef = ref.trim();
    final match = regex.firstMatch(cleanRef);
    if (match == null) {
      hasUnparsed = true;
      break;
    }
    final book = match.group(1)!.trim();
    final chapter = match.group(2)!;
    final verse = int.tryParse(match.group(3)!) ?? 0;

    final key = '$book $chapter';
    if (!groups.containsKey(key)) {
      groups[key] = [];
      order.add(key);
    }
    groups[key]!.add(verse);
  }

  if (hasUnparsed || groups.isEmpty) {
    return references.join('; ');
  }

  final formattedGroups = <String>[];
  for (final key in order) {
    final verses = groups[key]!;
    if (verses.isEmpty) continue;

    final sorted = [...verses]..sort();
    final ranges = <String>[];
    var start = sorted.first;
    var prev = start;
    for (var i = 1; i < sorted.length; i++) {
      final n = sorted[i];
      if (n == prev + 1) {
        prev = n;
      } else {
        ranges.add(start == prev ? '$start' : '$start-$prev');
        start = n;
        prev = n;
      }
    }
    ranges.add(start == prev ? '$start' : '$start-$prev');
    final compactedVerses = ranges.join(', ');

    formattedGroups.add('$key:$compactedVerses');
  }

  return formattedGroups.join('; ');
}

