# Social OAuth Setup

La app ya está preparada para login social real, pero todavía necesitas poner tus credenciales reales antes de distribuirla en dispositivos reales.

## Dart defines

Usa estos `--dart-define` al compilar:

- `MEMORIZAR_API_URL`
- `MEMORIZAR_GOOGLE_CLIENT_ID`
- `MEMORIZAR_GOOGLE_SERVER_CLIENT_ID`
- `MEMORIZAR_APPLE_SERVICE_ID`
- `MEMORIZAR_APPLE_REDIRECT_URI`
- `MEMORIZAR_FACEBOOK_APP_ID`
- `MEMORIZAR_FACEBOOK_CLIENT_TOKEN`

Ejemplo:

```bash
flutter run \
  --dart-define=MEMORIZAR_API_URL=https://api.tudominio.com \
  --dart-define=MEMORIZAR_GOOGLE_CLIENT_ID=tu-google-client-id \
  --dart-define=MEMORIZAR_GOOGLE_SERVER_CLIENT_ID=tu-google-server-client-id \
  --dart-define=MEMORIZAR_APPLE_SERVICE_ID=com.memorizar.signin \
  --dart-define=MEMORIZAR_APPLE_REDIRECT_URI=https://tudominio.com/auth/apple/callback \
  --dart-define=MEMORIZAR_FACEBOOK_APP_ID=tu-facebook-app-id \
  --dart-define=MEMORIZAR_FACEBOOK_CLIENT_TOKEN=tu-facebook-client-token
```

## iOS

- Bundle ID recomendado: `com.memorizar.memorizar`
- Activa `Sign In with Apple` en la app de Apple Developer.
- Configura el redirect real de Apple en tu servicio backend o web de callback.
- Añade URL schemes y Facebook setup real si vas a distribuir login por Facebook en iOS.
- Copia [OAuth.template.xcconfig](/Users/sargon/Documents/Coding/Memorizar/frontend/ios/Flutter/OAuth.template.xcconfig) a `frontend/ios/Flutter/OAuth.xcconfig` y rellena:
  - `FACEBOOK_APP_ID`
  - `FACEBOOK_CLIENT_TOKEN`
  - `FACEBOOK_URL_SCHEME`
  - `GOOGLE_REVERSED_CLIENT_ID`
  - `APPLE_SERVICE_ID`
  - `APPLE_REDIRECT_URI`

## Android

- Application ID actual: `com.memorizar.memorizar`
- Registra SHA-1 y SHA-256 del keystore de debug y release en Google/Firebase si usarás Google Sign-In.
- Añade la configuración real de Facebook en `AndroidManifest` o recursos cuando cierres el release.
- Puedes pasar `MEMORIZAR_FACEBOOK_APP_ID` y `MEMORIZAR_FACEBOOK_CLIENT_TOKEN` por `gradle.properties` o variables de entorno para que `build.gradle.kts` los inyecte en release.

## Facebook

- Necesitas App ID y Client Token reales.
- Debes registrar package name y bundle ID.
- Debes configurar deep links / callback URLs según plataforma.

## Estado actual

- Si falta configuración real, la app cae elegantemente al acceso manual.
- Si la configuración está puesta, el flujo nativo intenta usar el proveedor real primero.
