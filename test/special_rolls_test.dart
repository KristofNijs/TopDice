import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topdice/dice/dice_engine.dart';
import 'package:topdice/main.dart';

/// Fabriek zoals in app_test.dart (Random(1)-reeks); injecteerbaar voor tests.
Random _fixedRandom() => Random(1);

void main() {
  group('Bijzondere worpen: menu (SCRUM-20)', () {
    testWidgets('het startscherm biedt naast de dobbelstenen ook een muntje aan',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('Muntje'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isFalse,
          reason: 'Standaard blijft de klassieke d6 geselecteerd.');
    });

    testWidgets('de muntkeuze wordt bewaard en hersteld in een nieuwe sessie',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      // Sessie 1: kies het muntje.
      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muntje'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(kDiceSidesPrefKey), 2,
          reason: 'De muntkeuze wordt als 2-zijdige worp bewaard.');

      // Sessie 2: zelfde opslag, verse app-instantie.
      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('Muntje'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue,
          reason: 'De vorige sessie koos het muntje; dat moet hersteld worden.');
    });

    testWidgets('een bewaarde muntkeuze uit een oudere sessie wordt hersteld',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{'dice.sides': 2});

      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('Muntje'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue);
    });

    testWidgets('bij het muntje vraagt de app om het aantal munten',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muntje'));
      await tester.pumpAndSettle();

      expect(find.text('Aantal munten'), findsOneWidget);
    });
  });

  group('Bijzondere worpen: resultaatscherm (SCRUM-20)', () {
    testWidgets(
        'een muntje gooien toont kop of munt, zonder cijfertotaal',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muntje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      // Welke zijde Random(1) ook oplevert: er is precies een kop of munt.
      final value = DiceEngine.roll(count: 1, sides: 2, random: Random(1)).first;
      expect(find.text(CoinSide.fromRoll(value).label), findsOneWidget);
      expect(find.byType(CoinFace), findsOneWidget);
      expect(find.textContaining('Totaal:'), findsNothing,
          reason: 'Een muntje heeft geen zinvol cijfertotaal (SCRUM-20).');
      expect(find.textContaining('d2'), findsNothing,
          reason: 'Kop/munt is duidelijker dan "1d2".');
    });

    testWidgets('meerdere munten tonen allemaal kop of munt', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muntje'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      expect(find.byType(CoinFace), findsNWidgets(3));
      // Drie munten: samen exactly drie kop/munt-uitkomsten.
      final kop = find.text('kop').evaluate().length;
      final munt = find.text('munt').evaluate().length;
      expect(kop + munt, 3);
      expect(find.textContaining('Totaal:'), findsNothing);
    });

    testWidgets('opnieuw gooien werkt ook met munten', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muntje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opnieuw gooien'));
      await tester.pumpAndSettle();

      expect(find.byType(CoinFace), findsOneWidget);
    });

    testWidgets('d10/d12/d20-worpen tonen ogen in plaats van nummers',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      for (final sides in [10, 12, 20]) {
        // Vers app-scherm per soort: de router van de vorige iteratie lozen.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(DiceApp(randomFactory: _fixedRandom));
        await tester.pumpAndSettle();
        await tester.tap(find.text('$sides'));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Let's roll"));
        await tester.pumpAndSettle();

        final values = DiceEngine.roll(count: 1, sides: sides, random: Random(1));
        final pips = find.byKey(const Key('pip')).evaluate().length;
        expect(pips, values.first,
            reason: 'd$sides moet de geworpen waarde als ogen tonen.');
        expect(find.text('${values.first}'), findsNothing,
            reason: 'd$sides mag de waarde niet als kaal nummer tonen.');
        expect(find.textContaining('Totaal:'), findsOneWidget,
            reason: 'Dobbelstenen hebben wél een cijfertotaal.');
      }
    });
  });
}
