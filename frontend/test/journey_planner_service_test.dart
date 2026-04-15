import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/features/practice/services/journey_planner_service.dart';

void main() {
  const service = JourneyPlannerService();

  test('buildOptions creates useful presets for large plans', () {
    final options = service.buildOptions(totalItems: 120);

    expect(options.length, 4);
    expect(options.first.targetDays, 30);
    expect(options.first.itemsPerDay, 4);
    expect(options.last.targetDays, 365);
    expect(options.last.itemsPerDay, 1);
  });
}
