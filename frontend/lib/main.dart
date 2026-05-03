import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/theme.dart';
import 'features/home/presentation/ui_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.loadBible();
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
