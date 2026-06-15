import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

/// Web es plataforma secundaria (la app vive en desktop/móvil). `WebDatabase`
/// está deprecado pero sigue funcional ("bugfix-only"). La migración a
/// `package:drift/wasm.dart` (`WasmDatabase`) requiere servir los binarios
/// `sqlite3.wasm` + `drift_worker.js` en `web/` y validarse en un runtime web
/// real (IndexedDB) — pendiente hasta tener ese entorno. Por eso silenciamos
/// la deprecación aquí en lugar de migrar a ciegas y arriesgar romper web.
QueryExecutor connect({bool inMemory = false}) {
  if (inMemory) {
    // ignore: deprecated_member_use
    return WebDatabase('memorizar_in_memory', logStatements: false);
  }
  // ignore: deprecated_member_use
  return WebDatabase('memorizar', logStatements: false);
}

