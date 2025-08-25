// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:air_quality/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AirQualityApp());

    // Verify that the splash screen loads
    expect(find.text('Giám Sát Chất Lượng Không Khí IoT'), findsOneWidget);

    // Wait for splash screen animation
    await tester.pump(const Duration(seconds: 1));

    // Verify loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
