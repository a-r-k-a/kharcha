import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/money.dart';

void main() {
  group('Money.tryParse', () {
    test('parses whole and fractional amounts exactly', () {
      expect(Money.tryParse('1240'), const Money(124000));
      expect(Money.tryParse('1240.5'), const Money(124050));
      expect(Money.tryParse('0.05'), const Money(5));
      expect(Money.tryParse('10.005'), isNull);
      expect(Money.tryParse('  42 '), const Money(4200));
    });

    test('accepts a trailing decimal point while typing', () {
      expect(Money.tryParse('5.'), const Money(500));
    });

    test('parses negatives', () {
      expect(Money.tryParse('-3.2'), const Money(-320));
    });

    test('respects zero-decimal currencies', () {
      expect(
        Money.tryParse('1500', currency: Currency.jpy),
        const Money(1500, currency: Currency.jpy),
      );
      expect(Money.tryParse('1500.5', currency: Currency.jpy), isNull);
    });

    test('rejects malformed input', () {
      for (final input in ['', 'abc', '.5', '1,000', '1.2.3', '--1', '+1']) {
        expect(Money.tryParse(input), isNull, reason: input);
      }
    });

    test('rejects more than 13 integer digits', () {
      expect(Money.tryParse('9999999999999'), isNotNull);
      expect(Money.tryParse('10000000000000'), isNull);
    });
  });

  group('arithmetic', () {
    test('adds and subtracts in minor units', () {
      expect(const Money(150) + const Money(275), const Money(425));
      expect(const Money(150) - const Money(275), const Money(-125));
      expect(-const Money(10), const Money(-10));
    });

    test('multiplies with half-away-from-zero rounding', () {
      expect(const Money(101) * 0.5, const Money(51));
      expect(const Money(-101) * 0.5, const Money(-51));
    });

    test('divide rounds each share', () {
      expect(const Money(100000).divide(30), const Money(3333));
      expect(() => const Money(1).divide(0), throwsArgumentError);
    });

    test('allocate sums back exactly', () {
      final shares = const Money(1000).allocate(3);
      expect(shares, const [Money(334), Money(333), Money(333)]);
      expect(shares.fold<int>(0, (sum, m) => sum + m.minorUnits), 1000);

      final negative = const Money(-7).allocate(3);
      expect(negative.fold<int>(0, (sum, m) => sum + m.minorUnits), -7);
    });

    test('ratioOf handles a zero whole', () {
      expect(const Money(250).ratioOf(const Money(1000)), 0.25);
      expect(const Money(250).ratioOf(const Money.zero()), 0);
    });

    test('clampToZero and abs', () {
      expect(const Money(-5).clampToZero(), const Money.zero());
      expect(const Money(-5).abs(), const Money(5));
    });

    test('mixing currencies throws', () {
      expect(
        () => const Money(1) + const Money(1, currency: Currency.usd),
        throwsArgumentError,
      );
    });

    test('comparison operators', () {
      expect(const Money(1) < const Money(2), isTrue);
      expect(const Money(2) >= const Money(2), isTrue);
    });
  });
}
