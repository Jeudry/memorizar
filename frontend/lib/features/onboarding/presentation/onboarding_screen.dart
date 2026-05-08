import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Tutorial de 3 pasos que se muestra la primera vez que el usuario abre la
/// app. Marca un flag en SharedPreferences cuando termina para no volver a
/// mostrarse.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _flagKey = 'memorizar.onboarding.seen';

  /// Determina si hay que mostrarlo. Llamar desde main al arrancar.
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_flagKey) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flagKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.menu_book_rounded,
      title: 'Memoriza con propósito',
      body: 'Crea mazos desde la Biblia o pega tu propio contenido. La app te lleva paso a paso.',
    ),
    (
      icon: Icons.repeat_rounded,
      title: 'Repaso espaciado',
      body: 'Practica cada día. Las tarjetas más débiles aparecen primero para que no se pierdan.',
    ),
    (
      icon: Icons.groups_rounded,
      title: 'Estudia con amigos',
      body: 'Comparte mazos, únete a salas cooperativas y mira el progreso de tu comunidad.',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: RefColors.primary,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: RefColors.pink.withValues(alpha: .35),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(p.icon, color: Colors.white, size: 52),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        p.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: RefColors.muted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? RefColors.pink : RefColors.muted,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _page < _pages.length - 1
                ? Row(
                    children: [
                      Expanded(child: GhostButton('Saltar', onTap: _finish)),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Cta(
                          'Siguiente →',
                          onTap: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                    ],
                  )
                : Cta('Empezar', onTap: _finish),
          ),
        ],
      ),
    );
  }
}
