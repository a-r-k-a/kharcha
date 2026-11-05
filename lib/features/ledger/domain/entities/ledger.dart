import 'dart:collection';

import '../../../../core/domain/money.dart';
import 'account.dart';
import 'category.dart';
import 'transaction.dart';

/// An immutable snapshot of the user's books. A new snapshot is published
/// after every change; lookups and balances are computed once per snapshot.
final class Ledger {
  factory Ledger({
    required Currency currency,
    required Iterable<Account> accounts,
    required Iterable<Category> categories,
    required Iterable<Transaction> transactions,
  }) {
    final sortedAccounts = accounts.toList()
      ..sort((a, b) {
        final byGroup = a.type.group.index.compareTo(b.type.group.index);
        if (byGroup != 0) return byGroup;
        return a.createdAt.compareTo(b.createdAt);
      });
    final sortedCategories = categories.toList()
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    final sortedTransactions = transactions.toList()..sort(newestFirst);

    final balances = <String, Money>{
      for (final account in sortedAccounts) account.id: account.openingBalance,
    };
    for (final transaction in sortedTransactions) {
      for (final id in [
        transaction.accountId,
        ?transaction.counterpartyAccountId,
      ]) {
        final current = balances[id];
        if (current != null) {
          balances[id] = current + transaction.effectOn(id);
        }
      }
    }

    return Ledger._(
      currency: currency,
      accounts: UnmodifiableListView(sortedAccounts),
      categories: UnmodifiableListView(sortedCategories),
      transactions: UnmodifiableListView(sortedTransactions),
      accountsById: {for (final a in sortedAccounts) a.id: a},
      categoriesById: {for (final c in sortedCategories) c.id: c},
      balances: balances,
    );
  }

  Ledger._({
    required this.currency,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this._accountsById,
    required this._categoriesById,
    required this._balances,
  });

  /// An empty ledger in [currency].
  factory Ledger.empty(Currency currency) => Ledger(
    currency: currency,
    accounts: const [],
    categories: const [],
    transactions: const [],
  );

  final Currency currency;

  /// Grouped liquid → savings → credit, then by creation date.
  final List<Account> accounts;
  final List<Category> categories;

  /// Newest first.
  final List<Transaction> transactions;

  final Map<String, Account> _accountsById;
  final Map<String, Category> _categoriesById;
  final Map<String, Money> _balances;

  Money get zero => Money.zero(currency: currency);

  List<Account> get activeAccounts =>
      accounts.where((account) => !account.isArchived).toList();

  Account? accountById(String id) => _accountsById[id];

  Category? categoryById(String id) => _categoriesById[id];

  /// The top-level category [id] rolls up to (itself when top-level).
  Category? topLevelCategoryOf(String id) {
    final category = _categoriesById[id];
    if (category == null) return null;
    final parentId = category.parentId;
    return parentId == null
        ? category
        : (_categoriesById[parentId] ?? category);
  }

  List<Category> topLevelCategories(CategoryKind kind) => categories
      .where((category) => category.kind == kind && category.isTopLevel)
      .toList();

  List<Category> subcategoriesOf(String parentId) =>
      categories.where((category) => category.parentId == parentId).toList();

  /// Current balance, or zero for an unknown account.
  Money balanceOf(String accountId) => _balances[accountId] ?? zero;

  Transaction? transactionById(String id) {
    for (final transaction in transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  bool accountHasTransactions(String accountId) =>
      transactions.any((transaction) => transaction.touchesAccount(accountId));

  /// Newest first; most recent entry wins ties on creation time.
  static int newestFirst(Transaction a, Transaction b) {
    final byDate = b.occurredAt.compareTo(a.occurredAt);
    return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
  }
}
