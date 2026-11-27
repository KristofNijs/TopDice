import 'package:flutter/material.dart';

import '../casino_theme.dart';

/// Vormgetrouwe D&D-graphic per dobbelsteentype (SCRUM-28).
///
/// Tekent het herkenbare silhouet van elke dobbelsteen: tetraëder voor
/// d4, plat vierkant voor d6, ruit voor d8, vlieger voor d10,
/// vijfhoek voor d12 en zeshoek voor d20. De vormgeving gebruikt het
/// casino-palet: ivoorkleurig vlak met een gouden contourlijn.
class DiceShape extends StatelessWidget {
  const DiceShape({super.key, required this.sides, required this.size});

  /// Aantal zijden van de dobbelsteen die getekend moet worden.
  final int sides;

  /// Zijde van de graphic in logical pixels; schaalt mee met het scherm.
  final double size;

  /// Of er een vormgetrouwe graphic bestaat voor dit aantal zijden.
  static bool supports(int sides) => const [4, 6, 8, 10, 12, 20].contains(sides);

  /// Hoekpunten van de vorm in een genormaliseerd vlak (0.0 t/m 1.0).
  List<Offset>? get _polygon {
    switch (sides) {
      case 4:
        // Tetraëder van boven gezien: driehoek.
        return const [
          Offset(0.50, 0.02),
          Offset(0.98, 0.98),
          Offset(0.02, 0.98),
        ];
      case 6:
        // Platte d6: vierkant silhouet (SCRUM-35).
        return const [
          Offset(0.02, 0.02),
          Offset(0.98, 0.02),
          Offset(0.98, 0.98),
          Offset(0.02, 0.98),
        ];
      case 8:
        // Ruit van twee tetraëders.
        return const [
          Offset(0.50, 0.01),
          Offset(0.99, 0.50),
          Offset(0.50, 0.99),
          Offset(0.01, 0.50),
        ];
      case 10:
        // Vliegervorm van de d10 (pentagonal trapezohedron).
        return const [
          Offset(0.50, 0.01),
          Offset(0.90, 0.35),
          Offset(0.50, 0.99),
          Offset(0.10, 0.35),
        ];
      case 12:
        // Vijfhoek van de dodecaëder.
        return const [
          Offset(0.50, 0.01),
          Offset(0.99, 0.39),
          Offset(0.80, 0.99),
          Offset(0.20, 0.99),
          Offset(0.01, 0.39),
        ];
      case 20:
        // Zeshoek van de icosaëder.
        return const [
          Offset(0.50, 0.01),
          Offset(0.99, 0.26),
          Offset(0.99, 0.74),
          Offset(0.50, 0.99),
          Offset(0.01, 0.74),
          Offset(0.01, 0.26),
        ];
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiceShapePainter(
          polygon: _polygon,
          strokeColor: CasinoColors.gold,
          fillColor: CasinoColors.dieFace,
          strokeWidth: size * 0.05,
        ),
      ),
    );
  }
}

/// Tekent de silhouetvulling en de gouden contour van een dobbelsteen.
class _DiceShapePainter extends CustomPainter {
  const _DiceShapePainter({
    required this.polygon,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final List<Offset>? polygon;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth.clamp(1.0, size.width / 12);
    if (polygon == null) {
      return;
    }
    final outline = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final points = [
      for (final point in polygon!)
        Offset(point.dx * size.width, point.dy * size.height),
    ];
    final path = Path()..addPolygon(points, true);
    // Iets opspringen zodat de contour op de rand blijft en niet afgesneden.
    final center = Offset(size.width / 2, size.height / 2);
    final shrunk = _shrink(path, center, stroke / 2);

    canvas.drawPath(shrunk, fill);
    canvas.drawPath(shrunk, outline);
  }

  /// Trekt de polygon een halve lijnbreedte richting het middelpunt,
  /// zodat de volledige contour binnen de opgegeven grootte blijft.
  Path _shrink(Path path, Offset center, double amount) {
    final matrix = Matrix4.identity();
    final bounds = path.getBounds();
    final w = bounds.width;
    final h = bounds.height;
    if (w == 0 || h == 0) {
      return path;
    }
    matrix.translateByDouble(center.dx, center.dy, 0.0, 1.0);
    final scale = Matrix4.identity()
      ..scaleByDouble(
          (w - 2 * amount) / w, (h - 2 * amount) / h, 1.0, 1.0);
    matrix.multiply(scale);
    matrix.translateByDouble(-center.dx, -center.dy, 0.0, 1.0);
    return path.transform(matrix.storage);
  }

  @override
  bool shouldRepaint(covariant _DiceShapePainter old) =>
      old.polygon != polygon ||
      old.strokeColor != strokeColor ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth;
}
