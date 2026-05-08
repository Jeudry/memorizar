import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Hub para que el usuario llegue a TOS, Privacidad, DMCA y normas de
/// comunidad desde un solo lugar. Lo enlazamos desde Inicio → Más / Ajustes.
class LegalMenuScreen extends StatelessWidget {
  const LegalMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Legal'),
          Glass(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              children: [
                _LegalRow(
                  icon: Icons.gavel_rounded,
                  title: 'Términos de uso',
                  subtitle: 'Las reglas básicas para usar Memorizar.',
                  route: AppRoutes.legalTerms,
                ),
                _LegalRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacidad',
                  subtitle: 'Qué datos guardamos y por qué.',
                  route: AppRoutes.legalPrivacy,
                ),
                _LegalRow(
                  icon: Icons.copyright_rounded,
                  title: 'DMCA / Copyright',
                  subtitle: 'Reportar uso indebido de tu obra.',
                  route: AppRoutes.legalDmca,
                ),
                _LegalRow(
                  icon: Icons.groups_rounded,
                  title: 'Normas de comunidad',
                  subtitle: 'Qué se permite en mazos públicos.',
                  route: AppRoutes.legalCommunity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _LegalRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: RefColors.cyan.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: RefColors.cyan.withValues(alpha: .45),
                ),
              ),
              child: Icon(icon, color: RefColors.cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: RefColors.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
