// Basic Flutter widget smoke test.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EntrevistatApp());

    // Pump enough time for the async redirect, entrance animations,
    // and all FloatingGlassCard delayed futures to fire.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    // The landing screen renders the app title
    expect(find.text("Entrevista't"), findsOneWidget);
  });
}
