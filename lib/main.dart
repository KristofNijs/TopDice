import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_banner.dart';
import 'casino_theme.dart';
import 'dice/dice_engine.dart';
import 'dice/dice_pips.dart';
import 'dice/dice_shape.dart';

/// Creeert de toevalsbron voor elke worp; injecteerbaar voor tests.
typedef RandomFactory = Random Function();

/// Mogelijke aantal ogen per dobbelsteen (klassiek dobbelsteen-palet).
const kSupportedSides = [4, 6, 8, 10, 12, 20];

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
    return Scaffold(
      appBar: AppBar(title: const Text('TopDice')),
      bottomNavigationBar: const AdBanner(),
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
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DiceShape(
                          key: Key('chip-shape-$sides'),
                          sides: sides,
                          size: 22),
                      const SizedBox(width: 6),
                      Text('$sides'),
                    ],
                  ),
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

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late List<int> _values = DiceEngine.roll(
    count: widget.count,
    sides: widget.sides,
    random: widget.randomFactory(),
  );

  /// Tuimelanimatie bij elke worp (SCRUM-21); alleen transform-based,
  /// zodat de animatie ook op trage toestellen soepel blijft.
  static const _tumbleDuration = Duration(milliseconds: 600);

  late final AnimationController _tumble = AnimationController(
    vsync: this,
    duration: _tumbleDuration,
  )..forward();

  /// Tussenliggende waarden per dobbelsteen tijdens het tuimelen:
  /// vier willekeurige frames, gevolgd door de echte worp.
  late final List<List<int>> _tumbleFrames = _generateTumbleFrames();

  List<List<int>> _generateTumbleFrames() {
    final random = widget.randomFactory();
    return [
      for (var i = 0; i < widget.count; i++)
        [for (var f = 0; f < 4; f++) random.nextInt(widget.sides) + 1],
    ];
  }

  /// Of de dobbelstenen nog aan het tuimelen zijn.
  bool get _animating => _tumble.status != AnimationStatus.completed;

  int get _total => _values.fold(0, (a, b) => a + b);

  void _rollAgain() {
    setState(() {
      _valuesNewRoll();
      _tumble.forward(from: 0);
    });
  }

  void _valuesNewRoll() {
    _values = DiceEngine.roll(
      count: widget.count,
      sides: widget.sides,
      random: widget.randomFactory(),
    );
  }

  /// Een tik op het scherm slaat de animatie over: meteen naar het
  /// definitieve resultaat (SCRUM-21, overslaan is verplicht).
  void _skipAnimation() {
    if (_animating) {
      _tumble.stop();
      _tumble.value = 1;
    }
  }

  /// Waarde die de dobbelsteen op tijdstip [t] (0.0 t/m 1.0) toont.
  int _shownValue(int index, double t) {
    if (!_animating) {
      return _values[index];
    }
    final frames = _tumbleFrames[index];
    final frame = (t * frames.length).floor().clamp(0, frames.length - 1);
    return frames[frame];
  }

  /// De tuimelende dobbelsteen: roteert om twee assen en komt tot rust
  /// op de echte waarde zodra de animatie klaar is.
  Widget _tumblingDie(int index, double faceSize) {
    return AnimatedBuilder(
      animation: _tumble,
      builder: (context, _) {
        final face = DieFace(
          key: ValueKey('die-$index'),
          value: _shownValue(index, _tumble.value),
          size: faceSize,
          sides: widget.sides,
        );
        if (!_animating) {
          return face;
        }
        final eased = Curves.easeOut.transform(_tumble.value);
        // Volledige slagen in de laatste fase: hoe dichter bij het einde,
        // hoe langzamer het tuimelen, tot de steen stilvalt.
        final matrix = Matrix4.rotationX((1 - eased) * 2 * pi);
        matrix.multiply(Matrix4.rotationY((1 - eased) * 3 * pi));
        return Transform(
          key: const Key('tumbling'),
          transform: matrix,
          alignment: Alignment.center,
          child: face,
        );
      },
    );
  }

  @override
  void dispose() {
    _tumble.dispose();
    super.dispose();
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
      bottomNavigationBar: const AdBanner(),
      // Tikken op het scherm slaat de tuimelanimatie over.
      body: GestureDetector(
        key: const Key('die-skip-overlay'),
        onTap: _skipAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0; index < _values.length; index++)
                    _tumblingDie(index, faceSize),
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
      ),
    );
  }
}


/// Enkele dobbelsteen-face in de vorm van het echte D&D-type (SCRUM-28):
/// tetraëder voor d4, kubus voor d6, ruit voor d8, vlieger voor d10,
/// vijfhoek voor d12 en zeshoek voor d20. De waarde staat als klassiek
/// ogenpatroon (1 t/m 8) of als nummer (9 en hoger) op de vorm.
class DieFace extends StatelessWidget {
  const DieFace(
      {super.key, required this.value, required this.size, required this.sides});

  final int value;

  /// Zijde van de dobbelsteen in logical pixels; schaalt mee met het scherm.
  final double size;

  /// Aantal zijden van de dobbelsteen: bepaalt de vorm van de graphic.
  final int sides;

  /// Grootte van het waardevlak binnen de vorm: in scherpe hoeken als
  /// de d4 moet de waarde kleiner en lager staan; bij de d6 staan de
  /// ogen op het frontvlak van de kubus (SCRUM-30).
  double get _valueSize => switch (sides) {
        4 => size * 0.42,
        6 => size * 0.66,
        8 || 10 => size * 0.58,
        12 || 20 => size * 0.66,
        _ => size * 0.90,
      };

  Alignment get _valueAlignment => switch (sides) {
        4 => const Alignment(0, 0.18),
        // Middelpunt van het frontvlak van de kubus.
        6 => const Alignment(-0.16, 0.16),
        _ => Alignment.center,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget face;
    // Alleen de klassieke d6 heeft ogen (SCRUM-29); de andere stenen
    // tonen hun waarde als cijfer, zoals de echte d4/d8/d10/d12/d20.
    if (sides == 6 && DicePips.supports(value)) {
      face = DicePips(count: value, size: _valueSize);
    } else {
      face = Text(
        '$value',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: CasinoColors.dieValue,
          fontSize: _valueSize * 0.45,
        ),
      );
    }
    return Semantics(
      label: '$value ogen',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DiceShape(sides: sides, size: size),
            Align(alignment: _valueAlignment, child: face),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(DiceApp());
}
