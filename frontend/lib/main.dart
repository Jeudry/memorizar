import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/db/seed_data.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/core/router/app_router.dart';
import 'package:memorizar/core/theme/app_theme.dart';
import 'package:memorizar/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  globalPrefs = prefs;
  final db = AppDatabase();
  await seedDatabase(db);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MemorizarApp(),
    ),
  );
}

class MemorizarApp extends ConsumerWidget {
  const MemorizarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Memorizar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
