# TopDice

TopDice is een eenvoudige dobbelsteen-app voor Android: kies het aantal dobbelstenen en het aantal ogen per dobbelsteen, tik op **Let's roll** en gooi. Resultaten kun je opnieuw gooien of met andere dobbelstenen verder.

## Features

-. Menu met keuze van 1 tot 12 dobbelstenen
- Ondersteuning voor d4, d6, d8, d10, d12 en d20
- Resultaatscherm met totaalsom, "Opnieuw gooien" en teruggaan naar het menu

## Technologie

- Flutter (Dart), Material 3
- Package: `com.wodanixgames.topdice`
- Gelijkwaardigeworpen via `DiceEngine` (injecteerbare toevalsbron, volledig getest)

## Ontwikkelen

```bash
flutter pub get
flutter test
flutter run
```

## Bouwen voor de Play Store

```bash
flutter build appbundle
```
