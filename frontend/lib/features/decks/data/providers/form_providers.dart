import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/db/app_database.dart' hide Deck;
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:drift/drift.dart';

class DeckFormState {
  final String name;
  final String description;
  final String emoji;
  final DeckType type;
  final int accentColorIndex;
  final bool isSaving;

  const DeckFormState({
    this.name = '',
    this.description = '',
    this.emoji = '',
    this.type = DeckType.general,
    this.accentColorIndex = 0,
    this.isSaving = false,
  });

  DeckFormState copyWith({
    String? name,
    String? description,
    String? emoji,
    DeckType? type,
    int? accentColorIndex,
    bool? isSaving,
  }) {
    return DeckFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  bool get isValid => name.trim().isNotEmpty;
}

class DeckFormNotifier extends StateNotifier<DeckFormState> {
  DeckFormNotifier(this._deck, this._ref) : super(DeckFormState(
    name: _deck?.name ?? '',
    description: _deck?.description ?? '',
    emoji: _deck?.emoji ?? '',
    type: _deck?.type ?? DeckType.general,
    accentColorIndex: _deck?.accentColorIndex ?? 0,
  ));

  final Deck? _deck;
  final Ref _ref;

  bool get isEditing => _deck != null;

  void setName(String v) => state = state.copyWith(name: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setEmoji(String v) => state = state.copyWith(emoji: v);
  void setType(DeckType v) => state = state.copyWith(type: v);
  void setAccent(int v) => state = state.copyWith(accentColorIndex: v);

  Future<bool> save() async {
    if (!state.isValid) return false;
    state = state.copyWith(isSaving: true);

    try {
      final db = _ref.read(databaseProvider);
      final deckId = _deck?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      await db.upsertDeck(DecksCompanion(
        id: Value(deckId),
        name: Value(state.name.trim()),
        description: Value(state.description.trim()),
        type: Value(state.type.name),
        emoji: Value(state.emoji.isEmpty ? null : state.emoji),
        accentColorIndex: Value(state.accentColorIndex),
        createdAt: Value(_deck?.createdAt ?? DateTime.now()),
      ));

      _ref.invalidate(decksProvider);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final deckFormProvider = StateNotifierProvider.autoDispose
    .family<DeckFormNotifier, DeckFormState, Deck?>(
  (ref, deck) => DeckFormNotifier(deck, ref),
);