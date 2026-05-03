import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/exercise_level.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/social/data/models/social_models.dart';
import 'package:memorizar/features/social/services/social_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

final onboardingCompletedProvider = StateProvider<bool>((ref) => false);
final smartReminderOptInProvider =
    StateNotifierProvider<SmartReminderOptInNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SmartReminderOptInNotifier(prefs);
});

final reinforcementProgressProvider =
    StateNotifierProvider<ReinforcementProgressNotifier, ReinforcementProgressState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReinforcementProgressNotifier(prefs);
});

final cooperativeFollowUpProvider =
    StateNotifierProvider<CooperativeFollowUpNotifier, CooperativeFollowUpState?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CooperativeFollowUpNotifier(prefs);
});

final practiceSessionDraftProvider =
    StateNotifierProvider<PracticeSessionDraftNotifier, PracticeSessionDraft?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PracticeSessionDraftNotifier(prefs);
});

final socialSessionProvider =
    StateNotifierProvider<SocialSessionNotifier, SocialSessionState?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = SocialApiService();
  return SocialSessionNotifier(prefs, service);
});

class ReinforcementProgressState {
  const ReinforcementProgressState({
    required this.completedRoutesByDeck,
    required this.history,
  });

  final Map<String, Set<String>> completedRoutesByDeck;
  final List<ReinforcementHistoryEntry> history;
}

class SmartReminderOptInNotifier extends StateNotifier<bool> {
  SmartReminderOptInNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(prefs.getBool(_storageKey) ?? false);

  SmartReminderOptInNotifier.test(super.initial) : _prefs = null;

  static const _storageKey = 'memorizar_smart_reminders_opt_in';
  final SharedPreferences? _prefs;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_storageKey, enabled);
  }
}

class ReinforcementHistoryEntry {
  const ReinforcementHistoryEntry({
    required this.deckId,
    required this.routeLabel,
    required this.completedAt,
  });

  final String deckId;
  final String routeLabel;
  final DateTime completedAt;
}

class ReinforcementProgressNotifier extends StateNotifier<ReinforcementProgressState> {
  ReinforcementProgressNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_load(prefs));

  ReinforcementProgressNotifier.test(super.initial)
      : _prefs = null,
        super();

  static const _storageKey = 'memorizar_reinforcement_completed_routes';
  static const _historyStorageKey = 'memorizar_reinforcement_history';

  final SharedPreferences? _prefs;

  Future<void> markRouteCompleted({
    required String deckId,
    required String routeLabel,
  }) async {
    final next = <String, Set<String>>{
      for (final entry in state.completedRoutesByDeck.entries) entry.key: {...entry.value},
    };
    next.putIfAbsent(deckId, () => <String>{}).add(routeLabel);
    final history = [
      ReinforcementHistoryEntry(
        deckId: deckId,
        routeLabel: routeLabel,
        completedAt: DateTime.now(),
      ),
      ...state.history,
    ].take(8).toList();
    state = ReinforcementProgressState(
      completedRoutesByDeck: next,
      history: history,
    );
    await _persist();
  }

  Future<void> resetDeck(String deckId) async {
    final next = <String, Set<String>>{
      for (final entry in state.completedRoutesByDeck.entries)
        if (entry.key != deckId) entry.key: {...entry.value},
    };
    state = ReinforcementProgressState(
      completedRoutesByDeck: next,
      history: state.history,
    );
    await _persist();
  }

  static ReinforcementProgressState _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final parsed = <String, Set<String>>{};
    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      parsed.putIfAbsent(parts[0], () => <String>{}).add(parts[1]);
    }
    final rawHistory = prefs.getStringList(_historyStorageKey) ?? const <String>[];
    final history = <ReinforcementHistoryEntry>[];
    for (final entry in rawHistory) {
      final parts = entry.split('|');
      if (parts.length != 3) continue;
      final parsedDate = DateTime.tryParse(parts[2]);
      if (parsedDate == null) continue;
      history.add(
        ReinforcementHistoryEntry(
          deckId: parts[0],
          routeLabel: parts[1],
          completedAt: parsedDate,
        ),
      );
    }
    return ReinforcementProgressState(
      completedRoutesByDeck: parsed,
      history: history,
    );
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final values = <String>[
      for (final entry in state.completedRoutesByDeck.entries)
        for (final label in entry.value) '${entry.key}|$label',
    ];
    final historyValues = <String>[
      for (final entry in state.history)
        '${entry.deckId}|${entry.routeLabel}|${entry.completedAt.toIso8601String()}',
    ];
    await prefs.setStringList(_storageKey, values);
    await prefs.setStringList(_historyStorageKey, historyValues);
  }
}

class CooperativeFollowUpState {
  const CooperativeFollowUpState({
    required this.deckId,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String deckId;
  final String title;
  final String message;
  final DateTime createdAt;
}

class CooperativeFollowUpNotifier extends StateNotifier<CooperativeFollowUpState?> {
  CooperativeFollowUpNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_load(prefs));

  CooperativeFollowUpNotifier.test(super.initial) : _prefs = null;

  static const _storageKey = 'memorizar_cooperative_follow_up';
  final SharedPreferences? _prefs;

  Future<void> saveFromSession({
    required String deckId,
    required CooperativeMode mode,
    required double averageScore,
    required int rescueCount,
  }) async {
    if (mode == CooperativeMode.solo) return;
    final next = switch (mode) {
      CooperativeMode.solo => null,
      CooperativeMode.rescue => averageScore >= 0.82 && rescueCount <= 1
          ? const (
              title: 'Próxima dinámica sugerida',
              message: 'Ya casi no necesitan rescates. La próxima prueben Relevo para ganar continuidad.',
            )
          : const (
              title: 'Próxima dinámica sugerida',
              message: 'Repitan Rescate una ronda más para que el grupo se siga apoyando cuando alguien se trabe.',
            ),
      CooperativeMode.relay => averageScore >= 0.86
          ? const (
              title: 'Próxima dinámica sugerida',
              message: 'La próxima prueben Cadena: ya tienen base para enlazar la memoria paso por paso.',
            )
          : const (
              title: 'Próxima dinámica sugerida',
              message: 'Mantengan Relevo una sesión más para estabilizar el ritmo del grupo.',
            ),
      CooperativeMode.chain => averageScore >= 0.78
          ? const (
              title: 'Próxima dinámica sugerida',
              message: 'Cadena les está funcionando. La próxima pueden subir dificultad o intentar modo eco.',
            )
          : const (
              title: 'Próxima dinámica sugerida',
              message: 'Vuelvan a Relevo una sesión corta para recuperar fluidez antes de encadenar tanto.',
            ),
    };

    if (next == null) return;
    final entry = CooperativeFollowUpState(
      deckId: deckId,
      title: next.title,
      message: next.message,
      createdAt: DateTime.now(),
    );
    state = entry;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setStringList(_storageKey, [
      entry.deckId,
      entry.title,
      entry.message,
      entry.createdAt.toIso8601String(),
    ]);
  }

  Future<void> clear() async {
    state = null;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_storageKey);
  }

  static CooperativeFollowUpState? _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_storageKey);
    if (raw == null || raw.length != 4) return null;
    final createdAt = DateTime.tryParse(raw[3]);
    if (createdAt == null) return null;
    return CooperativeFollowUpState(
      deckId: raw[0],
      title: raw[1],
      message: raw[2],
      createdAt: createdAt,
    );
  }
}

class PracticeSessionDraft {
  const PracticeSessionDraft({
    required this.deckId,
    required this.difficulty,
    required this.objective,
    required this.weakOnly,
    required this.cooperativePlayers,
    required this.cooperativeMode,
    required this.itemIds,
    required this.steps,
    required this.currentItemIndex,
    required this.currentStepIndex,
    required this.currentTurnIndex,
    required this.turnHandoffs,
    required this.rescueCount,
    required this.updatedAt,
    this.planId,
    this.itemId,
    this.planName,
    this.latestTranscript,
    this.latestAudioPath,
  });

  final String deckId;
  final MemorizationDifficulty difficulty;
  final PracticeObjective objective;
  final bool weakOnly;
  final int cooperativePlayers;
  final CooperativeMode cooperativeMode;
  final List<String> itemIds;
  final List<ExerciseStep> steps;
  final int currentItemIndex;
  final int currentStepIndex;
  final int currentTurnIndex;
  final int turnHandoffs;
  final int rescueCount;
  final DateTime updatedAt;
  final String? planId;
  final String? itemId;
  final String? planName;
  final String? latestTranscript;
  final String? latestAudioPath;

  List<String> serialize() {
    return [
      deckId,
      difficulty.name,
      objective.name,
      weakOnly.toString(),
      cooperativePlayers.toString(),
      cooperativeMode.name,
      itemIds.join(','),
      steps
          .map(
            (step) => [
              step.type.storageValue,
              step.level?.name ?? '',
              step.instruction.replaceAll('|', '/'),
            ].join('|'),
          )
          .join('~'),
      currentItemIndex.toString(),
      currentStepIndex.toString(),
      currentTurnIndex.toString(),
      turnHandoffs.toString(),
      rescueCount.toString(),
      updatedAt.toIso8601String(),
      planId ?? '',
      itemId ?? '',
      planName ?? '',
      latestTranscript ?? '',
      latestAudioPath ?? '',
    ];
  }

  static PracticeSessionDraft? deserialize(List<String>? raw) {
    if (raw == null || raw.length < 19) return null;
    final updatedAt = DateTime.tryParse(raw[13]);
    if (updatedAt == null) return null;
    final steps = raw[7].isEmpty
        ? const <ExerciseStep>[]
        : raw[7].split('~').map((encoded) {
            final parts = encoded.split('|');
            final type = ExerciseStepType.values.firstWhere(
              (value) => value.storageValue == parts[0],
              orElse: () => ExerciseStepType.fillOptions,
            );
            final levelName = parts.length > 1 ? parts[1] : '';
            return ExerciseStep(
              type: type,
              level: levelName.isEmpty
                  ? null
                  : ExerciseLevel.values.firstWhere(
                      (value) => value.name == levelName,
                      orElse: () => ExerciseLevel.level1,
                    ),
              instruction: parts.length > 2 ? parts[2] : type.label,
            );
          }).toList();
    return PracticeSessionDraft(
      deckId: raw[0],
      difficulty: MemorizationDifficulty.values.firstWhere(
        (value) => value.name == raw[1],
        orElse: () => MemorizationDifficulty.beginner,
      ),
      objective: PracticeObjective.values.firstWhere(
        (value) => value.name == raw[2],
        orElse: () => PracticeObjective.deep,
      ),
      weakOnly: raw[3] == 'true',
      cooperativePlayers: int.tryParse(raw[4]) ?? 1,
      cooperativeMode: CooperativeMode.values.firstWhere(
        (value) => value.name == raw[5],
        orElse: () => CooperativeMode.solo,
      ),
      itemIds: raw[6].isEmpty ? const [] : raw[6].split(','),
      steps: steps,
      currentItemIndex: int.tryParse(raw[8]) ?? 0,
      currentStepIndex: int.tryParse(raw[9]) ?? 0,
      currentTurnIndex: int.tryParse(raw[10]) ?? 0,
      turnHandoffs: int.tryParse(raw[11]) ?? 0,
      rescueCount: int.tryParse(raw[12]) ?? 0,
      updatedAt: updatedAt,
      planId: raw[14].isEmpty ? null : raw[14],
      itemId: raw[15].isEmpty ? null : raw[15],
      planName: raw[16].isEmpty ? null : raw[16],
      latestTranscript: raw[17].isEmpty ? null : raw[17],
      latestAudioPath: raw[18].isEmpty ? null : raw[18],
    );
  }
}

class PracticeSessionDraftNotifier extends StateNotifier<PracticeSessionDraft?> {
  PracticeSessionDraftNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(PracticeSessionDraft.deserialize(prefs.getStringList(_storageKey)));

  PracticeSessionDraftNotifier.test(super.initial) : _prefs = null;

  static const _storageKey = 'memorizar_practice_session_draft';
  final SharedPreferences? _prefs;

  Future<void> save(PracticeSessionDraft draft) async {
    state = draft;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setStringList(_storageKey, draft.serialize());
  }

  Future<void> clear() async {
    state = null;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_storageKey);
  }
}

class SocialSessionNotifier extends StateNotifier<SocialSessionState?> {
  SocialSessionNotifier(SharedPreferences prefs, SocialApiService service)
      : _prefs = prefs,
        _service = service,
        super(_load(prefs));

  SocialSessionNotifier.test(super.initial)
      : _prefs = null,
        _service = SocialApiService();

  static const _storageKey = 'memorizar_social_session';

  final SharedPreferences? _prefs;
  final SocialApiService _service;

  Future<void> login({
    required String provider,
    String? providerUserId,
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    final session = await _service.login(
      provider: provider,
      providerUserId: providerUserId ?? '$provider:${email.trim().toLowerCase()}',
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    state = session;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_storageKey, session.serialize());
  }

  Future<void> requestFriend(String userId) async {
    final session = state;
    if (session == null) return;
    await _service.requestFriend(
      token: session.token,
      friendUserId: userId,
    );
  }

  Future<void> acceptFriend(String friendshipId) async {
    final session = state;
    if (session == null) return;
    await _service.acceptFriend(
      token: session.token,
      friendshipId: friendshipId,
    );
  }

  Future<void> logout() async {
    state = null;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_storageKey);
  }

  static SocialSessionState? _load(SharedPreferences prefs) {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return SocialSessionState.deserialize(raw);
    } catch (_) {
      return null;
    }
  }
}
