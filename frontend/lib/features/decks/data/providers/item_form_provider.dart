import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/db/app_database.dart' hide Item;
import 'package:memorizar/features/decks/data/models/item.dart' as model;
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:drift/drift.dart';

class ItemFormState {
  final String front;
  final String back;
  final bool hasBibleMeta;
  final String book;
  final int? chapter;
  final int? verse;
  final bool isSaving;

  const ItemFormState({
    this.front = '',
    this.back = '',
    this.hasBibleMeta = false,
    this.book = '',
    this.chapter,
    this.verse,
    this.isSaving = false,
  });

  ItemFormState copyWith({
    String? front,
    String? back,
    bool? hasBibleMeta,
    String? book,
    int? chapter,
    int? verse,
    bool? isSaving,
  }) {
    return ItemFormState(
      front: front ?? this.front,
      back: back ?? this.back,
      hasBibleMeta: hasBibleMeta ?? this.hasBibleMeta,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  bool get isValid => front.trim().isNotEmpty && back.trim().isNotEmpty;
}

class ItemFormNotifier extends StateNotifier<ItemFormState> {
  ItemFormNotifier(this._deckId, this._item, this._ref) : super(ItemFormState(
    front: _item?.front ?? '',
    back: _item?.back ?? '',
    hasBibleMeta: _item?.book != null,
    book: _item?.book ?? '',
    chapter: _item?.chapter,
    verse: _item?.verse,
  ));

  final String _deckId;
  final model.Item? _item;
  final Ref _ref;

  bool get isEditing => _item != null;

  void setFront(String v) => state = state.copyWith(front: v);
  void setBack(String v) => state = state.copyWith(back: v);
  void setHasBibleMeta(bool v) => state = state.copyWith(hasBibleMeta: v);
  void setBook(String v) => state = state.copyWith(book: v);
  void setChapter(String v) => state = state.copyWith(chapter: int.tryParse(v));
  void setVerse(String v) => state = state.copyWith(verse: int.tryParse(v));

  Future<bool> save() async {
    if (!state.isValid) return false;
    state = state.copyWith(isSaving: true);

    try {
      final db = _ref.read(databaseProvider);
      final itemId = _item?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      await db.upsertItem(ItemsCompanion(
        id: Value(itemId),
        deckId: Value(_deckId),
        front: Value(state.front.trim()),
        back: Value(state.back.trim()),
        book: Value(state.hasBibleMeta && state.book.isNotEmpty ? state.book : null),
        chapter: Value(state.hasBibleMeta ? state.chapter : null),
        verse: Value(state.hasBibleMeta ? state.verse : null),
        easeFactor: Value(_item?.easeFactor ?? 2.5),
        interval: Value(_item?.interval ?? 0),
        repetitions: Value(_item?.repetitions ?? 0),
        nextReviewAt: Value(_item?.nextReviewAt),
        lastReviewedAt: Value(_item?.lastReviewedAt),
      ));

      _ref.invalidate(itemsForDeckProvider(_deckId));
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final itemFormProvider = StateNotifierProvider.autoDispose
    .family<ItemFormNotifier, ItemFormState, (String, model.Item?)>(
  (ref, params) {
    final (deckId, item) = params;
    return ItemFormNotifier(deckId, item, ref);
  },
);