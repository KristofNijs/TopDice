import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/main.dart';

void main() {
  group('MainMenuScreen', () {
    testWidgets('starts with one six-sided die selected', (tester) async {
      final dice = DiceApp(randomFactory: () => Random(1));
      await tester.pumpWidget(dice);
      expect(find.text('TopDice'), findsOneWidget);
      expect(find.text('Aantal dobbelstenen'), findsOneWidget);
      expect(find.text('Ogen per dobbelsteen'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('6'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue);
    });

    testWidgets('increases the number of dice when + is tapped', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('selecting a different number of eyes updates the choice',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.text('20'));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('20'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue);
    });

    testWidgets('"Let\'s roll" navigates to the result screen showing the rolled dice',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      // Random(1) levert met d6 de reeks 1, 4, 6.
      // Random(1) levert met d6 de reeks 1, 4, 6.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.textContaining('Totaal: 11'), findsOneWidget);
    });
  });

  group('ResultScreen', () {
    testWidgets('rolls again without leaving the screen', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opnieuw gooien'));
      await tester.pumpAndSettle();
      // randomFactory maakt per worp een nieuwe Random(1): zelfde uitkomst.
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byType(DieFace), findsOneWidget);
    });

    testWidgets('returns to the menu with the back button', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Andere dobbelstenen'));
      await tester.pumpAndSettle();
      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('shows the number of dice that was configured', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(2)));
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      // Three dice configured: three die faces plus one total line.
      expect(find.byType(DieFace), findsNWidgets(3));
    });
  });
}
