import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';
import 'package:frontend/core/router/app_routes.dart';
import 'package:frontend/features/home/presentation/ui_screens.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    AppRoutes.register(buildAppRoutes());
    
    final store = AppStore(enableDatabasePersistence: false);
    // Build our app and trigger a frame.
    await tester.pumpWidget(AppScope(
      store: store,
      child: const MemorizarApp(),
    ));
    await tester.pump();

    // Verify that our home screen shows 'Biblia'.
    expect(find.text('Biblia'), findsOneWidget);
  });
}
