import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/date_range.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/utils/event_transformers.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/transaction_query.dart';
import '../../../ledger/domain/usecases/transaction_usecases.dart';

sealed class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to the ledger with [filters] applied.
final class ActivityStarted extends ActivityEvent {
  const ActivityStarted([this.filters = const TransactionQuery()]);

  final TransactionQuery filters;

  @override
  List<Object?> get props => [filters];
}

/// Search text changed. Debounced.
final class ActivitySearchChanged extends ActivityEvent {
  const ActivitySearchChanged(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Replaces the filters, keeping the search text.
final class ActivityFiltersChanged extends ActivityEvent {
  const ActivityFiltersChanged(this.filters);

  final TransactionQuery filters;

  @override
  List<Object?> get props => [filters];
}

final class ActivityDeleteRequested extends ActivityEvent {
  const ActivityDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ActivityUndoRequested extends ActivityEvent {
  const ActivityUndoRequested(this.transaction);

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

/// A row in the grouped activity list.
sealed class ActivityEntry extends Equatable {
  const ActivityEntry();
}

final class ActivityDayHeader extends ActivityEntry {
  const ActivityDayHeader({required this.day, required this.net});

  /// Local midnight of the day.
  final DateTime day;

  /// Income − expenses on that day among the shown transactions.
  final Money net;

  @override
  List<Object?> get props => [day, net];
}

final class ActivityItem extends ActivityEntry {
  const ActivityItem(this.transaction);

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

enum ActivityStatus { loading, ready }

final class ActivityState extends Equatable {
  const ActivityState({
    this.status = ActivityStatus.loading,
    this.ledger,
    this.query = const TransactionQuery(),
    this.entries = const [],
    this.resultCount = 0,
    this.lastDeleted,
    this.deletionCount = 0,
    this.failure,
    this.failureCount = 0,
  });

  final ActivityStatus status;
  final Ledger? ledger;
  final TransactionQuery query;
  final List<ActivityEntry> entries;
  final int resultCount;

  /// The most recent deletion, for the undo snackbar; [deletionCount]
  /// changes on every deletion so the same item can be undone twice.
  final Transaction? lastDeleted;
  final int deletionCount;

  /// A one-off failure to report; [failureCount] makes repeats distinct.
  final Failure? failure;
  final int failureCount;

  bool get hasAnyTransactions => ledger?.transactions.isNotEmpty ?? false;

  ActivityState copyWith({
    ActivityStatus? status,
    Ledger? ledger,
    TransactionQuery? query,
    List<ActivityEntry>? entries,
    int? resultCount,
    Transaction? lastDeleted,
    int? deletionCount,
    Failure? failure,
    int? failureCount,
  }) {
    return ActivityState(
      status: status ?? this.status,
      ledger: ledger ?? this.ledger,
      query: query ?? this.query,
      entries: entries ?? this.entries,
      resultCount: resultCount ?? this.resultCount,
      lastDeleted: lastDeleted ?? this.lastDeleted,
      deletionCount: deletionCount ?? this.deletionCount,
      failure: failure ?? this.failure,
      failureCount: failureCount ?? this.failureCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    ledger,
    query,
    entries,
    resultCount,
    lastDeleted,
    deletionCount,
    failure,
    failureCount,
  ];
}

/// Searchable, filterable transaction history grouped by day.
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc({
    required this._ledger,
    required this._delete,
    required this._restore,
    Duration searchDebounce = const Duration(milliseconds: 250),
  }) : super(const ActivityState()) {
    on<ActivityStarted>(_onStarted);
    on<ActivitySearchChanged>(
      _onSearchChanged,
      transformer: debounce(searchDebounce),
    );
    on<ActivityFiltersChanged>(_onFiltersChanged);
    on<ActivityDeleteRequested>(_onDeleteRequested);
    on<ActivityUndoRequested>(_onUndoRequested);
  }

  final LedgerRepository _ledger;
  final DeleteTransaction _delete;
  final RestoreTransaction _restore;

  Future<void> _onStarted(
    ActivityStarted event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(query: event.filters));
    await emit.forEach<Ledger>(
      _ledger.watch(),
      onData: (ledger) => _withResults(state.copyWith(ledger: ledger)),
    );
  }

  void _onSearchChanged(
    ActivitySearchChanged event,
    Emitter<ActivityState> emit,
  ) {
    if (event.text == state.query.text) return;
    emit(
      _withResults(
        state.copyWith(query: state.query.copyWith(text: event.text)),
      ),
    );
  }

  void _onFiltersChanged(
    ActivityFiltersChanged event,
    Emitter<ActivityState> emit,
  ) {
    final query = event.filters.copyWith(text: state.query.text);
    if (query == state.query) return;
    emit(_withResults(state.copyWith(query: query)));
  }

  Future<void> _onDeleteRequested(
    ActivityDeleteRequested event,
    Emitter<ActivityState> emit,
  ) async {
    switch (await _delete(event.id)) {
      case Ok(:final value):
        emit(
          state.copyWith(
            lastDeleted: value,
            deletionCount: state.deletionCount + 1,
          ),
        );
      case Err(:final failure):
        _report(failure, emit);
    }
  }

  Future<void> _onUndoRequested(
    ActivityUndoRequested event,
    Emitter<ActivityState> emit,
  ) async {
    if (await _restore(event.transaction) case Err(:final failure)) {
      _report(failure, emit);
    }
  }

  void _report(Failure failure, Emitter<ActivityState> emit) => emit(
    state.copyWith(failure: failure, failureCount: state.failureCount + 1),
  );

  static ActivityState _withResults(ActivityState state) {
    final ledger = state.ledger;
    if (ledger == null) return state;
    final results = state.query.apply(ledger);
    return state.copyWith(
      status: ActivityStatus.ready,
      entries: groupByDay(results, ledger.zero),
      resultCount: results.length,
    );
  }

  /// Interleaves day headers with [transactions] (newest first).
  static List<ActivityEntry> groupByDay(
    List<Transaction> transactions,
    Money zero,
  ) {
    final entries = <ActivityEntry>[];
    DateRange? currentDay;
    var headerIndex = -1;
    var net = zero;

    void closeDay() {
      final day = currentDay;
      if (day != null) {
        entries[headerIndex] = ActivityDayHeader(day: day.start, net: net);
      }
    }

    for (final t in transactions) {
      final day = currentDay;
      if (day == null || !day.contains(t.occurredAt)) {
        closeDay();
        final range = DateRange.day(t.occurredAt.toLocal());
        currentDay = range;
        net = zero;
        headerIndex = entries.length;
        entries.add(ActivityDayHeader(day: range.start, net: zero));
      }
      net += switch (t.type) {
        TransactionType.income => t.amount,
        TransactionType.expense => -t.amount,
        TransactionType.transfer || TransactionType.adjustment => zero,
      };
      entries.add(ActivityItem(t));
    }
    closeDay();
    return entries;
  }
}
