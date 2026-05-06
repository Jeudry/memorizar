import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart';

final dbReadyProvider = FutureProvider<AppDatabase>((ref) async {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main()');
});
