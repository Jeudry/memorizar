import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../../core/theme/ref_colors.dart';
import '../data/missions.dart';
import '../data/missions_tracker.dart';

class MissionsPanel extends StatefulWidget {
  const MissionsPanel({super.key});

  @override
  State<MissionsPanel> createState() => _MissionsPanelState();
}

class _MissionsPanelState extends State<MissionsPanel> {
  MissionPeriod _period = MissionPeriod.daily;
  final Map<String, int> _progress = {};
  final Map<String, bool> _done = {};
  bool _loading = true;
  AppStore? _store;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppScope.of(context);
    if (!identical(store, _store)) {
      _store?.removeListener(_onStoreChanged);
      _store = store;
      _store!.addListener(_onStoreChanged);
    }
  }

  @override
  void didUpdateWidget(covariant MissionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  @override
  void dispose() {
    _store?.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    final tracker = MissionsTracker.instance;
    final progress = <String, int>{};
    final done = <String, bool>{};
    for (final mission in kMissions) {
      progress[mission.id] = await tracker.progressFor(mission.id);
      done[mission.id] = await tracker.isDoneToday(mission.id);
    }
    if (!mounted) return;
    setState(() {
      _progress
        ..clear()
        ..addAll(progress);
      _done
        ..clear()
        ..addAll(done);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final missions = missionsByPeriod(_period);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: RefColors.glass,
            border: Border.all(color: RefColors.border, width: 1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 12),
              _periodTabs(),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...missions.map(_missionTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final completedCount = kMissions
        .where((m) => m.period == _period && (_done[m.id] ?? false))
        .length;
    final totalCount = missionsByPeriod(_period).length;
    return Row(
      children: [
        const Text('🎯', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Misiones del día',
            style: TextStyle(
              color: RefColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: RefColors.glassStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: RefColors.border),
          ),
          child: Text(
            '$completedCount/$totalCount',
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: RefColors.glassSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RefColors.border),
      ),
      child: Row(
        children: [
          _tab('Diarias', MissionPeriod.daily),
          _tab('Semanales', MissionPeriod.weekly),
        ],
      ),
    );
  }

  Widget _tab(String label, MissionPeriod period) {
    final selected = _period == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_period == period) return;
          setState(() => _period = period);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? RefColors.primary : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : RefColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _missionTile(Mission mission) {
    final raw = _progress[mission.id] ?? 0;
    final progress = raw.clamp(0, mission.target);
    final done = _done[mission.id] ?? false;
    final ratio = mission.target == 0 ? 0.0 : progress / mission.target;

    return Opacity(
      opacity: done ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RefColors.glassSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RefColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(mission.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mission.title,
                      style: TextStyle(
                        color: RefColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (done)
                    const Icon(
                      Icons.check_circle,
                      color: RefColors.lime,
                      size: 20,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: RefColors.glassStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+${mission.rewardXp} XP',
                        style: const TextStyle(
                          color: RefColors.sun,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0).toDouble(),
                        minHeight: 6,
                        backgroundColor: RefColors.glassStrong,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          done ? RefColors.lime : RefColors.cyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$progress/${mission.target}',
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
