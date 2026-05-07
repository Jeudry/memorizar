import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/router/app_routes.dart';
import 'core/theme.dart';
import 'core/ui/reference_page.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/presentation/ui_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.loadBible();

  // Wire the shared route map and the aurora background into the leaf-level
  // helpers in `core/`, so they don't need to import every feature screen.
  AppRoutes.register(buildAppRoutes());
  ReferencePage.registerBackgroundBuilder(() => const AppAuroraBackground());

  runApp(AppScope(store: store, child: const MemorizarApp()));
}

class MemorizarApp extends StatelessWidget {
  const MemorizarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memorizar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routes: AppRoutes.routes,
    );
  }
}
