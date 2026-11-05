import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/clock.dart';
import '../../../../core/domain/date_range.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/insight_engine.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';
import '../../../ledger/presentation/bloc/ledger_watcher.dart';

final class InsightsState extends Equatable {
  const InsightsState({
    required this.period,
    this.ledger,
    this.summary,
    this.breakdown = const [],
    this.insights = const [],
    this.history = const [],
    this.canGoForward = false,
  });

  final Period period;
  final Ledger? ledger;
  final PeriodSummary? summary;
  final List<CategoryShare> breakdown;
  final List<Insight> insights;

  /// This month and the five before it, newest first.
  final List<PeriodSummary> history;

  /// False on the current month: the future has no data.
  final bool canGoForward;

  bool get isLoading => ledger == null;
  bool get hasAnyTransactions => ledger?.transactions.isNotEmpty ?? false;

  @override
  List<Object?> get props => [
    period,
    ledger,
    summary,
    breakdown,
    insights,
    history,
    canGoForward,
  ];
}

/// Month-by-month analysis built entirely from recorded transactions.
class InsightsCubit extends Cubit<InsightsState> with LedgerWatcher {
  InsightsCubit({required LedgerRepository ledger, required this._clock})
    : super(InsightsState(period: Period(PeriodKind.month, _clock.now()))) {
    watchLedger(ledger, (ledger) => _compute(ledger, state.period));
  }

  final Clock _clock;

  static const historyLength = 6;

  void previousMonth() => _move(state.period.previous);

  void nextMonth() {
    if (state.canGoForward) _move(state.period.next);
  }

  void _move(Period period) {
    final ledger = state.ledger;
    if (ledger != null) _compute(ledger, period);
  }

  void _compute(Ledger ledger, Period period) {
    final now = _clock.now();
    final history = <PeriodSummary>[];
    var cursor = period;
    for (var i = 0; i < historyLength; i++) {
      history.add(LedgerAnalytics.summarize(ledger, cursor.range));
      cursor = cursor.previous;
    }
    emit(
      InsightsState(
        period: period,
        ledger: ledger,
        summary: history.first,
        breakdown: LedgerAnalytics.categoryBreakdown(
          ledger,
          period.range,
          CategoryKind.expense,
          maxSlices: 6,
        ),
        insights: InsightEngine.forPeriod(ledger, period, now: now),
        history: history,
        canGoForward:
            !period.range.contains(now) && period.range.start.isBefore(now),
      ),
    );
  }
}
