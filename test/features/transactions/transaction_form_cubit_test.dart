import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/clock.dart';
import 'package:kharcha/core/domain/id_generator.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/ledger/domain/entities/account.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';
import 'package:kharcha/features/ledger/domain/ledger_violation.dart';
import 'package:kharcha/features/ledger/domain/usecases/transaction_usecases.dart';
import 'package:kharcha/features/transactions/presentation/bloc/transaction_form_cubit.dart';

import '../../helpers/in_memory_ledger.dart';

void main() {
  late LedgerStore store;
  late FixedClock clock;

  setUp(() async {
    store = LedgerStore(InMemoryLedgerOpener());
    clock = FixedClock(DateTime(2026, 11, 4, 10));
    await store.open(ownerId: 'u', currency: Currency.inr);
    await store.saveAccount(testAccount('bank', opening: 1000));
    await store.saveAccount(testAccount('card', type: AccountType.creditCard));
    await store.saveAccount(testAccount('cash', type: AccountType.cash));
  });

  tearDown(() => store.dispose());

  TransactionFormCubit build([
    TransactionFormIntent intent = const NewTransaction(),
  ]) => TransactionFormCubit(
    ledger: store,
    save: SaveTransaction(
      ledger: store,
      transactions: store,
      clock: clock,
      ids: SequentialIdGenerator(),
    ),
    clock: clock,
    intent: intent,
  );

  test('a new expense defaults to the first bank account and UPI', () {
    final cubit = build();
    expect(cubit.state.status, TransactionFormStatus.editing);
    expect(cubit.state.accountId, 'bank');
    expect(cubit.state.paymentMethod, PaymentMethod.upi);
    expect(cubit.state.errorFor(TransactionField.amount), isNull);
  });

  test('the payment method follows the account until chosen', () {
    final cubit = build()..setAccount('card');
    expect(cubit.state.paymentMethod, PaymentMethod.creditCard);
    cubit
      ..setPaymentMethod(PaymentMethod.imps)
      ..setAccount('cash');
    expect(cubit.state.paymentMethod, PaymentMethod.imps);
  });

  test('switching type clears a category of the wrong kind', () {
    final cubit = build()
      ..setCategory('food')
      ..setType(TransactionType.income);
    expect(cubit.state.categoryId, isNull);
  });

  test('a new transfer preselects a different destination', () {
    final cubit = build(const NewTransaction(type: TransactionType.transfer));
    expect(cubit.state.accountId, 'bank');
    expect(cubit.state.counterpartyAccountId, isNot('bank'));
  });

  test('picking the destination as the source swaps them', () {
    final cubit = build(const NewTransaction(type: TransactionType.transfer));
    final destination = cubit.state.counterpartyAccountId;
    cubit.setAccount(destination ?? '');
    expect(cubit.state.counterpartyAccountId, 'bank');
  });

  test('submitting with no amount shows errors and saves nothing', () async {
    final cubit = build();
    await cubit.submit();
    expect(cubit.state.status, TransactionFormStatus.editing);
    expect(cubit.state.errorFor(TransactionField.amount), 'Enter an amount.');
    expect(store.current?.transactions, isEmpty);
  });

  test('a missing category is reported on the category field', () async {
    final cubit = build()..setAmount('99');
    await cubit.submit();
    expect(cubit.state.violation, LedgerViolation.categoryMissing);
    expect(cubit.state.errorFor(TransactionField.category), isNotNull);
    // Editing clears the stale message.
    cubit.setCategory('food');
    expect(cubit.state.errorFor(TransactionField.category), isNull);
  });

  test('a valid expense saves and reports saved', () async {
    final cubit = build()
      ..setAmount('250.75')
      ..setCategory('food.delivery')
      ..setTitle('Swiggy')
      ..addTag('Weekend')
      ..setReimbursable(true);
    await cubit.submit();
    expect(cubit.state.status, TransactionFormStatus.saved);
    final saved = store.current?.transactions.single;
    expect(saved?.amount, inr(250.75));
    expect(saved?.title, 'Swiggy');
    expect(saved?.tags, ['weekend']);
    expect(saved?.isReimbursable, isTrue);
  });

  test('a split tracks what is left and saves every line', () async {
    final cubit = build()
      ..setAmount('100')
      ..setCategory('food')
      ..setSplit(true);
    expect(cubit.state.splits.first.categoryId, 'food');
    cubit
      ..setSplitAmount(0, '60')
      ..setSplitCategory(1, 'shopping')
      ..setSplitAmount(1, '30');
    expect(cubit.state.splitRemaining, inr(10));

    await cubit.submit();
    expect(cubit.state.violation, LedgerViolation.splitDoesNotAddUp);

    cubit.setSplitAmount(1, '40');
    expect(cubit.state.splitRemaining, inr(0));
    await cubit.submit();
    expect(cubit.state.status, TransactionFormStatus.saved);
    expect(store.current?.transactions.single.allocations, hasLength(2));
  });

  test('editing prefills every field and keeps the id', () async {
    await store.saveTransaction(
      testExpense(
        't1',
        amount: 1234.5,
        at: DateTime.utc(2026, 11),
        category: 'food',
      ),
    );
    final cubit = build(const EditTransaction('t1'));
    expect(cubit.state.isEditing, isTrue);
    expect(cubit.state.amountText, '1234.50');
    expect(cubit.state.categoryId, 'food');
    cubit.setAmount('1300');
    await cubit.submit();
    expect(store.current?.transactionById('t1')?.amount, inr(1300));
    expect(store.current?.transactions, hasLength(1));
  });

  test('duplicating copies the entry with today’s date', () async {
    await store.saveTransaction(
      testExpense('t1', amount: 80, at: DateTime.utc(2026, 10)),
    );
    final cubit = build(const DuplicateTransaction('t1'));
    expect(cubit.state.isEditing, isFalse);
    expect(cubit.state.amountText, '80');
    expect(cubit.state.occurredAt, clock.now());
    await cubit.submit();
    expect(store.current?.transactions, hasLength(2));
  });

  test('editing a missing transaction reports not found', () {
    expect(
      build(const EditTransaction('nope')).state.status,
      TransactionFormStatus.notFound,
    );
  });
}
