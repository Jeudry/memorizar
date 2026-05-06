import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
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
