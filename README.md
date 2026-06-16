# Memorizar

Motor de memorización con **repetición espaciada (SRS)** y ejercicios generados por **IA local**. El deck principal es la **Biblia**, pero el sistema es genérico: vocabulario, fórmulas, fechas, citas — cualquier par frente/dorso.

Offline-first, con modo cooperativo en tiempo real y una comunidad para publicar, valorar y comentar mazos.

---

## ✨ Qué hace

### Memorización
- **SRS (SM-2)**: intervalos, `nextReviewAt` y tarjetas vencidas reales.
- **Motor de ejercicios** de 14 pasos por tarjeta: solo lectura, escuchar (TTS), leer en voz (reconocimiento de voz on-device), bloques, "elige la palabra" (N1-3), primera letra, anota, quiz.
- **Creación de mazos**: pega contenido y se auto-segmenta en tarjetas, deck "Biblia" (versículos/capítulos/libros), planes de lectura, **importar CSV/TSV**, **exportar a CSV**.
- **Grupos de mazos** y configuración de sesión (dificultad, rondas, duplicar ejercicios).

### IA local (privada, sin nube)
- Genera preguntas de quiz y distractores con **Gemma 3 4B QAT** corriendo **en el dispositivo**:
  - Móvil (Android/iOS): `flutter_gemma` (MediaPipe).
  - Escritorio: `llama.cpp` (`llama-server`, API compatible con OpenAI).
- Evaluación de respuestas abiertas por el modelo, con fallback determinista.

### Social y comunidad
- **Comunidad**: publicar mazos (con consentimiento de copyright), explorar por categorías, buscar, **valorar con estrellas + reseña**, **comentar**, dar like, seguir creadores, importar a tu colección.
- **Modo cooperativo** en tiempo real (WebSocket): crear/unirse a salas por código, lobby sincronizado, timer por pregunta, chat y reconexión.
- **Centro de notificaciones** in-app (campanita + badge) para likes, follows, valoraciones, comentarios y solicitudes; **push real vía FCM** (opcional).
- **Feed de actividad**, **achievements** automáticos y **amigos** con deeplinks de invitación.

### Plataforma
- **Stats** (racha, retención, filtros por periodo, por-mazo) y misiones diarias/semanales.
- **Moderación**: reportar mazos y cola de moderación (mantener/ocultar/eliminar), con roles.
- **Premium** server-side (trial), **analytics** self-hosted, **recordatorios** locales, **sync** de progreso a la nube, **secure storage** de tokens.

---

## 🧱 Stack

| | |
|---|---|
| **Frontend** | Flutter · `AppStore` (ChangeNotifier) + `AppScope` · `go_router` · `Drift` (SQLite offline-first) · `Dio` · `google_fonts` |
| **IA** | `flutter_gemma` (móvil) · `llama.cpp` (escritorio) · `sherpa_onnx` + `speech_to_text` (ASR) · `flutter_tts` |
| **Backend** | Go 1.25 · monolito modular + hexagonal · `net/http` · SQLite (`modernc.org/sqlite`, CGO off) · WebSocket coop |
| **Infra** | Docker (imagen distroless ~13 MB) · GitHub Actions CI |

El backend define un puerto `Repository` con **tres adapters** intercambiables: `sqlite` (default), `memory` (tests) y `file` (JSON).

---

## 🚀 Empezar

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run                                   # apunta a localhost:8080 por defecto
# generar código (Riverpod/Drift/Freezed)
flutter pub run build_runner build --delete-conflicting-outputs
```

Para apuntar a otro backend: `--dart-define=API_BASE=https://api.tu-dominio.com`.

### Backend (Go)

```bash
cd backend
go run cmd/api/main.go        # puerto 8080
go test ./...
```

### Docker

```bash
cp .env.example .env
docker compose up -d --build
curl http://localhost:8080/healthz
```

Ver **[DEPLOY.md](DEPLOY.md)** para producción (TLS, persistencia, FCM, hosting).

---

## 📂 Estructura

```
Memorizar/
  frontend/                 # app Flutter
    lib/
      core/                 # router, theme, db (Drift), api client, services
      features/             # home, decks, review, comunidad, coop, moderation, ...
  backend/                  # API Go
    cmd/api/                # entrypoint
    internal/
      social/               # domain · application (service) · ports · adapters
      httpapi/ · notify/ · coop/ · practice/
    migrations/ · Dockerfile
  docs/adr/                 # Architecture Decision Records
  DEPLOY.md · docker-compose.yml
```

---

## 🧪 Calidad

- **CI** (GitHub Actions): jobs Frontend (Flutter analyze + test) y Backend (Go build + vet + test) que fallan ante errores o tests rojos.
- Tests unitarios en ambos lados; lógica pura de ejercicios extraída a un archivo testeable.

---

## 📌 Estado

Repo público: <https://github.com/Jeudry/memorizar>. Rama principal: `main`.

> El push real (FCM) y el login social (Google/Apple/Facebook) están implementados pero requieren las credenciales del proyecto del propietario para activarse (`flutterfire configure`, claves OAuth). Ver [DEPLOY.md](DEPLOY.md).
