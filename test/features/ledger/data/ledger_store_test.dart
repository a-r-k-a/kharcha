import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:kharcha/core/domain/failure.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/core/domain/result.dart';
import 'package:kharcha/features/ledger/data/models/ledger_codec.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/ledger/domain/default_categories.dart';
import 'package:kharcha/features/ledger/domain/entities/account.dart';
import 'package:kharcha/features/ledger/domain/entities/ledger.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';

import '../../../helpers/in_memory_ledger.dart';

void main() {
  late InMemoryLedgerOpener opener;
  late LedgerStore store;

  setUp(() {
    opener = InMemoryLedgerOpener();
    store = LedgerStore(opener);
  });

  tearDown(() => store.dispose());

  Future<void> open(String owner) async => expect(
    await store.open(ownerId: owner, currency: Currency.inr),
    isA<Ok<void>>(),
  );

  test('seeds built-in categories on first open', () async {
    await open('u1');
    expect(
      store.current?.categories.map((c) => c.id).toSet(),
      DefaultCategories.build().map((c) => c.id).toSet(),
    );
    expect(store.current?.categoryById('food.groceries')?.parentId, 'food');
  });

  test('watch emits the current snapshot, then every change', () async {
    await open('u1');
    final emitted = <Ledger>[];
    final subscription = store.watch().listen(emitted.add);
    await pumpEventQueue();
    await store.saveAccount(testAccount('bank', opening: 10));
    await pumpEventQueue();
    await subscription.cancel();
    expect(emitted, hasLength(2));
    expect(emitted.last.accounts.single.id, 'bank');
  });

  test('keeps each owner\'s books separate', () async {
    await open('alice');
    await store.saveAccount(testAccount('alice-bank'));
    await open('bob');
    expect(store.current?.accounts, isEmpty);
    await open('alice');
    expect(store.current?.accountById('alice-bank'), isNotNull);
  });

  test('a failed write leaves the snapshot unchanged', () async {
    await open('u1');
    opener.byOwner['u1']?.accounts.failNextWrite = HiveError('disk full');
    final result = await store.saveAccount(testAccount('bank'));
    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<StorageFailure>());
    expect(store.current?.accounts, isEmpty);
  });

  test('skips malformed records instead of failing to open', () async {
    final collections = await opener.open('u1');
    await collections.accounts.putAll({
      'good': LedgerCodec.encodeAccount(testAccount('good')),
      'bad': '{"v":1,"id":"bad"}',
      'garbage': 'not json',
    });
    await open('u1');
    expect(store.current?.accounts.map((a) => a.id), ['good']);
  });

  test('eraseAll destroys the owner\'s data and closes the books', () async {
    await open('u1');
    await store.saveAccount(testAccount('bank'));
    expect(await store.eraseAll(), isA<Ok<void>>());
    expect(store.current, isNull);
    expect(opener.byOwner['u1']?.destroyed, isTrue);
  });

  group('codec', () {
    test('round-trips every field of a transaction', () {
      final original = Transaction(
        id: 't1',
        type: TransactionType.expense,
        amount: inr(1234.56),
        accountId: 'bank',
        allocations: [
          CategoryAllocation(categoryId: 'food', amount: inr(1000)),
          CategoryAllocation(categoryId: 'shopping', amount: inr(234.56)),
        ],
        occurredAt: DateTime.utc(2026, 11, 4, 12, 30),
        title: 'Big Bazaar',
        note: 'Monthly stock-up',
        tags: const ['home'],
        paymentMethod: PaymentMethod.upi,
        isReimbursable: true,
        createdAt: DateTime.utc(2026, 11, 4),
        updatedAt: DateTime.utc(2026, 11, 5),
      );
      expect(
        LedgerCodec.decodeTransaction(LedgerCodec.encodeTransaction(original)),
        original,
      );
    });

    test('round-trips a transfer and an account', () {
      final transfer = testTransfer(
        't2',
        amount: 500,
        at: DateTime.utc(2026),
        from: 'a',
        to: 'b',
      );
      expect(
        LedgerCodec.decodeTransaction(LedgerCodec.encodeTransaction(transfer)),
        transfer,
      );
      final card = testAccount(
        'c',
        type: AccountType.creditCard,
        opening: -99.5,
      );
      expect(LedgerCodec.decodeAccount(LedgerCodec.encodeAccount(card)), card);
    });

    test('rejects records from a newer schema or with bad fields', () {
      expect(
        () => LedgerCodec.decodeAccount('{"v":99}'),
        throwsA(isA<MalformedRecord>()),
      );
      final json = LedgerCodec.encodeAccount(testAccount('a'));
      expect(
        () => LedgerCodec.decodeAccount(json.replaceFirst('"INR"', '"XYZ"')),
        throwsA(isA<MalformedRecord>()),
      );
      expect(
        () => LedgerCodec.decodeAccount(
          json.replaceFirst('"savings"', '"mattress"'),
        ),
        throwsA(isA<MalformedRecord>()),
      );
    });
  });
}
