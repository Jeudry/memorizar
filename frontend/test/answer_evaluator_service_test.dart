import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/practice/data/models/exercise_level.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/services/answer_evaluator_service.dart';
import 'package:memorizar/features/practice/services/text_normalizer_service.dart';

void main() {
  const evaluator = AnswerEvaluatorService(TextNormalizerService());

  test('maskWord hides the full token without leaving the first letter visible', () {
    expect(evaluator.maskWord('Porque', ExerciseLevel.level1), '______');
    expect(evaluator.maskWord('mundo,', ExerciseLevel.level2), '_____,');
  });

  test('buildFillOptionsChallenge respects hidden fraction override', () {
    final item = const Item(
      id: 'b1',
      deckId: 'bible',
      front: 'Juan 3:16',
      back: 'Porque de tal manera amó Dios al mundo',
    );

    final challenge = evaluator.buildFillOptionsChallenge(
      item: item,
      deckItems: [item],
      level: ExerciseLevel.level1,
      difficulty: MemorizationDifficulty.beginner,
      hiddenFractionOverride: 0.5,
    );

    expect(challenge.hiddenIndexes, isNotEmpty);
    expect(challenge.hiddenIndexes.length, lessThan(challenge.words.length));
  });

  test('buildBlockReconstructionChallenge creates reorderable grouped blocks', () {
    final item = const Item(
      id: 'b1',
      deckId: 'bible',
      front: 'Juan 3:16',
      back: 'Porque de tal manera amó Dios al mundo que ha dado a su Hijo unigénito',
    );

    final challenge = evaluator.buildBlockReconstructionChallenge(item);

    expect(challenge.correctBlocks.length, greaterThan(1));
    expect(challenge.shuffledBlocks, unorderedEquals(challenge.correctBlocks));
  });

  test('buildErrorDetectionChallenge injects one wrong word for level1 and two for level2', () {
    final item = const Item(
      id: 'b1',
      deckId: 'bible',
      front: 'Juan 3:16',
      back: 'Porque de tal manera amó Dios al mundo',
    );

    final level1 = evaluator.buildErrorDetectionChallenge(
      item: item,
      deckItems: [item],
      level: ExerciseLevel.level1,
    );
    final level2 = evaluator.buildErrorDetectionChallenge(
      item: item,
      deckItems: [item],
      level: ExerciseLevel.level2,
    );

    expect(level1.alteredIndexes.length, 1);
    expect(level2.alteredIndexes.length, 2);
    expect(level1.displayWords.join(' '), isNot(equals(item.back)));
    expect(level2.displayWords.join(' '), isNot(equals(item.back)));
  });

  test('buildCompareVersionsChallenge returns one correct and one altered version', () {
    final item = const Item(
      id: 'b1',
      deckId: 'bible',
      front: 'Juan 3:16',
      back: 'Porque de tal manera amó Dios al mundo',
    );

    final challenge = evaluator.buildCompareVersionsChallenge(
      item: item,
      deckItems: [item],
    );

    final correctContent = challenge.correctVersion == 'A' ? challenge.versionA : challenge.versionB;
    final wrongContent = challenge.correctVersion == 'A' ? challenge.versionB : challenge.versionA;

    expect(correctContent, item.back);
    expect(wrongContent, isNot(equals(item.back)));
  });

  test('evaluate accepts custom mistake allowance for hidden voice reading', () {
    final result = evaluator.evaluate(
      expected: 'Porque de tal manera amó Dios al mundo',
      actual: 'Porque de tal manera Dios al mundo',
      level: ExerciseLevel.level1,
      maxMistakesOverride: 3,
    );

    expect(result.isCorrect, isTrue);
    expect(result.maxMistakes, 3);
  });
}
