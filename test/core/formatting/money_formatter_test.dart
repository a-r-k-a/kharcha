import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/core/formatting/money_formatter.dart';

void main() {
  final formatter = MoneyFormatter();

  test('uses Indian lakh grouping by default', () {
    expect(formatter.format(Money.fromMajor(124000)), '₹1,24,000');
    expect(formatter.format(Money.fromMajor(12345678)), '₹1,23,45,678');
  });

  test('auto precision hides a zero fraction', () {
    expect(formatter.format(Money.fromMajor(1240)), '₹1,240');
    expect(formatter.format(Money.fromMajor(1240.5)), '₹1,240.50');
  });

  test('explicit precision', () {
    expect(
      formatter.format(Money.fromMajor(1240), precision: MoneyPrecision.full),
      '₹1,240.00',
    );
    expect(
      formatter.format(
        Money.fromMajor(1240.75),
        precision: MoneyPrecision.whole,
      ),
      '₹1,241',
    );
  });

  test('uses a typographic minus and optional plus', () {
    expect(formatter.format(Money.fromMajor(-1850)), '−₹1,850');
    expect(formatter.format(Money.fromMajor(500), signed: true), '+₹500');
    expect(formatter.format(const Money.zero(), signed: true), '₹0');
  });

  test('splits parts for display', () {
    final parts = formatter.parts(Money.fromMajor(48250.5));
    expect(parts.sign, '');
    expect(parts.symbol, '₹');
    expect(parts.integer, '48,250');
    expect(parts.fraction, '.50');
  });

  test('western grouping for other locales', () {
    final us = MoneyFormatter(locale: 'en_US');
    expect(
      us.format(Money.fromMajor(124000, currency: Currency.usd)),
      r'$124,000',
    );
  });

  test('zero-decimal currencies never show a fraction', () {
    expect(
      formatter.format(
        const Money(1500, currency: Currency.jpy),
        precision: MoneyPrecision.full,
      ),
      '¥1,500',
    );
  });

  test('compact form keeps the symbol', () {
    final compact = formatter.compact(Money.fromMajor(120000));
    expect(compact, startsWith('₹'));
    expect(compact, isNot(contains(',')));
  });
}
