# CLAUDE.md — Memorizar

Motor de memorización genérico con SRS (Spaced Repetition System). El deck principal es la **Biblia**, pero el sistema soporta cualquier contenido: vocabulario, fórmulas, fechas, citas, etc.

---

## IMPORTANTE: Frontend primero

**El desarrollo arranca por el frontend.** La UI avanza con datos mock y persistencia local (Drift) sin depender del backend. El backend entra en Fase 3, cuando el frontend ya esté funcional y visualmente completo.

No bloquear trabajo de UI esperando endpoints — si algo necesita datos del backend, usar mocks o Drift local.

---

## Estructura del repositorio

```
Memorizar/
  frontend/     # Flutter app (arrancamos aquí)
  backend/      # Go API (Fase 3+)
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

# Backend (Fase 3+)
cd backend && go run cmd/api/main.go       # puerto 8080
cd backend && air                          # live reload

# Docker (Fase 3+)
docker-compose up
```

---

## Frontend (Flutter)

**Stack:**
- State: `Riverpod 2.x` con code generation (`riverpod_annotation`)
- Routing: `go_router`
- Models: `Freezed` + `json_serializable`
- Local DB: `Drift` (SQLite tipado) — offline-first desde el día uno
- HTTP: `Dio` (dormido hasta Fase 3)
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

**Fase actual: Fase 1 — UI completa con mocks.**
No conectar Dio todavía. Todo el estado viene de providers con datos hardcodeados o Drift local.

---

## Backend (Go) — Fase 3+

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

**No tocar el backend hasta terminar Fase 2 del frontend.**

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
