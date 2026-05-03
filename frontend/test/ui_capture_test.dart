import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/features/social/presentation/screens/social_screen.dart';

void main() {
  testWidgets('social screen renders login state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: SocialScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Social'), findsOneWidget);
    expect(find.textContaining('Google'), findsOneWidget);
  });
}
