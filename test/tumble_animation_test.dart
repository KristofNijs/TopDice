import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/dice/dice_engine.dart';
import 'package:topdice/main.dart';

/// Fabriek zoals in app_test.dart (Random(1)-reeks); injecteerbaar voor tests.
Random _fixedRandom() => Random(1);

void main() {
  group('Tuimelanimatie (SCRUM-21)', () {
    testWidgets(
        'een worp start met een 3D-tuimelanimatie die eindigt op het resultaat',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Let's roll"));
      await tester.pump();
      // Navigatie en tuimelanimatie zijn dan allebei bezig.
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('tumbling')), findsOneWidget,
          reason: 'Bij het werpen tuimelt de dobbelsteen eerst in 3D.');

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tumbling')), findsNothing,
          reason: 'De animatie eindigt op het definitieve resultaat.');
      final value =
          DiceEngine.roll(count: 1, sides: 6, random: Random(1)).first;
      expect(find.byType(DieFace), findsOneWidget);
      expect(find.byKey(const Key('pip')), findsNWidgets(value),
          reason: 'Na de animatie staat de echte worp op de steen.');
    });

    testWidgets('tikken op het scherm slaat de animatie over', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Let's roll"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('tumbling')), findsOneWidget);

      await tester.tap(find.byKey(const Key('die-skip-overlay')));
      await tester.pump();

      expect(find.byKey(const Key('tumbling')), findsNothing,
          reason: 'Een tik moet de animatie direct op het resultaat zetten.');
      final value =
          DiceEngine.roll(count: 1, sides: 6, random: Random(1)).first;
      expect(find.byKey(const Key('pip')), findsNWidgets(value));
    });

    testWidgets('opnieuw gooien start een nieuwe tuimelanimatie',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tumbling')), findsNothing);

      await tester.tap(find.text('Opnieuw gooien'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('tumbling')), findsOneWidget,
          reason: 'Ook een nieuwe worp begint met tuimelen.');

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tumbling')), findsNothing);
    });

    testWidgets('de tuimelanimatie duurt minder dan een seconde',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Let's roll"));
      await tester.pump();
      // Ruim genoeg voor de route-animatie plus de tuimel van 600 ms.
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byKey(const Key('tumbling')), findsNothing,
          reason:
              'De animatie moet soepel en kort blijven, ook op langzame toestellen.');
    });
  });
}
