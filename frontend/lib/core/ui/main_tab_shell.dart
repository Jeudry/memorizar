import 'package:flutter/material.dart';
import '../router/app_routes.dart';
import '../theme/ref_colors.dart';
import 'bottom_nav.dart';
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
  int _previousIndex = 0;

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
    _previousIndex = _currentIndex;
  }

  int _getIndexOfRoute(String route) {
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
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = newIndex;
      });
    }
  }

  void goToRoute(String route) {
    final targetIndex = _getIndexOfRoute(route);
    if (targetIndex != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = targetIndex;
      });
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

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const RepasarScreen();
      case 2:
        return const AmigosScreen();
      case 3:
        return const ComunidadScreen();
      case 4:
        return const StatsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slideDirection = _currentIndex >= _previousIndex ? 1.0 : -1.0;

    return Scaffold(
      backgroundColor: RefColors.bg,
      body: Stack(
        children: [
          // Aurora Background matching current variant
          AppAuroraBackground(variant: _getBackgroundVariant()),

          // Main page transitions using AnimatedSwitcher to avoid intermediate page flashing
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isEntering = child.key == ValueKey<int>(_currentIndex);
                if (isEntering) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(slideDirection, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                } else {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(-slideDirection, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                }
              },
              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                return Stack(
                  children: <Widget>[
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              child: SizedBox.expand(
                key: ValueKey<int>(_currentIndex),
                child: _buildScreen(_currentIndex),
              ),
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
