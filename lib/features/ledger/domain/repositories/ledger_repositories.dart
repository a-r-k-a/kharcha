import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../entities/account.dart';
import '../entities/category.dart';
import '../entities/ledger.dart';
import '../entities/transaction.dart';

/// Read side of the user's books, plus their lifecycle.
abstract interface class LedgerRepository {
  /// Opens the books owned by [ownerId]. Books are stored per owner, so one
  /// owner can never read another's data. Seeds the built-in categories the
  /// first time. Re-opening for the current owner is a no-op.
  Future<Result<void>> open({
    required String ownerId,
    required Currency currency,
  });

  /// Closes the open books and stops [watch] emitting.
  Future<void> close();

  /// The latest snapshot, or null while no books are open.
  Ledger? get current;

  /// Emits the current snapshot on listen (once books are open), then a new
  /// snapshot after every change.
  Stream<Ledger> watch();

  /// Permanently deletes every record of the open owner and closes the books.
  Future<Result<void>> eraseAll();
}

abstract interface class AccountRepository {
  Future<Result<void>> saveAccount(Account account);

  /// Fails with `ValidationFailure` if the account has transactions.
  Future<Result<void>> deleteAccount(String id);
}

abstract interface class TransactionRepository {
  Future<Result<void>> saveTransaction(Transaction transaction);
  Future<Result<void>> deleteTransaction(String id);
}

abstract interface class CategoryRepository {
  Future<Result<void>> saveCategory(Category category);

  /// Deletes [id] and, in the same write, moves every allocation that used
  /// it (or one of its subcategories) to [replacementId].
  Future<Result<void>> deleteCategory(
    String id, {
    required String replacementId,
  });
}
