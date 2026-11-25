import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/main.dart';

void main() {
  group('Dobbelpatronen (SCRUM-11)', () {
    testWidgets(
        'waarden 1 t/m 8 worden als klassiek ogenpatroon getoond, niet als nummer',
        (tester) async {
          for (final value in [1, 2, 3, 4, 5, 6, 7, 8]) {
            await tester.pumpWidget(MaterialApp(
              home: Scaffold(body: DieFace(value: value, size: 64)),
            ));

            expect(
                find.byKey(const Key('pip')), findsNWidgets(value),
                reason: 'Waarde $value moet exact $value ogen tonen.');
            expect(find.byType(Text), findsNothing,
                reason: 'Waarde $value mag geen nummer tonen.');
          }
        });

    testWidgets(
        'waarden 9 t/m 20 worden als ogenpatroon getoond, niet als nummer (SCRUM-20)',
        (tester) async {
          for (final value in [9, 10, 11, 12, 13, 15, 17, 20]) {
            await tester.pumpWidget(MaterialApp(
              home: Scaffold(body: DieFace(value: value, size: 96)),
            ));

            expect(
                find.byKey(const Key('pip')), findsNWidgets(value),
                reason: 'Waarde $value moet exact $value ogen tonen.');
            expect(find.text('$value'), findsNothing,
                reason: 'Waarde $value mag geen nummer tonen (SCRUM-20).');
          }
        });

    testWidgets('het ogenpatroon blijft behoud bij het dobbelen (d6)',
        (tester) async {
      await tester.pumpWidget(
          DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      // Random(1) levert met d6 de reeks 1, 4, 6.
      expect(find.byType(DieFace), findsNWidgets(3));
      expect(find.text('1'), findsNothing, reason: 'ogen i.p.v. nummers');
      expect(find.text('4'), findsNothing);
      expect(find.text('6'), findsNothing);
      expect(find.byKey(const Key('pip')), findsNWidgets(1 + 4 + 6));
      expect(find.textContaining('Totaal: 11'), findsOneWidget);
    });

    testWidgets('de dobbelsteen schaalt mee met de schermgrootte',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      final smallFace = tester.getSize(find.byType(DieFace).first);
      expect(find.byKey(const Key('pip')), findsOneWidget);

      tester.view.physicalSize = const Size(1200, 2000);
      await tester.pump();
      await tester.pumpAndSettle();

      final largeFace = tester.getSize(find.byType(DieFace).first);
      expect(largeFace.width, greaterThan(smallFace.width),
          reason: 'Op een groter scherm moet de dobbelsteen groter zijn.');
      expect(find.byKey(const Key('pip')), findsOneWidget,
          reason: 'Het patroon moet ook op het grotere scherm leesbaar zijn.');
    });
  });
}
