// Worker de drift para web (WasmDatabase). Compilado a web/drift_worker.js
// con: dart compile js -O2 web/drift_worker.dart -o web/drift_worker.js
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
