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

### Hot Restart & Hot Reload (Antigravity)
Utilizar la herramienta `manage_task` con la acción `send_input` y el comando `'r'` para Hot Reload o `'R'` para Hot Restart directamente sobre la tarea en ejecución de `flutter run`.

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

---

## 🛡️ PROTOCOLO DE SEGURIDAD DE GIT (MANDATORIO PARA IA)

Para evitar la pérdida accidental de código de producción, conflictos híbridos y errores de compilación, todo agente que trabaje en este repositorio **DEBE** acatar estrictamente las siguientes reglas:

### 1. Control de Archivos sin Registrar (Untracked)
- **Regla:** Antes de ejecutar cualquier comando destructivo (`git checkout .`, `git reset --hard`, `git clean`), ejecuta siempre `git status`.
- **Acción:** Si existen directorios o archivos nuevos sin registrar (como `missions/`, `plans/`, etc.), **debes agregarlos inmediatamente al stage (`git add .`)** para que Git los rastree. Nunca los dejes en limbo como untracked para evitar que se pierdan en worktrees ocultos o stashes.

### 2. Recuperación Segura de Stashes
- **Regla:** Si aplicas un `git stash pop` y se generan conflictos de fusión, **NUNCA** los borres o deshagas con un reset masivo.
- **Acción:** Inspecciona cada archivo marcado como "both modified" y resuelve pacientemente todos los marcadores (`<<<<<<<`, `=======`, `>>>>>>>`) combinando la lógica de ambas partes. Si no puedes resolverlos, utiliza `git stash apply` en lugar de `pop` para no perder la copia de seguridad física del stash.

### 3. Cero Commits con Errores de Sintaxis o Marcadores
- **Regla:** Queda prohibido hacer commits, push o crear Pull Requests que contengan marcadores de conflicto sobrantes en el código o fallos de compilación.
- **Acción:** Tras resolver conflictos, ejecuta obligatoriamente `flutter analyze` en el frontend y `go build` en el backend. Confirma que el reporte arroje **cero errores** antes de proceder a la firma del commit.

### 4. Búsqueda de Cambios "Perdidos"
- Si el usuario reporta que se perdieron cambios que ya se habían avanzado, **no declares el trabajo perdido** de inmediato. Realiza la búsqueda exhaustiva en:
  1. La lista de stashes locales: `git stash list`
  2. El registro interno de referencias de Git: `git reflog`
  3. Los subdirectorios ocultos de trabajo del worktree: `.claude/worktrees/`
