import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_state.dart';
import '../../../../core/theme/ref_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/ui_screens.dart';
import '../data/reading_plans.dart';

/// Detail screen for a [ReadingPlan]: lists all days, lets the user mark
/// progress (per-plan, persisted in SharedPreferences), and load a day's
/// verses into the current selection to start studying.
class PlanDetailScreen extends StatefulWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  static String prefsKeyFor(String planId) =>
      'memorizar.plan.$planId.currentDay';

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  int _currentDay = 1;
  final Set<int> _expanded = <int>{};
  bool _loaded = false;

  ReadingPlan? get _plan => findReadingPlan(widget.planId);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final day = prefs.getInt(PlanDetailScreen.prefsKeyFor(widget.planId)) ?? 1;
    if (!mounted) return;
    setState(() {
      _currentDay = day.clamp(1, _plan?.totalDays ?? 1);
      _expanded.add(_currentDay);
      _loaded = true;
    });
  }

  Future<void> _setCurrentDay(int day) async {
    setState(() => _currentDay = day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PlanDetailScreen.prefsKeyFor(widget.planId), day);
  }

  void _toggleExpanded(int day) {
    setState(() {
      if (_expanded.contains(day)) {
        _expanded.remove(day);
      } else {
        _expanded.add(day);
      }
    });
  }

  void _studyDay(PlanDay day) {
    final store = AppScope.of(context);
    final allVerses = store.bibleVerses;
    store.clearBibleSelection();
    var added = 0;
    for (final entry in day.entries) {
      Iterable<BibleVerseData> verses = allVerses.where(
        (v) => v.book == entry.book && v.chapter == entry.chapter,
      );
      if (entry.verses != null && entry.verses!.isNotEmpty) {
        final wanted = entry.verses!.toSet();
        verses = verses.where((v) => wanted.contains(v.verse));
      }
      for (final v in verses) {
        store.addBibleVerse(v);
        added++;
      }
    }
    _setCurrentDay(day.day);
    if (added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron versículos para este día.'),
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.iniciar);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      backgroundColor: RefColors.bg,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SafeArea(
            child: plan == null
                ? const Center(
                    child: Text(
                      'Plan no encontrado',
                      style: TextStyle(color: RefColors.ink),
                    ),
                  )
                : !_loaded
                    ? const Center(
                        child: CircularProgressIndicator(color: RefColors.pink),
                      )
                    : _buildBody(plan),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ReadingPlan plan) {
    final current = plan.days.firstWhere(
      (d) => d.day == _currentDay,
      orElse: () => plan.days.first,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
          child: Row(
            children: [
              _BackPill(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        color: RefColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Día $_currentDay de ${plan.totalDays}',
                      style: const TextStyle(
                        color: RefColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                plan.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _ProgressBar(
            value: _currentDay / plan.totalDays,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
            itemCount: plan.days.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final day = plan.days[index];
              final isCurrent = day.day == _currentDay;
              final isCompleted = day.day < _currentDay;
              final isExpanded = _expanded.contains(day.day);
              return _DayCard(
                day: day,
                isCurrent: isCurrent,
                isCompleted: isCompleted,
                isExpanded: isExpanded,
                onToggle: () => _toggleExpanded(day.day),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: _StudyCta(
            label: 'Estudiar día $_currentDay',
            onTap: () => _studyDay(current),
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final PlanDay day;
  final bool isCurrent;
  final bool isCompleted;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DayCard({
    required this.day,
    required this.isCurrent,
    required this.isCompleted,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isCurrent
        ? RefColors.lime
        : isCompleted
            ? RefColors.cyan
            : RefColors.muted;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent ? RefColors.glassStrong : RefColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent ? RefColors.lime : RefColors.border,
              width: isCurrent ? 1.2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: RefColors.glass,
                          border: Border.all(color: accent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isCompleted ? '✓' : '${day.day}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day.label,
                              style: const TextStyle(
                                color: RefColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _summary(day),
                              style: const TextStyle(
                                color: RefColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: RefColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final entry in day.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: RefColors.glassStrong,
                            border: Border.all(color: RefColors.border),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _entryLabel(entry),
                            style: const TextStyle(
                              color: RefColors.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _summary(PlanDay day) {
    if (day.entries.isEmpty) return '';
    final refs = day.entries.map(_entryLabel).toList();
    return refs.join(' · ');
  }

  String _entryLabel(PlanEntry e) {
    if (e.verses == null || e.verses!.isEmpty) {
      return '${e.book} ${e.chapter}';
    }
    final v = e.verses!;
    if (v.length == 1) return '${e.book} ${e.chapter}:${v.first}';
    // Render as ranges where contiguous (e.g., 3-12).
    final sorted = [...v]..sort();
    final ranges = <String>[];
    var start = sorted.first;
    var prev = start;
    for (var i = 1; i < sorted.length; i++) {
      final n = sorted[i];
      if (n == prev + 1) {
        prev = n;
        continue;
      }
      ranges.add(start == prev ? '$start' : '$start-$prev');
      start = n;
      prev = n;
    }
    ranges.add(start == prev ? '$start' : '$start-$prev');
    return '${e.book} ${e.chapter}:${ranges.join(",")}';
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: RefColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RefColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(gradient: RefColors.primary),
          ),
        ),
      ),
    );
  }
}

class _StudyCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StudyCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: RefColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: RefColors.pink.withValues(alpha: .4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RefColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RefColors.border),
          ),
          child: const Icon(Icons.arrow_back, color: RefColors.ink, size: 20),
        ),
      ),
    );
  }
}
