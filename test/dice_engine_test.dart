import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:topdice/dice/dice_engine.dart';

void main() {
  group('DiceEngine.roll', () {
    test('returns one value per requested die', () {
      final results = DiceEngine.roll(count: 3, sides: 6, random: Random(42));
      expect(results.length, 3);
    });

    test('every value is between 1 and the number of sides', () {
      final results = DiceEngine.roll(count: 50, sides: 6, random: Random(7));
      expect(results.every((v) => v >= 1 && v <= 6), isTrue);
    });

    test('same seed produces the same roll, different seed does not', () {
      final a = DiceEngine.roll(count: 5, sides: 6, random: Random(1));
      final b = DiceEngine.roll(count: 5, sides: 6, random: Random(1));
      final c = DiceEngine.roll(count: 5, sides: 6, random: Random(2));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('throws ArgumentError when count is zero or negative', () {
      expect(() => DiceEngine.roll(count: 0, sides: 6, random: Random(1)),
          throwsArgumentError);
      expect(() => DiceEngine.roll(count: -2, sides: 6, random: Random(1)),
          throwsArgumentError);
    });

    test('throws ArgumentError when sides is smaller than two', () {
      expect(() => DiceEngine.roll(count: 1, sides: 1, random: Random(1)),
          throwsArgumentError);
      expect(() => DiceEngine.roll(count: 1, sides: 0, random: Random(1)),
          throwsArgumentError);
    });

    test('supports polyhedral dice such as d4, d8, d12 and d20', () {
      for (final sides in [4, 8, 12, 20]) {
        final results =
            DiceEngine.roll(count: 20, sides: sides, random: Random(3));
        expect(results.every((v) => v >= 1 && v <= sides), isTrue,
            reason: 'failed for d$sides');
      }
    });

    test('defaults to one six-sided die when only a random is provided', () {
      final results = DiceEngine.roll(random: Random(5));
      expect(results.length, 1);
      expect(results.single, inInclusiveRange(1, 6));
    });
  });

  group('Muntje (SCRUM-20)', () {
    test('een muntje is een worp met twee zijden: alleen 1 of 2', () {
      final results = DiceEngine.roll(count: 50, sides: 2, random: Random(3));
      expect(results.every((v) => v == 1 || v == 2), isTrue,
          reason: 'Een muntje kent alleen kop en munt.');
    });

    test('werpwaarde 1 betekent kop en werpwaarde 2 betekent munt', () {
      expect(CoinSide.fromRoll(1), CoinSide.kop);
      expect(CoinSide.fromRoll(2), CoinSide.munt);
    });

    test('andere werpwaarden zijn geen geldige muntzijde', () {
      expect(() => CoinSide.fromRoll(0), throwsArgumentError);
      expect(() => CoinSide.fromRoll(3), throwsArgumentError);
    });

    test('elke muntzijde heeft een leesbaar Nederlands label', () {
      expect(CoinSide.kop.label, 'kop');
      expect(CoinSide.munt.label, 'munt');
    });
  });
}
