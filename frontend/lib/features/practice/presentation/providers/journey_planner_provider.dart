import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/practice/services/journey_planner_service.dart';

final journeyPlannerProvider = Provider<JourneyPlannerService>((ref) {
  return const JourneyPlannerService();
});
