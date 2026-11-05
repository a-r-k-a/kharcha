import 'package:equatable/equatable.dart';

import '../../../../core/domain/date_range.dart';
import '../../../../core/domain/money.dart';
import '../entities/account.dart';
import '../entities/category.dart';
import '../entities/ledger.dart';
import '../entities/transaction.dart';

/// What the user owns and owes across active (non-archived) accounts.
///
/// Each account is classified by the sign of its balance, so an overdrawn
/// bank account counts as a liability and an overpaid card as an asset.
/// `netWorth == assets − liabilities` always holds.
final class NetPosition extends Equatable {
  const NetPosition({
    required this.liquid,
    required this.assets,
    required this.liabilities,
  });

  /// Spendable balance: bank accounts, cash and wallets.
  final Money liquid;
  final Money assets;

  /// Owed amounts, as a positive figure.
  final Money liabilities;

  Money get netWorth => assets - liabilities;

  @override
  List<Object?> get props => [liquid, assets, liabilities];
}

/// Income and spending over a range. Transfers and adjustments are never
/// included: moving money between your own accounts isn't earning or
/// spending it.
final class PeriodSummary extends Equatable {
  const PeriodSummary({
    required this.range,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  final DateRange range;
  final Money income;
  final Money expense;

  /// Expense and income entries counted.
  final int transactionCount;

  /// Income − expenses.
  Money get netCashFlow => income - expense;

  /// Share of income kept, as a percentage; null when there was no income,
  /// since a rate of "nothing" is undefined rather than zero.
  double? get savingsRate =>
      income.isPositive ? netCashFlow.ratioOf(income) * 100 : null;

  /// Average daily spending over the range.
  Money get averageDailyExpense => expense.divide(range.dayCount);

  @override
  List<Object?> get props => [range, income, expense, transactionCount];
}

/// One slice of a category breakdown.
final class CategoryShare extends Equatable {
  const CategoryShare({
    required this.category,
    required this.amount,
    required this.share,
  });

  /// The top-level category; null for the folded "everything else" slice.
  final Category? category;
  final Money amount;

  /// Fraction of the breakdown's total, 0–1.
  final double share;

  bool get isRemainder => category == null;

  @override
  List<Object?> get props => [category, amount, share];
}

/// Income and spending in one chart bucket.
final class CashFlowBucket extends Equatable {
  const CashFlowBucket({
    required this.range,
    required this.income,
    required this.expense,
  });

  final DateRange range;
  final Money income;
  final Money expense;

  @override
  List<Object?> get props => [range, income, expense];
}

/// Pure financial calculations over a [Ledger]. Stateless and deterministic:
/// every input, including the period, is passed in.
abstract final class LedgerAnalytics {
  static NetPosition netPosition(Ledger ledger) {
    var liquid = ledger.zero;
    var assets = ledger.zero;
    var liabilities = ledger.zero;
    for (final account in ledger.accounts) {
      if (account.isArchived) continue;
      final balance = ledger.balanceOf(account.id);
      if (account.type.group == AccountGroup.liquid) liquid += balance;
      if (balance.isNegative) {
        liabilities += -balance;
      } else {
        assets += balance;
      }
    }
    return NetPosition(
      liquid: liquid,
      assets: assets,
      liabilities: liabilities,
    );
  }

  /// Cash-flow transactions in [range], optionally for one account.
  static Iterable<Transaction> cashFlowIn(
    Ledger ledger,
    DateRange range, {
    String? accountId,
  }) {
    return ledger.transactions.where(
      (t) =>
          t.isCashFlow &&
          range.contains(t.occurredAt) &&
          (accountId == null || t.accountId == accountId),
    );
  }

  static PeriodSummary summarize(
    Ledger ledger,
    DateRange range, {
    String? accountId,
  }) {
    var income = ledger.zero;
    var expense = ledger.zero;
    var count = 0;
    for (final t in cashFlowIn(ledger, range, accountId: accountId)) {
      count++;
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return PeriodSummary(
      range: range,
      income: income,
      expense: expense,
      transactionCount: count,
    );
  }

  /// Totals per top-level category of [kind], largest first. Subcategory
  /// amounts roll up into their parent; split transactions contribute each
  /// allocation to its own category.
  static Map<Category, Money> totalsByCategory(
    Ledger ledger,
    DateRange range,
    CategoryKind kind, {
    String? accountId,
  }) {
    final type = kind == CategoryKind.expense
        ? TransactionType.expense
        : TransactionType.income;
    final totals = <Category, Money>{};
    for (final t in cashFlowIn(ledger, range, accountId: accountId)) {
      if (t.type != type) continue;
      for (final allocation in t.allocations) {
        final category = ledger.topLevelCategoryOf(allocation.categoryId);
        if (category == null) continue;
        totals[category] =
            (totals[category] ?? ledger.zero) + allocation.amount;
      }
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in sorted) entry.key: entry.value};
  }

  /// Breakdown with at most [maxSlices] named slices; anything beyond is
  /// folded into one remainder slice so the chart never needs a ninth color.
  static List<CategoryShare> categoryBreakdown(
    Ledger ledger,
    DateRange range,
    CategoryKind kind, {
    String? accountId,
    int maxSlices = 5,
  }) {
    final totals = totalsByCategory(ledger, range, kind, accountId: accountId);
    final total = totals.values.fold(ledger.zero, (sum, m) => sum + m);
    if (!total.isPositive) return const [];

    final entries = totals.entries.toList();
    final named = entries.take(maxSlices).toList();
    final rest = entries
        .skip(maxSlices)
        .fold(ledger.zero, (sum, e) => sum + e.value);

    return [
      for (final entry in named)
        CategoryShare(
          category: entry.key,
          amount: entry.value,
          share: entry.value.ratioOf(total),
        ),
      if (rest.isPositive)
        CategoryShare(category: null, amount: rest, share: rest.ratioOf(total)),
    ];
  }

  /// Chart buckets for [period]: hours are too sparse to be useful, so a
  /// day shows the 7 days ending on it; a week shows its days; a month its
  /// days; a year its months.
  static List<CashFlowBucket> cashFlow(
    Ledger ledger,
    Period period, {
    String? accountId,
  }) {
    final buckets = _bucketsFor(period);
    if (buckets.isEmpty) return const [];
    final income = List.filled(buckets.length, ledger.zero);
    final expense = List.filled(buckets.length, ledger.zero);
    final span = DateRange(buckets.first.start, buckets.last.end);

    for (final t in cashFlowIn(ledger, span, accountId: accountId)) {
      final index = buckets.indexWhere((b) => b.contains(t.occurredAt));
      if (index < 0) continue;
      if (t.type == TransactionType.income) {
        income[index] += t.amount;
      } else {
        expense[index] += t.amount;
      }
    }
    return [
      for (var i = 0; i < buckets.length; i++)
        CashFlowBucket(
          range: buckets[i],
          income: income[i],
          expense: expense[i],
        ),
    ];
  }

  static List<DateRange> _bucketsFor(Period period) {
    final range = period.range;
    final start = range.start;
    return switch (period.kind) {
      PeriodKind.day => [
        for (var i = 6; i >= 0; i--)
          DateRange.day(DateTime(start.year, start.month, start.day - i)),
      ],
      PeriodKind.week || PeriodKind.month => [
        for (var i = 0; i < range.dayCount; i++)
          DateRange.day(DateTime(start.year, start.month, start.day + i)),
      ],
      PeriodKind.year => [
        for (var m = 1; m <= 12; m++)
          DateRange(DateTime(start.year, m), DateTime(start.year, m + 1)),
      ],
    };
  }

  /// Relative change from [previous] to [current], as a percentage; null
  /// when there is no baseline to compare against.
  static double? percentChange(Money current, Money previous) {
    if (previous.isZero) return null;
    return (current - previous).ratioOf(previous.abs()) * 100;
  }
}
