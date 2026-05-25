import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones push.
///
/// **Estado actual**: integración solo de plumbing — el plugin se inicializa
/// y muestra notificaciones locales. Para PUSH remotas (FCM) hay que:
///
/// 1. Crear proyecto en https://console.firebase.google.com.
/// 2. Bajar `GoogleService-Info.plist` y meterlo en `ios/Runner/`.
/// 3. Bajar `google-services.json` y meterlo en `android/app/`.
/// 4. Habilitar APNs en Apple Developer (key + bundle id) y subir la key
///    al proyecto Firebase.
/// 5. Llamar `Firebase.initializeApp()` en main.dart antes de runApp.
/// 6. Inyectar `FirebaseMessaging.instance` aquí y registrar `getToken()`.
///
/// Mientras esos pasos no estén, la app funciona sin push remoto pero las
/// notificaciones locales (recordatorios diarios) ya quedan operativas
/// sin config nativa.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(
        iOS: ios,
        android: android,
        macOS: ios,
      ),
    );
    _initialized = true;
  }

  /// Pide permisos al usuario (solo iOS los pide explícitamente; Android
  /// usa el toggle de la app en settings).
  Future<bool> requestPermissions() async {
    final iosImpl = _local.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? true;
  }

  /// Programa un recordatorio diario simple. En esta sesión no estamos
  /// agendando notificaciones programadas — solo deja preparado el flujo
  /// de show inmediato. Para schedule real hay que sumar
  /// `flutter_local_notifications` con timezone + zoned schedule.
  Future<void> showLocalNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    const ios = DarwinNotificationDetails();
    const android = AndroidNotificationDetails(
      'memorizar_reminders',
      'Recordatorios',
      channelDescription:
          'Recordatorios para mantener tu racha de memorización.',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      id,
      title,
      body,
      const NotificationDetails(
        iOS: ios,
        android: android,
        macOS: ios,
      ),
    );
  }

  /// TODO: cuando Firebase esté configurado, reemplazar por:
  ///   final token = await FirebaseMessaging.instance.getToken();
  ///   POST /v1/push/register-token  { token, deviceId, platform }
  Future<String?> getDeviceToken() async {
    if (kDebugMode) {
      debugPrint('[PushService] Firebase no configurado todavía — '
          'devolvemos null. Ver docs en push_service.dart.');
    }
    return null;
  }
}
