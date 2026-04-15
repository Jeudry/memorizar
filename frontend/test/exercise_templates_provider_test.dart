import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_templates_provider.dart';

void main() {
  test('beginner template includes hidden voice reading before fill options', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final template = container.read(exerciseTemplatesProvider)[MemorizationDifficulty.beginner]!;
    final ordered = template.orderedStepsForSession(Random(1));
    final hiddenVoiceIndex = ordered.indexWhere((step) => step.type == ExerciseStepType.readHiddenWithVoice);
    final fillIndex = ordered.indexWhere((step) => step.type == ExerciseStepType.fillOptions);

    expect(hiddenVoiceIndex, greaterThanOrEqualTo(0));
    expect(hiddenVoiceIndex, lessThan(fillIndex));
    expect(ordered[hiddenVoiceIndex].hiddenFractionOverride, 0.5);
    expect(ordered[hiddenVoiceIndex].allowedMistakesRatioOverride, 0.3);
  });

  test('beginner template includes block reconstruction early and error detection before final voice', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final template = container.read(exerciseTemplatesProvider)[MemorizationDifficulty.beginner]!;
    final ordered = template.orderedStepsForSession(Random(7));
    final reconstructIndex = ordered.indexWhere((step) => step.type == ExerciseStepType.reconstructBlocks);
    final readAlongIndex = ordered.indexWhere((step) => step.type == ExerciseStepType.readAlong);
    final errorIndexes = [
      for (var i = 0; i < ordered.length; i++)
        if (ordered[i].type == ExerciseStepType.detectErrors) i,
    ];
    final compareIndex = ordered.indexWhere((step) => step.type == ExerciseStepType.compareVersions);
    final understandingIndex = ordered.indexWhere((step) => step.type == ExerciseStepType.understandingQuestion);
    final finalVoiceIndex = ordered.indexWhere((step) => step.type == ExerciseStepType.reciteFromMemoryVoice);

    expect(reconstructIndex, greaterThan(readAlongIndex));
    expect(reconstructIndex, lessThan(ordered.indexWhere((step) => step.type == ExerciseStepType.recordReading)));
    expect(errorIndexes.length, 2);
    expect(compareIndex, greaterThanOrEqualTo(template.fixedPrefixCount));
    expect(understandingIndex, greaterThanOrEqualTo(template.fixedPrefixCount));
    expect(errorIndexes.every((index) => index < finalVoiceIndex), isTrue);
  });

  test('expert template keeps the direct exam flow without hidden voice reading', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final template = container.read(exerciseTemplatesProvider)[MemorizationDifficulty.expert]!;
    expect(template.steps.any((step) => step.type == ExerciseStepType.readHiddenWithVoice), isFalse);
    expect(template.steps.any((step) => step.type == ExerciseStepType.reconstructBlocks), isTrue);
    expect(template.steps.any((step) => step.type == ExerciseStepType.detectErrors), isTrue);
    expect(template.steps.any((step) => step.type == ExerciseStepType.compareVersions), isTrue);
    expect(template.steps.any((step) => step.type == ExerciseStepType.understandingQuestion), isTrue);
  });

  test('session ordering keeps fixed prefix and suffix while varying the middle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final template = container.read(exerciseTemplatesProvider)[MemorizationDifficulty.beginner]!;
    final orderedA = template.orderedStepsForSession(Random(1));
    final orderedB = template.orderedStepsForSession(Random(2));

    expect(
      orderedA.take(template.fixedPrefixCount).map((step) => step.type).toList(),
      orderedB.take(template.fixedPrefixCount).map((step) => step.type).toList(),
    );
    expect(
      orderedA.last.type,
      ExerciseStepType.reciteFromMemoryVoice,
    );
    expect(
      orderedB.last.type,
      ExerciseStepType.reciteFromMemoryVoice,
    );
    expect(
      orderedA.skip(template.fixedPrefixCount).take(orderedA.length - template.fixedPrefixCount - template.fixedSuffixCount).map((step) => step.type).toList(),
      isNot(
        orderedB
            .skip(template.fixedPrefixCount)
            .take(orderedB.length - template.fixedPrefixCount - template.fixedSuffixCount)
            .map((step) => step.type)
            .toList(),
      ),
    );
  });
}
