import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/date_range.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/ledger/domain/default_categories.dart';
import 'package:kharcha/features/ledger/domain/entities/ledger.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';
import 'package:kharcha/features/ledger/domain/services/insight_engine.dart';

import '../../../helpers/in_memory_ledger.dart';

void main() {
  DateTime oct(int d) => DateTime(2026, 10, d, 12).toUtc();
  DateTime nov(int d) => DateTime(2026, 11, d, 12).toUtc();

  Ledger ledgerOf(List<Transaction> transactions) => Ledger(
    currency: Currency.inr,
    accounts: [testAccount('bank')],
    categories: DefaultCategories.build(),
    transactions: transactions,
  );

  final november = Period(PeriodKind.month, DateTime(2026, 11, 15));
  final endOfMonth = DateTime(2026, 12);

  List<T> only<T extends Insight>(List<Insight> insights) =>
      insights.whereType<T>().toList();

  test('reports a significant category change with its figures', () {
    final insights = InsightEngine.forPeriod(
      ledgerOf([
        testExpense('a', amount: 10000, at: oct(5), category: 'food'),
        testExpense('b', amount: 12300, at: nov(5), category: 'food'),
        testExpense('c', amount: 20000, at: oct(5), category: 'housing'),
        testExpense('d', amount: 20500, at: nov(5), category: 'housing'),
      ]),
      november,
      now: endOfMonth,
    );
    final changes = only<CategoryChangeInsight>(insights);
    expect(changes, hasLength(1));
    expect(changes.single.category.id, 'food');
    expect(changes.single.percentChange, closeTo(23, 1e-9));
    expect(changes.single.difference, inr(2300));
  });

  test('ignores small categories', () {
    final insights = InsightEngine.forPeriod(
      ledgerOf([
        testExpense('a', amount: 100, at: oct(5), category: 'education'),
        testExpense('b', amount: 400, at: nov(5), category: 'education'),
        testExpense('c', amount: 50000, at: oct(5), category: 'housing'),
        testExpense('d', amount: 50000, at: nov(5), category: 'housing'),
      ]),
      november,
      now: endOfMonth,
    );
    expect(only<CategoryChangeInsight>(insights), isEmpty);
  });

  test('reports a savings-rate change only when both months had income', () {
    final ledger = ledgerOf([
      testIncome('i1', amount: 100000, at: oct(1)),
      testExpense('e1', amount: 85000, at: oct(2), category: 'housing'),
      testIncome('i2', amount: 100000, at: nov(1)),
      testExpense('e2', amount: 78000, at: nov(2), category: 'housing'),
    ]);
    final rate = only<SavingsRateInsight>(
      InsightEngine.forPeriod(ledger, november, now: endOfMonth),
    ).single;
    expect(rate.previous, closeTo(15, 1e-9));
    expect(rate.current, closeTo(22, 1e-9));
  });

  test('flags a category taking a large share of income', () {
    final share = only<IncomeShareInsight>(
      InsightEngine.forPeriod(
        ledgerOf([
          testIncome('i', amount: 40000, at: nov(1)),
          testExpense(
            'rent',
            amount: 14000,
            at: nov(2),
            category: 'housing.rent',
          ),
        ]),
        november,
        now: endOfMonth,
      ),
    ).single;
    expect(share.category.id, 'housing');
    expect(share.percentOfIncome, closeTo(35, 1e-9));
  });

  test('projects month-end spending only mid-month with enough data', () {
    final ledger = ledgerOf([
      testExpense('a', amount: 3000, at: nov(2), category: 'food'),
    ]);
    final pace = only<SpendingPaceInsight>(
      InsightEngine.forPeriod(ledger, november, now: DateTime(2026, 11, 10, 8)),
    ).single;
    expect(pace.daysElapsed, 10);
    expect(pace.daysInPeriod, 30);
    expect(pace.projected, inr(9000));

    expect(
      only<SpendingPaceInsight>(
        InsightEngine.forPeriod(ledger, november, now: DateTime(2026, 11, 3)),
      ),
      isEmpty,
    );
    expect(
      only<SpendingPaceInsight>(
        InsightEngine.forPeriod(ledger, november, now: endOfMonth),
      ),
      isEmpty,
    );
  });

  test('transfers never produce insights', () {
    final insights = InsightEngine.forPeriod(
      Ledger(
        currency: Currency.inr,
        accounts: [testAccount('bank'), testAccount('cash')],
        categories: DefaultCategories.build(),
        transactions: [
          testTransfer(
            't1',
            amount: 9000,
            at: oct(5),
            from: 'bank',
            to: 'cash',
          ),
          testTransfer(
            't2',
            amount: 1000,
            at: nov(5),
            from: 'bank',
            to: 'cash',
          ),
        ],
      ),
      november,
      now: endOfMonth,
    );
    expect(insights, isEmpty);
  });
}
