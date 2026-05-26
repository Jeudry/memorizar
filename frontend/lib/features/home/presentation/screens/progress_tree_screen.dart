// Generado del refactor de ui_screens.dart.
// _ProgressTreeScreen + _ReferenceTimelineStep + _TimelineIconBadge.
part of '../ui_screens.dart';

class _ProgressTreeScreen extends StatefulWidget {
  const _ProgressTreeScreen();

  @override
  State<_ProgressTreeScreen> createState() => _ProgressTreeScreenState();
}

class _ProgressTreeScreenState extends State<_ProgressTreeScreen> {
  final GlobalKey _currentStepKey = GlobalKey();
  int _lastScrolledIndex = -1;

  void _scheduleScrollToCurrent(int currentIndex) {
    if (_lastScrolledIndex == currentIndex) return;
    // Wait for the screen slide transition animation to complete (typically 300ms)
    // before executing ensureVisible, preventing transition system overrides.
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      final ctx = _currentStepKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
        _lastScrolledIndex = currentIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final steps = _sessionFlowSteps(store);
    final firstIncompleteIndex = steps.indexWhere(
      (s) => !store.isExerciseStepCompleted(s.slug),
    );
    final currentStepIndex = firstIncompleteIndex < 0
        ? steps.length - 1
        : firstIncompleteIndex;

    _scheduleScrollToCurrent(currentStepIndex);

    return ReferencePage(
      showBottomNav: false,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: RefColors.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RefColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Progreso del ejercicio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (store.sessionDailyTarget > 1)
                      Text(
                        'Tarjeta ${(store.sessionCardsCompleted + 1).clamp(1, store.sessionDailyTarget)} de ${store.sessionDailyTarget}',
                        style: const TextStyle(
                          color: RefColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(2, 2, 0, 10),
              children: [
                for (final group in _phaseGroups(steps))
                  ..._buildGroup(
                    context: context,
                    group: group,
                    steps: steps,
                    currentStepIndex: currentStepIndex,
                    store: store,
                    currentStepKey: _currentStepKey,
                  ),
              ],
            ),
          ),
          // "Pausar y volver al inicio" — la sesión y el deck siguen guardados,
          // así que al volver el usuario retoma desde el mismo paso.
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: GhostButton(
              'Pausar y volver al inicio',
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, int, int)> _phaseGroups(List<ExerciseFlowData> steps) {
    final groups = <(String, int, int)>[];
    var cursor = 0;
    while (cursor < steps.length) {
      final label = _phaseLabelFor(steps[cursor].slug);
      var end = cursor + 1;
      while (end < steps.length && _phaseLabelFor(steps[end].slug) == label) {
        end++;
      }
      groups.add((label, cursor, end));
      cursor = end;
    }
    return groups;
  }

  List<Widget> _buildGroup({
    required BuildContext context,
    required (String, int, int) group,
    required List<ExerciseFlowData> steps,
    required int currentStepIndex,
    required AppStore store,
    required GlobalKey currentStepKey,
  }) {
    final start = group.$2.clamp(0, steps.length);
    final end = group.$3.clamp(0, steps.length);
    if (start >= end) return const [];
    final groupSteps = steps.sublist(start, end);
    final active = currentStepIndex >= start && currentStepIndex < end;
    final completed = currentStepIndex >= end;
    final accent = completed
        ? RefColors.lime
        : active
        ? RefColors.pink
        : RefColors.muted;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(58, 6, 4, 8),
        child: Row(
          children: [
            Text(
              group.$1.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                color: accent.withValues(alpha: active ? .45 : .22),
              ),
            ),
          ],
        ),
      ),
      for (int local = 0; local < groupSteps.length; local++)
        _ReferenceTimelineStep(
          key: (start + local) == currentStepIndex ? currentStepKey : null,
          step: groupSteps[local],
          index: start + local,
          totalCount: steps.length,
          currentIndex: currentStepIndex,
          store: store,
          isLastInGroup: local == groupSteps.length - 1,
          onTapStep: (slug) => Navigator.pushReplacementNamed(
            context,
            '${AppRoutes.flow}/$slug',
          ),
        ),
    ];
  }
}

class _ReferenceTimelineStep extends StatelessWidget {
  final ExerciseFlowData step;
  final int index;
  final int totalCount;
  final int currentIndex;
  final AppStore store;
  final void Function(String slug) onTapStep;
  final bool isLastInGroup;

  const _ReferenceTimelineStep({
    super.key,
    required this.step,
    required this.index,
    required this.totalCount,
    required this.currentIndex,
    required this.store,
    required this.onTapStep,
    this.isLastInGroup = false,
  });

  static const _activeCard = Color(0xFF4A3854);
  static const _idleCard = Color(0xFF363838);
  static const _badgeSize = 38.0;
  static const _titleAnchor = 24.0;

  @override
  Widget build(BuildContext context) {
    final isCompleted = store.isExerciseStepCompleted(step.slug);
    final isCurrent = index == currentIndex;
    final isLocked = !isCompleted && index > currentIndex;
    final isLast = isLastInGroup || index == totalCount - 1;
    final accent = isCompleted
        ? RefColors.lime
        : isCurrent
        ? RefColors.pink
        : RefColors.muted;
    final borderColor = isCompleted
        ? RefColors.lime.withValues(alpha: .85)
        : isCurrent
        ? RefColors.pink.withValues(alpha: .82)
        : RefColors.ink.withValues(alpha: .12);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Opacity(
        opacity: isLocked ? 0.42 : 1.0,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 56,
                child: Stack(
                  children: [
                    if (!isLast)
                      Positioned(
                        top: _titleAnchor + _badgeSize / 2,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? RefColors.lime.withValues(alpha: .58)
                                  : RefColors.muted.withValues(alpha: .38),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: _titleAnchor - _badgeSize / 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _TimelineIconBadge(
                          icon: _timelineIconFor(step.slug),
                          accent: accent,
                          active: isCurrent,
                          completed: isCompleted,
                          locked: isLocked,
                          size: _badgeSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: isLocked ? null : () => onTapStep(step.slug),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? _activeCard : _idleCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                        width: isCurrent || isCompleted ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                step.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLocked
                                      ? RefColors.muted
                                      : RefColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (isLocked)
                              Icon(
                                Icons.lock_rounded,
                                color: RefColors.muted.withValues(alpha: .68),
                                size: 22,
                              )
                            else if (isCompleted)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: RefColors.lime,
                                size: 22,
                              )
                            else
                              Icon(
                                isCurrent
                                    ? Icons.chevron_right_rounded
                                    : Icons.play_arrow_rounded,
                                color: isCurrent
                                    ? RefColors.pink
                                    : RefColors.muted,
                                size: 26,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isLocked
                                ? RefColors.muted
                                : RefColors.ink.withValues(alpha: .82),
                            fontSize: 12,
                            height: 1.26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineIconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool active;
  final bool completed;
  final bool locked;
  final double size;

  const _TimelineIconBadge({
    required this.icon,
    required this.accent,
    required this.active,
    required this.completed,
    required this.locked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? RefColors.pink.withValues(alpha: .72)
            : completed
            ? RefColors.lime.withValues(alpha: .18)
            : RefColors.glassStrong,
        border: Border.all(
          color: active
              ? RefColors.pink.withValues(alpha: .95)
              : completed
              ? RefColors.lime.withValues(alpha: .85)
              : RefColors.ink.withValues(alpha: .14),
          width: active || completed ? 1.6 : 1,
        ),
      ),
      child: Icon(
        icon,
        color: active
            ? RefColors.ink
            : locked
            ? RefColors.muted
            : completed
            ? RefColors.lime
            : accent,
        size: size * .55,
      ),
    );
  }
}

IconData _timelineIconFor(String slug) {
  if (_isCompletionSlug(slug)) return Icons.keyboard_alt_rounded;
  if (_isFirstLetterSlug(slug)) return Icons.short_text_rounded;
  if (_isFinalVoiceSlug(slug)) return Icons.mic_rounded;
  switch (slug) {
    case '01-escuchar':
    case '02-lectura-frag':
      return Icons.menu_book_rounded;
    case '03-leer-voz':
    case '08-voz-guiada':
      return Icons.mic_rounded;
    case '04-escuchar-voz':
      return Icons.headphones_rounded;
    case '05-bloques':
      return Icons.segment_rounded;
    case '09-quiz':
      return Icons.help_outline_rounded;
    default:
      return Icons.radio_button_unchecked_rounded;
  }
}

