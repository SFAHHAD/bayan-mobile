import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const BayanApp());
    await tester.pump();
    expect(find.text('بَيَان'), findsOneWidget);
  });
}
