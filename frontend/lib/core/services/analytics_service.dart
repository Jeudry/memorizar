import 'package:flutter/foundation.dart';

/// Servicio de analytics agnóstico de proveedor. Hoy solo loguea a consola
/// en debug. Para producción intercambias `_provider` por una implementación
/// que mande a Mixpanel / Amplitude / Firebase Analytics.
///
/// Diseñado para que la app llame `Analytics.instance.track('event', {...})`
/// desde cualquier lado sin acoplarse al SDK específico.
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  AnalyticsProvider _provider = const _DebugProvider();

  /// Inyectar un provider real (Mixpanel/Amplitude). Llamar una vez en main.
  void use(AnalyticsProvider provider) => _provider = provider;

  void identify(String userId, {Map<String, dynamic>? traits}) {
    _provider.identify(userId, traits ?? const {});
  }

  void track(String event, [Map<String, dynamic> props = const {}]) {
    _provider.track(event, props);
  }

  void screen(String name) => track('screen_view', {'name': name});

  void reset() => _provider.reset();
}

abstract class AnalyticsProvider {
  void identify(String userId, Map<String, dynamic> traits);
  void track(String event, Map<String, dynamic> props);
  void reset();
}

class _DebugProvider implements AnalyticsProvider {
  const _DebugProvider();
  @override
  void identify(String userId, Map<String, dynamic> traits) {
    if (kDebugMode) debugPrint('[analytics] identify $userId $traits');
  }

  @override
  void track(String event, Map<String, dynamic> props) {
    if (kDebugMode) debugPrint('[analytics] $event $props');
  }

  @override
  void reset() {
    if (kDebugMode) debugPrint('[analytics] reset');
  }
}
