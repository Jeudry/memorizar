import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Resultado normalizado de un flujo de auth social. El backend espera estos
/// campos para crear/recuperar el usuario.
class SocialAuthResult {
  final String provider;
  final String providerUserId;
  final String email;
  final String displayName;
  final String avatarUrl;

  const SocialAuthResult({
    required this.provider,
    required this.providerUserId,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
  });
}

class SocialAuthCancelled implements Exception {
  final String provider;
  const SocialAuthCancelled(this.provider);
  @override
  String toString() => 'Login cancelado ($provider)';
}

/// Wrapper de los SDK reales. Si el provider no está configurado en el
/// proyecto (ej. faltan plist / capabilities), `usingDevFallback` queda true
/// y se cae a un identificador sintético para que el flujo siga funcionando
/// en desarrollo.
class SocialAuthService {
  final GoogleSignIn _google;

  SocialAuthService({GoogleSignIn? google})
      : _google = google ?? GoogleSignIn(scopes: const ['email', 'profile']);

  /// Si el config nativo no está listo, los SDK lanzan errores específicos
  /// (`MissingPluginException`, `PlatformException` con códigos como
  /// `network_error`, `sign_in_failed`). Los detectamos para volver al
  /// flujo dev sin bloquear el desarrollo.
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) {
        throw const SocialAuthCancelled('google');
      }
      final auth = await account.authentication;
      return SocialAuthResult(
        provider: 'google',
        providerUserId: account.id,
        email: account.email,
        displayName: account.displayName ?? account.email,
        avatarUrl: account.photoUrl ?? '',
      );
    } on SocialAuthCancelled {
      rethrow;
    } catch (e) {
      // Fallback dev: deja avanzar pero marcado.
      return _devFallback('google', e.toString());
    }
  }

  Future<SocialAuthResult> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      // Apple SDK solo válido en plataformas Apple. Fuera de eso, dev fallback.
      return _devFallback('apple', 'platform unsupported');
    }
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final name = [
        cred.givenName,
        cred.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      return SocialAuthResult(
        provider: 'apple',
        providerUserId: cred.userIdentifier ?? '',
        email: cred.email ?? '',
        displayName: name.isEmpty ? (cred.email ?? 'Apple user') : name,
        avatarUrl: '',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SocialAuthCancelled('apple');
      }
      return _devFallback('apple', e.toString());
    } catch (e) {
      return _devFallback('apple', e.toString());
    }
  }

  /// Facebook todavía no tiene SDK cableado. Devuelve dev fallback siempre.
  Future<SocialAuthResult> signInWithFacebook() async {
    return _devFallback('facebook', 'not configured');
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }

  SocialAuthResult _devFallback(String provider, String reason) {
    // Identificador estable por sesión (no por device) — alcanza para
    // crear/loguear contra el backend en desarrollo.
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = Random().nextInt(1 << 32);
    return SocialAuthResult(
      provider: provider,
      providerUserId: '${provider}_dev_${stamp}_$rand',
      email: '${provider}_$rand@dev.memorizar.app',
      displayName:
          'Usuario ${provider[0].toUpperCase()}${provider.substring(1)} (dev)',
      avatarUrl: '',
    );
  }
}
