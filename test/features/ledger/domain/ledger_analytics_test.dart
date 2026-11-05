import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/date_range.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/ledger/domain/default_categories.dart';
import 'package:kharcha/features/ledger/domain/entities/account.dart';
import 'package:kharcha/features/ledger/domain/entities/category.dart';
import 'package:kharcha/features/ledger/domain/entities/ledger.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';
import 'package:kharcha/features/ledger/domain/services/ledger_analytics.dart';

import '../../../helpers/in_memory_ledger.dart';

void main() {
  DateTime day(int month, int d, [int hour = 12]) =>
      DateTime(2026, month, d, hour).toUtc();

  Ledger ledgerOf(List<Account> accounts, List<Transaction> transactions) =>
      Ledger(
        currency: Currency.inr,
        accounts: accounts,
        categories: DefaultCategories.build(),
        transactions: transactions,
      );

  final november = Period(PeriodKind.month, DateTime(2026, 11, 15)).range;

  group('balances', () {
    test('opening balance plus income minus expense', () {
      final ledger = ledgerOf(
        [testAccount('bank', opening: 1000)],
        [
          testIncome('i', amount: 500, at: day(11, 1)),
          testExpense('e', amount: 200.50, at: day(11, 2)),
        ],
      );
      expect(ledger.balanceOf('bank'), inr(1299.50));
    });

    test('a transfer moves money without changing the total', () {
      final ledger = ledgerOf(
        [
          testAccount('bank', opening: 10000),
          testAccount('cash', type: AccountType.cash),
        ],
        [
          testTransfer(
            't',
            amount: 2500,
            at: day(11, 3),
            from: 'bank',
            to: 'cash',
          ),
        ],
      );
      expect(ledger.balanceOf('bank'), inr(7500));
      expect(ledger.balanceOf('cash'), inr(2500));
      expect(LedgerAnalytics.netPosition(ledger).netWorth, inr(10000));
    });

    test('card spending deepens a liability; paying it off reduces it', () {
      final ledger = ledgerOf(
        [
          testAccount('bank', opening: 20000),
          testAccount('card', type: AccountType.creditCard, opening: -3000),
        ],
        [
          testExpense('e', amount: 2000, at: day(11, 1), account: 'card'),
          testTransfer(
            'pay',
            amount: 5000,
            at: day(11, 5),
            from: 'bank',
            to: 'card',
          ),
        ],
      );
      expect(ledger.balanceOf('card'), inr(0));
      expect(ledger.balanceOf('bank'), inr(15000));
    });

    test('adjustments are signed', () {
      final ledger = ledgerOf(
        [testAccount('bank', opening: 100)],
        [
          Transaction(
            id: 'a',
            type: TransactionType.adjustment,
            amount: inr(-40),
            accountId: 'bank',
            occurredAt: day(11, 1),
            createdAt: day(11, 1),
            updatedAt: day(11, 1),
          ),
        ],
      );
      expect(ledger.balanceOf('bank'), inr(60));
    });
  });

  group('netPosition', () {
    test('classifies each account by the sign of its balance', () {
      final ledger = ledgerOf([
        testAccount('bank', opening: 50000),
        testAccount('wallet', type: AccountType.digitalWallet, opening: 500),
        testAccount('fd', type: AccountType.fixedDeposit, opening: 100000),
        testAccount('card', type: AccountType.creditCard, opening: -12000),
        testAccount('overdrawn', type: AccountType.current, opening: -1000),
      ], const []);
      final position = LedgerAnalytics.netPosition(ledger);
      expect(position.liquid, inr(49500));
      expect(position.assets, inr(150500));
      expect(position.liabilities, inr(13000));
      expect(position.netWorth, inr(137500));
    });

    test('excludes archived accounts', () {
      final ledger = ledgerOf([
        testAccount('bank', opening: 100),
        testAccount('old', opening: 900, archived: true),
      ], const []);
      expect(LedgerAnalytics.netPosition(ledger).netWorth, inr(100));
    });
  });

  group('summarize', () {
    final ledger = ledgerOf(
      [
        testAccount('bank', opening: 100000),
        testAccount('cash', type: AccountType.cash),
      ],
      [
        testIncome('salary', amount: 60000, at: day(11, 1)),
        testExpense(
          'rent',
          amount: 15000,
          at: day(11, 2),
          category: 'housing.rent',
        ),
        testExpense('food', amount: 3000, at: day(11, 4), account: 'cash'),
        testTransfer(
          'atm',
          amount: 5000,
          at: day(11, 3),
          from: 'bank',
          to: 'cash',
        ),
        testExpense('october', amount: 999, at: day(10, 31)),
        testExpense('december', amount: 999, at: day(12, 1, 0)),
      ],
    );

    test('excludes transfers and other periods', () {
      final summary = LedgerAnalytics.summarize(ledger, november);
      expect(summary.income, inr(60000));
      expect(summary.expense, inr(18000));
      expect(summary.netCashFlow, inr(42000));
      expect(summary.transactionCount, 3);
    });

    test('savings rate is (income − expenses) ÷ income', () {
      final rate = LedgerAnalytics.summarize(ledger, november).savingsRate;
      expect(rate, closeTo(70, 1e-9));
    });

    test('savings rate is undefined without income', () {
      final noIncome = LedgerAnalytics.summarize(
        ledger,
        Period(PeriodKind.month, DateTime(2026, 10, 5)).range,
      );
      expect(noIncome.savingsRate, isNull);
      expect(noIncome.netCashFlow, inr(-999));
    });

    test('filters by account', () {
      final cash = LedgerAnalytics.summarize(
        ledger,
        november,
        accountId: 'cash',
      );
      expect(cash.income, inr(0));
      expect(cash.expense, inr(3000));
    });

    test('average daily expense divides by days in the range', () {
      final summary = LedgerAnalytics.summarize(ledger, november);
      expect(summary.averageDailyExpense, inr(600));
    });
  });

  group('categoryBreakdown', () {
    test('rolls subcategories up and orders by amount', () {
      final ledger = ledgerOf(
        [testAccount('bank')],
        [
          testExpense('a', amount: 300, at: day(11, 1)),
          testExpense('b', amount: 200, at: day(11, 2), category: 'food'),
          testExpense(
            'c',
            amount: 1000,
            at: day(11, 3),
            category: 'housing.rent',
          ),
        ],
      );
      final shares = LedgerAnalytics.categoryBreakdown(
        ledger,
        november,
        CategoryKind.expense,
      );
      expect(shares.map((s) => s.category?.id), ['housing', 'food']);
      expect(shares.first.amount, inr(1000));
      expect(shares.first.share, closeTo(2 / 3, 1e-9));
      expect(shares.last.amount, inr(500));
    });

    test('split transactions count toward each category', () {
      final split = Transaction(
        id: 's',
        type: TransactionType.expense,
        amount: inr(1000),
        accountId: 'bank',
        allocations: [
          CategoryAllocation(categoryId: 'food.groceries', amount: inr(700)),
          CategoryAllocation(categoryId: 'personal.grooming', amount: inr(300)),
        ],
        occurredAt: day(11, 1),
        createdAt: day(11, 1),
        updatedAt: day(11, 1),
      );
      final shares = LedgerAnalytics.categoryBreakdown(
        ledgerOf([testAccount('bank')], [split]),
        november,
        CategoryKind.expense,
      );
      expect(
        {for (final s in shares) s.category?.id: s.amount},
        {'food': inr(700), 'personal': inr(300)},
      );
    });

    test('folds everything past maxSlices into one remainder', () {
      final categories = [
        'food',
        'transport',
        'housing',
        'shopping',
        'health',
        'entertainment',
        'education',
      ];
      final ledger = ledgerOf(
        [testAccount('bank')],
        [
          for (var i = 0; i < categories.length; i++)
            testExpense(
              'e$i',
              amount: 100 * (categories.length - i),
              at: day(11, 1),
              category: categories[i],
            ),
        ],
      );
      final shares = LedgerAnalytics.categoryBreakdown(
        ledger,
        november,
        CategoryKind.expense,
      );
      expect(shares, hasLength(6));
      expect(shares.last.isRemainder, isTrue);
      expect(shares.last.amount, inr(300));
      expect(
        shares.fold<double>(0, (sum, s) => sum + s.share),
        closeTo(1, 1e-9),
      );
    });

    test('is empty when nothing was spent', () {
      expect(
        LedgerAnalytics.categoryBreakdown(
          ledgerOf([testAccount('bank')], const []),
          november,
          CategoryKind.expense,
        ),
        isEmpty,
      );
    });
  });

  group('cashFlow', () {
    final ledger = ledgerOf(
      [testAccount('bank'), testAccount('cash', type: AccountType.cash)],
      [
        testIncome('i', amount: 1000, at: day(11, 2, 9)),
        testExpense('e', amount: 250, at: day(11, 2, 18)),
        testTransfer(
          't',
          amount: 100,
          at: day(11, 3),
          from: 'bank',
          to: 'cash',
        ),
      ],
    );

    test('a month has one bucket per day', () {
      final buckets = LedgerAnalytics.cashFlow(
        ledger,
        Period(PeriodKind.month, DateTime(2026, 11)),
      );
      expect(buckets, hasLength(30));
      expect(buckets[1].income, inr(1000));
      expect(buckets[1].expense, inr(250));
      expect(buckets[2].income, inr(0));
      expect(buckets[2].expense, inr(0));
    });

    test('a year has twelve monthly buckets', () {
      final buckets = LedgerAnalytics.cashFlow(
        ledger,
        Period(PeriodKind.year, DateTime(2026, 5)),
      );
      expect(buckets, hasLength(12));
      expect(buckets[10].income, inr(1000));
    });

    test('a day shows the seven days ending on it', () {
      final buckets = LedgerAnalytics.cashFlow(
        ledger,
        Period(PeriodKind.day, DateTime(2026, 11, 4)),
      );
      expect(buckets, hasLength(7));
      expect(buckets.last.range.start, DateTime(2026, 11, 4));
      expect(buckets[4].expense, inr(250));
    });
  });

  group('percentChange', () {
    test('is relative to the previous value', () {
      expect(
        LedgerAnalytics.percentChange(inr(123), inr(100)),
        closeTo(23, 1e-9),
      );
      expect(
        LedgerAnalytics.percentChange(inr(50), inr(100)),
        closeTo(-50, 1e-9),
      );
    });

    test('is undefined without a baseline', () {
      expect(LedgerAnalytics.percentChange(inr(10), inr(0)), isNull);
    });
  });
}
