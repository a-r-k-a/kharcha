import 'package:equatable/equatable.dart';

import '../../../../core/domain/date_range.dart';
import '../../../../core/domain/money.dart';
import '../entities/category.dart';
import '../entities/ledger.dart';
import 'ledger_analytics.dart';

/// A computed observation about the user's money. Every insight carries the
/// figures it was derived from, so the UI can show its working.
sealed class Insight extends Equatable {
  const Insight();
}

/// Spending in [category] moved notably versus the previous period.
final class CategoryChangeInsight extends Insight {
  const CategoryChangeInsight({
    required this.category,
    required this.current,
    required this.previous,
    required this.percentChange,
  });

  final Category category;
  final Money current;
  final Money previous;
  final double percentChange;

  Money get difference => current - previous;

  @override
  List<Object?> get props => [category, current, previous, percentChange];
}

/// The savings rate changed between periods (both had income).
final class SavingsRateInsight extends Insight {
  const SavingsRateInsight({required this.current, required this.previous});

  /// Percentages.
  final double current;
  final double previous;

  @override
  List<Object?> get props => [current, previous];
}

/// One category takes a large share of income.
final class IncomeShareInsight extends Insight {
  const IncomeShareInsight({
    required this.category,
    required this.amount,
    required this.income,
  });

  final Category category;
  final Money amount;
  final Money income;

  double get percentOfIncome => amount.ratioOf(income) * 100;

  @override
  List<Object?> get props => [category, amount, income];
}

/// A straight-line projection of spending to the end of the period.
/// A projection, not a fact: the UI must label it as such.
final class SpendingPaceInsight extends Insight {
  const SpendingPaceInsight({
    required this.spentSoFar,
    required this.projected,
    required this.previousTotal,
    required this.daysElapsed,
    required this.daysInPeriod,
  });

  final Money spentSoFar;
  final Money projected;
  final Money previousTotal;
  final int daysElapsed;
  final int daysInPeriod;

  @override
  List<Object?> get props => [
    spentSoFar,
    projected,
    previousTotal,
    daysElapsed,
    daysInPeriod,
  ];
}

/// Derives [Insight]s from real transactions. Thresholds keep noise out:
/// small categories and small changes are not worth a sentence.
abstract final class InsightEngine {
  /// Minimum relative change for a category to be called out.
  static const categoryChangeThreshold = 20.0;

  /// A category must be at least this share of the period's spending (in
  /// either period) to be called out.
  static const categoryMinimumShare = 0.05;

  /// Savings-rate moves smaller than this many points aren't reported.
  static const savingsRateThreshold = 3.0;

  /// A category above this share of income is reported.
  static const incomeShareThreshold = 30.0;

  /// Projections need this many days of data to be meaningful.
  static const minimumDaysForPace = 5;

  static List<Insight> forPeriod(
    Ledger ledger,
    Period period, {
    required DateTime now,
  }) {
    final range = period.range;
    final previousRange = period.previous.range;
    final current = LedgerAnalytics.summarize(ledger, range);
    final previous = LedgerAnalytics.summarize(ledger, previousRange);
    final insights = <Insight>[];

    final pace = _pace(ledger, period, current, previous, now);
    if (pace != null) insights.add(pace);

    insights.addAll(
      _categoryChanges(ledger, range, previousRange, current, previous),
    );

    final currentRate = current.savingsRate;
    final previousRate = previous.savingsRate;
    if (currentRate != null &&
        previousRate != null &&
        (currentRate - previousRate).abs() >= savingsRateThreshold) {
      insights.add(
        SavingsRateInsight(current: currentRate, previous: previousRate),
      );
    }

    if (current.income.isPositive) {
      final totals = LedgerAnalytics.totalsByCategory(
        ledger,
        range,
        CategoryKind.expense,
      );
      final top = totals.entries.firstOrNull;
      if (top != null &&
          top.value.ratioOf(current.income) * 100 >= incomeShareThreshold) {
        insights.add(
          IncomeShareInsight(
            category: top.key,
            amount: top.value,
            income: current.income,
          ),
        );
      }
    }
    return insights;
  }

  static Iterable<Insight> _categoryChanges(
    Ledger ledger,
    DateRange range,
    DateRange previousRange,
    PeriodSummary current,
    PeriodSummary previous,
  ) sync* {
    final now = LedgerAnalytics.totalsByCategory(
      ledger,
      range,
      CategoryKind.expense,
    );
    final before = LedgerAnalytics.totalsByCategory(
      ledger,
      previousRange,
      CategoryKind.expense,
    );
    final changes = <CategoryChangeInsight>[];
    for (final category in {...now.keys, ...before.keys}) {
      final a = now[category] ?? ledger.zero;
      final b = before[category] ?? ledger.zero;
      final change = LedgerAnalytics.percentChange(a, b);
      if (change == null || change.abs() < categoryChangeThreshold) continue;
      final significant =
          (current.expense.isPositive &&
              a.ratioOf(current.expense) >= categoryMinimumShare) ||
          (previous.expense.isPositive &&
              b.ratioOf(previous.expense) >= categoryMinimumShare);
      if (!significant) continue;
      changes.add(
        CategoryChangeInsight(
          category: category,
          current: a,
          previous: b,
          percentChange: change,
        ),
      );
    }
    // Largest absolute money movement first; at most three.
    changes.sort((x, y) => y.difference.abs().compareTo(x.difference.abs()));
    yield* changes.take(3);
  }

  static SpendingPaceInsight? _pace(
    Ledger ledger,
    Period period,
    PeriodSummary current,
    PeriodSummary previous,
    DateTime now,
  ) {
    final range = period.range;
    if (period.kind == PeriodKind.day || !range.contains(now)) return null;
    final elapsed = DateRange(
      range.start,
      DateTime(now.year, now.month, now.day + 1),
    ).dayCount;
    if (elapsed < minimumDaysForPace || !current.expense.isPositive) {
      return null;
    }
    final total = range.dayCount;
    if (elapsed >= total) return null;
    return SpendingPaceInsight(
      spentSoFar: current.expense,
      projected: current.expense * (total / elapsed),
      previousTotal: previous.expense,
      daysElapsed: elapsed,
      daysInPeriod: total,
    );
  }
}
