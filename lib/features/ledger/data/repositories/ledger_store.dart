import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../domain/default_categories.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/ledger_repositories.dart';
import '../datasources/record_collection.dart';
import '../models/ledger_codec.dart';

/// The user's books: an in-memory cache over persistent collections that
/// publishes an immutable [Ledger] after every successful write.
///
/// Writes reach storage before the cache changes, so the UI never shows a
/// change that wasn't persisted. Implements every ledger contract so all
/// features share one source of truth.
final class LedgerStore
    implements
        LedgerRepository,
        AccountRepository,
        TransactionRepository,
        CategoryRepository {
  LedgerStore(this._opener);

  final LedgerCollectionsOpener _opener;
  final StreamController<Ledger> _changes = StreamController.broadcast();

  LedgerCollections? _collections;
  String? _ownerId;
  Currency _currency = Currency.inr;
  final Map<String, Account> _accounts = {};
  final Map<String, Category> _categories = {};
  final Map<String, Transaction> _transactions = {};
  Ledger? _current;

  @override
  Ledger? get current => _current;

  @override
  Stream<Ledger> watch() => Stream.multi((controller) {
    final current = _current;
    if (current != null) controller.add(current);
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<Result<void>> open({
    required String ownerId,
    required Currency currency,
  }) => _guard('open', () async {
    if (_ownerId == ownerId && _collections != null) return;
    await close();

    final collections = await _opener.open(ownerId);
    _readInto(collections.accounts, _accounts, LedgerCodec.decodeAccount);
    _readInto(collections.categories, _categories, LedgerCodec.decodeCategory);
    _readInto(
      collections.transactions,
      _transactions,
      LedgerCodec.decodeTransaction,
    );

    // Seed built-ins that are missing: all of them on first open, and any
    // added by a newer app version afterwards.
    final missing = {
      for (final category in DefaultCategories.build())
        if (!_categories.containsKey(category.id)) category.id: category,
    };
    if (missing.isNotEmpty) {
      await collections.categories.putAll({
        for (final MapEntry(:key, :value) in missing.entries)
          key: LedgerCodec.encodeCategory(value),
      });
      _categories.addAll(missing);
    }

    _collections = collections;
    _ownerId = ownerId;
    _currency = currency;
    _publish();
  });

  @override
  Future<void> close() async => _detach()?.close();

  @override
  Future<Result<void>> eraseAll() => _guard('erase', () async {
    // Destroy closes as it deletes; closing first would leave nothing to
    // delete through.
    await _detach()?.destroy();
  });

  /// Forgets the open books and returns their collections.
  LedgerCollections? _detach() {
    final collections = _collections;
    _collections = null;
    _ownerId = null;
    _current = null;
    _accounts.clear();
    _categories.clear();
    _transactions.clear();
    return collections;
  }

  // Accounts

  @override
  Future<Result<void>> saveAccount(Account account) => _write(
    'save account',
    (c) => c.accounts.putAll({account.id: LedgerCodec.encodeAccount(account)}),
    () => _accounts[account.id] = account,
  );

  @override
  Future<Result<void>> deleteAccount(String id) async {
    if (_transactions.values.any((t) => t.touchesAccount(id))) {
      return const Err(ValidationFailure('accountHasTransactions'));
    }
    return _write(
      'delete account',
      (c) => c.accounts.deleteAll([id]),
      () => _accounts.remove(id),
    );
  }

  // Transactions

  @override
  Future<Result<void>> saveTransaction(Transaction transaction) => _write(
    'save transaction',
    (c) => c.transactions.putAll({
      transaction.id: LedgerCodec.encodeTransaction(transaction),
    }),
    () => _transactions[transaction.id] = transaction,
  );

  @override
  Future<Result<void>> deleteTransaction(String id) => _write(
    'delete transaction',
    (c) => c.transactions.deleteAll([id]),
    () => _transactions.remove(id),
  );

  // Categories

  @override
  Future<Result<void>> saveCategory(Category category) => _write(
    'save category',
    (c) => c.categories.putAll({
      category.id: LedgerCodec.encodeCategory(category),
    }),
    () => _categories[category.id] = category,
  );

  @override
  Future<Result<void>> deleteCategory(
    String id, {
    required String replacementId,
  }) async {
    final removed = {
      id,
      for (final c in _categories.values)
        if (c.parentId == id) c.id,
    };
    if (removed.contains(replacementId) ||
        !_categories.containsKey(replacementId)) {
      return const Err(ValidationFailure('categoryParentInvalid'));
    }
    final reassigned = <String, Transaction>{
      for (final t in _transactions.values)
        if (t.allocations.any((a) => removed.contains(a.categoryId)))
          t.id: t.copyWith(
            allocations: _reassign(t.allocations, removed, replacementId),
          ),
    };

    return _write(
      'delete category',
      (c) async {
        // Reassign first: if the delete then fails, every transaction still
        // points at a category that exists.
        if (reassigned.isNotEmpty) {
          await c.transactions.putAll({
            for (final t in reassigned.values)
              t.id: LedgerCodec.encodeTransaction(t),
          });
        }
        await c.categories.deleteAll(removed);
      },
      () {
        _transactions.addAll(reassigned);
        removed.forEach(_categories.remove);
      },
    );
  }

  /// Moves allocations in [removed] to [replacementId], merging amounts if
  /// the transaction already had an allocation there.
  static List<CategoryAllocation> _reassign(
    List<CategoryAllocation> allocations,
    Set<String> removed,
    String replacementId,
  ) {
    final merged = <String, Money>{};
    for (final a in allocations) {
      final target = removed.contains(a.categoryId)
          ? replacementId
          : a.categoryId;
      final existing = merged[target];
      merged[target] = existing == null ? a.amount : existing + a.amount;
    }
    return [
      for (final MapEntry(:key, :value) in merged.entries)
        CategoryAllocation(categoryId: key, amount: value),
    ];
  }

  // Internals

  Future<Result<void>> _write(
    String operation,
    Future<void> Function(LedgerCollections collections) persist,
    void Function() apply,
  ) {
    final collections = _collections;
    if (collections == null) {
      return Future.value(const Err(StorageFailure()));
    }
    return _guard(operation, () async {
      await persist(collections);
      // Ignore the result if the books were closed or switched meanwhile.
      if (!identical(_collections, collections)) return;
      apply();
      _publish();
    });
  }

  void _publish() {
    final ledger = Ledger(
      currency: _currency,
      accounts: _accounts.values,
      categories: _categories.values,
      transactions: _transactions.values,
    );
    _current = ledger;
    _changes.add(ledger);
  }

  void _readInto<T>(
    RecordCollection collection,
    Map<String, T> target,
    T Function(String source) decode,
  ) {
    target.clear();
    var skipped = 0;
    for (final MapEntry(:key, :value) in collection.readAll().entries) {
      try {
        target[key] = decode(value);
      } on MalformedRecord catch (error) {
        skipped++;
        // Log the field only: record contents are financial data.
        developer.log(
          'Skipped malformed record (${error.field})',
          name: 'ledger',
        );
      }
    }
    if (skipped > 0) {
      developer.log('$skipped record(s) could not be read', name: 'ledger');
    }
  }

  Future<Result<void>> _guard(
    String operation,
    Future<void> Function() body,
  ) async {
    try {
      await body();
      return const Ok(null);
    } on HiveError catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    } on FileSystemException catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    } on StateError catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    }
  }

  Result<void> _fail(String operation, Object error, StackTrace stackTrace) {
    developer.log(
      'Ledger $operation failed',
      name: 'ledger',
      error: error,
      stackTrace: stackTrace,
    );
    return Err(StorageFailure(cause: error));
  }

  /// Closes storage and the change stream. For app shutdown and tests.
  Future<void> dispose() async {
    await close();
    await _changes.close();
  }
}
