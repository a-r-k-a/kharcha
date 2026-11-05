import 'package:intl/intl.dart';

import '../domain/money.dart';

enum MoneyPrecision {
  /// Show the fraction only when it is non-zero: ₹1,240 / ₹1,240.50.
  auto,

  /// Always round to whole units: ₹1,241.
  whole,

  /// Always show the full fraction: ₹1,240.00.
  full,
}

/// A formatted amount split into the pieces `MoneyText` renders at
/// different sizes.
final class MoneyParts {
  const MoneyParts({
    required this.sign,
    required this.symbol,
    required this.integer,
    required this.fraction,
  });

  /// `−`, `+` or empty.
  final String sign;
  final String symbol;

  /// Grouped integer digits, e.g. `1,24,000`.
  final String integer;

  /// Decimal separator plus digits, e.g. `.50`, or empty.
  final String fraction;

  @override
  String toString() => '$sign$symbol$integer$fraction';
}

/// Formats [Money] for display. Grouping follows [locale]; the default
/// `en_IN` gives lakh/crore grouping (1,24,000).
final class MoneyFormatter {
  MoneyFormatter({this.locale = 'en_IN'});

  final String locale;
  final Map<int, NumberFormat> _decimalFormats = {};
  NumberFormat? _compactFormat;

  static const _symbols = {
    Currency.inr: '₹',
    Currency.usd: r'$',
    Currency.eur: '€',
    Currency.gbp: '£',
    Currency.aed: 'AED ',
    Currency.sgd: r'S$',
    Currency.jpy: '¥',
  };

  /// Typographic minus, not a hyphen.
  static const minusSign = '−';

  String symbolOf(Currency currency) => _symbols[currency] ?? currency.code;

  MoneyParts parts(
    Money money, {
    MoneyPrecision precision = MoneyPrecision.auto,
    bool signed = false,
  }) {
    final decimals = _decimalsFor(money, precision);
    final format = _decimalFormat(decimals);
    final formatted = format.format(money.abs().major);
    final separator = format.symbols.DECIMAL_SEP;
    final separatorIndex = formatted.indexOf(separator);
    final hasFraction = decimals > 0 && separatorIndex >= 0;

    return MoneyParts(
      sign: money.isNegative
          ? minusSign
          : (signed && money.isPositive ? '+' : ''),
      symbol: symbolOf(money.currency),
      integer: hasFraction ? formatted.substring(0, separatorIndex) : formatted,
      fraction: hasFraction ? formatted.substring(separatorIndex) : '',
    );
  }

  String format(
    Money money, {
    MoneyPrecision precision = MoneyPrecision.auto,
    bool signed = false,
  }) => parts(money, precision: precision, signed: signed).toString();

  /// Short form for chart axes and tight spaces: ₹1.2L, ₹45K.
  String compact(Money money) {
    final format = _compactFormat ??= NumberFormat.compact(locale: locale);
    final sign = money.isNegative ? minusSign : '';
    return '$sign${symbolOf(money.currency)}${format.format(money.abs().major)}';
  }

  int _decimalsFor(Money money, MoneyPrecision precision) {
    final decimals = money.currency.decimals;
    return switch (precision) {
      MoneyPrecision.whole => 0,
      MoneyPrecision.full => decimals,
      MoneyPrecision.auto =>
        money.minorUnits % money.currency.minorPerMajor == 0 ? 0 : decimals,
    };
  }

  NumberFormat _decimalFormat(int decimals) {
    return _decimalFormats.putIfAbsent(decimals, () {
      final format = NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = decimals
        ..maximumFractionDigits = decimals;
      return format;
    });
  }
}
