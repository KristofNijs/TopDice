import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/casino_theme.dart';
import 'package:topdice/dice/dice_shape.dart';
import 'package:topdice/main.dart';

double _relativeLuminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// Contrastverhouding volgens WCAG 2.1 (1.0 tot 21.0).
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lightest = math.max(la, lb);
  final darkest = math.min(la, lb);
  return (lightest + 0.05) / (darkest + 0.05);
}

void main() {
  group('DiceShape (SCRUM-28)', () {
    test('elk ondersteund type heeft een eigen vorm', () {
      for (final sides in [4, 6, 8, 10, 12, 20]) {
        expect(DiceShape.supports(sides), isTrue,
            reason: 'd$sides hoort een vormgetrouwe graphic te hebben.');
      }
    });

    test('niet-ondersteunde types hebben geen vorm', () {
      expect(DiceShape.supports(2), isFalse,
          reason: 'Het muntje komt pas later terug (SCRUM-20 heropend).');
      expect(DiceShape.supports(7), isFalse);
      expect(DiceShape.supports(100), isFalse);
    });

    testWidgets('elke vorm tekent als CustomPaint op de gevraagde grootte',
        (tester) async {
      for (final sides in [4, 6, 8, 10, 12, 20]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: DiceShape(key: Key('shape-$sides'), sides: sides, size: 64),
          ),
        ));

        expect(find.byKey(Key('shape-$sides')), findsOneWidget);
        expect(
            find.descendant(
                of: find.byKey(Key('shape-$sides')),
                matching: find.byType(CustomPaint)),
            findsOneWidget,
            reason: 'd$sides moet als eigen graphic getekend worden.');
        expect(tester.getSize(find.byKey(Key('shape-$sides'))),
            const Size(64, 64));
      }
    });

    testWidgets('de graphics schalen correct mee met de opgegeven grootte',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: DiceShape(sides: 20, size: 40),
          ),
        ),
      ));
      expect(tester.getSize(find.byType(DiceShape)), const Size(40, 40));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: DiceShape(sides: 20, size: 120),
          ),
        ),
      ));
      expect(tester.getSize(find.byType(DiceShape)), const Size(120, 120));
    });

    test('de gouden vormlijn houdt voldoende contrast met het tafelgroen',
        () {
      expect(_contrastRatio(CasinoColors.gold, CasinoColors.tableGreen),
          greaterThan(3.0),
          reason:
              'WCAG 1.4.11 vereist minstens 3:1 voor grafische componenten.');
    });

    test('de dobbelsteenwaarde houdt AA-contrast op de vormvlak', () {
      expect(_contrastRatio(CasinoColors.dieValue, CasinoColors.dieFace),
          greaterThan(4.5));
    });
  });

  group('d6 als plat vierkant (SCRUM-35)', () {
    testWidgets('de d6 toont zijn ogen gecentreerd op het vierkant',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: DieFace(value: 5, size: 64, sides: 6),
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('pip')), findsNWidgets(5));

      // De middelste oog hoort exact in het midden van het platte
      // vierkant te staan.
      final dieCenter = tester.getCenter(find.byType(DieFace));
      final middlePip = tester.getCenter(find.byKey(const Key('pip')).at(2));
      expect(middlePip, dieCenter,
          reason: 'De ogen staan gecentreerd op de platte d6.');
    });

    testWidgets('de d6 behoudt zijn afmetingen op verschillende groottes',
        (tester) async {
      for (final size in [22.0, 64.0, 120.0]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: DiceShape(sides: 6, size: size),
            ),
          ),
        ));

        expect(tester.getSize(find.byType(DiceShape)), Size(size, size));
      }
    });
  });

  group('D&D-vormgetrouw in de app (SCRUM-28)', () {
    testWidgets('elke typekeuze in het startscherm toont zijn eigen graphic',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => math.Random(1)));
      await tester.pumpAndSettle();

      for (final sides in [4, 6, 8, 10, 12, 20]) {
        final shape = tester.widget<DiceShape>(
            find.byKey(Key('chip-shape-$sides')));
        expect(shape.sides, sides,
            reason: 'De chip van d$sides hoort de d$sides-vorm te tonen.');
      }
    });

    testWidgets('het resultaatscherm toont de vorm van het gekozen type',
        (tester) async {
      for (final sides in [4, 20]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(DiceApp(randomFactory: () => math.Random(1)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('$sides'));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Let's roll"));
        await tester.pumpAndSettle();

        expect(
            find.byWidgetPredicate(
                (w) => w is DiceShape && w.sides == sides),
            findsOneWidget,
            reason: 'd$sides moet op het resultaatscherm vormgetrouw zijn.');
      }
    });
  });
}
