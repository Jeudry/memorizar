import 'package:flutter/material.dart';
import 'main_tab_shell.dart';

import '../router/app_routes.dart';
import '../theme/ref_colors.dart';
import 'bottom_nav.dart';

/// The shell every reference screen sits inside. Provides the aurora
/// background, safe-area padding, optional scroll behaviour and the floating
/// bottom-nav pill.
///
/// `AppAuroraBackground` is provided by the host app (it lives in the home
/// feature alongside the variant selector). To keep this file a leaf
/// dependency we accept the background widget by reference — the default
/// builder lives in `home/presentation/ui_screens.dart` and is the
/// `AppAuroraBackground()` const.
class ReferencePage extends StatelessWidget {
  final Widget child;
  final bool showBottomNav;
  final String active;

  /// When false, the body is laid out in a non-scrolling column. Useful for
  /// screens that own their own scroll views (e.g. progress trees).
  final bool scrollable;

  /// Background widget rendered behind the content. Defaults to a transparent
  /// SizedBox if no background was registered via [registerBackgroundBuilder].
  static Widget Function() backgroundBuilder = _defaultBackground;

  static Widget _defaultBackground() => const SizedBox.expand();

  /// Lets the app inject its aurora background once at startup so this widget
  /// stays decoupled from the home feature.
  static void registerBackgroundBuilder(Widget Function() builder) {
    backgroundBuilder = builder;
  }

  const ReferencePage({
    super.key,
    required this.child,
    this.showBottomNav = true,
    this.active = AppRoutes.home,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isInsideShell = MainTabShell.of(context) != null;

    if (isInsideShell) {
      return scrollable
          ? SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                4,
                18,
                showBottomNav ? 118 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [child],
              ),
            )
          : Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                4,
                18,
                showBottomNav ? 118 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: child)],
              ),
            );
    }

    return Scaffold(
      backgroundColor: RefColors.bg,
      body: Stack(
        children: [
          backgroundBuilder(),
          SafeArea(
            child: scrollable
                ? SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      showBottomNav ? 118 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [child],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      showBottomNav ? 118 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Expanded(child: child)],
                    ),
                  ),
          ),
          if (showBottomNav)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: RefBottomNav(active: active),
            ),
        ],
      ),
    );
  }
}
