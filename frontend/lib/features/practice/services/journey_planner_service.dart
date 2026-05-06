import 'package:memorizar/features/practice/data/models/journey_plan_option.dart';

class JourneyPlannerService {
  const JourneyPlannerService();

  List<JourneyPlanOption> buildOptions({
    required int totalItems,
    List<int> targetDays = const [30, 90, 180, 365],
  }) {
    if (totalItems <= 0) return const [];

    return targetDays.map((days) {
      final itemsPerDay = (totalItems / days).ceil().clamp(1, 9999);
      final months = (days / 30).toStringAsFixed(days >= 90 ? 0 : 1);
      return JourneyPlanOption(
        targetDays: days,
        itemsPerDay: itemsPerDay,
        targetItemCount: totalItems,
        label: '$days días',
        summary: '$itemsPerDay items/día durante ~$months meses',
      );
    }).toList();
  }
}
