import 'dart:math' as math;

import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/practice/data/models/answer_evaluation_result.dart';
import 'package:memorizar/features/practice/data/models/exercise_level.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/services/text_normalizer_service.dart';

class FillOptionsChallenge {
  const FillOptionsChallenge({
    required this.words,
    required this.hiddenIndexes,
    required this.optionsByIndex,
  });

  final List<String> words;
  final List<int> hiddenIndexes;
  final Map<int, List<String>> optionsByIndex;
}

class BlockReconstructionChallenge {
  const BlockReconstructionChallenge({
    required this.correctBlocks,
    required this.shuffledBlocks,
  });

  final List<String> correctBlocks;
  final List<String> shuffledBlocks;
}

class ErrorDetectionChallenge {
  const ErrorDetectionChallenge({
    required this.words,
    required this.alteredIndexes,
    required this.displayWords,
  });

  final List<String> words;
  final List<int> alteredIndexes;
  final List<String> displayWords;
}

class CompareVersionsChallenge {
  const CompareVersionsChallenge({
    required this.versionA,
    required this.versionB,
    required this.correctVersion,
  });

  final String versionA;
  final String versionB;
  final String correctVersion;
}

class AnswerEvaluatorService {
  const AnswerEvaluatorService(this._normalizer);

  final TextNormalizerService _normalizer;

  AnswerEvaluationResult evaluate({
    required String expected,
    required String actual,
    required ExerciseLevel level,
    int? maxMistakesOverride,
  }) {
    final expectedTokens = _normalizer.tokenize(expected);
    final actualTokens = _normalizer.tokenize(actual);
    final maxMistakes = maxMistakesOverride ?? level.allowedMistakes(expectedTokens.length);
    final distance = _levenshtein(expectedTokens, actualTokens);
    final mistakes = math.max(0, distance);
    final matchedWords = expectedTokens.where(actualTokens.contains).toList();
    final missingWords = expectedTokens.where((token) => !actualTokens.contains(token)).toList();
    final score = expectedTokens.isEmpty
        ? 1.0
        : ((expectedTokens.length - mistakes) / expectedTokens.length).clamp(0.0, 1.0);
    final isCorrect = mistakes <= maxMistakes;

    return AnswerEvaluationResult(
      isCorrect: isCorrect,
      score: score,
      mistakes: mistakes,
      maxMistakes: maxMistakes,
      normalizedExpected: expectedTokens.join(' '),
      normalizedActual: actualTokens.join(' '),
      matchedWords: matchedWords,
      missingWords: missingWords,
      feedback: isCorrect
          ? 'Coincidencia dentro del margen permitido.'
          : 'Se detectaron más diferencias de las permitidas para ${level.label.toLowerCase()}.',
    );
  }

  FillOptionsChallenge buildFillOptionsChallenge({
    required Item item,
    required List<Item> deckItems,
    required ExerciseLevel level,
    required MemorizationDifficulty difficulty,
    double? hiddenFractionOverride,
  }) {
    final words = item.back.split(RegExp(r'\s+'));
    final hiddenIndexes = _hiddenIndexes(words, level, hiddenFractionOverride: hiddenFractionOverride);
    final bank = deckItems
        .expand((deckItem) => deckItem.back.split(RegExp(r'\s+')))
        .map((word) => word.replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ]'), ''))
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final optionsByIndex = <int, List<String>>{};
    for (final index in hiddenIndexes) {
      final correct = words[index];
      final normalizedCorrect = _normalizer.normalize(correct);
      final distractors = bank
          .where((candidate) => _normalizer.normalize(candidate) != normalizedCorrect)
          .take(math.max(0, difficulty.fillOptionCount - 1))
          .toList();
      final options = [...distractors, correct]..shuffle();
      optionsByIndex[index] = options;
    }

    return FillOptionsChallenge(
      words: words,
      hiddenIndexes: hiddenIndexes,
      optionsByIndex: optionsByIndex,
    );
  }

  BlockReconstructionChallenge buildBlockReconstructionChallenge(Item item) {
    final words = item.back.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final correctBlocks = <String>[];
    for (var i = 0; i < words.length; i += 3) {
      final end = math.min(i + 3, words.length);
      correctBlocks.add(words.sublist(i, end).join(' '));
    }
    final shuffledBlocks = [...correctBlocks]..shuffle();
    if (shuffledBlocks.join('|') == correctBlocks.join('|') && shuffledBlocks.length > 1) {
      final first = shuffledBlocks.removeAt(0);
      shuffledBlocks.add(first);
    }
    return BlockReconstructionChallenge(correctBlocks: correctBlocks, shuffledBlocks: shuffledBlocks);
  }

  ErrorDetectionChallenge buildErrorDetectionChallenge({
    required Item item,
    required List<Item> deckItems,
    required ExerciseLevel level,
  }) {
    final words = item.back.split(RegExp(r'\s+'));
    final eligibleIndexes = <int>[];
    for (var i = 0; i < words.length; i++) {
      final clean = words[i].replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ]'), '');
      if (clean.length > 2) {
        eligibleIndexes.add(i);
      }
    }

    final wrongCount = level == ExerciseLevel.level1 ? 1 : 2;
    final alteredIndexes = eligibleIndexes.take(wrongCount).toList();
    final bank = deckItems
        .expand((deckItem) => deckItem.back.split(RegExp(r'\s+')))
        .map((word) => word.replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ]'), ''))
        .where((word) => word.length > 2)
        .toSet()
        .toList()
      ..sort();

    final displayWords = [...words];
    for (final index in alteredIndexes) {
      final original = words[index];
      final cleanOriginal = original.replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ]'), '');
      final replacement = bank.firstWhere(
        (candidate) => _normalizer.normalize(candidate) != _normalizer.normalize(cleanOriginal),
        orElse: () => '${cleanOriginal}X',
      );
      displayWords[index] = original.replaceFirst(cleanOriginal, replacement);
    }

    return ErrorDetectionChallenge(
      words: words,
      alteredIndexes: alteredIndexes,
      displayWords: displayWords,
    );
  }

  CompareVersionsChallenge buildCompareVersionsChallenge({
    required Item item,
    required List<Item> deckItems,
  }) {
    final altered = buildErrorDetectionChallenge(
      item: item,
      deckItems: deckItems,
      level: ExerciseLevel.level1,
    ).displayWords.join(' ');

    final showCorrectFirst = item.id.hashCode.isEven;
    return CompareVersionsChallenge(
      versionA: showCorrectFirst ? item.back : altered,
      versionB: showCorrectFirst ? altered : item.back,
      correctVersion: showCorrectFirst ? 'A' : 'B',
    );
  }

  List<int> _hiddenIndexes(List<String> words, ExerciseLevel level, {double? hiddenFractionOverride}) {
    final eligibleIndexes = <int>[];
    for (var i = 0; i < words.length; i++) {
      final cleaned = words[i].replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ]'), '');
      if (cleaned.length > 2) {
        eligibleIndexes.add(i);
      }
    }
    if (eligibleIndexes.isEmpty) return const [];
    final hiddenCount = math.max(1, (eligibleIndexes.length * (hiddenFractionOverride ?? level.hiddenFraction)).ceil());
    return eligibleIndexes.take(hiddenCount).toList();
  }

  String maskWord(String word, ExerciseLevel level) {
    final clean = word.replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ]'), '');
    if (clean.isEmpty) return word;
    return word.replaceFirst(clean, '_' * clean.length);
  }

  String firstLetterOf(String word) {
    final normalized = word.replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ]'), '');
    if (normalized.isEmpty) return '';
    return normalized.substring(0, 1);
  }

  int _levenshtein(List<String> a, List<String> b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = math.min(
          math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[a.length][b.length];
  }
}
