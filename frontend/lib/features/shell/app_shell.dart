import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/layout/responsive.dart';
import 'package:memorizar/core/theme/theme_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _locationToIndex(String location) {
    if (location.startsWith('/decks')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Responsive(
      mobile: _MobileShell(currentIndex: currentIndex, isDark: isDark, ref: ref, child: child),
      desktop: _DesktopShell(currentIndex: currentIndex, isDark: isDark, ref: ref, child: child),
    );
  }
}

// ── Mobile: bottom navigation bar ────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.child, required this.currentIndex, required this.isDark, required this.ref});
  final Widget child;
  final int currentIndex;
  final bool isDark;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTap(context),
        destinations: _destinations,
      ),
    );
  }
}

// ── Desktop: side rail ────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.child, required this.currentIndex, required this.isDark, required this.ref});
  final Widget child;
  final int currentIndex;
  final bool isDark;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isExpanded = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

    return Scaffold(
      body: Row(
        children: [
          // Side rail
          Container(
            width: isExpanded ? 220 : 72,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(right: BorderSide(color: cs.outline)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 20 : 0,
                  ),
                  child: isExpanded
                      ? Row(children: [
                          const SizedBox(width: 4),
                          Text('🧠', style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text(
                            'Memorizar',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ])
                      : Center(
                          child: Text('🧠', style: const TextStyle(fontSize: 22)),
                        ),
                ),
                const SizedBox(height: 32),
                // Nav items
                _RailItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Inicio',
                  selected: currentIndex == 0,
                  expanded: isExpanded,
                  onTap: () => context.go('/home'),
                ),
                const SizedBox(height: 4),
                _RailItem(
                  icon: Icons.style_outlined,
                  selectedIcon: Icons.style_rounded,
                  label: 'Decks',
                  selected: currentIndex == 1,
                  expanded: isExpanded,
                  onTap: () => context.go('/decks'),
                ),
                const Spacer(),
                // Theme toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: InkWell(
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isExpanded ? 14 : 0,
                        vertical: 12,
                      ),
                      child: isExpanded
                          ? Row(children: [
                              Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 12),
                              Text(
                                isDark ? 'Modo claro' : 'Modo oscuro',
                                style: GoogleFonts.dmSans(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                              ),
                            ])
                          : Center(
                              child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5);
    final bg = selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 14 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: expanded
              ? Row(children: [
                  Icon(selected ? selectedIcon : icon, color: color, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ])
              : Center(
                  child: Icon(selected ? selectedIcon : icon, color: color, size: 22),
                ),
        ),
      ),
    );
  }
}

void Function(int) _onTap(BuildContext context) => (index) {
      switch (index) {
        case 0:
          context.go('/home');
        case 1:
          context.go('/decks');
      }
    };

const _destinations = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home_rounded),
    label: 'Inicio',
  ),
  NavigationDestination(
    icon: Icon(Icons.style_outlined),
    selectedIcon: Icon(Icons.style_rounded),
    label: 'Decks',
  ),
];
