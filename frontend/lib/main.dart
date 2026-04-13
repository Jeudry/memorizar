import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/router/app_router.dart';
import 'package:memorizar/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MemorizarApp()));
}

class MemorizarApp extends StatelessWidget {
  const MemorizarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Memorizar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
