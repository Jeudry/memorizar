import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../api/memorizar_client.dart';

/// Servicio de notificaciones push (locales + remotas vía FCM).
///
/// Las notificaciones **locales** (recordatorios diarios) funcionan siempre,
/// sin config nativa. Las **remotas (FCM)** se activan automáticamente en
/// cuanto el proyecto Firebase del usuario esté configurado: el código real ya
/// está aquí ([getDeviceToken] llama a `FirebaseMessaging.getToken()` y
/// [registerWithBackend] lo persiste vía `POST /v1/push/register-token`).
///
/// Único paso que falta — y que solo puede hacer el dueño del proyecto porque
/// embebe sus credenciales:
///
/// 1. `flutterfire configure` (genera `firebase_options.dart`,
///    `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`).
/// 2. Habilitar APNs en Apple Developer y subir la key a Firebase (iOS).
/// 3. En el backend, setear `MEMORIZAR_FCM_CREDENTIALS_FILE` al service account.
///
/// Sin esos archivos, `Firebase.initializeApp()` falla de forma controlada y
/// la app sigue corriendo solo con notificaciones locales (getToken → null).
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timezoneReady = false;
  bool _firebaseChecked = false;
  bool _firebaseReady = false;

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
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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

  /// Inicializa Firebase una sola vez, de forma tolerante a fallos: si el
  /// proyecto no está configurado (sin `google-services.json` /
  /// `GoogleService-Info.plist`), `initializeApp` lanza y devolvemos false sin
  /// romper la app. Web queda fuera (FCM web requiere vapidKey aparte).
  Future<bool> _ensureFirebase() async {
    if (_firebaseChecked) return _firebaseReady;
    _firebaseChecked = true;
    if (kIsWeb) return false;
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      _firebaseReady = false;
      debugPrint('[PushService] Firebase no configurado ($e) — '
          'push remoto inactivo; corre `flutterfire configure`.');
    }
    return _firebaseReady;
  }

  /// Devuelve el token FCM real del dispositivo, o null si Firebase no está
  /// configurado / falla. Pide permiso de notificaciones en el proceso.
  Future<String?> getDeviceToken() async {
    if (!await _ensureFirebase()) return null;
    try {
      await FirebaseMessaging.instance.requestPermission();
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[PushService] No se pudo obtener el token FCM: $e');
      return null;
    }
  }

  /// Obtiene el token del dispositivo y lo registra en el backend para que las
  /// notificaciones (likes, follows, etc.) lleguen como push. No-op silencioso
  /// si no hay token (Firebase sin configurar) o si falla el registro. Llamar
  /// tras tener sesión iniciada.
  Future<void> registerWithBackend(MemorizarClient api) async {
    final token = await getDeviceToken();
    if (token == null || token.isEmpty) return;
    try {
      await api.registerPushToken(token: token, platform: _platformLabel());
      debugPrint('[PushService] Token FCM registrado en el backend.');
    } catch (e) {
      debugPrint('[PushService] No se pudo registrar el token push: $e');
    }
  }

  String _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return 'other';
    }
  }
}
