import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String deckId,
    required String front,
    required String back,
    // SRS fields (SM-2)
    @Default(2.5) double easeFactor,
    @Default(0) int interval,
    @Default(0) int repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    // Bible-specific metadata (null for non-bible decks)
    String? book,
    int? chapter,
    int? verse,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
}

extension ItemReviewState on Item {
  bool get isDue {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  bool get isNew => repetitions == 0;
}
