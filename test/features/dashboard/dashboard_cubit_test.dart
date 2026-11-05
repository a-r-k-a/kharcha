import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/clock.dart';
import 'package:kharcha/core/domain/date_range.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/ledger/domain/entities/account.dart';

import '../../helpers/in_memory_ledger.dart';

void main() {
  late LedgerStore store;
  final clock = FixedClock(DateTime(2026, 11, 4, 10));

  setUp(() async {
    store = LedgerStore(InMemoryLedgerOpener());
    await store.open(ownerId: 'u', currency: Currency.inr);
    await store.saveAccount(testAccount('bank', opening: 10000));
    await store.saveAccount(testAccount('cash', type: AccountType.cash));
    await store.saveTransaction(
      testIncome('i', amount: 50000, at: DateTime(2026, 11).toUtc()),
    );
    await store.saveTransaction(
      testExpense('e1', amount: 2000, at: DateTime(2026, 11, 3).toUtc()),
    );
    await store.saveTransaction(
      testExpense(
        'e2',
        amount: 500,
        at: DateTime(2026, 11, 4).toUtc(),
        account: 'cash',
      ),
    );
    await store.saveTransaction(
      testExpense('oct', amount: 1000, at: DateTime(2026, 10, 15).toUtc()),
    );
  });

  tearDown(() => store.dispose());

  test('summarizes the current month against the previous one', () async {
    final cubit = DashboardCubit(ledger: store, clock: clock);
    await pumpEventQueue();
    final view = cubit.state.view;
    expect(view?.summary.income, inr(50000));
    expect(view?.summary.expense, inr(2500));
    expect(view?.previous.expense, inr(1000));
    expect(view?.cashFlow, hasLength(30));
    expect(view?.breakdown.single.category?.id, 'food');
    expect(view?.recent.first.id, 'e2');
    expect(view?.position.liquid, inr(56500));
    await cubit.close();
  });

  test('the account filter narrows flows but not the balance card', () async {
    final cubit = DashboardCubit(ledger: store, clock: clock)
      ..setAccount('cash');
    await pumpEventQueue();
    final view = cubit.state.view;
    expect(view?.summary.expense, inr(500));
    expect(view?.summary.income, inr(0));
    expect(view?.recent.map((t) => t.id), ['e2']);
    expect(view?.position.liquid, inr(56500));
    await cubit.close();
  });

  test('switching to a week recomputes the buckets', () async {
    final cubit = DashboardCubit(ledger: store, clock: clock);
    await pumpEventQueue();
    cubit.setPeriod(PeriodKind.week);
    final view = cubit.state.view;
    expect(view?.period.kind, PeriodKind.week);
    expect(view?.cashFlow, hasLength(7));
    expect(view?.summary.expense, inr(2500));
    await cubit.close();
  });

  test('hiding amounts keeps the figures and flips the flag', () async {
    final cubit = DashboardCubit(ledger: store, clock: clock);
    await pumpEventQueue();
    cubit.toggleBalances();
    expect(cubit.state.balancesHidden, isTrue);
    expect(cubit.state.view, isNotNull);
    await cubit.close();
  });

  test('updates live when a transaction is added', () async {
    final cubit = DashboardCubit(ledger: store, clock: clock);
    await pumpEventQueue();
    await store.saveTransaction(
      testExpense('e3', amount: 100, at: DateTime(2026, 11, 4, 9).toUtc()),
    );
    await pumpEventQueue();
    expect(cubit.state.view?.summary.expense, inr(2600));
    await cubit.close();
  });
}
