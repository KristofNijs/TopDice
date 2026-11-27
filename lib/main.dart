import 'dart:convert';
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

/// Maximum aantal dobbelstenen in een samengestelde worp.
const int kMaxDice = 12;

/// Sleutel waaronder de samengestelde dobbelsteenpool bewaard wordt
/// tussen sessies, als JSON-map "soort: aantal".
const String kDicePoolPrefKey = 'dice.pool';

/// Verouderde sleutel van alleen de soort dobbelsteen (vóór SCRUM-36);
/// nog steeds gelezen om oude sessies te migreren.
const String kDiceSidesPrefKey = 'dice.sides';

Random _defaultRandomFactory() => Random();

/// Standaardpool voor een nieuwe speler: één d6.
Map<int, int> _defaultPool() => {6: 1};

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

/// Startscherm: stel per dobbelsteentype het aantal in en druk op
/// "Let's roll" voor een gemengde worp (SCRUM-36).
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key, required this.randomFactory});

  final RandomFactory randomFactory;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  /// Aantal dobbelstenen per soort, bijv. {4: 2, 6: 1} voor 2 d4 + 1 d6.
  Map<int, int> _pool = _defaultPool();

  @override
  void initState() {
    super.initState();
    _restorePool();
  }

  int get _totalDice => _pool.values.fold(0, (a, b) => a + b);

  /// Herstelt de samengestelde pool uit de vorige sessie (SCRUM-36).
  ///
  /// Fouten of ongeldige waarden worden genegeerd en valt de app terug
  /// op de standaardpool. Bestaat alleen nog de oude soortkeuze
  /// (dice.sides), dan wordt die gemigreerd naar een pool met 1
  /// dobbelsteen van dat type.
  Future<void> _restorePool() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(kDicePoolPrefKey);
      if (!mounted) return;
      if (stored != null) {
        final restored = _parsePool(stored);
        if (restored != null) {
          setState(() => _pool = restored);
        }
        return;
      }
      // Migratie van de oude situatie: alleen een soort opgeslagen.
      final legacySides = prefs.getInt(kDiceSidesPrefKey);
      if (legacySides != null && kSupportedSides.contains(legacySides)) {
        setState(() => _pool = {legacySides: 1});
      }
    } catch (_) {
      // Opslag niet beschikbaar: de standaardpool blijft geldig.
    }
  }

  /// Zet JSON om naar een geldige pool, of null als die onbruikbaar is.
  static Map<int, int>? _parsePool(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final pool = <int, int>{};
      var total = 0;
      for (final entry in decoded.entries) {
        final sides = int.tryParse(entry.key);
        final count = entry.value;
        if (sides == null ||
            count is! int ||
            !kSupportedSides.contains(sides) ||
            count < 0 ||
            count > kMaxDice) {
          return null;
        }
        if (count > 0) {
          pool[sides] = count;
        }
        total += count;
      }
      if (total < 1 || total > kMaxDice) {
        return null;
      }
      return pool;
    } catch (_) {
      return null;
    }
  }

  /// Past de pool aan en bewaart ze voor de volgende sessie.
  ///
  /// Lokaal bewaren is een gemaksfunctie: mislukt het, dan geldt de
  /// keuze gewoon voor deze sessie.
  Future<void> _savePool() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kDicePoolPrefKey, jsonEncode(_pool));
      // De oude soortkeuze is voortaan overbodig.
      await prefs.remove(kDiceSidesPrefKey);
    } catch (_) {
      // Niet bewaren is geen fout voor de speler.
    }
  }

  /// Voegt een dobbelsteen van [sides] ogen toe, zolang de begrenzing
  /// het toelaat (SCRUM-36).
  void _addDie(int sides) {
    if (_totalDice >= kMaxDice) {
      return;
    }
    setState(() => _pool[sides] = (_pool[sides] ?? 0) + 1);
    _savePool();
  }

  /// Haalt een dobbelsteen van [sides] ogen uit de pool; de laatste van
  /// een soort verdwijnt helemaal uit de pool.
  void _removeDie(int sides) {
    final count = _pool[sides] ?? 0;
    if (count == 0) {
      return;
    }
    setState(() {
      if (count == 1) {
        _pool.remove(sides);
      } else {
        _pool[sides] = count - 1;
      }
    });
    _savePool();
  }

  /// Dobbelstenen van de pool in vast soortvolgorde, bijv. [4, 4, 6].
  List<int> get _dice =>
      [for (final sides in kSupportedSides) for (var i = 0; i < (_pool[sides] ?? 0); i++) sides];

  void _roll() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          dice: _dice,
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
          Text('Dobbelstenen', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('$_totalDice van $kMaxDice dobbelstenen',
              key: const Key('pool-total'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final sides in kSupportedSides)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  DiceShape(
                      key: Key('pool-shape-$sides'), sides: sides, size: 28),
                  const SizedBox(width: 8),
                  Text('d$sides', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    key: Key('remove-$sides'),
                    icon: const Icon(Icons.remove),
                    onPressed:
                        (_pool[sides] ?? 0) > 0 ? () => _removeDie(sides) : null,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${_pool[sides] ?? 0}',
                      key: Key('pool-count-$sides'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: Key('add-$sides'),
                    icon: const Icon(Icons.add),
                    onPressed:
                        _totalDice < kMaxDice ? () => _addDie(sides) : null,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          FilledButton(
            key: const Key('lets-roll'),
            onPressed: _totalDice > 0 ? _roll : null,
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

/// Resultaatscherm: toont de gegooide dobbelstenen van een gemengde
/// worp, elk met de vorm van zijn eigen type (SCRUM-36).
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.dice,
    required this.randomFactory,
  });

  /// Aantal ogen per dobbelsteen in de pool, bijv. [4, 4, 6].
  final List<int> dice;

  final RandomFactory randomFactory;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  /// Gegooide waarden, parallel aan [ResultScreen.dice].
  late List<int> _values = _rollAll();

  /// Gooit alle dobbelstenen: per soort in één worp, zodat de
  /// geinjecteerde toevalsbron per soort deterministisch blijft.
  List<int> _rollAll() {
    final values = List<int>.filled(widget.dice.length, 0);
    // Eerste voorkomens-volgorde van de soorten in de pool.
    final sidesInOrder = <int>[];
    for (final sides in widget.dice) {
      if (!sidesInOrder.contains(sides)) {
        sidesInOrder.add(sides);
      }
    }
    for (final sides in sidesInOrder) {
      final count = widget.dice.where((s) => s == sides).length;
      final rolled = DiceEngine.roll(
        count: count,
        sides: sides,
        random: widget.randomFactory(),
      );
      var taken = 0;
      for (var i = 0; i < widget.dice.length; i++) {
        if (widget.dice[i] == sides) {
          values[i] = rolled[taken++];
        }
      }
    }
    return values;
  }

  int get _total => _values.fold(0, (a, b) => a + b);

  /// Notatie van de worp, bijv. "2d4 + 1d6" (SCRUM-36).
  String get _poolLabel {
    final parts = <String>[];
    for (final sides in kSupportedSides) {
      final count = widget.dice.where((s) => s == sides).length;
      if (count > 0) {
        parts.add('${count}d$sides');
      }
    }
    return parts.join(' + ');
  }

  void _rollAgain() {
    setState(() {
      _values = _rollAll();
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
      appBar: AppBar(title: Text(_poolLabel)),
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
                for (final (index, sides) in widget.dice.indexed)
                  DieFace(
                    key: ValueKey('die-$index'),
                    value: _values[index],
                    size: faceSize,
                    sides: sides,
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

/// Enkele dobbelsteen-face in de vorm van het echte D&D-type (SCRUM-28):
/// tetraëder voor d4, plat vierkant voor d6, ruit voor d8, vlieger voor d10,
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
  /// de d4 moet de waarde kleiner en lager staan; de d6 vult zijn
  /// platte vierkant met ogen (SCRUM-35).
  double get _valueSize => switch (sides) {
        4 => size * 0.42,
        6 => size * 0.66,
        8 || 10 => size * 0.58,
        12 || 20 => size * 0.66,
        _ => size * 0.90,
      };

  Alignment get _valueAlignment => switch (sides) {
        4 => const Alignment(0, 0.18),
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
