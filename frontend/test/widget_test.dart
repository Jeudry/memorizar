import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemorizarApp());
    await tester.pumpAndSettle();

    // Verify that our home screen shows 'Hola Ana'.
    expect(find.text('Hola Ana'), findsOneWidget);
  });
}
