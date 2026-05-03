import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_templates_provider.dart';

void main() {
  test('beginner template contains the expected guided steps', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final template = container.read(exerciseTemplatesProvider)[MemorizationDifficulty.beginner]!;
    final types = template.steps.map((step) => step.type).toList();

    expect(types, contains(ExerciseStepType.listen));
    expect(types, contains(ExerciseStepType.readAlong));
    expect(types, contains(ExerciseStepType.readHiddenWithVoice));
    expect(types, contains(ExerciseStepType.fillOptions));
    expect(types, contains(ExerciseStepType.reciteFromMemoryVoice));
  });

  test('expert template avoids hidden voice reading but keeps hard checks', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final template = container.read(exerciseTemplatesProvider)[MemorizationDifficulty.expert]!;
    final types = template.steps.map((step) => step.type).toList();

    expect(types, isNot(contains(ExerciseStepType.readHiddenWithVoice)));
    expect(types, contains(ExerciseStepType.compareVersions));
    expect(types, contains(ExerciseStepType.detectErrors));
    expect(types, contains(ExerciseStepType.totalExam));
  });

  test('session ordering preserves suffix and varies the middle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final template = container.read(exerciseTemplatesProvider)[MemorizationDifficulty.beginner]!;
    final orderedA = template.orderedStepsForSession(Random(1));
    final orderedB = template.orderedStepsForSession(Random(2));

    expect(orderedA.last.type, ExerciseStepType.reciteFromMemoryVoice);
    expect(orderedB.last.type, ExerciseStepType.reciteFromMemoryVoice);
    expect(
      orderedA.map((step) => step.type).toList(),
      isNot(orderedB.map((step) => step.type).toList()),
    );
  });
}
