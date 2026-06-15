import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Conexión web con `WasmDatabase` (reemplaza al deprecado `WebDatabase`).
///
/// Sirve `sqlite3.wasm` y `drift_worker.js` desde `web/` (copiados/compilados
/// desde el paquete drift — ver `web/drift_worker.dart`). En runtime drift
/// elige el mejor backend de almacenamiento disponible (OPFS → IndexedDB →
/// memoria) y persiste ahí. Web sigue siendo plataforma secundaria; la app
/// vive en desktop/móvil, pero ya sin la API deprecada.
QueryExecutor connect({bool inMemory = false}) {
  // `LazyDatabase` mantiene la firma síncrona: la apertura real de
  // WasmDatabase (asíncrona, hace probing del storage) ocurre al primer uso.
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: inMemory ? 'memorizar_in_memory' : 'memorizar',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
