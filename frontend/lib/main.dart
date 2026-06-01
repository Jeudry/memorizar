import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'core/i18n/strings.dart';
import 'core/router/app_routes.dart';
import 'core/services/analytics_service.dart';
import 'core/services/deeplink_service.dart';
import 'core/services/push_service.dart';
import 'core/theme.dart';
import 'core/ui/reference_page.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/presentation/ui_screens.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _deeplinks = DeeplinkService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(enableDatabasePersistence: !kIsWeb);
  await store.loadBible();
  await store.bootstrapSession();
  await store.bootstrapPreferences();


  AppRoutes.register(buildAppRoutes());
  ReferencePage.registerBackgroundBuilder(() => const AppAuroraBackground());

  // Push: solo inicializa el plugin local, no requiere Firebase para correr.
  await PushService.instance.initialize();

  // Si hay usuario logueado, identifícalo en analytics.
  if (store.currentUser != null) {
    Analytics.instance.identify(store.currentUser!.id, traits: {
      'email': store.currentUser!.email,
    });
  }

  // Decidir pantalla inicial: si nunca completó onboarding, mostrarlo.
  final showOnboarding = await OnboardingScreen.shouldShow();

  runApp(AppScope(
    store: store,
    child: MemorizarApp(showOnboarding: showOnboarding),
  ));

  // Deeplinks: arrancar después de runApp para que el navigator key esté
  // adjunto al widget tree.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _deeplinks.attach(navKey: _navigatorKey, store: store);
  });
}

class MemorizarApp extends StatefulWidget {
  final bool showOnboarding;
  const MemorizarApp({super.key, this.showOnboarding = false});

  @override
  State<MemorizarApp> createState() => _MemorizarAppState();
}

class _MemorizarAppState extends State<MemorizarApp> {
  bool _onboardingShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.showOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_onboardingShown) return;
        _onboardingShown = true;
        final nav = _navigatorKey.currentState;
        if (nav != null) {
          nav.push(MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return MaterialApp(
      title: 'Memorizar',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: store.themeMode,
      locale: Locale(store.locale),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRoutes.generateRoute,
      routes: AppRoutes.routes,
    );
  }
}
