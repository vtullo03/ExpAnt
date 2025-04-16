import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_expant1/main.dart';

void main() {
  testWidgets('Message screen loads with title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Check that the app bar has the text 'messages'
    expect(find.text('messages'), findsOneWidget);

    // Check that at least one contact name appears
    expect(find.text('John Smith'), findsOneWidget);
  });
}
