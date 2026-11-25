import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_banner.dart';
import 'casino_theme.dart';
import 'dice/dice_engine.dart';
import 'dice/dice_pips.dart';

/// Creeert de toevalsbron voor elke worp; injecteerbaar voor tests.
typedef RandomFactory = Random Function();

/// Mogelijke soorten worpen: muntje (2 zijden) plus het klassieke palet.
const kSupportedSides = [2, 4, 6, 8, 10, 12, 20];

/// Zijden van een muntje: kop of munt.
const int kCoinSides = 2;

/// Label voor een soort in het menu: het muntje heeft een naam, de
/// dobbelstenen worden bij hun aantal zijden genoemd.
String sidesLabel(int sides) => sides == kCoinSides ? 'Muntje' : '$sides';

/// Of een worp met dit aantal zijden een muntje is.
bool isCoin(int sides) => sides == kCoinSides;

/// Sleutel waaronder de gekozen soort dobbelsteen bewaard wordt tussen sessies.
const String kDiceSidesPrefKey = 'dice.sides';

Random _defaultRandomFactory() => Random();

class DiceApp extends StatelessWidget {
  const DiceApp({super.key, this.randomFactory = _defaultRandomFactory});

  final RandomFactory randomFactory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TopDice',
      theme: casinoTheme,
      home: MainMenuScreen(randomFactory: randomFactory),
    );
  }
}

/// Startscher: kies aantal dobbelstenen en aantal ogen, druk op "Let's roll".
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key, required this.randomFactory});

  final RandomFactory randomFactory;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _count = 1;
  int _sides = 6;

  static const _maxDice = 12;

  @override
  void initState() {
    super.initState();
    _restoreSides();
  }

  /// Herstelt de laatst gekozen soort uit de vorige sessie.
  ///
  /// Fouten of niet-ondersteunde waarden (bijv. een oudere app-versie) worden
  /// genegeerd en valt de app terug op de standaard d6.
  Future<void> _restoreSides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(kDiceSidesPrefKey);
      if (!mounted || stored == null || !kSupportedSides.contains(stored)) {
        return;
      }
      setState(() => _sides = stored);
    } catch (_) {
      // Opslag niet beschikbaar: de standaardkeuze d6 blijft geldig.
    }
  }

  /// Kiest de soort dobbelsteen en bewaart de keuze voor de volgende sessie.
  ///
  /// Lokaal bewaren is een gemaksfunctie: mislukt het, dan geldt de keuze
  /// gewoon voor deze sessie.
  Future<void> _selectSides(int sides) async {
    setState(() => _sides = sides);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kDiceSidesPrefKey, sides);
    } catch (_) {
      // Niet bewaren is geen fout voor de speler.
    }
  }

  void _changeCount(int delta) {
    setState(() {
      _count = (_count + delta).clamp(1, _maxDice);
    });
  }

  void _roll() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          count: _count,
          sides: _sides,
          randomFactory: widget.randomFactory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steenLabel = isCoin(_sides) ? 'munten' : 'dobbelstenen';
    return Scaffold(
      appBar: AppBar(title: const Text('TopDice')),
      bottomNavigationBar: const AdBanner(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Aantal $steenLabel', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('count-minus'),
                icon: const Icon(Icons.remove),
                onPressed: _count > 1 ? () => _changeCount(-1) : null,
              ),
              Text('$_count',
                  key: const Key('dice-count'),
                  style: theme.textTheme.displayMedium),
              IconButton(
                key: const Key('count-plus'),
                icon: const Icon(Icons.add),
                onPressed: _count < _maxDice ? () => _changeCount(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Dobbelsteen of muntje', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final sides in kSupportedSides)
                ChoiceChip(
                  key: Key('sides-$sides'),
                  label: Text(sidesLabel(sides)),
                  selected: _sides == sides,
                  onSelected: (_) => _selectSides(sides),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            key: const Key('lets-roll'),
            onPressed: _roll,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text("Let's roll",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resultaatscher: toont de gegooide dobbelstenen.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.count,
    required this.sides,
    required this.randomFactory,
  });

  final int count;
  final int sides;
  final RandomFactory randomFactory;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<int> _values = DiceEngine.roll(
    count: widget.count,
    sides: widget.sides,
    random: widget.randomFactory(),
  );

  int get _total => _values.fold(0, (a, b) => a + b);

  void _rollAgain() {
    setState(() {
      _values = DiceEngine.roll(
        count: widget.count,
        sides: widget.sides,
        random: widget.randomFactory(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dobbelsteengrootte schaalt mee met het scherm, met een leesbaar
    // minimum en maximum.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final faceSize = (screenWidth / 6).clamp(48.0, 96.0);
    final coin = isCoin(widget.sides);
    final title = coin
        ? (widget.count == 1 ? 'Muntje' : '${widget.count} munten')
        : '${widget.count}d${widget.sides}';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: const AdBanner(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (index, value) in _values.indexed)
                  coin
                      ? CoinFace(
                          key: ValueKey('coin-$index'),
                          side: CoinSide.fromRoll(value),
                          size: faceSize,
                        )
                      : DieFace(
                          key: ValueKey('die-$index'),
                          value: value,
                          size: faceSize,
                        ),
              ],
            ),
            const SizedBox(height: 16),
            // Alleen dobbelstenen hebben een zinvol cijfertotaal;
            // bij een muntje zegt kop/munt alles (SCRUM-20).
            if (!coin)
              Text('Totaal: $_total', style: theme.textTheme.titleLarge),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('roll-again'),
              onPressed: _rollAgain,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('Opnieuw gooien'),
              ),
            ),
            TextButton(
              key: const Key('back-to-menu'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Andere dobbelstenen'),
            ),
          ],
        ),
      ),
    );
  }
}


/// Gouden muntje met de geworpen zijde: kop of munt.
class CoinFace extends StatelessWidget {
  const CoinFace({super.key, required this.side, required this.size});

  final CoinSide side;

  /// Zijde van de munt in logical pixels; schaalt mee met het scherm.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: side.label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CasinoColors.gold,
          shape: BoxShape.circle,
          border: Border.all(color: CasinoColors.goldInk, width: size * 0.04),
        ),
        child: Text(
          side.label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: CasinoColors.goldInk,
          ),
        ),
      ),
    );
  }
}

/// Enkele dobbelsteen-face: klassieke ogen voor 1 t/m 8, rooster van
/// ogen voor hogere waarden (SCRUM-20).
class DieFace extends StatelessWidget {
  const DieFace({super.key, required this.value, required this.size});

  final int value;

  /// Zijde van de dobbelsteen in logical pixels; schaalt mee met het scherm.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget face;
    if (DicePips.supports(value)) {
      face = DicePips(count: value, size: size);
    } else {
      face = Text(
        '$value',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: CasinoColors.dieValue,
          fontSize: size * 0.45,
        ),
      );
    }
    return Semantics(
      label: '$value ogen',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CasinoColors.dieFace,
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        child: face,
      ),
    );
  }
}

void main() {
  runApp(DiceApp());
}
