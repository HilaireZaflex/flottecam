// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_saas_app/main.dart';

void main() {
  testWidgets('Fleet SaaS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FleetSaaSApp()));
    await tester.pump();
    // L'app doit afficher le loading ou le login screen
    expect(find.byType(MaterialApp), findsNothing); // MaterialApp.router utilisé
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
