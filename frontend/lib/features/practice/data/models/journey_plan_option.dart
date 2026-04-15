class JourneyPlanOption {
  const JourneyPlanOption({
    required this.targetDays,
    required this.itemsPerDay,
    required this.targetItemCount,
    required this.label,
    required this.summary,
  });

  final int targetDays;
  final int itemsPerDay;
  final int targetItemCount;
  final String label;
  final String summary;
}
