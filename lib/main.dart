import 'dart:math';

import 'package:flutter/material.dart';

import 'casino_theme.dart';
import 'dice/dice_engine.dart';
import 'dice/dice_pips.dart';

/// Creeert de toevalsbron voor elke worp; injecteerbaar voor tests.
typedef RandomFactory = Random Function();

/// Mogelijke aantal ogen per dobbelsteen (klassiek dobbelsteen-palet).
const kSupportedSides = [4, 6, 8, 10, 12, 20];

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
    return Scaffold(
      appBar: AppBar(title: const Text('TopDice')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Aantal dobbelstenen', style: theme.textTheme.titleMedium),
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
          Text('Ogen per dobbelsteen', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final sides in kSupportedSides)
                ChoiceChip(
                  key: Key('sides-$sides'),
                  label: Text('$sides'),
                  selected: _sides == sides,
                  onSelected: (_) => setState(() => _sides = sides),
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
    return Scaffold(
      appBar: AppBar(title: Text('${widget.count}d${widget.sides}')),
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
                  DieFace(
                    key: ValueKey('die-$index'),
                    value: value,
                    size: faceSize,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Totaal: $_total',
                style: theme.textTheme.titleLarge),
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


/// Enkele dobbelsteen-face: klassieke ogen voor 1 t/m 8, nummer voor
/// waarden zonder klassiek patroon (d10, d12, d20).
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
