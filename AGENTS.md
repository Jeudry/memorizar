# AGENTS.md — Memorizar

Motor de memorización genérico con SRS (Spaced Repetition System). El deck principal es la **Biblia**, pero el sistema soporta cualquier contenido: vocabulario, fórmulas, fechas, citas, etc.

---

## Integración de Arquitectura

**El frontend y el backend están activamente integrados.** Todo el estado y flujo de autenticación, repetición y sincronización de mazos viaja a través de peticiones HTTP reales (Dio) hacia el backend en Go (puerto 8080) y persistencia local integrada.

No simular datos o usar maquetaciones mock si existen endpoints funcionales en el backend.

---

## Estructura del repositorio

```
Memorizar/
  frontend/     # Flutter app
  backend/      # Go API
  docs/
    adr/        # Architecture Decision Records
```

---

## Build & Run

```bash
# Frontend
cd frontend && flutter run

# Generar código (Riverpod, Drift, Freezed)
cd frontend && flutter pub run build_runner build --delete-conflicting-outputs

# Backend
cd backend && go run cmd/api/main.go       # puerto 8080
cd backend && air                          # live reload

# Docker
docker-compose up
```

### Hot Restart (Antigravity ONLY)
**CRITICAL:** NEVER use `manage_task` tool with `send_input` 'R' to perform a Flutter hot restart.
Instead, ALWAYS run the automatic hot restart trigger script:
```bash
dart /Users/sargon/.gemini/antigravity/brain/ad9a501d-71ee-4863-a468-bff6eb05a209/scratch/hot_restart.dart
```

---

## Frontend (Flutter)

**Stack:**
- State: `Riverpod 2.x` con code generation (`riverpod_annotation`)
- Routing: `go_router`
- Models: `Freezed` + `json_serializable`
- Local DB: `Drift` (SQLite tipado) — offline-first sincronizado
- HTTP: `Dio` — activo y conectado al backend
- UI: `google_fonts` (Outfit headings, DM Sans body)
- Hooks: `flutter_hooks` + `hooks_riverpod`

**Arquitectura feature-driven:**
```
frontend/lib/
  core/
    router/       # go_router config
    theme/        # colores, tipografía, tokens
    db/           # Drift database
  features/
    decks/        # lista y detalle de decks
    review/       # sesión de repaso SRS
    home/         # dashboard / estadísticas
```

**Estado actual:** Integración completa de producción. Comunicación Dio activa hacia el backend.

---

## Backend (Go)

**Stack:**
- Go 1.24+, puerto **8080** (no usar 3000)
- Connect-RPC (Buf) o Huma
- sqlc — SQL tipado
- PostgreSQL + pgvector
- Redis / Valkey
- Arquitectura: Modular Monolith + Hexagonal + CQRS ligero

```
backend/
  cmd/api/
  internal/
    memorization/    # domain, application, ports, adapters
    catalog/         # decks + items
    shared/          # eventbus, telemetry
  migrations/
  docs/adr/
```

---

## Dominio

- **Deck**: colección temática (ej: "Biblia", "Inglés B2", "Historia")
- **Item**: par frente/dorso dentro de un deck
- **Review**: resultado de un repaso (Again/Hard/Good/Easy)
- **Algoritmo SRS**: SM-2 o FSRS — `easeFactor`, `interval`, `repetitions`, `nextReviewAt`

El deck "Biblia" tiene metadatos extra: `book`, `chapter`, `verse`.

---

## Git

- Rama principal: `main`
- Naming: `feature/MM-{número}_{descripción}`
- Repo: `https://github.com/Jeudry/memorizar` (público)

### Regla de ramas

**SIEMPRE usar `/create-branch` para cada cambio.** No trabajar directamente en `main` ni hacer commit sin rama nueva. Cada feature/tarea/refactor debe tener su propia rama antes de tocar código.

- Rama base: `main` (siempre crear desde main — no preguntar)
- Naming: `feature/MM-{número}_{descripción}`
