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

  void close() => _http.close();
}
