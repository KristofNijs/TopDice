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

/// Tekent [count] ogen in het klassieke patroon, geschaald naar [size].
///
/// Waarden zonder klassiek patroon (9 en hoger, zoals d10/d12/d20) worden
/// door de aanroeper als cijfer weergegeven, zoals bij echte dobbelstenen.
class DicePips extends StatelessWidget {
  const DicePips({super.key, required this.count, required this.size});

  final int count;
  final double size;

  /// Of er een klassiek ogenpatroon bestaat voor deze waarde.
  static bool supports(int value) => kPipLayouts.containsKey(value);

  @override
  Widget build(BuildContext context) {
    final positions = kPipLayouts[count]!;
    final pipDiameter = size * 0.17;
    // Factor 0,55 houdt de ogen net binnen de afgeronde hoeken.
    Alignment pipPosition(Alignment position) =>
        Alignment(position.x * 0.55, position.y * 0.55);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (final position in positions)
            Align(
              alignment: pipPosition(position),
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
