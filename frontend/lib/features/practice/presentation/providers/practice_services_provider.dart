import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/practice/services/answer_evaluator_service.dart';
import 'package:memorizar/features/practice/services/adaptive_practice_service.dart';
import 'package:memorizar/features/practice/services/audio_practice_service.dart';
import 'package:memorizar/features/practice/services/practice_coach_service.dart';
import 'package:memorizar/features/practice/services/text_normalizer_service.dart';
import 'package:memorizar/features/practice/services/understanding_exercise_service.dart';
import 'package:memorizar/features/practice/services/voice_analysis_service.dart';

final textNormalizerProvider = Provider<TextNormalizerService>((ref) {
  return const TextNormalizerService();
});

final answerEvaluatorProvider = Provider<AnswerEvaluatorService>((ref) {
  final normalizer = ref.watch(textNormalizerProvider);
  return AnswerEvaluatorService(normalizer);
});

final audioPracticeServiceProvider = Provider<AudioPracticeService>((ref) {
  final service = AudioPracticeService();
  ref.onDispose(service.dispose);
  return service;
});

final understandingExerciseProvider = Provider<UnderstandingExerciseService>((ref) {
  final normalizer = ref.watch(textNormalizerProvider);
  return UnderstandingExerciseService(normalizer);
});

final practiceCoachProvider = Provider<PracticeCoachService>((ref) {
  return const PracticeCoachService();
});

final adaptivePracticeServiceProvider = Provider<AdaptivePracticeService>((ref) {
  return const AdaptivePracticeService();
});

final voiceAnalysisServiceProvider = Provider<VoiceAnalysisService>((ref) {
  return VoiceAnalysisService(ref.watch(textNormalizerProvider));
});
