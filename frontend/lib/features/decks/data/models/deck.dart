import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck.freezed.dart';
part 'deck.g.dart';

@freezed
class Deck with _$Deck {
  const factory Deck({
    required String id,
    required String name,
    required String description,
    required DeckType type,
    required int accentColorIndex,
    required int totalItems,
    required int dueToday,
    required int learned,
    required DateTime createdAt,
    String? emoji,
  }) = _Deck;

  factory Deck.fromJson(Map<String, dynamic> json) => _$DeckFromJson(json);
}

enum DeckType {
  bible,
  language,
  general,
}

extension DeckTypeLabel on DeckType {
  String get label {
    switch (this) {
      case DeckType.bible:
        return 'Biblia';
      case DeckType.language:
        return 'Idioma';
      case DeckType.general:
        return 'General';
    }
  }
}
