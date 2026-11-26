# TopDice

TopDice is een dobbelsteen-app voor Android in casinostijl: kies het aantal dobbelstenen en de soort (d4 t/m d20), tik op **Let's roll** en gooi. De stenen tuimelen in 3D naar hun resultaat, het resultaatscherm toont vormgetrouwe graphics met de totaalsom, en je kunt ter plekke opnieuw gooien of terug naar het menu.

## Features

- Menu met keuze van 1 tot 12 dobbelstenen
- Ondersteuning voor d4, d6, d8, d10, d12 en d20
- Echte 3D-dobbelstenen: elke steen is een driedimensionaal veelvlak (tetraëder, kubus, octaëder, pentagonale trapezoëder, dodecaëder, icosaëder) dat geroteerd en belicht getekend wordt, vlak voor vlak in schildersvolgorde
- Vormgetrouwe graphics per type in het startscherm én op het resultaatscherm
- De d6 toont klassieke ogenpatronen; de andere stenen tonen hun waarde als cijfer, zoals de echte stenen
- Witte dobbelstenen met zwarte ogen (d6) en zwarte cijfers, zoals klassieke stenen; de 3D-belichting gebruikt een subtiele grijze schaduw, zodat elk vlak bij elke belichting wit blijft. Alle steenkleuren staan centraal in het palet (`CasinoColors`), zodat een toekomstig themasysteem ze kan overschrijven
- 3D-tuimelanimatie bij elke worp, die eindigt op het definitieve resultaat en soepel blijft op trage toestellen; tik op het scherm om de animatie over te slaan
- De gekozen dobbelsteensoort wordt bewaard tussen sessies (`shared_preferences`)
- Resultaatscherm met totaalsom, "Opnieuw gooien" en teruggaan naar het menu
- Dobbelstenen schalen mee met de schermgrootte en zijn toegankelijk via `Semantics`-labels
- Casino-thema: tafelgroene achtergrond op elk scherm, gouden accenten op knoppen en dobbelsteencontouren, en WCAG AA-contrast (minimaal 4,5:1)
- Vaste advertentiebalk onderaan elk scherm (placeholder tijdens ontwikkeling, uitbreidbaar met echte advertentiecontent)

## Technologie

- Flutter (Dart), Material 3
- Package: `com.wodanixgames.topdice`
- Worpen via `DiceEngine` met injecteerbare toevalsbron, volledig unittestbaar
- 3D-weergave via een eigen orthografische projectie met belichting (`dice_projection.dart`), zonder externe 3D-packages

## Projectstructuur

```text
lib/
  main.dart            # DiceApp, hoofdmenu- en resultaatscherm (incl. tuimelanimatie)
  casino_theme.dart    # casino-thema en kleurenpalet (CasinoColors)
  ad_banner.dart       # advertentiebalk onderaan elk scherm
  dice/
    dice_engine.dart   # worpen-logica (injecteerbare toevalsbron)
    dice_pips.dart     # klassieke ogenpatronen voor de d6
    dice_shape.dart    # 3D-weergave per dobbelsteentype (d6 als kubus)
    dice_model.dart    # veelvlakmodellen: vertices en vlakken per steen
    dice_projection.dart # rotatie, belichting en 2D-projectie van de modellen
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
