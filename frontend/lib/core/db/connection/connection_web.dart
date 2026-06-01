import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor connect({bool inMemory = false}) {
  if (inMemory) {
    return WebDatabase('memorizar_in_memory', logStatements: false);
  }
  return WebDatabase('memorizar', logStatements: false);
}

