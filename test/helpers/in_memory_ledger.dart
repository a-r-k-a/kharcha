import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/ledger/data/datasources/record_collection.dart';
import 'package:kharcha/features/ledger/domain/entities/account.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';

final class InMemoryRecordCollection implements RecordCollection {
  final Map<String, String> records = {};

  /// When set, the next write throws this and is not applied.
  Object? failNextWrite;

  @override
  Map<String, String> readAll() => Map.of(records);

  @override
  Future<void> putAll(Map<String, String> entries) async {
    _maybeFail();
    records.addAll(entries);
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    _maybeFail();
    ids.forEach(records.remove);
  }

  void _maybeFail() {
    final failure = failNextWrite;
    if (failure != null) {
      failNextWrite = null;
      throw failure;
    }
  }
}

final class InMemoryLedgerCollections implements LedgerCollections {
  @override
  final InMemoryRecordCollection accounts = InMemoryRecordCollection();
  @override
  final InMemoryRecordCollection categories = InMemoryRecordCollection();
  @override
  final InMemoryRecordCollection transactions = InMemoryRecordCollection();

  bool destroyed = false;

  @override
  Future<void> close() async {}

  @override
  Future<void> destroy() async {
    destroyed = true;
    accounts.records.clear();
    categories.records.clear();
    transactions.records.clear();
  }
}

/// Keeps one set of collections per owner, like the Hive opener does.
final class InMemoryLedgerOpener implements LedgerCollectionsOpener {
  final Map<String, InMemoryLedgerCollections> byOwner = {};

  @override
  Future<LedgerCollections> open(String ownerId) async =>
      byOwner.putIfAbsent(ownerId, InMemoryLedgerCollections.new);
}

Money inr(num major) => Money.fromMajor(major);

final testEpoch = DateTime.utc(2026);

Account testAccount(
  String id, {
  AccountType type = AccountType.savings,
  num opening = 0,
  bool archived = false,
  String? name,
}) => Account(
  id: id,
  name: name ?? 'Account $id',
  type: type,
  openingBalance: inr(opening),
  isArchived: archived,
  createdAt: testEpoch,
  updatedAt: testEpoch,
);

Transaction testExpense(
  String id, {
  required num amount,
  required DateTime at,
  String account = 'bank',
  String category = 'food.groceries',
  String title = '',
}) => Transaction(
  id: id,
  type: TransactionType.expense,
  amount: inr(amount),
  accountId: account,
  allocations: [CategoryAllocation(categoryId: category, amount: inr(amount))],
  occurredAt: at,
  title: title,
  createdAt: at,
  updatedAt: at,
);

Transaction testIncome(
  String id, {
  required num amount,
  required DateTime at,
  String account = 'bank',
  String category = 'income.salary',
}) => Transaction(
  id: id,
  type: TransactionType.income,
  amount: inr(amount),
  accountId: account,
  allocations: [CategoryAllocation(categoryId: category, amount: inr(amount))],
  occurredAt: at,
  createdAt: at,
  updatedAt: at,
);

Transaction testTransfer(
  String id, {
  required num amount,
  required DateTime at,
  required String from,
  required String to,
}) => Transaction(
  id: id,
  type: TransactionType.transfer,
  amount: inr(amount),
  accountId: from,
  counterpartyAccountId: to,
  occurredAt: at,
  createdAt: at,
  updatedAt: at,
);
