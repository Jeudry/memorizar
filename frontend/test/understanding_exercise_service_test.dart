import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/practice/services/text_normalizer_service.dart';
import 'package:memorizar/features/practice/services/understanding_exercise_service.dart';

void main() {
  const service = UnderstandingExerciseService(TextNormalizerService());

  test('buildQuestion uses reference question for bible items', () {
    const item = Item(
      id: 'b1',
      deckId: 'bible',
      front: 'Juan 3:16',
      back: 'Porque de tal manera amó Dios al mundo',
      book: 'Juan',
      chapter: 3,
      verse: 16,
    );

    const other = Item(
      id: 'b2',
      deckId: 'bible',
      front: 'Salmo 119:11',
      back: 'En mi corazón he guardado tus dichos',
      book: 'Salmos',
      chapter: 119,
      verse: 11,
    );

    final challenge = service.buildQuestion(item: item, deckItems: [item, other]);

    expect(challenge.question, contains('referencia'));
    expect(challenge.correctAnswer, item.front);
    expect(challenge.options, contains(item.front));
  });

  test('buildQuestion falls back to central idea question for generic items', () {
    const item = Item(
      id: 'g1',
      deckId: 'general',
      front: 'Ley de Newton',
      back: 'La fuerza es igual a la masa por la aceleración',
    );

    const other = Item(
      id: 'g2',
      deckId: 'general',
      front: 'Ley de Ohm',
      back: 'El voltaje es igual a la corriente por la resistencia',
    );

    final challenge = service.buildQuestion(item: item, deckItems: [item, other]);

    expect(challenge.question, contains('idea central'));
    expect(challenge.correctAnswer, contains('Habla principalmente'));
    expect(challenge.options.length, greaterThanOrEqualTo(2));
  });
}
