import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/ad_banner.dart';
import 'package:topdice/main.dart';

void main() {
  group('Advertentiebalk (SCRUM-13)', () {
    testWidgets('het hoofdmenu toont onderaan een vaste advertentiebalk',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));

      final banner = find.byKey(const Key('ad-banner'));
      expect(banner, findsOneWidget);

      final bannerRect = tester.getRect(banner);
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(bannerRect.height, 56, reason: 'De balk heeft een vaste hoogte.');
      expect(bannerRect.bottom, screenSize.height,
          reason: 'De balk staat tegen de onderrand van het scherm.');
    });

    testWidgets('het resultaatscherm toont dezelfde advertentiebalk',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));
      await tester.tap(find.text("Let's roll"));
      await tester.pumpAndSettle();

      final banner = find.byKey(const Key('ad-banner'));
      expect(banner, findsOneWidget,
          reason: 'Elk scherm moet de balk tonen.');
    });

    testWidgets('de hoofdinhoud wordt niet afgedekt door de balk',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));

      final rollButton = tester.getRect(find.byKey(const Key('lets-roll')));
      final bannerTop =
          tester.getTopLeft(find.byKey(const Key('ad-banner'))).dy;

      expect(rollButton.bottom, lessThan(bannerTop),
          reason: 'De roll-knop moet volledig boven de balk blijven.');
    });

    testWidgets('zonder eigen content toont de balk een placeholder',
        (tester) async {
      await tester.pumpWidget(DiceApp(randomFactory: () => Random(1)));

      final banner = find.byKey(const Key('ad-banner'));
      expect(
          find.descendant(of: banner, matching: find.text('Advertentie')),
          findsOneWidget,
          reason: 'Tijdens ontwikkeling is een placeholder zichtbaar.');
    });

    testWidgets('de balk kan later echte advertentiecontent tonen',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AdBanner(child: Text('ECHTE-AD')),
        ),
      ));

      expect(find.text('ECHTE-AD'), findsOneWidget);
      expect(find.text('Advertentie'), findsNothing,
          reason: 'Eigen content vervangt de placeholder.');
    });
  });
}
