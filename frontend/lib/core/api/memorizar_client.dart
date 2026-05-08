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
      final msg = body is Map && body['error'] is String
          ? body['error'] as String
          : 'HTTP ${r.statusCode}';
      throw HttpException(msg, uri: r.request?.url);
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
  }) async {
    final r = await _http.post(
      _uri('/v1/auth/email/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'displayName': displayName,
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
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (locale != null) body['locale'] = locale;
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

  Future<Map<String, dynamic>> createCoopRoom() async {
    final r = await _http.post(_uri('/v1/coop/rooms'), headers: _headers);
    return _decode(r);
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

  void close() => _http.close();
}
