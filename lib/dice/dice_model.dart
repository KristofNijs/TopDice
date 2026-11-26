import 'dart:math' as math;

/// Punt in 3D, klein en puur: alleen wat de projectie nodig heeft.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  double get length => math.sqrt(dot(this));

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator *(double factor) => Vec3(x * factor, y * factor, z * factor);

  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;

  Vec3 cross(Vec3 other) => Vec3(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
      );

  Vec3 normalized() {
    final l = length;
    return l == 0 ? this : this * (1.0 / l);
  }
}

/// Convex veelvlak: hoekpunten plus vlakken als cyclische indexlijsten.
class Polyhedron {
  const Polyhedron(this.vertices, this.faces);

  /// Hoekpunten van het veelvlak.
  final List<Vec3> vertices;

  /// Vlakken, elk geordend rond de omtrek; indices in [vertices].
  final List<List<int>> faces;

  int get vertexCount => vertices.length;
  int get faceCount => faces.length;

  /// Zwaartepunt van alle hoekpunten.
  Vec3 get center {
    var sx = 0.0, sy = 0.0, sz = 0.0;
    for (final v in vertices) {
      sx += v.x;
      sy += v.y;
      sz += v.z;
    }
    return Vec3(sx / vertices.length, sy / vertices.length, sz / vertices.length);
  }

  /// Aantal ribben: elke rib precies een keer, gedeeld door twee vlakken.
  int get edgeCount {
    final edges = <String>{};
    for (final face in faces) {
      for (var i = 0; i < face.length; i++) {
        final a = face[i];
        final b = face[(i + 1) % face.length];
        edges.add(a < b ? '$a-$b' : '$b-$a');
      }
    }
    return edges.length;
  }

  /// Middelpunt van een vlak.
  Vec3 faceCenter(List<int> face) {
    var sx = 0.0, sy = 0.0, sz = 0.0;
    for (final i in face) {
      final v = vertices[i];
      sx += v.x;
      sy += v.y;
      sz += v.z;
    }
    final n = face.length.toDouble();
    return Vec3(sx / n, sy / n, sz / n);
  }

  /// Normal van een vlak, gegarandeerd naar buiten (van het midden af).
  Vec3 faceNormal(List<int> face) {
    final a = vertices[face[0]];
    final b = vertices[face[1]];
    final c = vertices[face[2]];
    var normal = (b - a).cross(c - a).normalized();
    if (normal.dot(faceCenter(face) - center) < 0) {
      normal = normal * -1.0;
    }
    return normal;
  }
}

/// Genormaliseerd model per dobbelsteentype (SCRUM-31): tetraëder, kubus,
/// octaëder, pentagonale trapezoëder, dodecaëder en icosaëder.
Polyhedron polyhedronFor(int sides) {
  switch (sides) {
    case 4:
      return _normalize(_tetrahedron());
    case 6:
      return _normalize(_cube());
    case 8:
      return _normalize(_octahedron());
    case 10:
      return _normalize(_trapezohedron());
    case 12:
      return _normalize(_dodecahedron());
    case 20:
      return _normalize(_icosahedron());
    default:
      throw ArgumentError.value(
          sides, 'sides', 'Er is geen 3D-model voor dit aantal zijden.');
  }
}

/// Schalen zodat de verste hoekpunt afstand 1 heeft: alle stenen hebben
/// dan dezelfde visuele omvang, onafhankelijk van het soort veelvlak.
Polyhedron _normalize(Polyhedron model) {
  final max = model.vertices
      .map((v) => v.length)
      .reduce((a, b) => a > b ? a : b);
  return Polyhedron(
    [for (final v in model.vertices) v * (1.0 / max)],
    model.faces,
  );
}

Polyhedron _tetrahedron() {
  final vertices = [
    Vec3(1, 1, 1),
    Vec3(1, -1, -1),
    Vec3(-1, 1, -1),
    Vec3(-1, -1, 1),
  ];
  return Polyhedron(vertices, _hullFaces(vertices));
}

Polyhedron _cube() {
  final vertices = [
    for (final x in [-1.0, 1.0])
      for (final y in [-1.0, 1.0])
        for (final z in [-1.0, 1.0]) Vec3(x, y, z),
  ];
  return Polyhedron(vertices, _hullFaces(vertices));
}

Polyhedron _octahedron() {
  final vertices = [
    Vec3(1, 0, 0),
    Vec3(-1, 0, 0),
    Vec3(0, 1, 0),
    Vec3(0, -1, 0),
    Vec3(0, 0, 1),
    Vec3(0, 0, -1),
  ];
  return Polyhedron(vertices, _hullFaces(vertices));
}

/// Pentagonale trapezoëder (d10): twee toppen en tien equatoriale
/// hoekpunten om en om hoog/laag; tien vliegervlakken. De top-hoogte
/// volgt uit de eis dat de vier hoekpunten van elk vliegervlak
/// coplanair zijn; exact berekend, zodat de steunvlak-test ze herkent.
Polyhedron _trapezohedron() {
  const ringZ = 0.15;
  final apexZ = _trapezohedronApexHeight(ringZ);
  final vertices = <Vec3>[
    Vec3(0, 0, apexZ), // top
    Vec3(0, 0, -apexZ), // onder
  ];
  for (var i = 0; i < 10; i++) {
    final angle = i * math.pi / 5;
    final z = i.isEven ? ringZ : -ringZ;
    vertices.add(Vec3(math.cos(angle), math.sin(angle), z));
  }
  return Polyhedron(vertices, _hullFaces(vertices));
}

/// Top-hoogte waarbij top, twee hoge ringpunten en het ertussen liggende
/// lage ringpunt precies in één vlak liggen (coplanaire vliegervlakken).
double _trapezohedronApexHeight(double ringZ) {
  final step = math.pi / 5; // 36°.
  final a = math.sin(2 * step) * math.cos(step) +
      (1 - math.cos(2 * step)) * math.sin(step);
  final s = math.sin(2 * step);
  return ringZ * (a + s) / (a - s);
}

Polyhedron _dodecahedron() {
  // De dodecaëder is de duaal van de icosaëder: de centra van de
  // twintig icosaëdervlakken zijn de hoekpunten van de dodecaëder,
  // en rond elk icosaëderhoekpunt vormen de aangrenzende
  // vlakcentra een pentagonvlak. Zo zijn de vlakken per constructie
  // juist, zonder rompberekening met kans op schijnvlakken.
  final ico = _icosahedron();
  final centers = [for (final face in ico.faces) ico.faceCenter(face)];
  final faces = <List<int>>[];
  for (var v = 0; v < ico.vertices.length; v++) {
    final ring = <int>[
      for (var f = 0; f < ico.faces.length; f++)
        if (ico.faces[f].contains(v)) f,
    ];
    faces.add(_orderAroundFace(centers, ring));
  }
  return Polyhedron(centers, faces);
}

Polyhedron _icosahedron() {
  final phi = (1 + math.sqrt(5)) / 2;
  final vertices = <Vec3>[
    for (final a in [-1.0, 1.0])
      for (final b in [-phi, phi]) Vec3(0, a, b),
    for (final a in [-1.0, 1.0])
      for (final b in [-phi, phi]) Vec3(a, b, 0),
    for (final a in [-1.0, 1.0])
      for (final b in [-phi, phi]) Vec3(b, 0, a),
  ];
  return Polyhedron(vertices, _hullFaces(vertices));
}

/// Bepaalt de vlakken van een convex veelvlak via steunvlakken: elk
/// vlak is een vlak waarvan alle hoekpunten aan één kant liggen. Een
/// kandidaat is pas een echt vlak als alle opeenvolgende hoekpuntparen
/// ribben van de romp zijn: anders is het een "driepoot"-rustvlak dat
/// de steen maar in drie punten raakt. De hoekpunten van elk vlak
/// worden cyclisch rond de omtrek geordend.
List<List<int>> _hullFaces(List<Vec3> vertices) {
  final candidates = <List<int>>[];
  final n = vertices.length;

  bool onPlane(Vec3 a, Vec3 b, Vec3 c, Vec3 p, double eps) {
    return ((b - a).cross(c - a)).dot(p - a).abs() <= eps;
  }

  bool isSupporting(Vec3 a, Vec3 b, Vec3 c) {
    final normal = (b - a).cross(c - a);
    var positive = false;
    var negative = false;
    for (var m = 0; m < n; m++) {
      final d = normal.dot(vertices[m] - a);
      if (d > 1e-9) positive = true;
      if (d < -1e-9) negative = true;
    }
    return !(positive && negative);
  }

  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      for (var k = j + 1; k < n; k++) {
        final a = vertices[i];
        final b = vertices[j];
        final c = vertices[k];
        if ((b - a).cross(c - a).length < 1e-9) {
          continue; // collineair drietal.
        }
        if (!isSupporting(a, b, c)) {
          continue; // Snijdt het binnenste: geen steunvlak.
        }
        // Alle hoekpunten op dit steunvlak vormen samen de kandidaat.
        final face = <int>[];
        for (var m = 0; m < n; m++) {
          if (onPlane(a, b, c, vertices[m], 1e-9)) {
            face.add(m);
          }
        }
        if (face.length < 3) {
          continue;
        }
        final ordered = _orderAroundFace(vertices, face);
        if (!_containsFace(candidates, ordered)) {
          candidates.add(ordered);
        }
      }
    }
  }

  // Ribben van de romp: een paar is een ribbe als er een steunvlak
  // door beide hoekpunten bestaat.
  final edges = <String>{};
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (_isHullEdge(vertices, i, j)) {
        edges.add(i < j ? '$i-$j' : '$j-$i');
      }
    }
  }

  return [
    for (final face in candidates)
      if (_isRealFace(face, edges)) face,
  ];
}

/// Of dit paar hoekpunten op de rand van de romp ligt: er bestaat dan
/// een vlak door beide punten met alle overige punten aan één kant.
bool _isHullEdge(List<Vec3> vertices, int i, int j) {
  final n = vertices.length;
  final a = vertices[i];
  final b = vertices[j];
  for (var k = 0; k < n; k++) {
    if (k == i || k == j) continue;
    final normal = (b - a).cross(vertices[k] - a);
    if (normal.length < 1e-9) continue;
    var positive = false;
    var negative = false;
    for (var m = 0; m < n; m++) {
      final d = normal.dot(vertices[m] - a);
      if (d > 1e-9) positive = true;
      if (d < -1e-9) negative = true;
    }
    if (!(positive && negative)) {
      return true;
    }
  }
  return false;
}

/// Een kandidaat-vlak is echt als elke opeenvolgende paar hoekpunten
/// verbonden is met een ribbe van de romp.
bool _isRealFace(List<int> face, Set<String> hullEdges) {
  for (var i = 0; i < face.length; i++) {
    final a = face[i];
    final b = face[(i + 1) % face.length];
    final key = a < b ? '$a-$b' : '$b-$a';
    if (!hullEdges.contains(key)) {
      return false;
    }
  }
  return true;
}

/// Ordent vlakhoekpunten cyclisch: sorteren op hoek rond de vlaknormal.
List<int> _orderAroundFace(List<Vec3> vertices, List<int> face) {
  final model = Polyhedron(vertices, [face]);
  final center = model.faceCenter(face);
  final normal = model.faceNormal(face);
  // Rechthoekige basis in het vlak om hoeken te kunnen meten.
  final helper = normal.x.abs() < 0.9 ? Vec3(1, 0, 0) : Vec3(0, 1, 0);
  final u = normal.cross(helper).normalized();
  final v = normal.cross(u);

  final entries = face.map((index) {
    final d = vertices[index] - center;
    return (index, math.atan2(d.dot(v), d.dot(u)));
  }).toList()
    ..sort((x, y) => x.$2.compareTo(y.$2));
  return entries.map((e) => e.$1).toList();
}

bool _containsFace(List<List<int>> known, List<int> face) {
  final set = face.toSet();
  return known.any((f) => f.toSet().containsAll(set) && set.containsAll(f));
}
