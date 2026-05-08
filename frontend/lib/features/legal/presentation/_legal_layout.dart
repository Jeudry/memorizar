import 'package:flutter/material.dart';

import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// One section of a legal document — a heading + a body of plain prose.
class LegalSection {
  final String heading;
  final String body;
  const LegalSection({required this.heading, required this.body});
}

/// Shared scaffold for the four legal screens (Terms, Privacy, DMCA,
/// Community Guidelines). Keeps typography + spacing consistent.
class LegalLayout extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;
  /// Optional intro paragraph rendered below the title before the first
  /// section.
  final String? intro;
  /// Optional updated-at label, shown right under the title.
  final String? updatedAt;

  const LegalLayout({
    super.key,
    required this.title,
    required this.sections,
    this.intro,
    this.updatedAt = 'Actualizado en mayo 2026',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RefTopBar(title: title),
        Glass(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (updatedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  updatedAt!,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
              ],
              if (intro != null) ...[
                const SizedBox(height: 12),
                Text(
                  intro!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: RefColors.ink,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final s in sections) ...[
                const SizedBox(height: 16),
                Text(
                  s.heading,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: RefColors.pink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: RefColors.ink,
                  ),
                ),
              ],
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}
