import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'dice_model.dart';

/// Eén geschat vlak van de geprojecteerde dobbelsteen: de omtrek in
/// schermcoördinaten, de helderheid (0..1) en de diepte (groter is
/// verder weg), klaar voor de schildersvolgorde.
class ShadedFace {
  const ShadedFace({
    required this.outline,
    required this.brightness,
    required this.depth,
  });

  /// Omtrek van het vlak in schermcoördinaten.
  final List<Offset> outline;

  /// Helderheid van het vlak, 0 (donker) tot 1 (licht).
  final double brightness;

  /// Diepte van het vlakcentrum: groter betekent verder weg.
  final double depth;
}

/// Roteert en projecteert veelvlakken naar 2D met eenvoudige
/// lamport-achtige belichting: genoeg voor het silhouet van een
/// dobbelsteen, zonder zware 3D-dependencies (SCRUM-31).
class DiceProjection {
  DiceProjection._();

  /// Vaste lichtbron in beeldruimte, schuin van boven rechts.
  static final Vec3 _light = Vec3(0.35, -0.45, 0.8).normalized();

  /// Roteert het model: eerst yaw rond de Y-as, dan pitch rond de
  /// X-as. Alle hoekpunten houden hun afstand tot het midden.
  static Polyhedron rotate(Polyhedron model, {double yaw = 0.0, double pitch = 0.0}) {
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    Vec3 rotatePoint(Vec3 v) {
      // Yaw rond de Y-as.
      final x1 = v.x * cosY + v.z * sinY;
      final z1 = -v.x * sinY + v.z * cosY;
      // Pitch rond de X-as.
      final y2 = v.y * cosP - z1 * sinP;
      final z2 = v.y * sinP + z1 * cosP;
      return Vec3(x1, y2, z2);
    }

    return Polyhedron(
      [for (final v in model.vertices) rotatePoint(v)],
      model.faces,
    );
  }

  /// Projecteert het model naar een vierkant van [size] bij [size]
  /// en sorteert de vlakken van achter naar voren, zodat de tekenaar
  /// ze in volgorde kan vullen.
  static List<ShadedFace> project(Polyhedron model,
      {double yaw = 0.0, double pitch = 0.0, required double size}) {
    final rotated = rotate(model, yaw: yaw, pitch: pitch);
    final center = Offset(size / 2, size / 2);
    // Iets marge rond de steen: de genormaliseerde straal is 1.
    final scale = size * 0.45;

    final faces = <ShadedFace>[];
    for (final face in rotated.faces) {
      final normal = rotated.faceNormal(face);
      final brightness =
          (0.25 + 0.75 * math.max(0.0, normal.dot(_light))).clamp(0.0, 1.0);

      final faceCenter = rotated.faceCenter(face);
      final outline = <Offset>[
        for (final index in face)
          Offset(
            center.dx + rotated.vertices[index].x * scale,
            center.dy + rotated.vertices[index].y * scale,
          ),
      ];
      faces.add(ShadedFace(
        outline: outline,
        brightness: brightness,
        depth: faceCenter.z,
      ));
    }

    faces.sort((a, b) => b.depth.compareTo(a.depth));
    return faces;
  }
}
