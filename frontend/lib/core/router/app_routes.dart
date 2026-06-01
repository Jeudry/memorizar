import 'package:flutter/material.dart';

/// Route name constants + the shared slide-page transition.
///
/// The actual `name → WidgetBuilder` map lives outside `core/` (in
/// `ui_screens.dart`'s `buildAppRoutes()` for now) so this file stays a leaf
/// dependency that anything can import without pulling in every feature
/// screen. `register()` is called once from `main.dart` so [slideRoute] can
/// resolve names without taking the map as a parameter at every call site.
class AppRoutes {
  static const home = '/';
  static const biblia = '/biblia';
  static const especificar = '/especificar';
  static const iniciar = '/iniciar';
  static const repasar = '/repasar';
  static const comunidad = '/comunidad';
  static const amigos = '/amigos';
  static const stats = '/stats';
  static const cooperativo = '/cooperativo';
  static const cooperativoJuego = '/cooperativo/juego';
  static const cooperativoLogrado = '/cooperativo/logrado';
  static const ejercicios = '/ejercicios';
  static const flashcards = '/flashcards';
  static const premium = '/premium';
  static const planes = '/planes';
  static const flow = '/ejercicios-flow';
  static const bgNocturnoMate = '/preview/background/nocturno-mate';
  static const bgVinoAhumado = '/preview/background/vino-ahumado';
  static const bgTintaProfunda = '/preview/background/tinta-profunda';
  static const bgBrasaSuave = '/preview/background/brasa-suave';
  static const bgCarbonAmbar = '/preview/background/carbon-ambar';
  static const bgCiruelaTostada = '/preview/background/ciruela-tostada';
  static const bgPetroleoDorado = '/preview/background/petroleo-dorado';
  static const bgNaranjaNocturno = '/preview/background/naranja-nocturno';
  static const bgActualSuave = '/preview/background/actual-suave';

  // Legal hub + sub-pages.
  static const legalMenu = '/legal';
  static const legalTerms = '/legal/terms';
  static const legalPrivacy = '/legal/privacy';
  static const legalDmca = '/legal/dmca';
  static const legalCommunity = '/legal/community';

  // Mock moderation queue (admin / owner only — real auth comes in Fase 3).
  static const moderationQueue = '/moderation';

  // Auth + cuenta + bandeja de compartidos.
  static const login = '/login';
  static const account = '/account';
  static const settings = '/settings';
  static const shareInbox = '/inbox';
  static const verifyEmail = '/verify-email';
  static const passwordReset = '/password-reset';

  static Map<String, WidgetBuilder>? _routes;

  /// Inject the master route map. Call once from `main.dart` before the app
  /// runs.
  static void register(Map<String, WidgetBuilder> routes) {
    _routes = routes;
  }

  /// The currently registered route map. Use this for `MaterialApp.routes`.
  static Map<String, WidgetBuilder> get routes {
    final r = _routes;
    if (r == null) {
      throw FlutterError(
        'AppRoutes.routes was read before AppRoutes.register() was called. '
        'Make sure main.dart registers the route map before runApp().',
      );
    }
    return r;
  }

  /// Slide + fade transition used by the reference screens.
  static Route<dynamic> slideRoute(
    String name, {
    Offset begin = const Offset(1, 0),
  }) {
    final builder = routes[name];
    if (builder == null) {
      throw FlutterError('Unknown route: $name');
    }
    return PageRouteBuilder(
      settings: RouteSettings(name: name),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondary) => builder(context),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  /// Fade + scale suave para abrir una pantalla "modal" (login, account,
  /// onboarding). 320ms ida, 200ms vuelta.
  static Route<dynamic> fadeScaleRoute(String name) {
    final builder = routes[name];
    if (builder == null) {
      throw FlutterError('Unknown route: $name');
    }
    return PageRouteBuilder(
      settings: RouteSettings(name: name),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondary) => builder(context),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Aplica defaults coherentes a `Navigator.pushNamed` cuando la ruta no
  /// llamó explícitamente a slideRoute / fadeScaleRoute. Wireado vía
  /// `MaterialApp.onGenerateRoute` desde `main.dart`.
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null) return null;
    final builder = routes[name];
    if (builder == null) return null;

    // Pantallas que se sienten como "modales" → fadeScale.
    const modalLike = {login, account, AppRoutes.settings, shareInbox, legalMenu};
    if (modalLike.contains(name)) {
      return fadeScaleRoute(name);
    }
    // Default: slide con fade.
    return slideRoute(name);
  }
}
