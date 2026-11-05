import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';
import 'package:kharcha/features/ledger/domain/services/transaction_query.dart';
import 'package:kharcha/features/ledger/domain/usecases/transaction_usecases.dart';
import 'package:kharcha/features/transactions/presentation/bloc/activity_bloc.dart';

import '../../helpers/in_memory_ledger.dart';

void main() {
  late LedgerStore store;

  DateTime at(int day, [int hour = 12]) =>
      DateTime(2026, 11, day, hour).toUtc();

  setUp(() async {
    store = LedgerStore(InMemoryLedgerOpener());
    await store.open(ownerId: 'u', currency: Currency.inr);
    await store.saveAccount(testAccount('bank', opening: 5000));
    await store.saveTransaction(
      testExpense(
        'swiggy',
        amount: 300,
        at: at(3, 20),
        title: 'Swiggy',
        category: 'food.delivery',
      ),
    );
    await store.saveTransaction(
      testExpense(
        'rent',
        amount: 15000,
        at: at(3, 9),
        category: 'housing.rent',
      ),
    );
    await store.saveTransaction(testIncome('salary', amount: 60000, at: at(1)));
  });

  tearDown(() => store.dispose());

  ActivityBloc build() => ActivityBloc(
    ledger: store,
    delete: DeleteTransaction(ledger: store, transactions: store),
    restore: RestoreTransaction(store),
    searchDebounce: Duration.zero,
  );

  List<String> ids(ActivityState state) => [
    for (final e in state.entries)
      if (e case ActivityItem(:final transaction)) transaction.id,
  ];

  test('groups by day, newest first, with each day’s net', () async {
    final bloc = build()..add(const ActivityStarted());
    await pumpEventQueue();
    final state = bloc.state;
    expect(state.status, ActivityStatus.ready);
    expect(ids(state), ['swiggy', 'rent', 'salary']);
    final headers = state.entries.whereType<ActivityDayHeader>().toList();
    expect(headers, hasLength(2));
    expect(headers.first.net, inr(-15300));
    expect(headers.last.net, inr(60000));
    await bloc.close();
  });

  test('search matches title, category and amount', () async {
    final bloc = build()..add(const ActivityStarted());
    await pumpEventQueue();
    bloc.add(const ActivitySearchChanged('swig'));
    await pumpEventQueue();
    expect(ids(bloc.state), ['swiggy']);
    bloc.add(const ActivitySearchChanged('rent'));
    await pumpEventQueue();
    expect(ids(bloc.state), ['rent']);
    bloc.add(const ActivitySearchChanged('60000'));
    await pumpEventQueue();
    expect(ids(bloc.state), ['salary']);
    await bloc.close();
  });

  test('filters by type and by top-level category', () async {
    final bloc = build()
      ..add(
        const ActivityStarted(
          TransactionQuery(types: {TransactionType.expense}),
        ),
      );
    await pumpEventQueue();
    expect(ids(bloc.state), ['swiggy', 'rent']);
    bloc.add(
      const ActivityFiltersChanged(TransactionQuery(categoryIds: {'food'})),
    );
    await pumpEventQueue();
    expect(ids(bloc.state), ['swiggy']);
    await bloc.close();
  });

  test('filters survive a search and vice versa', () async {
    final bloc = build()..add(const ActivityStarted());
    await pumpEventQueue();
    bloc
      ..add(const ActivitySearchChanged('s'))
      ..add(
        const ActivityFiltersChanged(
          TransactionQuery(types: {TransactionType.income}),
        ),
      );
    await pumpEventQueue();
    expect(bloc.state.query.text, 's');
    expect(ids(bloc.state), ['salary']);
    await bloc.close();
  });

  blocTest<ActivityBloc, ActivityState>(
    'delete then undo restores the transaction',
    build: build,
    act: (bloc) async {
      bloc.add(const ActivityStarted());
      await pumpEventQueue();
      bloc.add(const ActivityDeleteRequested('rent'));
      await pumpEventQueue();
      final deleted = bloc.state.lastDeleted;
      if (deleted != null) bloc.add(ActivityUndoRequested(deleted));
      await pumpEventQueue();
    },
    verify: (bloc) {
      expect(bloc.state.deletionCount, 1);
      expect(bloc.state.lastDeleted?.id, 'rent');
      expect(ids(bloc.state), ['swiggy', 'rent', 'salary']);
    },
  );

  test('deleting something already gone reports a failure', () async {
    final bloc = build()..add(const ActivityStarted());
    await pumpEventQueue();
    bloc.add(const ActivityDeleteRequested('missing'));
    await pumpEventQueue();
    expect(bloc.state.failureCount, 1);
    await bloc.close();
  });
}
