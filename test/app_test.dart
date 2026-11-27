import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/main.dart';

void main() {
  group('MainMenuScreen (SCRUM-36)', () {
    testWidgets('start standaard met 1 d6 in de pool', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.pumpAndSettle();
      expect(find.text('TopDice'), findsOneWidget);
      expect(find.text('Dobbelstenen'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('pool-count-6'))).data,
          '1');
      expect(tester.widget<Text>(find.byKey(const Key('pool-count-4'))).data,
          '0');
      expect(tester.widget<Text>(find.byKey(const Key('pool-total'))).data,
          '1 van 12 dobbelstenen');
    });

    testWidgets('per type is een eigen aantal te kiezen', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-6')));
      await tester.pump();

      expect(tester.widget<Text>(find.byKey(const Key('pool-count-4'))).data,
          '2');
      expect(tester.widget<Text>(find.byKey(const Key('pool-count-6'))).data,
          '2');

      await tester.tap(find.byKey(const Key('remove-4')));
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('pool-count-4'))).data,
          '1');
    });

    testWidgets('"Let\'s roll" is uitgeschakeld bij een lege pool',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('remove-6')));
      await tester.pump();

      expect(
          tester.widget<FilledButton>(find.byKey(const Key('lets-roll')))
              .onPressed,
          isNull,
          reason: 'Zonder dobbelstenen kan er niet gegooid worden.');
    });

    testWidgets('de pool is begrensd op 12 dobbelstenen', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.pumpAndSettle();

      for (var i = 0; i < 11; i++) {
        await tester.tap(find.byKey(const Key('add-6')));
        await tester.pump();
      }
      expect(tester.widget<Text>(find.byKey(const Key('pool-total'))).data,
          '12 van 12 dobbelstenen');
      expect(tester.widget<IconButton>(find.byKey(const Key('add-6'))).onPressed,
          isNull,
          reason: 'Bij de begrenzing doet + niets meer.');
    });

    testWidgets('een gemengde worp toont elke steen met zijn eigen type',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.pumpAndSettle();

      // Pool: 2 d4 + 1 d6.
      await tester.tap(find.byKey(const Key('add-4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-4')));
      await tester.pump();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text('2d4 + 1d6'), findsOneWidget);
      expect(find.byType(DieFace), findsNWidgets(3));
      expect(
          find.byWidgetPredicate(
              (w) => w is DieFace && w.sides == 4),
          findsNWidgets(2));
      expect(
          find.byWidgetPredicate(
              (w) => w is DieFace && w.sides == 6),
          findsOneWidget);
    });

    testWidgets('drie d6 gooien geeft de bekende Random(1)-reeks',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.pumpAndSettle();

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('add-6')));
        await tester.pump();
      }
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      // Random(1) levert met d6 de reeks 1, 4, 6: ogen i.p.v. nummers.
      expect(find.byType(DieFace), findsNWidgets(3));
      expect(find.byKey(const Key('pip')), findsNWidgets(1 + 4 + 6));
      expect(find.textContaining('Totaal: 11'), findsOneWidget);
    });
  });

  group('ResultScreen (SCRUM-36)', () {
    testWidgets('rolls again without leaving the screen', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Andere dobbelstenen'));
      await tester.pumpAndSettle();
      expect(find.byType(MainMenuScreen), findsOneWidget);
    });
  });
}
