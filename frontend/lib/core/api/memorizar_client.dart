import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

/// HTTP client thin wrapper para el backend Go (`backend/cmd/api`).
///
/// El backend escucha en `:8080` por default. Para correrlo localmente:
/// `cd backend && go run cmd/api/main.go`.
///
/// La URL base se puede sobreescribir vía `--dart-define=API_BASE=...`
/// — útil para testing en device físico, donde `localhost` no apunta al Mac.
/// Excepción personalizada del sistema para mostrar mensajes amigables y premium
/// al usuario, evitando exponer detalles técnicos o URLs del servidor.
class MemorizarException implements Exception {
  final String message;
  const MemorizarException(this.message);

  @override
  String toString() => message;
}

class MemorizarClient {
  /// Base URL del backend. Por defecto:
  /// - iOS Simulator: `http://localhost:8080` (comparte loopback con Mac)
  /// - Android Emulator: `http://10.0.2.2:8080`
  /// - Device físico: hay que pasar la IP de la LAN vía `--dart-define`.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8080',
  );

  final String baseUrl;
  final http.Client _http;
  String? _bearerToken;

  MemorizarClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
      _http = client ?? http.Client();

  void setSessionToken(String? token) => _bearerToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_bearerToken != null && _bearerToken!.isNotEmpty)
          'Authorization': 'Bearer $_bearerToken',
      };

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _decode(http.Response r) async {
    if (r.body.isEmpty) return const {};
    final body = jsonDecode(r.body);
    if (r.statusCode >= 400) {
      final rawError = body is Map && body['error'] is String
          ? body['error'] as String
          : 'HTTP ${r.statusCode}';
      
      // Traducir todos los errores comunes del backend en Go
      String friendlyMsg = rawError;
      if (rawError.contains('email already in use') || rawError.contains('already in use')) {
        friendlyMsg = 'Este correo electrónico ya está registrado. Por favor, inicia sesión.';
      } else if (rawError.contains('username already in use')) {
        friendlyMsg = 'Este nombre de usuario ya está en uso. Elige otro.';
      } else if (rawError.contains('username must be 3-15 chars')) {
        friendlyMsg = 'El usuario debe tener entre 3 y 15 letras, números o guiones bajos.';
      } else if (rawError.contains('invalid age')) {
        friendlyMsg = 'Por favor, introduce una edad válida.';
      } else if (rawError.contains('invalid credentials')) {
        friendlyMsg = 'El correo o la contraseña son incorrectos.';
      } else if (rawError.contains('password must be at least 8 characters') || rawError.contains('weak password')) {
        friendlyMsg = 'La contraseña debe tener al menos 8 caracteres.';
      } else if (rawError.contains('friendship already exists') || rawError.contains('friendship exists')) {
        friendlyMsg = 'Ya tienes una solicitud de amistad activa con este usuario.';
      } else if (rawError.contains('user not found')) {
        friendlyMsg = 'No se encontró el usuario especificado.';
      } else if (rawError.contains('missing bearer token') || rawError.contains('invalid session')) {
        friendlyMsg = 'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.';
      } else if (rawError.contains('file too large')) {
        friendlyMsg = 'La foto es demasiado grande (máximo 8 MB).';
      } else if (rawError.contains('unsupported format')) {
        friendlyMsg = 'Formato de imagen no soportado. Usa PNG, JPG o WebP.';
      }
      
      throw MemorizarException(friendlyMsg);
    }
    if (body is Map<String, dynamic>) return body;
    return {'data': body};
  }

  // ─── Auth ───────────────────────────────────────────────────────────────

  Future<SessionResult> socialLogin({
    required String provider,
    required String providerUserId,
    required String email,
    required String displayName,
    String avatarUrl = '',
  }) async {
    final r = await _http.post(
      _uri('/v1/auth/social/login'),
      headers: _headers,
      body: jsonEncode({
        'provider': provider,
        'providerUserId': providerUserId,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
      }),
    );
    final body = await _decode(r);
    return SessionResult.fromJson(body);
  }

  Future<RemoteUser> me() async {
    final r = await _http.get(_uri('/v1/auth/me'), headers: _headers);
    final body = await _decode(r);
    return RemoteUser.fromJson(body);
  }

  Future<SessionResult> registerEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
    required int age,
  }) async {
    final r = await _http.post(
      _uri('/v1/auth/email/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'displayName': displayName,
        'username': username,
        'age': age,
      }),
    );
    return SessionResult.fromJson(await _decode(r));
  }

  Future<SessionResult> loginEmail({
    required String email,
    required String password,
  }) async {
    final r = await _http.post(
      _uri('/v1/auth/email/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return SessionResult.fromJson(await _decode(r));
  }

  Future<RemoteUser> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? locale,
    String? username,
    int? age,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (locale != null) body['locale'] = locale;
    if (username != null) body['username'] = username;
    if (age != null) body['age'] = age;
    final r = await _http.post(
      _uri('/v1/auth/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return RemoteUser.fromJson(await _decode(r));
  }

  /// Sube una imagen como avatar. Devuelve la URL pública (path relativo
  /// al backend). El llamador típicamente concatena `baseUrl + url`.
  Future<String> uploadAvatar({required String filePath}) async {
    final req = http.MultipartRequest('POST', _uri('/v1/auth/avatar'));
    if (_bearerToken != null) {
      req.headers['Authorization'] = 'Bearer $_bearerToken';
    }
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await _http.send(req);
    final r = await http.Response.fromStream(streamed);
    final body = await _decode(r);
    return (body['avatarUrl'] as String?) ?? '';
  }

  Future<String> requestEmailVerify() async {
    final r = await _http.post(
      _uri('/v1/auth/email/verify/request'),
      headers: _headers,
    );
    final body = await _decode(r);
    return (body['devToken'] as String?) ?? '';
  }

  Future<void> confirmEmailVerify(String token) async {
    final r = await _http.post(
      _uri('/v1/auth/email/verify/confirm'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    await _decode(r);
  }

  Future<String> requestPasswordReset(String email) async {
    final r = await _http.post(
      _uri('/v1/auth/password/reset/request'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    final body = await _decode(r);
    return (body['devToken'] as String?) ?? '';
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    final r = await _http.post(
      _uri('/v1/auth/password/reset/confirm'),
      headers: _headers,
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    await _decode(r);
  }

  Future<void> deleteAccount() async {
    final r = await _http.delete(
      _uri('/v1/auth/account'),
      headers: _headers,
    );
    if (r.statusCode >= 400) {
      throw HttpException('HTTP ${r.statusCode}', uri: r.request?.url);
    }
  }

  // ─── Social ─────────────────────────────────────────────────────────────

  Future<FriendsResult> listFriends() async {
    final r = await _http.get(_uri('/v1/social/friends'), headers: _headers);
    final body = await _decode(r);
    return FriendsResult.fromJson(body);
  }

  Future<List<RemoteUser>> suggestions() async {
    final r =
        await _http.get(_uri('/v1/social/suggestions'), headers: _headers);
    final body = await _decode(r);
    final list = (body['users'] as List? ?? const []).cast<dynamic>();
    return list
        .map((e) => RemoteUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RemoteUser>> searchPeople(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final r = await _http.get(
      _uri('/v1/social/search?q=$encoded'),
      headers: _headers,
    );
    final body = await _decode(r);
    final list = (body['users'] as List? ?? const []).cast<dynamic>();
    return list
        .map((e) => RemoteUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfileResult> getUser(String targetUserId) async {
    final encoded = Uri.encodeQueryComponent(targetUserId);
    final r = await _http.get(
      _uri('/v1/social/user?id=$encoded'),
      headers: _headers,
    );
    final body = await _decode(r);
    return UserProfileResult.fromJson(body);
  }

  Future<Friendship> requestFriend(String friendUserId) async {
    final r = await _http.post(
      _uri('/v1/social/friends/request'),
      headers: _headers,
      body: jsonEncode({'friendUserId': friendUserId}),
    );
    return Friendship.fromJson(await _decode(r));
  }

  Future<Friendship> acceptFriend(String friendshipId) async {
    final r = await _http.post(
      _uri('/v1/social/friends/accept'),
      headers: _headers,
      body: jsonEncode({'friendshipId': friendshipId}),
    );
    return Friendship.fromJson(await _decode(r));
  }

  Future<Friendship> acceptFriendInvite(String referrerId) async {
    final r = await _http.post(
      _uri('/v1/social/friends/invite/accept'),
      headers: _headers,
      body: jsonEncode({'referrerId': referrerId}),
    );
    return Friendship.fromJson(await _decode(r));
  }

  Future<List<FeedEntry>> feed() async {
    final r = await _http.get(_uri('/v1/social/feed'), headers: _headers);
    final body = await _decode(r);
    final list = (body['entries'] as List? ?? const []).cast<dynamic>();
    return list
        .map((e) => FeedEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordActivity({
    required String code,
    required String title,
    required String description,
    String deckName = '',
  }) async {
    final r = await _http.post(
      _uri('/v1/social/activities'),
      headers: _headers,
      body: jsonEncode({
        'code': code,
        'title': title,
        'description': description,
        'deckName': deckName,
      }),
    );
    await _decode(r);
  }

  /// Reacciona con un emoji a una entrada del feed de amigos.
  Future<void> reactToFeedEntry({
    required String entryId,
    required String emoji,
  }) async {
    final r = await _http.post(
      _uri('/v1/social/feed/reactions'),
      headers: _headers,
      body: jsonEncode({'entryId': entryId, 'emoji': emoji}),
    );
    await _decode(r);
  }

  Future<void> recordAchievement({
    required String code,
    required String title,
    required String description,
    String deckName = '',
    String emoji = '',
  }) async {
    final r = await _http.post(
      _uri('/v1/social/achievements'),
      headers: _headers,
      body: jsonEncode({
        'code': code,
        'title': title,
        'description': description,
        'deckName': deckName,
        'emoji': emoji,
      }),
    );
    await _decode(r);
  }

  // ─── Sharing ────────────────────────────────────────────────────────────

  /// Comparte un mazo. `payloadJson` es el dump serializado del mazo
  /// (cards, retention, etc.) para que el receptor pueda reconstruirlo.
  Future<Map<String, dynamic>> shareDeck({
    required String deckId,
    required String title,
    required String summary,
    required String payloadJson,
    String? targetUserId,
    bool isPublic = false,
  }) async {
    final r = await _http.post(
      _uri('/v1/social/shares'),
      headers: _headers,
      body: jsonEncode({
        'kind': 'deck',
        'deckId': deckId,
        'title': title,
        'summary': summary,
        'payloadJson': payloadJson,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'targetUserId': targetUserId,
        'isPublic': isPublic,
      }),
    );
    return _decode(r);
  }

  Future<List<Map<String, dynamic>>> searchCommunityDecks(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final r = await _http.get(
      _uri('/v1/community/decks?q=$encoded'),
      headers: _headers,
    );
    final body = await _decode(r);
    final list = (body['decks'] as List? ?? const []).cast<dynamic>();
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listShares() async {
    final r = await _http.get(_uri('/v1/social/shares'), headers: _headers);
    final body = await _decode(r);
    final list = (body['shares'] as List? ?? const []).cast<dynamic>();
    return list.cast<Map<String, dynamic>>();
  }

  /// Registra el token de push del dispositivo (FCM/APNs) en el backend.
  Future<void> registerPushToken({
    required String token,
    required String platform,
  }) async {
    final r = await _http.post(
      _uri('/v1/push/register-token'),
      headers: _headers,
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (r.statusCode >= 400) {
      throw Exception('No se pudo registrar el token push (${r.statusCode}).');
    }
  }

  /// Activa el trial premium del usuario en el backend.
  Future<Map<String, dynamic>> activatePremiumTrial() async {
    final r = await _http.post(_uri('/v1/premium/trial'), headers: _headers);
    return _decode(r);
  }

  /// Estado premium vigente del usuario (persistido server-side).
  Future<Map<String, dynamic>> getPremiumStatus() async {
    final r = await _http.get(_uri('/v1/premium/status'), headers: _headers);
    return _decode(r);
  }

  /// Envía un batch de eventos de producto al backend de analytics propio.
  /// Funciona también sin sesión (eventos de invitado).
  Future<void> sendAnalyticsEvents(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return;
    final r = await _http.post(
      _uri('/v1/analytics/events'),
      headers: _headers,
      body: jsonEncode({'events': events}),
    );
    if (r.statusCode >= 400) {
      throw Exception('No se pudo enviar analytics (${r.statusCode}).');
    }
  }

  /// Portada de Comunidad: destacados, populares, creadores y categorías
  /// reales del catálogo público.
  Future<Map<String, dynamic>> getCommunityOverview() async {
    final r = await _http.get(_uri('/v1/community/overview'), headers: _headers);
    return _decode(r);
  }

  /// Mis decks publicados a la comunidad, con stats (importCount).
  Future<List<Map<String, dynamic>>> listMyCommunityDecks() async {
    final r = await _http.get(_uri('/v1/community/mine'), headers: _headers);
    final body = await _decode(r);
    final list = (body['decks'] as List? ?? const []).cast<dynamic>();
    return list.cast<Map<String, dynamic>>();
  }

  /// Archiva una denuncia de mazo en la cola de moderación del backend.
  Future<Map<String, dynamic>> fileDeckReport({
    required String deckId,
    required String deckTitle,
    required String reason,
    String note = '',
  }) async {
    final r = await _http.post(
      _uri('/v1/community/reports'),
      headers: _headers,
      body: jsonEncode({
        'deckId': deckId,
        'deckTitle': deckTitle,
        'reason': reason,
        'note': note,
      }),
    );
    return _decode(r);
  }

  /// Cola de moderación persistida en el backend.
  Future<List<Map<String, dynamic>>> listDeckReports() async {
    final r = await _http.get(_uri('/v1/community/reports'), headers: _headers);
    final body = await _decode(r);
    final list = (body['reports'] as List? ?? const []).cast<dynamic>();
    return list.cast<Map<String, dynamic>>();
  }

  /// Cierra un reporte con su resolución: kept | hidden | removed.
  Future<Map<String, dynamic>> resolveDeckReport({
    required String reportId,
    required String resolution,
  }) async {
    final r = await _http.post(
      _uri('/v1/community/reports/resolve'),
      headers: _headers,
      body: jsonEncode({'reportId': reportId, 'resolution': resolution}),
    );
    return _decode(r);
  }

  /// Registra que este usuario importó un deck comunitario (stats del autor).
  Future<void> registerCommunityImport(String shareId) async {
    final r = await _http.post(
      _uri('/v1/community/imports'),
      headers: _headers,
      body: jsonEncode({'shareId': shareId}),
    );
    if (r.statusCode >= 400) {
      throw Exception('No se pudo registrar la importación (${r.statusCode}).');
    }
  }

  // ─── Sync de progreso ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProgressSnapshot() async {
    final r = await _http.get(_uri('/v1/sync/progress'), headers: _headers);
    final body = await _decode(r);
    final snap = body['snapshot'];
    if (snap == null) return null;
    return snap as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveProgressSnapshot({
    required String deviceId,
    required String payloadJson,
  }) async {
    final r = await _http.post(
      _uri('/v1/sync/progress'),
      headers: _headers,
      body: jsonEncode({
        'deviceId': deviceId,
        'payloadJson': payloadJson,
      }),
    );
    return _decode(r);
  }

  // ─── Cooperativo ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createCoopRoom({
    bool isPublic = true,
    String deckId = '',
    String deckName = '',
    String? hostId,
  }) async {
    final r = await _http.post(
      _uri('/v1/coop/rooms'),
      headers: _headers,
      body: jsonEncode({
        'isPublic': isPublic,
        'deckId': deckId,
        'deckName': deckName,
        if (hostId != null) 'hostId': hostId,
      }),
    );
    return _decode(r);
  }

  Future<Map<String, dynamic>> listPublicRoomsPaged({
    int? difficulty,
    String? mode,
    String? query,
    bool? hideFull,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (difficulty != null && difficulty > 0) 'difficulty': difficulty.toString(),
      if (mode != null && mode.isNotEmpty) 'mode': mode,
      if (query != null && query.isNotEmpty) 'query': query,
      if (hideFull != null) 'hideFull': hideFull.toString(),
    };
    final baseUri = _uri('/v1/coop/rooms/public');
    final uri = baseUri.replace(queryParameters: queryParams);
    final r = await _http.get(uri, headers: _headers);
    return await _decode(r);
  }

  Future<List<dynamic>> listPublicRooms() async {
    try {
      final decoded = await listPublicRoomsPaged(page: 1, limit: 100);
      final list = decoded['rooms'];
      if (list is List) return list;
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> lookupCoopRoom(String code) async {
    final r = await _http.get(
      _uri('/v1/coop/rooms/lookup?code=${Uri.encodeQueryComponent(code)}'),
      headers: _headers,
    );
    if (r.statusCode == 404) return null;
    return _decode(r);
  }

  /// URL del websocket del cooperativo. La construimos sustituyendo
  /// `http://` por `ws://` en `baseUrl` para mantener un único punto de
  /// configuración.
  Uri coopWsUri({required String code, required String userId, String name = ''}) {
    final base = Uri.parse(baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: scheme,
      path: '/v1/coop/ws',
      queryParameters: {
        'code': code,
        'user': userId,
        'name': name,
      },
    );
  }

  Future<void> sendCoopInvite({
    required String friendUserId,
    required String roomCode,
    required String hostName,
  }) async {
    final r = await _http.post(
      _uri('/v1/coop/invite'),
      headers: _headers,
      body: jsonEncode({
        'friendUserId': friendUserId,
        'roomCode': roomCode,
        'hostName': hostName,
      }),
    );
    await _decode(r);
  }

  Future<List<dynamic>> getPendingCoopInvites() async {
    final r = await _http.get(
      _uri('/v1/coop/invites/pending'),
      headers: _headers,
    );
    final decoded = await _decode(r);
    final list = decoded['data'];
    if (list is List) return list;
    return [];
  }

  void close() => _http.close();
}
