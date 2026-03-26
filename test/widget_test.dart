import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App boots without error', (WidgetTester tester) async {
    await tester.pumpWidget(const EntrevistatApp());
    expect(find.byType(EntrevistatApp), findsOneWidget);
  });
}
