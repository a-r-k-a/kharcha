import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/clock.dart';
import '../../../../core/domain/date_range.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';
import '../../../ledger/presentation/bloc/ledger_watcher.dart';

/// Everything the dashboard shows for one period and account filter.
final class DashboardView extends Equatable {
  const DashboardView({
    required this.period,
    required this.position,
    required this.summary,
    required this.previous,
    required this.cashFlow,
    required this.breakdown,
    required this.recent,
  });

  final Period period;

  /// Across all active accounts, regardless of the account filter.
  final NetPosition position;
  final PeriodSummary summary;

  /// The same figures for the previous period, for comparison.
  final PeriodSummary previous;
  final List<CashFlowBucket> cashFlow;
  final List<CategoryShare> breakdown;
  final List<Transaction> recent;

  @override
  List<Object?> get props => [
    period,
    position,
    summary,
    previous,
    cashFlow,
    breakdown,
    recent,
  ];
}

final class DashboardState extends Equatable {
  const DashboardState({
    this.ledger,
    this.periodKind = PeriodKind.month,
    this.accountId,
    this.balancesHidden = false,
    this.view,
  });

  final Ledger? ledger;
  final PeriodKind periodKind;

  /// Restricts income, spending and charts to one account.
  final String? accountId;

  /// Masks amounts for privacy in public places.
  final bool balancesHidden;
  final DashboardView? view;

  bool get isLoading => view == null;
  bool get hasAccounts => ledger?.accounts.isNotEmpty ?? false;
  bool get hasTransactions => ledger?.transactions.isNotEmpty ?? false;

  @override
  List<Object?> get props => [
    ledger,
    periodKind,
    accountId,
    balancesHidden,
    view,
  ];
}

class DashboardCubit extends Cubit<DashboardState> with LedgerWatcher {
  DashboardCubit({required LedgerRepository ledger, required this._clock})
    : super(const DashboardState()) {
    watchLedger(ledger, (ledger) => _recompute(ledger: ledger));
  }

  final Clock _clock;

  static const recentCount = 5;

  void setPeriod(PeriodKind kind) => _recompute(periodKind: kind);

  /// Null shows every account.
  void setAccount(String? accountId) => _recompute(accountId: () => accountId);

  void toggleBalances() => emit(
    DashboardState(
      ledger: state.ledger,
      periodKind: state.periodKind,
      accountId: state.accountId,
      balancesHidden: !state.balancesHidden,
      view: state.view,
    ),
  );

  void _recompute({
    Ledger? ledger,
    PeriodKind? periodKind,
    String? Function()? accountId,
  }) {
    final books = ledger ?? state.ledger;
    final kind = periodKind ?? state.periodKind;
    final requested = accountId != null ? accountId() : state.accountId;
    if (books == null) {
      // Keep the choice so it applies once the first snapshot arrives.
      emit(
        DashboardState(
          periodKind: kind,
          accountId: requested,
          balancesHidden: state.balancesHidden,
        ),
      );
      return;
    }
    // Drop a filter whose account has since been deleted.
    final account = requested != null && books.accountById(requested) != null
        ? requested
        : null;

    final period = Period(kind, _clock.now());
    final recent = books.transactions
        .where((t) => account == null || t.touchesAccount(account))
        .take(recentCount)
        .toList();

    emit(
      DashboardState(
        ledger: books,
        periodKind: kind,
        accountId: account,
        balancesHidden: state.balancesHidden,
        view: DashboardView(
          period: period,
          position: LedgerAnalytics.netPosition(books),
          summary: LedgerAnalytics.summarize(
            books,
            period.range,
            accountId: account,
          ),
          previous: LedgerAnalytics.summarize(
            books,
            period.previous.range,
            accountId: account,
          ),
          cashFlow: LedgerAnalytics.cashFlow(books, period, accountId: account),
          breakdown: LedgerAnalytics.categoryBreakdown(
            books,
            period.range,
            CategoryKind.expense,
            accountId: account,
          ),
          recent: recent,
        ),
      ),
    );
  }
}
