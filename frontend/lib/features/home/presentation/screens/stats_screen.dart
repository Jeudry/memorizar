// Generado del refactor de ui_screens.dart.
// StatsScreen + helpers.
part of '../ui_screens.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _periods = [
    (label: 'Hoy', days: 1),
    (label: 'Semana', days: 7),
    (label: 'Mes', days: 30),
    (label: 'Todo', days: 0),
  ];

  int _periodIndex = 1;

  /// Actividad del período activo; days == 0 significa todo el historial.
  ({int correct, int wrong, int reviewed}) _periodActivity(AppStore store) {
    final days = _periods[_periodIndex].days;
    if (days == 0) {
      var correct = 0;
      var wrong = 0;
      var reviewed = 0;
      for (final entry in store.dailyActivity) {
        correct += entry.correct;
        wrong += entry.wrong;
        reviewed += entry.cardsReviewed;
      }
      return (correct: correct, wrong: wrong, reviewed: reviewed);
    }
    return store.activityInLastDays(days);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final hasData = store.decks.isNotEmpty;
    if (!hasData) {
      return ReferencePage(
        active: AppRoutes.stats,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RefTopBar(title: 'Tu progreso'),
            Glass(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  Icon(Icons.bar_chart_rounded,
                      color: RefColors.cyan, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Crea tu primer mazo para ver tus números aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final activity = _periodActivity(store);
    final correct = activity.correct;
    final wrong = activity.wrong;
    final accuracy = (correct + wrong) == 0
        ? 0
        : ((correct / (correct + wrong)) * 100).round();
    return ReferencePage(
      active: AppRoutes.stats,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Tu progreso'),
          _StatsPeriodTabs(
            periods: [for (final p in _periods) p.label],
            activeIndex: _periodIndex,
            onSelect: (index) => setState(() => _periodIndex = index),
          ),
          _StreakHeroCard(store: store),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  emoji: '🎯',
                  value: '${store.averageRetention}%',
                  label: 'Retención prom.',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  emoji: '⚡',
                  value: '${store.dominatedCards}',
                  label: 'Dominadas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  emoji: '🧩',
                  value: '${store.totalCards}',
                  label: 'Tarjetas totales',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  emoji: '⚠️',
                  value: '${store.weakCards}',
                  label: 'Débiles',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  emoji: '✅',
                  value: '$correct',
                  label: 'Aciertos · ${_periods[_periodIndex].label.toLowerCase()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  emoji: '❌',
                  value: '$wrong',
                  label: 'Errores · ${_periods[_periodIndex].label.toLowerCase()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  emoji: '%',
                  value: '$accuracy%',
                  label: 'Precisión',
                ),
              ),
            ],
          ),
          const SectionHead('Por mazo'),
          for (final deck in store.decks)
            _DeckStatsRow(deck: deck),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      color: HtmlRefColors.glassSoft,
      border: Border.all(color: HtmlRefColors.glassBorder),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckStatsRow extends StatelessWidget {
  final MemoryDeckData deck;
  const _DeckStatsRow({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          GlyphIcon(deck.icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (deck.retention / 100).clamp(0, 1),
                    backgroundColor: HtmlRefColors.glassStrong,
                    valueColor: AlwaysStoppedAnimation(
                      deck.retention >= 80
                          ? RefColors.lime
                          : deck.retention >= 50
                              ? RefColors.sun
                              : RefColors.urgent,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${deck.retention}%',
            style: TextStyle(
              color: deck.retention >= 80
                  ? RefColors.lime
                  : deck.retention >= 50
                      ? RefColors.sun
                      : RefColors.urgent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPeriodTabs extends StatelessWidget {
  final List<String> periods;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _StatsPeriodTabs({
    required this.periods,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 12,
        padding: const EdgeInsets.all(4),
        color: HtmlRefColors.glassSoft,
        border: Border.all(color: HtmlRefColors.glassBorder),
        child: Row(
          children: [
            for (var i = 0; i < periods.length; i++)
              Expanded(
                child: _PeriodTab(
                  periods[i],
                  active: i == activeIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodTab(this.label, {this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? HtmlRefColors.glassStrong : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: HtmlRefColors.glassBorder) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? RefColors.ink : RefColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  final AppStore store;

  const _StreakHeroCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .22),
            RefColors.sun.withValues(alpha: .34),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: HtmlRefColors.glassBorder),
        child: Column(
          children: [
            Text(
              'Tu racha 🔥',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${store.streakDays}',
                  style: const TextStyle(
                    fontSize: 52,
                    height: .95,
                    fontWeight: FontWeight.w900,
                    color: RefColors.sun,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'DÍAS\nSEGUIDOS',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.18,
                    color: RefColors.muted,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StreakMetric(
                  '${store.activityInLastDays(1).reviewed}',
                  'TARJETAS HOY',
                ),
                const SizedBox(width: 22),
                _StreakMetric('${store.estimatedPendingMinutes} min', 'TIEMPO'),
                const SizedBox(width: 22),
                _StreakMetric('${store.averageRetention}%', 'ACIERTOS'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  final String value;
  final String label;

  const _StreakMetric(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: RefColors.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: .45,
          ),
        ),
      ],
    );
  }
}

