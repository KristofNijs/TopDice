import 'dart:math';

/// Zijde van een muntje: kop of munt.
enum CoinSide {
  kop,
  munt;

  /// Leesbaar label voor in de UI, met kleine letter zoals in een zin.
  String get label => this == CoinSide.kop ? 'kop' : 'munt';

  /// Vertaalt een muntworp (1 of 2) naar de bijbehorende zijde.
  static CoinSide fromRoll(int value) {
    if (value == 1) {
      return CoinSide.kop;
    }
    if (value == 2) {
      return CoinSide.munt;
    }
    throw ArgumentError.value(value, 'value', 'Alleen 1 (kop) en 2 (munt) zijn geldig.');
  }
}

/// Rolls dice: pure logic, random source injectable for testing.
class DiceEngine {
  /// Rolls [count] dice with [sides] eyes each.
  ///
  /// Every value lies between 1 and [sides] (inclusive).
  /// Throws [ArgumentError] if [count] < 1 or [sides] < 2.
  static List<int> roll({int count = 1, int sides = 6, required Random random}) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'Er is minstens één dobbelsteen nodig.');
    }
    if (sides < 2) {
      throw ArgumentError.value(sides, 'sides', 'Een dobbelsteen heeft minstens 2 zijden.');
    }
    return List<int>.generate(count, (_) => random.nextInt(sides) + 1);
  }
}
