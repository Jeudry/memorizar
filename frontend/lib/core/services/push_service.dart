import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
  bool _timezoneReady = false;

  static const int _dailyReminderId = 7001;

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

  Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;
    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      // Sin nombre IANA detectable (raro): tz.local queda en UTC.
      debugPrint('[PushService] No se pudo detectar la zona horaria: $e');
    }
    _timezoneReady = true;
  }

  static const NotificationDetails _reminderDetails = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails(
      'memorizar_reminders',
      'Recordatorios',
      channelDescription:
          'Recordatorios para mantener tu racha de memorización.',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Programa el recordatorio diario de repaso a la [hour] local. Reemplaza
  /// cualquier programación previa.
  Future<void> scheduleDailyReminder({required int hour}) async {
    await initialize();
    await requestPermissions();
    await _ensureTimezone();

    final now = tz.TZDateTime.now(tz.local);
    var firstFire =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!firstFire.isAfter(now)) {
      firstFire = firstFire.add(const Duration(days: 1));
    }

    await _local.zonedSchedule(
      _dailyReminderId,
      'Hora de repasar 🔥',
      'Tus tarjetas te esperan. Un repaso corto mantiene tu racha viva.',
      firstFire,
      _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[PushService] Recordatorio diario programado a las $hour:00');
  }

  /// Cancela el recordatorio diario.
  Future<void> cancelDailyReminder() async {
    await initialize();
    await _local.cancel(_dailyReminderId);
  }

  /// Muestra una notificación local inmediata.
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

  /// TODO: cuando Firebase esté configurado (requiere proyecto FCM externo),
  /// reemplazar por `FirebaseMessaging.instance.getToken()`. El resto del
  /// pipeline YA existe: `MemorizarClient.registerPushToken` y el endpoint
  /// `POST /v1/push/register-token` persisten el token en el backend.
  Future<String?> getDeviceToken() async {
    if (kDebugMode) {
      debugPrint('[PushService] Firebase no configurado todavía — '
          'devolvemos null. Ver docs en push_service.dart.');
    }
    return null;
  }
}
