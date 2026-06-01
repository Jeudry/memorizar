import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor connect({bool inMemory = false}) {
  if (inMemory) {
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'memorizar.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
