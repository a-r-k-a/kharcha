/// Supported currencies. Only the ISO code and minor-unit precision live in
/// the domain; symbols and grouping are a presentation concern.
enum Currency {
  inr('INR', 2),
  usd('USD', 2),
  eur('EUR', 2),
  gbp('GBP', 2),
  aed('AED', 2),
  sgd('SGD', 2),
  jpy('JPY', 0);

  const Currency(this.code, this.decimals);

  final String code;
  final int decimals;

  int get minorPerMajor => switch (decimals) {
    0 => 1,
    2 => 100,
    _ => throw StateError('Unsupported precision $decimals'),
  };

  static Currency? tryParse(String code) {
    for (final currency in values) {
      if (currency.code == code) return currency;
    }
    return null;
  }
}

/// An immutable amount of money held in integer minor units (paise for INR),
/// so budget arithmetic never accumulates floating-point drift.
///
/// Mixing currencies in arithmetic is a programming error and throws.
final class Money implements Comparable<Money> {
  const Money(this.minorUnits, {this.currency = Currency.inr});

  /// Rounds half away from zero to the currency's precision.
  ///
  /// Goes through floating point, so prefer [tryParse] for user input:
  /// `10.005 * 100` is `1000.4999…` in binary.
  factory Money.fromMajor(num major, {Currency currency = Currency.inr}) {
    return Money((major * currency.minorPerMajor).round(), currency: currency);
  }

  const Money.zero({this.currency = Currency.inr}) : minorUnits = 0;

  /// Parses a plain decimal string (`1240`, `1240.5`, `5.`) exactly, without
  /// floating point. Returns null for malformed input, more fraction digits
  /// than the currency allows, or more than 13 integer digits.
  static Money? tryParse(String input, {Currency currency = Currency.inr}) {
    final match = _decimalPattern.firstMatch(input.trim());
    if (match == null) return null;
    final whole = int.tryParse(match.group(2) ?? '');
    final fraction = match.group(3) ?? '';
    if (whole == null || fraction.length > currency.decimals) return null;

    final paddedFraction = fraction.padRight(currency.decimals, '0');
    final minor =
        whole * currency.minorPerMajor +
        (paddedFraction.isEmpty ? 0 : int.parse(paddedFraction));
    return Money(match.group(1) == null ? minor : -minor, currency: currency);
  }

  static final _decimalPattern = RegExp(r'^(-)?(\d{1,13})(?:\.(\d*))?$');

  final int minorUnits;
  final Currency currency;

  /// Major units as a double. For charts and ratios only; never feed this
  /// back into stored amounts.
  double get major => minorUnits / currency.minorPerMajor;

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency: currency);
  }

  Money operator -() => Money(-minorUnits, currency: currency);

  /// Multiplies and rounds half away from zero.
  Money operator *(num factor) =>
      Money((minorUnits * factor).round(), currency: currency);

  /// Divides into [parts] equal shares, rounding half away from zero.
  /// The shares may not sum back exactly; use [allocate] when they must.
  Money divide(int parts) {
    if (parts <= 0) {
      throw ArgumentError.value(parts, 'parts', 'must be positive');
    }
    return Money((minorUnits / parts).round(), currency: currency);
  }

  /// Splits into [parts] shares that sum exactly to this amount. The
  /// remainder is spread one minor unit at a time over the first shares.
  List<Money> allocate(int parts) {
    if (parts <= 0) {
      throw ArgumentError.value(parts, 'parts', 'must be positive');
    }
    final base = minorUnits ~/ parts;
    final remainder = minorUnits.remainder(parts);
    final step = remainder.sign;
    return List.generate(
      parts,
      (i) => Money(base + (i < remainder.abs() ? step : 0), currency: currency),
    );
  }

  /// This amount as a fraction of [whole]. Returns 0 when [whole] is zero.
  double ratioOf(Money whole) {
    _assertSameCurrency(whole);
    if (whole.minorUnits == 0) return 0;
    return minorUnits / whole.minorUnits;
  }

  Money abs() => isNegative ? -this : this;

  /// Clamps negative amounts to zero.
  Money clampToZero() => isNegative ? Money.zero(currency: currency) : this;

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Currency mismatch: ${currency.code} vs ${other.currency.code}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($minorUnits ${currency.code})';
}
