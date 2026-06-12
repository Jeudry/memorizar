import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/memorizar_client.dart';
import 'analytics_service.dart';

/// Provider de analytics que persiste los eventos en el backend propio
/// (`/v1/analytics/events`). Bufferea en memoria y hace flush por lote para
/// no meter una request por cada tap; los errores de red descartan el lote
/// sin afectar la UX.
class BackendAnalyticsProvider implements AnalyticsProvider {
  static const int _flushThreshold = 20;
  static const Duration _flushInterval = Duration(seconds: 15);
  static const int _maxBuffer = 200;

  final MemorizarClient api;
  final List<Map<String, dynamic>> _buffer = [];
  Timer? _timer;
  bool _flushing = false;

  BackendAnalyticsProvider({required this.api}) {
    _timer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  @override
  void identify(String userId, Map<String, dynamic> traits) {
    _enqueue('identify', {'userId': userId, ...traits});
  }

  @override
  void track(String event, Map<String, dynamic> props) {
    _enqueue(event, props);
  }

  @override
  void reset() {
    _buffer.clear();
  }

  void _enqueue(String event, Map<String, dynamic> props) {
    if (_buffer.length >= _maxBuffer) {
      _buffer.removeAt(0);
    }
    _buffer.add({'event': event, if (props.isNotEmpty) 'props': props});
    if (_buffer.length >= _flushThreshold) {
      _flush();
    }
  }

  Future<void> _flush() async {
    if (_flushing || _buffer.isEmpty) return;
    _flushing = true;
    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    try {
      await api.sendAnalyticsEvents(batch);
    } catch (e) {
      debugPrint('[analytics] flush falló (${batch.length} eventos): $e');
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _flush();
  }
}
