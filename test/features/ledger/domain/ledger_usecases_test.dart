import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/clock.dart';
import 'package:kharcha/core/domain/failure.dart';
import 'package:kharcha/core/domain/id_generator.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/core/domain/result.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/ledger/domain/entities/account.dart';
import 'package:kharcha/features/ledger/domain/entities/category.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';
import 'package:kharcha/features/ledger/domain/ledger_violation.dart';
import 'package:kharcha/features/ledger/domain/usecases/account_usecases.dart';
import 'package:kharcha/features/ledger/domain/usecases/category_usecases.dart';
import 'package:kharcha/features/ledger/domain/usecases/drafts.dart';
import 'package:kharcha/features/ledger/domain/usecases/transaction_usecases.dart';

import '../../../helpers/in_memory_ledger.dart';

void main() {
  late LedgerStore store;
  late FixedClock clock;
  late SequentialIdGenerator ids;
  late SaveTransaction saveTransaction;
  late SaveAccount saveAccount;

  T value<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  LedgerViolation? violation<T>(Result<T> result) => switch (result) {
    Ok() => null,
    Err(:final failure) => LedgerViolation.of(failure),
  };

  setUp(() async {
    store = LedgerStore(InMemoryLedgerOpener());
    clock = FixedClock(DateTime.utc(2026, 11, 4, 10));
    ids = SequentialIdGenerator();
    saveTransaction = SaveTransaction(
      ledger: store,
      transactions: store,
      clock: clock,
      ids: ids,
    );
    saveAccount = SaveAccount(
      ledger: store,
      accounts: store,
      clock: clock,
      ids: ids,
    );
    value(await store.open(ownerId: 'u1', currency: Currency.inr));
  });

  tearDown(() => store.dispose());

  Future<Account> addAccount(
    String name, {
    AccountType type = AccountType.savings,
    num opening = 0,
  }) async => value(
    await saveAccount(
      AccountDraft(name: name, type: type, openingBalance: inr(opening)),
    ),
  );

  TransactionDraft expense(
    String accountId,
    num amount, {
    List<CategoryAllocation>? allocations,
  }) => TransactionDraft(
    type: TransactionType.expense,
    amount: inr(amount),
    accountId: accountId,
    occurredAt: clock.now(),
    allocations:
        allocations ??
        [CategoryAllocation(categoryId: 'food', amount: inr(amount))],
  );

  group('SaveTransaction', () {
    test('stores a valid expense with ids and timestamps', () async {
      final bank = await addAccount('HDFC', opening: 1000);
      final saved = value(
        await saveTransaction(
          expense(bank.id, 250).copyWithTitle('  Swiggy  '),
        ),
      );
      expect(saved.id, isNotEmpty);
      expect(saved.title, 'Swiggy');
      expect(saved.createdAt, clock.now());
      expect(store.current?.balanceOf(bank.id), inr(750));
    });

    test('rejects zero and negative amounts', () async {
      final bank = await addAccount('HDFC');
      expect(
        violation(await saveTransaction(expense(bank.id, 0))),
        LedgerViolation.amountNotPositive,
      );
      expect(
        violation(await saveTransaction(expense(bank.id, -5))),
        LedgerViolation.amountNotPositive,
      );
    });

    test('rejects an unknown account and an archived one', () async {
      expect(
        violation(await saveTransaction(expense('nope', 10))),
        LedgerViolation.accountMissing,
      );
      final old = await addAccount('Old');
      await SetAccountArchived(ledger: store, accounts: store, clock: clock)(
        old.id,
        archived: true,
      );
      expect(
        violation(await saveTransaction(expense(old.id, 10))),
        LedgerViolation.accountArchived,
      );
    });

    test('requires a category of the matching kind', () async {
      final bank = await addAccount('HDFC');
      expect(
        violation(await saveTransaction(expense(bank.id, 10, allocations: []))),
        LedgerViolation.categoryMissing,
      );
      expect(
        violation(
          await saveTransaction(
            expense(
              bank.id,
              10,
              allocations: [
                CategoryAllocation(
                  categoryId: 'income.salary',
                  amount: inr(10),
                ),
              ],
            ),
          ),
        ),
        LedgerViolation.categoryKindMismatch,
      );
    });

    test('splits must add up exactly, to the paisa', () async {
      final bank = await addAccount('HDFC');
      final off = expense(
        bank.id,
        100,
        allocations: [
          CategoryAllocation(categoryId: 'food', amount: inr(60)),
          CategoryAllocation(categoryId: 'shopping', amount: inr(39.99)),
        ],
      );
      expect(
        violation(await saveTransaction(off)),
        LedgerViolation.splitDoesNotAddUp,
      );
      final exact = expense(
        bank.id,
        100,
        allocations: [
          CategoryAllocation(categoryId: 'food', amount: inr(60.01)),
          CategoryAllocation(categoryId: 'shopping', amount: inr(39.99)),
        ],
      );
      expect(violation(await saveTransaction(exact)), isNull);
    });

    test(
      'a transfer needs two different accounts and drops categories',
      () async {
        final bank = await addAccount('HDFC', opening: 10000);
        final cash = await addAccount('Cash', type: AccountType.cash);
        TransactionDraft transfer(String? to) => TransactionDraft(
          type: TransactionType.transfer,
          amount: inr(10000),
          accountId: bank.id,
          counterpartyAccountId: to,
          occurredAt: clock.now(),
          allocations: [CategoryAllocation(categoryId: 'food', amount: inr(1))],
          isReimbursable: true,
        );
        expect(
          violation(await saveTransaction(transfer(null))),
          LedgerViolation.transferNeedsDestination,
        );
        expect(
          violation(await saveTransaction(transfer(bank.id))),
          LedgerViolation.transferSameAccount,
        );
        final saved = value(await saveTransaction(transfer(cash.id)));
        expect(saved.allocations, isEmpty);
        expect(saved.isReimbursable, isFalse);
        final ledger = store.current;
        expect(ledger?.balanceOf(bank.id), inr(0));
        expect(ledger?.balanceOf(cash.id), inr(10000));
      },
    );

    test('editing keeps id and createdAt and updates updatedAt', () async {
      final bank = await addAccount('HDFC');
      final original = value(await saveTransaction(expense(bank.id, 10)));
      clock.advance(const Duration(hours: 1));
      final edited = value(
        await saveTransaction(
          TransactionDraft.fromTransaction(original).copyWithTitle('Edited'),
        ),
      );
      expect(edited.id, original.id);
      expect(edited.createdAt, original.createdAt);
      expect(edited.updatedAt, clock.now());
      expect(store.current?.transactions, hasLength(1));
    });

    test('tags are normalized and limited', () async {
      final bank = await addAccount('HDFC');
      final saved = value(
        await saveTransaction(
          expense(bank.id, 10).copyWithTags([' Work ', 'work', '', 'Trip']),
        ),
      );
      expect(saved.tags, ['work', 'trip']);
      expect(
        violation(
          await saveTransaction(
            expense(
              bank.id,
              10,
            ).copyWithTags([for (var i = 0; i < 11; i++) 't$i']),
          ),
        ),
        LedgerViolation.tooManyTags,
      );
    });
  });

  test('delete then restore puts the transaction back unchanged', () async {
    final bank = await addAccount('HDFC', opening: 100);
    final saved = value(await saveTransaction(expense(bank.id, 40)));
    final deleted = value(
      await DeleteTransaction(ledger: store, transactions: store)(saved.id),
    );
    expect(store.current?.balanceOf(bank.id), inr(100));
    value(await RestoreTransaction(store)(deleted));
    expect(store.current?.transactionById(saved.id), saved);
    expect(store.current?.balanceOf(bank.id), inr(60));
  });

  group('accounts', () {
    test('names must be present and unique, ignoring case', () async {
      await addAccount('HDFC Savings');
      expect(
        violation(
          await saveAccount(
            AccountDraft(
              name: '  ',
              type: AccountType.cash,
              openingBalance: inr(0),
            ),
          ),
        ),
        LedgerViolation.nameEmpty,
      );
      expect(
        violation(
          await saveAccount(
            AccountDraft(
              name: 'hdfc savings',
              type: AccountType.cash,
              openingBalance: inr(0),
            ),
          ),
        ),
        LedgerViolation.nameTaken,
      );
    });

    test('an account with history cannot be deleted, only archived', () async {
      final bank = await addAccount('HDFC');
      final unused = await addAccount('Unused');
      await saveTransaction(expense(bank.id, 5));
      final delete = DeleteAccount(ledger: store, accounts: store);
      expect(
        violation(await delete(bank.id)),
        LedgerViolation.accountHasTransactions,
      );
      value(await delete(unused.id));
      expect(store.current?.accountById(unused.id), isNull);
    });

    test('reconcile records the difference as an adjustment', () async {
      final bank = await addAccount('HDFC', opening: 1000);
      final reconcile = ReconcileAccount(
        ledger: store,
        transactions: store,
        clock: clock,
        ids: ids,
      );
      final adjustment = value(await reconcile(bank.id, inr(1250.75)));
      expect(adjustment?.type, TransactionType.adjustment);
      expect(adjustment?.amount, inr(250.75));
      expect(store.current?.balanceOf(bank.id), inr(1250.75));
      expect(value(await reconcile(bank.id, inr(1250.75))), isNull);
    });
  });

  group('categories', () {
    test('custom categories are created; built-ins keep their name', () async {
      final save = SaveCategory(ledger: store, categories: store, ids: ids);
      final pets = value(
        await save(
          const CategoryDraft(
            name: 'Pets',
            kind: CategoryKind.expense,
            glyph: CategoryGlyph.pets,
            tone: CategoryTone.green,
          ),
        ),
      );
      expect(pets.isCustom, isTrue);
      expect(
        violation(
          await save(
            const CategoryDraft(
              id: 'food',
              name: 'Eats',
              kind: CategoryKind.expense,
              glyph: CategoryGlyph.food,
              tone: CategoryTone.blue,
            ),
          ),
        ),
        LedgerViolation.categoryBuiltIn,
      );
      final restyled = value(
        await save(
          const CategoryDraft(
            id: 'food',
            name: 'Food',
            kind: CategoryKind.expense,
            glyph: CategoryGlyph.coffee,
            tone: CategoryTone.red,
          ),
        ),
      );
      expect(restyled.tone, CategoryTone.red);
    });

    test(
      'deleting a category moves its transactions, merging splits',
      () async {
        final save = SaveCategory(ledger: store, categories: store, ids: ids);
        final snacks = value(
          await save(
            const CategoryDraft(
              name: 'Snacks',
              kind: CategoryKind.expense,
              parentId: 'food',
              glyph: CategoryGlyph.coffee,
              tone: CategoryTone.blue,
            ),
          ),
        );
        final bank = await addAccount('HDFC');
        final split = value(
          await saveTransaction(
            expense(
              bank.id,
              100,
              allocations: [
                CategoryAllocation(categoryId: snacks.id, amount: inr(30)),
                CategoryAllocation(categoryId: 'food', amount: inr(70)),
              ],
            ),
          ),
        );

        final delete = DeleteCategory(ledger: store, categories: store);
        value(await delete(snacks.id));

        final ledger = store.current;
        expect(ledger?.categoryById(snacks.id), isNull);
        expect(ledger?.transactionById(split.id)?.allocations, [
          CategoryAllocation(categoryId: 'food', amount: inr(100)),
        ]);
        expect(
          violation(await delete('food')),
          LedgerViolation.categoryBuiltIn,
        );
      },
    );
  });

  test('writes fail cleanly when no books are open', () async {
    await store.close();
    final result = await saveTransaction(expense('x', 1));
    expect(result, isA<Err<Transaction>>());
    expect((result as Err<Transaction>).failure, isA<StorageFailure>());
  });
}

extension on TransactionDraft {
  TransactionDraft copyWithTitle(String title) => _copy(title: title);
  TransactionDraft copyWithTags(List<String> tags) => _copy(tags: tags);

  TransactionDraft _copy({String? title, List<String>? tags}) =>
      TransactionDraft(
        id: id,
        type: type,
        amount: amount,
        accountId: accountId,
        counterpartyAccountId: counterpartyAccountId,
        allocations: allocations,
        occurredAt: occurredAt,
        title: title ?? this.title,
        note: note,
        tags: tags ?? this.tags,
        paymentMethod: paymentMethod,
        isReimbursable: isReimbursable,
      );
}
