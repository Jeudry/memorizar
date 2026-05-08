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

  const CoopRoomState({
    required this.code,
    required this.hostId,
    required this.memberIds,
  });

  CoopRoomState copyWith({Set<String>? memberIds}) => CoopRoomState(
        code: code,
        hostId: hostId,
        memberIds: memberIds ?? this.memberIds,
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

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  CoopRoomState? _state;
  final _stateCtrl = StreamController<CoopRoomState>.broadcast();
  final _messagesCtrl = StreamController<CoopMessage>.broadcast();

  CoopRoomState? get state => _state;
  Stream<CoopRoomState> get stateStream => _stateCtrl.stream;
  Stream<CoopMessage> get messages => _messagesCtrl.stream;

  Future<CoopRoomState> createRoom({required String userId, required String name}) async {
    final res = await client.createCoopRoom();
    final code = (res['code'] as String?) ?? '';
    final hostId = (res['hostId'] as String?) ?? userId;
    await connect(code: code, userId: userId, name: name, hostId: hostId);
    return _state!;
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
    await connect(code: code, userId: userId, name: name, hostId: hostId);
  }

  Future<void> connect({
    required String code,
    required String userId,
    required String name,
    required String hostId,
  }) async {
    await disconnect();
    final uri = client.coopWsUri(code: code, userId: userId, name: name);
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _state = CoopRoomState(code: code, hostId: hostId, memberIds: {userId});
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
    }
    _messagesCtrl.add(msg);
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
