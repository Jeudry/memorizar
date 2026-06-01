enum MissionPeriod { daily, weekly }

class Mission {
  final String id;
  final String title;
  final String emoji;
  final int target;
  final MissionPeriod period;
  final int rewardXp;

  const Mission({
    required this.id,
    required this.title,
    required this.emoji,
    required this.target,
    required this.period,
    required this.rewardXp,
  });
}

const List<Mission> kMissions = [
  Mission(
    id: 'daily-practice-1',
    title: 'Practica 1 tarjeta hoy',
    emoji: '🃏',
    target: 1,
    period: MissionPeriod.daily,
    rewardXp: 10,
  ),
  Mission(
    id: 'daily-streak',
    title: 'Mantén tu racha',
    emoji: '🔥',
    target: 1,
    period: MissionPeriod.daily,
    rewardXp: 5,
  ),
  Mission(
    id: 'daily-perfect-3',
    title: '3 aciertos seguidos',
    emoji: '🎯',
    target: 3,
    period: MissionPeriod.daily,
    rewardXp: 20,
  ),
  Mission(
    id: 'weekly-7days',
    title: 'Practica 7 días esta semana',
    emoji: '📅',
    target: 7,
    period: MissionPeriod.weekly,
    rewardXp: 50,
  ),
  Mission(
    id: 'weekly-50cards',
    title: 'Memoriza 50 tarjetas esta semana',
    emoji: '🧠',
    target: 50,
    period: MissionPeriod.weekly,
    rewardXp: 30,
  ),
];

List<Mission> missionsByPeriod(MissionPeriod period) =>
    kMissions.where((m) => m.period == period).toList();

Mission? missionById(String id) {
  for (final m in kMissions) {
    if (m.id == id) return m;
  }
  return null;
}
