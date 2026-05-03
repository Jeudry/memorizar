import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/practice/data/models/answer_evaluation_result.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/exercise_performance_summary.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/data/models/voice_analysis_result.dart';

class ExerciseSessionState {
  const ExerciseSessionState({
    required this.queue,
    required this.steps,
    required this.currentItemIndex,
    required this.currentStepIndex,
    required this.difficulty,
    required this.objective,
    required this.cooperativePlayers,
    required this.cooperativeMode,
    required this.currentTurnIndex,
    required this.rescuePending,
    required this.turnHandoffs,
    required this.rescueCount,
    required this.isLoading,
    required this.isFinished,
    required this.completedItems,
    required this.performanceSummaries,
    this.deckId,
    this.planId,
    this.planName,
    this.lastEvaluation,
    this.latestAudioPath,
    this.latestTranscript,
    this.coachFeedback,
    this.voiceFeedback,
    this.voiceAnalysis,
    this.duelBestScore,
  });

  final List<Item> queue;
  final List<ExerciseStep> steps;
  final int currentItemIndex;
  final int currentStepIndex;
  final MemorizationDifficulty difficulty;
  final PracticeObjective objective;
  final int cooperativePlayers;
  final CooperativeMode cooperativeMode;
  final int currentTurnIndex;
  final bool rescuePending;
  final int turnHandoffs;
  final int rescueCount;
  final bool isLoading;
  final bool isFinished;
  final List<Item> completedItems;
  final List<ExercisePerformanceSummary> performanceSummaries;
  final String? deckId;
  final String? planId;
  final String? planName;
  final AnswerEvaluationResult? lastEvaluation;
  final String? latestAudioPath;
  final String? latestTranscript;
  final String? coachFeedback;
  final String? voiceFeedback;
  final VoiceAnalysisResult? voiceAnalysis;
  final double? duelBestScore;

  Item? get currentItem =>
      currentItemIndex >= 0 && currentItemIndex < queue.length ? queue[currentItemIndex] : null;

  ExerciseStep? get currentStep =>
      currentStepIndex >= 0 && currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  double get itemProgress => steps.isEmpty ? 1 : currentStepIndex / steps.length;
  double get queueProgress => queue.isEmpty ? 1 : currentItemIndex / queue.length;

  ExerciseSessionState copyWith({
    List<Item>? queue,
    List<ExerciseStep>? steps,
    int? currentItemIndex,
    int? currentStepIndex,
    MemorizationDifficulty? difficulty,
    PracticeObjective? objective,
    int? cooperativePlayers,
    CooperativeMode? cooperativeMode,
    int? currentTurnIndex,
    bool? rescuePending,
    int? turnHandoffs,
    int? rescueCount,
    bool? isLoading,
    bool? isFinished,
    List<Item>? completedItems,
    List<ExercisePerformanceSummary>? performanceSummaries,
    String? deckId,
    String? planId,
    String? planName,
    AnswerEvaluationResult? lastEvaluation,
    String? latestAudioPath,
    String? latestTranscript,
    String? coachFeedback,
    String? voiceFeedback,
    VoiceAnalysisResult? voiceAnalysis,
    double? duelBestScore,
    bool clearEvaluation = false,
    bool clearAudioPath = false,
    bool clearTranscript = false,
  }) {
    return ExerciseSessionState(
      queue: queue ?? this.queue,
      steps: steps ?? this.steps,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      difficulty: difficulty ?? this.difficulty,
      objective: objective ?? this.objective,
      cooperativePlayers: cooperativePlayers ?? this.cooperativePlayers,
      cooperativeMode: cooperativeMode ?? this.cooperativeMode,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      rescuePending: rescuePending ?? this.rescuePending,
      turnHandoffs: turnHandoffs ?? this.turnHandoffs,
      rescueCount: rescueCount ?? this.rescueCount,
      isLoading: isLoading ?? this.isLoading,
      isFinished: isFinished ?? this.isFinished,
      completedItems: completedItems ?? this.completedItems,
      performanceSummaries: performanceSummaries ?? this.performanceSummaries,
      deckId: deckId ?? this.deckId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      lastEvaluation: clearEvaluation ? null : (lastEvaluation ?? this.lastEvaluation),
      latestAudioPath: clearAudioPath ? null : (latestAudioPath ?? this.latestAudioPath),
      latestTranscript: clearTranscript ? null : (latestTranscript ?? this.latestTranscript),
      coachFeedback: coachFeedback ?? this.coachFeedback,
      voiceFeedback: voiceFeedback ?? this.voiceFeedback,
      voiceAnalysis: voiceAnalysis ?? this.voiceAnalysis,
      duelBestScore: duelBestScore ?? this.duelBestScore,
    );
  }

  factory ExerciseSessionState.initial(
    MemorizationDifficulty difficulty, {
    PracticeObjective objective = PracticeObjective.deep,
    int cooperativePlayers = 1,
    CooperativeMode cooperativeMode = CooperativeMode.solo,
  }) {
    return ExerciseSessionState(
      queue: const [],
      steps: const [],
      currentItemIndex: 0,
      currentStepIndex: 0,
      difficulty: difficulty,
      objective: objective,
      cooperativePlayers: cooperativePlayers,
      cooperativeMode: cooperativeMode,
      currentTurnIndex: 0,
      rescuePending: false,
      turnHandoffs: 0,
      rescueCount: 0,
      isLoading: true,
      isFinished: false,
      completedItems: const [],
      performanceSummaries: const [],
    );
  }
}
