# Despliegue — Memorizar

Memorizar tiene dos piezas que se despliegan distinto:

- **Backend (Go)** → contenedor Docker (este doc). Un binario estático
  distroless (~13 MB) con SQLite persistido en un volumen.
- **Frontend (Flutter)** → builds nativos por plataforma (DMG/macOS, APK/AAB
  Android, web). No se containeriza; se distribuye como app y apunta al
  backend vía `--dart-define=API_BASE=...`.

---

## 1. Backend con Docker Compose

```bash
cp .env.example .env          # ajusta las variables
docker compose up -d --build  # build + run en background
curl http://localhost:8080/healthz   # → 200
```

- Imagen: distroless estática (CGO off, `modernc.org/sqlite`).
- Datos: volumen `memorizar-data` montado en `/data` — sobrevive a `docker
  compose down` (NO usar `-v`, borraría la DB).
- Healthcheck: el propio binario con `-healthcheck` (sin curl en la imagen).

Variables de entorno: ver [`.env.example`](.env.example). Las relevantes:

| Variable | Default | Para qué |
|---|---|---|
| `MEMORIZAR_API_ADDR` | `:8080` | puerto de escucha |
| `MEMORIZAR_STORE` | `sqlite` | `sqlite` o `file` |
| `MEMORIZAR_SQLITE_PATH` | `/data/memorizar.db` | ruta de la DB |
| `MEMORIZAR_MODERATOR_EMAILS` | (vacío) | correos que pueden moderar |
| `MEMORIZAR_FCM_CREDENTIALS_FILE` | (vacío) | push real (ver §4) |

---

## 2. TLS / HTTPS (producción)

El API sirve **HTTP plano** — no termina TLS por sí mismo. En producción ponlo
detrás de un reverse proxy que termine HTTPS:

- **Caddy** (lo más simple, certs automáticos):
  ```
  api.tudominio.com {
      reverse_proxy localhost:8080
  }
  ```
- O nginx/Traefik, o el TLS gestionado de la plataforma (Fly.io, Railway,
  Render terminan TLS por ti).

El frontend debe apuntar a la URL **https** del proxy, no al :8080 directo.

---

## 3. Apuntar el frontend al backend desplegado

El cliente usa `API_BASE` (default `http://localhost:8080`). En cada build:

```bash
# Web
flutter build web --dart-define=API_BASE=https://api.tudominio.com
# Android
flutter build apk  --release --dart-define=API_BASE=https://api.tudominio.com
# macOS
flutter build macos --release --dart-define=API_BASE=https://api.tudominio.com
```

Nota: CORS en el backend está abierto (`Access-Control-Allow-Origin: *`),
suficiente para un API público. Si quieres restringir a tu dominio, edítalo en
`backend/internal/httpapi/json.go` (`withCORS`).

---

## 4. Activar push real (FCM) — opcional

El push remoto está implementado pero dormido hasta que aportes las
credenciales de tu proyecto Firebase:

1. `cd frontend && flutterfire configure` → genera `firebase_options.dart`,
   `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`.
2. iOS: habilita APNs en Apple Developer y sube la key a Firebase.
3. Backend: descarga el service account JSON de Firebase, móntalo en el
   contenedor (p.ej. `/secrets/firebase-sa.json`) y setea
   `MEMORIZAR_FCM_CREDENTIALS_FILE` a esa ruta. El log dirá
   `push: FcmNotifier habilitado`. Sin eso, usa `LogNotifier` (sin push) y
   arranca igual.

---

## 5. Opciones de hosting

Cualquier plataforma que corra un contenedor sirve. El binario es estático y
chico, sin dependencias de sistema:

- **Fly.io / Railway / Render**: apuntan al `backend/Dockerfile`, exponen 8080,
  TLS gestionado. Monta un volumen persistente en `/data`.
- **VPS** (cualquiera con Docker): `docker compose up -d` + Caddy delante.

Backup: el estado vive en un solo archivo (`/data/memorizar.db`). Copia el
volumen para respaldar.
