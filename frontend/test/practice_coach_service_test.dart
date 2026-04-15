import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/features/practice/data/models/exercise_performance_summary.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/services/practice_coach_service.dart';

void main() {
  const service = PracticeCoachService();

  test('coach feedback suggests targeted next action from weakest step', () {
    final feedback = service.buildCoachFeedback(
      summaries: const [
        ExercisePerformanceSummary(
          type: ExerciseStepType.reverseReference,
          attemptCount: 2,
          averageScore: 0.4,
          totalMistakes: 3,
        ),
        ExercisePerformanceSummary(
          type: ExerciseStepType.listen,
          attemptCount: 2,
          averageScore: 1,
          totalMistakes: 0,
        ),
      ],
      objective: PracticeObjective.deep,
    );

    expect(feedback, contains('referencia inversa'));
    expect(feedback, contains('referencia'));
  });
}
