import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/features/cards/services/cards_session_service.dart';
import 'package:memorizar/features/decks/data/models/item.dart';

void main() {
  const service = CardsSessionService();

  final items = List.generate(
    6,
    (index) => Item(
      id: 'i$index',
      deckId: 'bible',
      front: 'Genesis 1:${index + 1}',
      back: 'Contenido ${index + 1}',
    ),
  );

  test('selectFlashcards keeps a small subset', () {
    final flashcards = service.selectFlashcards(items, count: 5);
    expect(flashcards.length, 5);
    expect(flashcards.first.id, 'i0');
  });

  test('buildMatchingChallenge uses nearby items only', () {
    final challenge = service.buildMatchingChallenge(items);
    expect(challenge.items.length, 4);
    expect(challenge.contents.length, 4);
    expect(challenge.contents.toSet(), challenge.items.map((item) => item.back).toSet());
  });

  test('buildIntruderChallenge includes one outsider', () {
    final challenge = service.buildIntruderChallenge(items);
    expect(challenge.options.length, 5);
    expect(challenge.options.any((item) => item.id == challenge.intruderId), isTrue);
  });
}
