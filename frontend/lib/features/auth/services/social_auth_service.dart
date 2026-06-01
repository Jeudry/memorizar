import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Resultado normalizado de un flujo de auth social. El backend espera estos
/// campos para crear/recuperar el usuario y validar su sesión.
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

/// Servicio de Autenticación Social real e integrado con los SDK oficiales.
/// Soporta de forma directa Web (Chrome), macOS Desktop y Android/iOS.
class SocialAuthService {
  static const _webClientId =
      '106168748090-3krdd1sakko189j93aimecj5s61i9cr2.apps.googleusercontent.com';

  final GoogleSignIn _google;

  SocialAuthService({GoogleSignIn? google})
      : _google = google ?? _createGoogleSignIn();

  static GoogleSignIn _createGoogleSignIn() {
    String? clientId;
    if (kIsWeb) {
      clientId = _webClientId;
    } else if (Platform.isMacOS) {
      clientId = '106168748090-7a0q71bdnaq64g7q79o9eipr34dv8phs.apps.googleusercontent.com';
    } else if (Platform.isAndroid) {
      clientId = '106168748090-nth3427k9lc496nrnk94i6bhn28l65qv.apps.googleusercontent.com';
    }
    
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: _webClientId,
      clientId: clientId,
    );
  }

  /// Ejecuta el flujo real de autenticación con Google.
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) {
        throw const SocialAuthCancelled('google');
      }
      await account.authentication;
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
      // Propaga el error real de Firebase/Google Sign-In para depuración
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  /// Ejecuta el flujo real de autenticación con Apple.
  Future<SocialAuthResult> signInWithApple() async {
    if (kIsWeb) {
      throw UnsupportedError('Apple Sign In no está soportado en la plataforma Web.');
    }
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple Sign In solo está disponible en dispositivos iOS y macOS.');
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
      throw Exception('Error de autorización con Apple: ${e.message}');
    } catch (e) {
      throw Exception('Error al iniciar sesión con Apple: $e');
    }
  }

  /// Facebook Sign In real utilizando el SDK oficial flutter_facebook_auth.
  Future<SocialAuthResult> signInWithFacebook() async {
    try {
      if (kIsWeb || (!kIsWeb && Platform.isMacOS)) {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: '1510636987221105',
          cookie: true,
          xfbml: true,
          version: 'v17.0',
        );
      }

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        
        final pictureData = userData['picture'] as Map<String, dynamic>?;
        final pictureDataData = pictureData?['data'] as Map<String, dynamic>?;
        final avatarUrl = pictureDataData?['url'] as String? ?? '';
        final email = userData['email'] as String? ?? '';
        final id = userData['id'] as String? ?? '';
        final name = userData['name'] as String? ?? 'Facebook User';

        if (id.isEmpty) {
          throw Exception('No se pudo obtener el ID del usuario de Facebook.');
        }

        return SocialAuthResult(
          provider: 'facebook',
          providerUserId: id,
          email: email.isEmpty ? '$id@facebook.com' : email,
          displayName: name,
          avatarUrl: avatarUrl,
        );
      } else if (result.status == LoginStatus.cancelled) {
        throw const SocialAuthCancelled('facebook');
      } else {
        throw Exception('Error al iniciar sesión con Facebook: ${result.message}');
      }
    } on SocialAuthCancelled {
      rethrow;
    } catch (e) {
      throw Exception('Error al iniciar sesión con Facebook: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}
