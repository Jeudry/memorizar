class MemorizationJourney {
  const MemorizationJourney({
    required this.id,
    required this.deckId,
    required this.title,
    required this.targetDays,
    required this.itemsPerDay,
    required this.targetItemCount,
    required this.objective,
    required this.createdAt,
  });

  final String id;
  final String deckId;
  final String title;
  final int targetDays;
  final int itemsPerDay;
  final int targetItemCount;
  final String objective;
  final DateTime createdAt;
}
