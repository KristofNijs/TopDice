import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/casino_theme.dart';
import 'package:topdice/main.dart';

/// Effectieve achtergrondkleur van het bovenste Scaffold: de expliciete
/// [Scaffold.backgroundColor], of anders de kleur uit het thema.
Color _effectiveScaffoldBackground(WidgetTester tester) {
  final scaffoldFinder = find.byType(Scaffold);
  final scaffold = tester.widget<Scaffold>(scaffoldFinder);
  return scaffold.backgroundColor ??
      Theme.of(tester.element(scaffoldFinder)).scaffoldBackgroundColor;
}

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
  group('Casino-achtergrond (SCRUM-10)', () {
    testWidgets('hoofdmenu gebruikt casinotafel-groen als achtergrond',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => math.Random(1)));

      expect(_effectiveScaffoldBackground(tester), CasinoColors.tableGreen);
    });

    testWidgets('resultaatscherm gebruikt hetzelfde casinotafel-groen',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => math.Random(1)));
      final menuBackground = _effectiveScaffoldBackground(tester);

      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();
      final resultBackground = _effectiveScaffoldBackground(tester);

      expect(resultBackground, CasinoColors.tableGreen);
      expect(resultBackground, menuBackground,
          reason: 'De achtergrond moet consistent zijn op alle schermen.');
    });

    testWidgets('tekst op de achtergrond blijft goed leesbaar', (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => math.Random(1)));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      final background = theme.scaffoldBackgroundColor;

      expect(
          _contrastRatio(theme.textTheme.bodyMedium!.color!, background),
          greaterThan(4.5),
          reason: 'WCAG AA vereist minimaal 4.5:1 voor bodytekst.');
      expect(
          _contrastRatio(theme.textTheme.titleMedium!.color!, background),
          greaterThan(4.5));
    });

    testWidgets('knoplabels blijven leesbaar op de gouden accentkleur',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => math.Random(1)));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));

      expect(
          _contrastRatio(
              theme.colorScheme.onPrimary, theme.colorScheme.primary),
          greaterThan(4.5),
          reason: 'Tekst op knoppen moet minstens 4.5:1 contrast hebben.');
    });

    testWidgets('dobbelsteenwaarde blijft leesbaar op de dobbelsteen-face',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => math.Random(1)));

      expect(
          _contrastRatio(CasinoColors.dieValue, CasinoColors.dieFace),
          greaterThan(4.5));
    });
  });
}
