import 'package:flutter/material.dart';
import '../router/app_routes.dart';
import '../theme/ref_colors.dart';
import 'bottom_nav.dart';
import 'reference_page.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/ui_screens.dart';

class MainTabShell extends StatefulWidget {
  final String initialRoute;

  const MainTabShell({super.key, this.initialRoute = AppRoutes.home});

  static MainTabShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainTabShellState>();
  }

  @override
  State<MainTabShell> createState() => MainTabShellState();
}

class MainTabShellState extends State<MainTabShell> {
  late int _currentIndex;
  late final PageController _pageController;

  static const List<String> routesOrder = [
    AppRoutes.home,
    AppRoutes.repasar,
    AppRoutes.amigos,
    AppRoutes.comunidad,
    AppRoutes.stats,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _getIndexOfRoute(widget.initialRoute);
    _pageController = PageController(initialPage: _currentIndex);
  }

  int _getIndexOfRoute(String route) {
    // Treat any bg* variant routes as index 0 (home)
    if (route.contains('/preview/background/')) {
      return 0;
    }
    final index = routesOrder.indexOf(route);
    return index == -1 ? 0 : index;
  }

  @override
  void didUpdateWidget(MainTabShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = _getIndexOfRoute(widget.initialRoute);
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToRoute(String route) {
    final targetIndex = _getIndexOfRoute(route);
    if (targetIndex != _currentIndex) {
      setState(() {
        _currentIndex = targetIndex;
      });
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String get activeRoute => routesOrder[_currentIndex];

  HomeBackgroundVariant _getBackgroundVariant() {
    switch (widget.initialRoute) {
      case AppRoutes.bgNocturnoMate:
        return HomeBackgroundVariant.nocturnoMate;
      case AppRoutes.bgVinoAhumado:
        return HomeBackgroundVariant.vinoAhumado;
      case AppRoutes.bgTintaProfunda:
        return HomeBackgroundVariant.tintaProfunda;
      case AppRoutes.bgBrasaSuave:
        return HomeBackgroundVariant.brasaSuave;
      case AppRoutes.bgCarbonAmbar:
        return HomeBackgroundVariant.carbonAmbar;
      case AppRoutes.bgCiruelaTostada:
        return HomeBackgroundVariant.ciruelaTostada;
      case AppRoutes.bgPetroleoDorado:
        return HomeBackgroundVariant.petroleoDorado;
      case AppRoutes.bgNaranjaNocturno:
        return HomeBackgroundVariant.naranjaNocturno;
      case AppRoutes.bgActualSuave:
        return HomeBackgroundVariant.actualSuave;
      default:
        return HomeBackgroundVariant.actualSuave;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RefColors.bg,
      body: Stack(
        children: [
          // Aurora Background matching current variant
          AppAuroraBackground(variant: _getBackgroundVariant()),

          // Main page transitions
          SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Only tap navigation
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: const [
                HomeScreen(),
                RepasarScreen(),
                AmigosScreen(),
                ComunidadScreen(),
                StatsScreen(),
              ],
            ),
          ),

          // Persistent and static bottom navigation bar
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: RefBottomNav(active: routesOrder[_currentIndex]),
          ),
        ],
      ),
    );
  }
}
