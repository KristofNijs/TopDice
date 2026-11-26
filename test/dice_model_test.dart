import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/dice/dice_model.dart';

void main() {
  group('3D-modellen per dobbelsteentype (SCRUM-31)', () {
    test('elk type heeft het juiste aantal hoekpunten en vlakken', () {
      final expected = {
        4: (4, 4), // tetraëder
        6: (8, 6), // kubus
        8: (6, 8), // octaëder
        10: (12, 10), // pentagonale trapezoëder
        12: (20, 12), // dodecaëder
        20: (12, 20), // icosaëder
      };
      for (final entry in expected.entries) {
        final model = polyhedronFor(entry.key);
        expect(model.vertexCount, entry.value.$1,
            reason: 'd${entry.key} hoort ${entry.value.$1} hoekpunten te hebben.');
        expect(model.faceCount, entry.value.$2,
            reason: 'd${entry.key} hoort ${entry.value.$2} vlakken te hebben.');
      }
    });

    test('elke steen voldoet aan de formule van Euler (V - E + F = 2)', () {
      for (final sides in [4, 6, 8, 10, 12, 20]) {
        final model = polyhedronFor(sides);
        expect(model.vertexCount - model.edgeCount + model.faceCount, 2,
            reason:
                'd$sides moet een gesloten convex veelvlak zijn (Euler).');
      }
    });

    test('elk vlak heeft minstens drie hoekpunten en is cyclisch geordend',
        () {
      for (final sides in [4, 6, 8, 10, 12, 20]) {
        final model = polyhedronFor(sides);
        for (final face in model.faces) {
          expect(face.length, greaterThanOrEqualTo(3),
              reason: 'd$sides: elk vlak is minstens een driehoek.');
          expect(face.toSet().length, face.length,
              reason: 'd$sides: geen hoekpunt twee keer in een vlak.');
        }
      }
    });

    test('de vlakken liggen bol naar buiten gericht', () {
      for (final sides in [4, 6, 8, 10, 12, 20]) {
        final model = polyhedronFor(sides);
        final center = model.center;
        for (final face in model.faces) {
          final faceCenter = model.faceCenter(face);
          final normal = model.faceNormal(face);
          final outward = faceCenter - center;
          expect(normal.dot(outward), greaterThan(0),
              reason:
                  'd$sides: elk vlaknormal moet naar buiten wijzen voor correcte belichting.');
        }
      }
    });

    test('alle hoekpunten passen binnen de genormaliseerde straal', () {
      for (final sides in [4, 6, 8, 10, 12, 20]) {
        final model = polyhedronFor(sides);
        for (final vertex in model.vertices) {
          expect(vertex.length, lessThan(1.6),
              reason: 'd$sides: het model moet genormaliseerd zijn.');
        }
      }
    });
  });
}
