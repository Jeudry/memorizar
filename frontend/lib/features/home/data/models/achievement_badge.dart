class AchievementBadge {
  const AchievementBadge({
    required this.code,
    required this.title,
    required this.description,
    required this.unlocked,
    this.unlockedAt,
  });

  final String code;
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;
}
