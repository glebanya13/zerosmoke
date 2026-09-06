import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerosmoke/features/rating/how_to_earn_screen.dart';

void main() {
  testWidgets('HowToEarnScreen shows all reward categories', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HowToEarnScreen()),
    );

    expect(find.text('Как заработать'), findsOneWidget);
    expect(find.text('Звёзды'), findsOneWidget);
    expect(find.text('Очки'), findsOneWidget);
    expect(find.text('Монеты'), findsOneWidget);
    expect(find.text('Награды'), findsOneWidget);
  });
}
