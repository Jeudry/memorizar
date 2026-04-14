import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

QueryExecutor openAppDb() => LazyDatabase(() async {
      final sqlite3 = await WasmSqlite3.loadFromUrl(
        Uri.parse('sqlite3.wasm'),
      );
      final fileSystem = await IndexedDbFileSystem.open(dbName: 'memorizar');
      return WasmDatabase(
        sqlite3: sqlite3,
        path: '/memorizar.db',
        fileSystem: fileSystem,
      );
    });
