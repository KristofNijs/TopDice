# TopDice

TopDice is een dobbelsteen-app voor Android in casinostijl: kies het aantal dobbelstenen en de soort (d4 t/m d20), tik op **Let's roll** en gooi. Het resultaatscherm toont echte ogenpatronen en de totaalsom, en je kunt ter plekke opnieuw gooien of terug naar het menu.

## Features

- Menu met keuze van 1 tot 12 dobbelstenen
- Ondersteuning voor d4, d6, d8, d10, d12 en d20
- De gekozen dobbelsteensoort wordt bewaard tussen sessies (`shared_preferences`)
- Resultaatscherm met klassieke ogenpatronen (1 t/m 8 ogen) of een cijfer in casino-stijl voor d10/d12/d20, met totaalsom, "Opnieuw gooien" en teruggaan naar het menu
- Dobbelstenen schalen mee met de schermgrootte en zijn toegankelijk via `Semantics`-labels
- Casino-thema: tafelgroene achtergrond op elk scherm, gouden accenten en WCAG AA-contrast (minimaal 4,5:1)
- Vaste advertentiebalk onderaan elk scherm (placeholder tijdens ontwikkeling, uitbreidbaar met echte advertentiecontent)

## Technologie

- Flutter (Dart), Material 3
- Package: `com.wodanixgames.topdice`
- Worpen via `DiceEngine` met injecteerbare toevalsbron, volledig unittestbaar

## Projectstructuur

```text
lib/
  main.dart            # DiceApp, hoofdmenu- en resultaatscherm
  casino_theme.dart    # casino-thema en kleurenpalet (CasinoColors)
  ad_banner.dart       # advertentiebalk onderaan elk scherm
  dice/
    dice_engine.dart   # worpen-logica (injecteerbare toevalsbron)
    dice_pips.dart     # klassieke ogenpatronen voor 1 t/m 8 ogen
test/                  # widget- en unit-tests (flutter_test)
```

## Ontwikkelen

```bash
flutter pub get
flutter test
flutter run
```

> **Let op (Windows)**: houd de pub-cache op hetzelfde station als het project (bijv. `PUB_CACHE` op `E:` bij een project op `E:`). Het project bevat daarnaast een fix in `android/build.gradle.kts` die de Kotlin-incrementele compilatie voor plugins uitzet, zodat de Android-build ook bij een pub-cache op een ander station lukt (KT-63983).

## Bouwen voor de Play Store

```bash
flutter build appbundle
```
