import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/api/memorizar_client.dart';

/// Snapshot mínimo de una sala cooperativa. Se rellena por mensajes que
/// vienen del websocket.
class CoopRoomState {
  final String code;
  final String hostId;
  final Set<String> memberIds;
  /// Tarjeta actualmente sincronizada por el host. `null` antes de empezar.
  final String? currentDeckId;
  final int currentCardIndex;
  final String? currentSlug;
  /// Puntaje acumulado por miembro (userId → score).
  final Map<String, int> scores;
  /// Mazo configurado en el lobby.
  final String? lobbyDeckId;
  final String? lobbyDeckName;
  final String mode; // "turnos", "libre"
  final bool isPublic;
  final int sessionDifficulty;
  final int sessionDailyTarget;
  final int sessionMaxPlayers;

  const CoopRoomState({
    required this.code,
    required this.hostId,
    required this.memberIds,
    this.currentDeckId,
    this.currentCardIndex = 0,
    this.currentSlug,
    this.scores = const {},
    this.lobbyDeckId,
    this.lobbyDeckName,
    this.mode = 'turnos',
    this.isPublic = true,
    this.sessionDifficulty = 1,
    this.sessionDailyTarget = 0,
    this.sessionMaxPlayers = 4,
  });

  CoopRoomState copyWith({
    Set<String>? memberIds,
    Map<String, int>? scores,
    String? lobbyDeckId,
    String? lobbyDeckName,
    String? mode,
    bool? isPublic,
    int? sessionDifficulty,
    int? sessionDailyTarget,
    int? sessionMaxPlayers,
    String? currentSlug,
  }) =>
      CoopRoomState(
        code: code,
        hostId: hostId,
        memberIds: memberIds ?? this.memberIds,
        currentDeckId: currentDeckId,
        currentCardIndex: currentCardIndex,
        currentSlug: currentSlug ?? this.currentSlug,
        scores: scores ?? this.scores,
        lobbyDeckId: lobbyDeckId ?? this.lobbyDeckId,
        lobbyDeckName: lobbyDeckName ?? this.lobbyDeckName,
        mode: mode ?? this.mode,
        isPublic: isPublic ?? this.isPublic,
        sessionDifficulty: sessionDifficulty ?? this.sessionDifficulty,
        sessionDailyTarget: sessionDailyTarget ?? this.sessionDailyTarget,
        sessionMaxPlayers: sessionMaxPlayers ?? this.sessionMaxPlayers,
      );

  CoopRoomState copyWithCard({required String deckId, required int cardIndex, String? slug}) =>
      CoopRoomState(
        code: code,
        hostId: hostId,
        memberIds: memberIds,
        currentDeckId: deckId,
        currentCardIndex: cardIndex,
        currentSlug: slug ?? this.currentSlug,
        scores: scores,
        lobbyDeckId: lobbyDeckId,
        lobbyDeckName: lobbyDeckName,
        mode: mode,
        isPublic: isPublic,
        sessionDifficulty: sessionDifficulty,
        sessionDailyTarget: sessionDailyTarget,
        sessionMaxPlayers: sessionMaxPlayers,
      );
}

class CoopMessage {
  final String type;
  final String userId;
  final Map<String, dynamic>? payload;

  const CoopMessage({
    required this.type,
    required this.userId,
    this.payload,
  });

  factory CoopMessage.fromJson(Map<String, dynamic> json) => CoopMessage(
        type: (json['type'] as String?) ?? '',
        userId: (json['userId'] as String?) ?? '',
        payload: json['payload'] is Map<String, dynamic>
            ? json['payload'] as Map<String, dynamic>
            : null,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'userId': userId,
        if (payload != null) 'payload': payload,
      };
}

/// Cliente reactivo del cooperativo. Llama a `connect` con el código de
/// sala; expone `state` (sala actual) y `messages` (stream de eventos).
class CoopService {
  final MemorizarClient client;
  CoopService({required this.client});

  /// Sesión activa compartida entre el lobby y la pantalla de juego. La
  /// lobby la asigna después de connect/createRoom; el juego la lee. Se
  /// limpia en disconnect/dispose. Acceso global a propósito — el route
  /// nombrado `cooperativoJuego` no recibe argumentos.
  static CoopService? active;

  /// userId del usuario local (host o invitado). Se setea junto con `active`
  /// para que la pantalla de juego sepa cuál fila del scoreboard es "yo".
  static String? activeUserId;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  CoopRoomState? _state;
  final _stateCtrl = StreamController<CoopRoomState>.broadcast();
  final _messagesCtrl = StreamController<CoopMessage>.broadcast();

  CoopRoomState? get state => _state;
  Stream<CoopRoomState> get stateStream => _stateCtrl.stream;
  Stream<CoopMessage> get messages => _messagesCtrl.stream;

  Future<CoopRoomState> createRoom({
    required String userId,
    required String name,
    bool isPublic = true,
    String deckId = '',
    String deckName = '',
  }) async {
    final res = await client.createCoopRoom(
      isPublic: isPublic,
      deckId: deckId,
      deckName: deckName,
    );
    final code = (res['code'] as String?) ?? '';
    final hostId = (res['hostId'] as String?) ?? userId;
    await connect(
      code: code,
      userId: userId,
      name: name,
      hostId: hostId,
      lobbyDeckId: deckId,
      lobbyDeckName: deckName,
      mode: 'turnos',
      isPublic: isPublic,
    );
    return _state!;
  }

  Future<List<dynamic>> listPublicRooms() async {
    return await client.listPublicRooms();
  }

  Future<void> joinRoom({
    required String code,
    required String userId,
    required String name,
  }) async {
    final res = await client.lookupCoopRoom(code);
    if (res == null) {
      throw Exception('Sala no encontrada');
    }
    final hostId = (res['hostId'] as String?) ?? '';
    final deckId = (res['deckId'] as String?) ?? '';
    final deckName = (res['deckName'] as String?) ?? '';
    final mode = (res['mode'] as String?) ?? 'turnos';
    final isPublic = (res['isPublic'] as bool?) ?? true;
    await connect(
      code: code,
      userId: userId,
      name: name,
      hostId: hostId,
      lobbyDeckId: deckId,
      lobbyDeckName: deckName,
      mode: mode,
      isPublic: isPublic,
    );
  }

  Future<void> connect({
    required String code,
    required String userId,
    required String name,
    required String hostId,
    String? lobbyDeckId,
    String? lobbyDeckName,
    String mode = 'turnos',
    bool isPublic = true,
  }) async {
    await disconnect();
    final uri = client.coopWsUri(code: code, userId: userId, name: name);
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _state = CoopRoomState(
      code: code,
      hostId: hostId,
      memberIds: {userId},
      lobbyDeckId: lobbyDeckId,
      lobbyDeckName: lobbyDeckName,
      mode: mode,
      isPublic: isPublic,
    );
    _stateCtrl.add(_state!);

    _sub = channel.stream.listen(
      (raw) {
        try {
          final json = jsonDecode(raw as String) as Map<String, dynamic>;
          final msg = CoopMessage.fromJson(json);
          _handleMessage(msg);
        } catch (e) {
          if (kDebugMode) debugPrint('[coop] bad message: $e');
        }
      },
      onDone: () => _state = null,
      onError: (_) => _state = null,
    );
  }

  void _handleMessage(CoopMessage msg) {
    final state = _state;
    if (state == null) return;
    switch (msg.type) {
      case 'join':
        _state = state.copyWith(memberIds: {...state.memberIds, msg.userId});
        _stateCtrl.add(_state!);
        break;
      case 'leave':
        _state = state.copyWith(
          memberIds: {...state.memberIds}..remove(msg.userId),
        );
        _stateCtrl.add(_state!);
        break;
      case 'deck':
        final deckId = (msg.payload?['deckId'] as String?) ?? '';
        final deckName = (msg.payload?['deckName'] as String?) ?? '';
        _state = state.copyWith(lobbyDeckId: deckId, lobbyDeckName: deckName);
        _stateCtrl.add(_state!);
        break;
      case 'mode':
        final mode = (msg.payload?['mode'] as String?) ?? 'turnos';
        _state = state.copyWith(mode: mode);
        _stateCtrl.add(_state!);
        break;
      case 'visibility':
        final isPublic = (msg.payload?['isPublic'] as bool?) ?? true;
        _state = state.copyWith(isPublic: isPublic);
        _stateCtrl.add(_state!);
        break;
      case 'card':
        // Host avanzó a una tarjeta nueva. Payload: {cardIndex, deckId, slug}.
        final idx = (msg.payload?['cardIndex'] as int?) ?? 0;
        final deckId = (msg.payload?['deckId'] as String?) ?? '';
        final slug = (msg.payload?['slug'] as String?) ?? '';
        _state = state.copyWithCard(deckId: deckId, cardIndex: idx, slug: slug);
        _stateCtrl.add(_state!);
        break;
      case 'score':
        // Un miembro obtuvo puntos. Payload: {points}.
        final pts = (msg.payload?['points'] as int?) ?? 0;
        final newScores = {...state.scores};
        newScores[msg.userId] = (newScores[msg.userId] ?? 0) + pts;
        _state = state.copyWith(scores: newScores);
        _stateCtrl.add(_state!);
        break;
      case 'session_config':
        final diff = (msg.payload?['difficulty'] as int?) ?? 1;
        final target = (msg.payload?['dailyTarget'] as int?) ?? 0;
        final maxP = (msg.payload?['maxPlayers'] as int?) ?? 4;
        _state = state.copyWith(sessionDifficulty: diff, sessionDailyTarget: target, sessionMaxPlayers: maxP);
        _stateCtrl.add(_state!);
        break;
    }
    _messagesCtrl.add(msg);
  }

  /// Sincroniza la configuración de sesión elegida por el Host
  void broadcastSessionConfig({required int difficulty, required int dailyTarget, required int maxPlayers}) {
    send(CoopMessage(
      type: 'session_config',
      userId: '',
      payload: {'difficulty': difficulty, 'dailyTarget': dailyTarget, 'maxPlayers': maxPlayers},
    ));
  }

  void broadcastCountdown() {
    send(CoopMessage(
      type: 'countdown',
      userId: '',
    ));
  }

  /// Conveniencia para que el host empuje "estamos en la tarjeta N del
  /// deck D" a todos los miembros.
  void broadcastCard({required String deckId, required int cardIndex, String? slug}) {
    send(CoopMessage(
      type: 'card',
      userId: '',
      payload: {
        'deckId': deckId,
        'cardIndex': cardIndex,
        if (slug != null) 'slug': slug,
      },
    ));
  }

  void broadcastLobbyDeck({required String deckId, required String deckName}) {
    send(CoopMessage(
      type: 'deck',
      userId: '',
      payload: {'deckId': deckId, 'deckName': deckName},
    ));
  }

  void broadcastMode(String mode) {
    send(CoopMessage(
      type: 'mode',
      userId: '',
      payload: {'mode': mode},
    ));
  }

  void broadcastVisibility(bool isPublic) {
    send(CoopMessage(
      type: 'visibility',
      userId: '',
      payload: {'isPublic': isPublic},
    ));
  }

  /// Conveniencia para reportar score (el server reenvía a todos).
  void reportScore(int points) {
    send(CoopMessage(
      type: 'score',
      userId: '',
      payload: {'points': points},
    ));
  }

  void send(CoopMessage msg) {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(jsonEncode(msg.toJson()));
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _state = null;
    _sub = null;
  }

  void dispose() {
    disconnect();
    _stateCtrl.close();
    _messagesCtrl.close();
  }
}
