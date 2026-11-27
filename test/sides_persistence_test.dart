import 'dart:convert';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topdice/main.dart';

/// Fabriek zoals in app_test.dart ( Random(1)-reeks); injecteerbaar voor tests.
Random _fixedRandom() => Random(1);

void main() {
  group('Dobbelsteenpool bewaren (SCRUM-36)', () {
    testWidgets('eerste sessie start standaard met 1 d6', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('pool-count-6'))).data,
          '1');
    });

    testWidgets('de samengestelde pool wordt bewaard en hersteld',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      // Sessie 1: kies 2 d4 en 1 d20.
      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-20')));
      await tester.pumpAndSettle();

      // Opgeslagen in de lokale opslag.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(kDicePoolPrefKey);
      expect(stored, isNotNull);
      expect(jsonDecode(stored!), {'4': 2, '6': 1, '20': 1});

      // Sessie 2: zelfde opslag, verse app-instantie.
      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(const Key('pool-count-4'))).data,
          '2');
      expect(tester.widget<Text>(find.byKey(const Key('pool-count-20'))).data,
          '1',
          reason: 'De vorige sessie koos 1 d20; die moet hersteld worden.');
    });

    testWidgets('een oude soortkeuze (dice.sides) wordt gemigreerd naar een pool',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dice.sides': 12,
      });

      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('pool-count-12'))).data,
          '1',
          reason: 'De oude keuze d12 moet als 1 d12 in de pool terechtkomen.');

      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      expect(find.text('1d12'), findsOneWidget,
          reason: 'De gemigreerde keuze d12 moet naar het resultaatscherm gaan.');
    });

    testWidgets('een ongeldige pool valt veilig terug op 1 d6',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dice.pool': 'dit-is-geen-json',
      });

      await tester.pumpWidget(DiceApp(randomFactory: () => _fixedRandom()));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('pool-count-6'))).data,
          '1',
          reason: 'Corrupte opslag mag de app niet breken.');
    });
  });
}
