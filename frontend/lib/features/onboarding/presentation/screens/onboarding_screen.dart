import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingKey = 'memorizar_onboarding_done';

Future<void> markOnboardingDone(SharedPreferences prefs) async {
  await prefs.setBool(_kOnboardingKey, true);
}

const _pages = [
  _OnboardingPage(
    emoji: '🧠',
    title: 'Memoriza cualquier cosa',
    body:
        'Desde versículos bíblicos hasta vocabulario en otros idiomas. Crea decks temáticos y memoriza con un sistema científico.',
    color: AppColors.indigo,
  ),
  _OnboardingPage(
    emoji: '🔁',
    title: 'Repaso espaciado (SRS)',
    body:
        'El algoritmo SM-2 calcula exactamente cuándo necesitas repasar cada tarjeta para maximizar la retención a largo plazo.',
    color: Color(0xFF8B5CF6),
  ),
  _OnboardingPage(
    emoji: '✝️',
    title: 'Deck Biblia incluido',
    body:
        'Versículos del Antiguo y Nuevo Testamento precargados. Empieza a memorizar la Palabra desde el primer día.',
    color: AppColors.success,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await markOnboardingDone(prefs);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.color.withValues(alpha: 0.12),
                  cs.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Omitir',
                        style: GoogleFonts.dmSans(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) => _PageContent(page: _pages[i]),
                  ),
                ),
                // Dots + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? page.color
                                  : cs.onSurface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: page.color,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              isLast ? '¡Empezar!' : 'Siguiente',
                              style: GoogleFonts.dmSans(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(page.emoji, style: const TextStyle(fontSize: 54)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });
  final String emoji;
  final String title;
  final String body;
  final Color color;
}
