class MemorizationGoal {
  const MemorizationGoal({
    required this.id,
    required this.deckId,
    required this.title,
    required this.objective,
    required this.targetItems,
    required this.createdAt,
    this.targetDate,
    this.status = 'active',
  });

  final String id;
  final String deckId;
  final String title;
  final String objective;
  final int targetItems;
  final DateTime createdAt;
  final DateTime? targetDate;
  final String status;
}
