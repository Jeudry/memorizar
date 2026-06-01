import '/Users/sargon/Documents/Coding/Memorizar/frontend/lib/core/app_state.dart';

void main() {
  final store = AppStore();
  final text = '''
Den gracias al Señor, porque Él es bueno;
Porque para siempre es Su misericordia.
2 Díganlo los redimidos del Señor,
A quienes ha redimido de la mano del adversario,
''';
  final cards = store.segmentContent(text);
  print('Cards length: ' + cards.length.toString());
  for (var i = 0; i < cards.length; i++) {
    print('Card ' + (i + 1).toString() + ': ' + cards[i].front + ' -> ' + cards[i].back);
  }
}
