import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Nombre del archivo de base de datos. Sobreescribible por dart-define para
/// correr una segunda instancia de escritorio con sesión/usuario aislado:
/// `flutter build macos --dart-define=DB_NAME=user2.sqlite`.
const String _dbName =
    String.fromEnvironment('DB_NAME', defaultValue: 'memorizar.sqlite');

QueryExecutor connect({bool inMemory = false}) {
  if (inMemory) {
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, _dbName));
    return NativeDatabase.createInBackground(file);
  });
}
