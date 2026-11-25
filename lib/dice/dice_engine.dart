import 'dart:math';

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
