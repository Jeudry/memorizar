// Stub for platforms that don't have native or web implementations.
import 'package:drift/drift.dart';

QueryExecutor openConnection() {
  throw UnsupportedError('No database implementation available for this platform');
}
