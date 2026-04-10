import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke: MaterialApp renders without errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('بيان'))),
    );
    expect(find.text('بيان'), findsOneWidget);
  });
}
