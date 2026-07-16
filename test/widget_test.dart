// Smoke test dasar untuk apkabsensi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apkabsensi/config.dart';

void main() {
  testWidgets('App theme builds', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.build(),
      home: const Scaffold(body: Center(child: Text('Absensi'))),
    ));
    expect(find.text('Absensi'), findsOneWidget);
  });
}
