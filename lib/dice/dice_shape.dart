import 'package:flutter/material.dart';

import '../casino_theme.dart';
import 'dice_model.dart';
import 'dice_projection.dart';

/// De drie zichtbare vlakken van de kubus, in genormaliseerde
/// coördinaten (0.0 t/m 1.0).
class CubeFaces {
  const CubeFaces({required this.front, required this.top, required this.side});

  /// Frontvlak: het vierkant waar de ogen op staan.
  final List<Offset> front;

  /// Bovenvlak: parallellogram rechtsboven het frontvlak.
  final List<Offset> top;

  /// Zijvlak: parallellogram rechts naast het frontvlak.
  final List<Offset> side;
}

/// Genormaliseerde kubus met dieptekant van 16%: front, boven en zijkant.
///
/// De kubus vult het vlak met een kleine marge, zodat de gouden
/// contourlijn binnen de opgegeven grootte blijft.
CubeFaces cubeFaces() => const CubeFaces(
      front: [
        Offset(0.02, 0.18),
        Offset(0.82, 0.18),
        Offset(0.82, 0.98),
        Offset(0.02, 0.98),
      ],
      top: [
        Offset(0.02, 0.18),
        Offset(0.18, 0.02),
        Offset(0.98, 0.02),
        Offset(0.82, 0.18),
      ],
      side: [
        Offset(0.82, 0.18),
        Offset(0.98, 0.02),
        Offset(0.98, 0.82),
        Offset(0.82, 0.98),
      ],
    );

/// Vormgetrouwe dobbelsteen-graphic per type (SCRUM-28/31).
///
/// Elke steen is een echt 3D-object (SCRUM-31): de polyhedronmodellen
/// uit [dice_model] worden geroteerd, belicht en vlak voor vlak
/// getekend in schildersvolgorde. De d6 tekent als klassieke
/// isometrische kubus met frontvlak voor de ogen (SCRUM-30). De
/// vormgeving gebruikt het casino-palet: ivoor met goud, donkere
/// vlakken schaduwen richting tafelgroen.
class DiceShape extends StatelessWidget {
  const DiceShape({super.key, required this.sides, required this.size});

  /// Aantal zijden van de dobbelsteen die getekend moet worden.
  final int sides;

  /// Zijde van de graphic in logical pixels; schaalt mee met het scherm.
  final double size;

  /// Of er een vormgetrouwe graphic bestaat voor dit aantal zijden.
  static bool supports(int sides) => const [4, 6, 8, 10, 12, 20].contains(sides);

  /// Het 3D-model achter deze steen (SCRUM-31): vertices en vlakken
  /// van het bijbehorende veelvlak, genormaliseerd op straal 1.
  Polyhedron get model => polyhedronFor(sides);

  /// Vaste stand waarin elke steen getekend wordt: een kwartslag
  /// gedraaid en licht gekanteld, zodat meerdere vlakken zichtbaar zijn.
  static const double viewYaw = 0.55;
  static const double viewPitch = 0.38;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiceShapePainter(
          sides: sides,
          model: sides == 6 ? null : model,
          isCube: sides == 6,
          strokeColor: CasinoColors.gold,
          fillColor: CasinoColors.dieFace,
          strokeWidth: size * 0.05,
        ),
      ),
    );
  }
}

/// Tekent de dobbelsteen: 3D-projectie met belichting, of voor de d6
/// de klassieke kubus met gouden contourlijnen.
class _DiceShapePainter extends CustomPainter {
  const _DiceShapePainter({
    required this.sides,
    required this.model,
    required this.isCube,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final int sides;
  final Polyhedron? model;
  final bool isCube;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth.clamp(1.0, size.width / 12);
    if (isCube) {
      _paintCube(canvas, size, stroke);
      return;
    }
    if (model != null) {
      _paint3D(canvas, size, stroke);
    }
  }

  /// Echte 3D-weergave (SCRUM-31): het model wordt geroteerd en
  /// belicht; de vlakken worden van achter naar voren gevuld. Lichte
  /// vlakken zijn ivoor, donkere vlakken schaduwen richting donker
  /// tafelgroen, en de gouden contour verheldert met het licht.
  void _paint3D(Canvas canvas, Size size, double stroke) {
    final faces = DiceProjection.project(model!,
        yaw: DiceShape.viewYaw,
        pitch: DiceShape.viewPitch,
        size: size.width);

    final outline = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;

    for (final face in faces) {
      final path = Path()..addPolygon(face.outline, true);
      // Donkere vlakken zakken richting de grijze schaduwkleur.
      final fill = Paint()
        ..color = Color.lerp(
            CasinoColors.dieShadow, fillColor, face.brightness)!
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
      // Contour meebewegen met het licht: donkere randen blijven subtiel.
      canvas.drawPath(
        path,
        outline
          ..color = strokeColor.withValues(alpha: 0.35 + 0.65 * face.brightness),
      );
    }
  }

  /// Isometrische kubus (SCRUM-30): gouden bovenvlak, gearceerde zijkant
  /// en een ivoorkleurig frontvlak met gouden contourlijnen.
  void _paintCube(Canvas canvas, Size size, double stroke) {
    final faces = cubeFaces();
    Path scaled(List<Offset> face) => Path()
      ..addPolygon(
        [
          for (final point in face)
            Offset(point.dx * size.width, point.dy * size.height),
        ],
        true,
      );

    final depth = stroke / 2;
    final shrink = Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height / 2, 0.0, 1.0)
      ..scaleByDouble(1 - depth / size.width, 1 - depth / size.height, 1.0, 1.0)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0.0, 1.0);

    final topPath = scaled(faces.top).transform(shrink.storage);
    final sidePath = scaled(faces.side).transform(shrink.storage);
    final frontPath = scaled(faces.front).transform(shrink.storage);

    // Volgorde: eerst boven- en zijvlak, dan het frontvlak eroverheen.
    final goldFill = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    final sideFill = Paint()
      ..color = _shadedFace()
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPath, goldFill);
    canvas.drawPath(sidePath, sideFill);
    canvas.drawPath(frontPath, Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill);
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    for (final path in [topPath, sidePath, frontPath]) {
      canvas.drawPath(path, strokePaint);
    }
  }

  /// Gearceerde zijkant: wit met een vleug grijs, zodat de
  /// kubusdiepte leesbaar blijft bij een witte steen (SCRUM-33).
  Color _shadedFace() {
    return Color.alphaBlend(
      CasinoColors.dieShadow.withValues(alpha: 0.12),
      fillColor,
    );
  }

  @override
  bool shouldRepaint(covariant _DiceShapePainter old) =>
      old.sides != sides ||
      old.strokeColor != strokeColor ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth;
}
