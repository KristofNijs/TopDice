import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topdice/main.dart';

/// Fabriek zoals in app_test.dart ( Random(1)-reeks); injecteerbaar voor tests.
Random _fixedRandom() => Random(1);

void main() {
  group('Soort dobbelsteen bewaren (SCRUM-12)', () {
    testWidgets('eerste sessie start standaard met d6', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('6'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue);
    });

    testWidgets('de gekozen soort wordt bewaard en hersteld in een nieuwe sessie',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      // Sessie 1: kies d20.
      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      // Opgeslagen in de lokale opslag.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(kDiceSidesPrefKey), 20);

      // Sessie 2: zelfde opslag, verse app-instantie.
      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('20'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue,
          reason: 'De vorige sessie koos d20; die keuze moet hersteld worden.');
    });

    testWidgets('de herstelde soort wordt gebruikt tijdens het spel',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{'dice.sides': 12});

      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      expect(find.text('1d12'), findsOneWidget,
          reason: 'De herstelde keuze d12 moet naar het resultaatscherm gaan.');
    });

    testWidgets('een ongeldige of niet-ondersteunde waarde valt terug op d6',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{'dice.sides': 7});

      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: find.text('6'), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue,
          reason: 'd7 bestaat niet; de app moet veilig terugvallen op d6.');
    });
  });
}
