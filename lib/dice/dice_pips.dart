import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../casino_theme.dart';

/// Klassieke ogenpatronen: positie (raster -1 t/m 1) per oog voor 1 t/m 8 ogen.
const Map<int, List<Alignment>> kPipLayouts = {
  1: [Alignment.center],
  2: [Alignment(-1, -1), Alignment(1, 1)],
  3: [Alignment(-1, -1), Alignment.center, Alignment(1, 1)],
  4: [
    Alignment(-1, -1),
    Alignment(1, -1),
    Alignment(-1, 1),
    Alignment(1, 1),
  ],
  5: [
    Alignment(-1, -1),
    Alignment(1, -1),
    Alignment.center,
    Alignment(-1, 1),
    Alignment(1, 1),
  ],
  6: [
    Alignment(-1, -1),
    Alignment(1, -1),
    Alignment(-1, 0),
    Alignment(1, 0),
    Alignment(-1, 1),
    Alignment(1, 1),
  ],
  7: [
    Alignment(-1, -1),
    Alignment(1, -1),
    Alignment(-1, 0),
    Alignment(1, 0),
    Alignment(-1, 1),
    Alignment(1, 1),
    Alignment.center,
  ],
  8: [
    Alignment(-1, -1),
    Alignment(0, -1),
    Alignment(1, -1),
    Alignment(-1, 0),
    Alignment(1, 0),
    Alignment(-1, 1),
    Alignment(0, 1),
    Alignment(1, 1),
  ],
};

/// Tekent [count] ogen, geschaald naar [size].
///
/// Waarden 1 t/m 8 gebruiken de klassieke patronen hierboven; hogere
/// waarden (9 t/m 20 voor d10, d12 en d20, SCRUM-20) krijgen een
/// dicht, regelmatig roosterpatroon. Sinds SCRUM-20 tonen alle stenen
/// ogen in plaats van nummers.
class DicePips extends StatelessWidget {
  const DicePips({super.key, required this.count, required this.size});

  final int count;
  final double size;

  /// Of deze waarde als ogenpatroon getoond kan worden.
  static bool supports(int value) => value >= 1 && value <= 20;

  /// Roosterpatroon voor waarden zonder klassiek patroon: zo vierkant
  /// mogelijk, waarbij een incomplete laatste rij gecentreerd wordt.
  static List<Alignment> _gridLayout(int value) {
    final columns = math.sqrt(value).ceil();
    final rows = (value / columns).ceil();
    final positions = <Alignment>[];
    for (var i = 0; i < value; i++) {
      final row = i ~/ columns;
      final inRow = row == rows - 1 ? value - row * columns : columns;
      final column = i % columns;
      final shift = (columns - inRow) / 2;
      final x = columns == 1 ? 0.0 : (2 * (column + shift) / (columns - 1) - 1);
      final y = rows == 1 ? 0.0 : (2 * row / (rows - 1) - 1);
      positions.add(Alignment(x * 0.55, y * 0.55));
    }
    return positions;
  }

  /// Diameter van een oog, kleiner zodra het patroon dichter wordt.
  double _pipDiameter(int value) {
    final columns = math.sqrt(value).ceil();
    final spacing = columns == 1 ? size * 0.55 : size * 0.55 / (columns - 1);
    return (size * 0.17).clamp(0.0, spacing * 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final positions =
        kPipLayouts[count] ?? _gridLayout(count);
    final pipDiameter = _pipDiameter(count);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (final position in positions)
            Align(
              alignment: position,
              child: Container(
                key: const Key('pip'),
                width: pipDiameter,
                height: pipDiameter,
                decoration: BoxDecoration(
                  color: CasinoColors.dieValue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
