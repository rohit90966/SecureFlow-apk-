import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:last_final/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PasswordManagerApp());

    // Verify that the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}