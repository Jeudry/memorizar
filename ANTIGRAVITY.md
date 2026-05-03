# ANTIGRAVITY.md — Memorizar

Este archivo contiene las instrucciones para el agente Antigravity en el proyecto Memorizar.

---

## Proyecto: Memorizar
Motor de memorización genérico con SRS (Spaced Repetition System).

### Reglas Críticas para Antigravity:
1. **Frontend Primero**: El desarrollo siempre comienza por el frontend (Flutter) usando mocks y Drift local.
2. **Backend**: No tocar el backend (Go) hasta que la Fase 2 del frontend esté completa.
3. **Arquitectura**: 
   - Frontend: Riverpod 2.x, go_router, Drift, Freezed.
   - Backend: Go 1.24+, Connect-RPC, sqlc, PostgreSQL.
4. **Git**: Usar siempre `/create-branch` para cada cambio. Naming: `feature/MM-{número}_{descripción}`.

---

## Estructura del repositorio

```
Memorizar/
  frontend/     # Flutter app
  backend/      # Go API
  docs/
    adr/        # Architecture Decision Records
```

Para más detalles, consultar `AGENTS.md`.
