import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/dice/dice_model.dart';
import 'package:topdice/dice/dice_projection.dart';

void main() {
  group('3D-projectie (SCRUM-31)', () {
    test('rotatie behoudt alle hoekpunten en hun afstand tot het midden', () {
      final model = polyhedronFor(20);
      final before = model.vertices.map((v) => v.length).toList();

      final rotated = DiceProjection.rotate(model,
          yaw: 0.7, pitch: -0.4);

      expect(rotated.vertexCount, model.vertexCount);
      final after = rotated.vertices.map((v) => v.length).toList();
      for (var i = 0; i < before.length; i++) {
        expect(after[i], closeTo(before[i], 0.0001),
            reason: 'Rotatie mag geen vorm vervormen.');
      }
    });

    test('elk vlak krijgt een helderheid tussen 0 en 1', () {
      final model = polyhedronFor(12);

      final faces = DiceProjection.project(model,
          yaw: 0.5, pitch: 0.3, size: 96.0);

      expect(faces.length, model.faceCount,
          reason: 'Elk vlak van de steen wordt geprojecteerd.');
      for (final face in faces) {
        expect(face.brightness, inInclusiveRange(0.0, 1.0));
        expect(face.outline.length, greaterThanOrEqualTo(3));
      }
    });

    test('vlakken liggen van achter naar voren gesorteerd (schildersvolgorde)',
        () {
      final model = polyhedronFor(20);

      final faces = DiceProjection.project(model,
          yaw: 0.9, pitch: 0.2, size: 64.0);

      for (var i = 0; i + 1 < faces.length; i++) {
        expect(faces[i].depth, greaterThanOrEqualTo(faces[i + 1].depth),
            reason:
                'Verder weg liggende vlakken worden eerst getekend, dichtbij laatst.');
      }
    });

    test('de projectie blijft binnen de opgegeven grootte', () {
      final model = polyhedronFor(6);

      final faces = DiceProjection.project(model,
          yaw: 0.6, pitch: 0.35, size: 96.0);

      for (final face in faces) {
        for (final point in face.outline) {
          expect(point.dx, inInclusiveRange(-4.0, 100.0));
          expect(point.dy, inInclusiveRange(-4.0, 100.0));
        }
      }
    });

    test('een vlak naar het licht is helderder dan een vlak ervan af',
        () {
      final model = polyhedronFor(8);
      final faces = DiceProjection.project(model,
          yaw: 0.0, pitch: 0.0, size: 64.0);

      final brightest = faces
          .map((f) => f.brightness)
          .reduce((a, b) => a > b ? a : b);
      final darkest = faces
          .map((f) => f.brightness)
          .reduce((a, b) => a < b ? a : b);

      expect(brightest, greaterThan(darkest),
          reason: 'Belichting moet zichtbaar verschillen tussen vlakken.');
      expect(brightest - darkest, greaterThan(0.2),
          reason: 'Het contrast tussen belichte en donkere vlakken moet voelbaar zijn.');
    });
  });
}
