import '../../../../core/domain/clock.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/id_generator.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../entities/account.dart';
import '../entities/transaction.dart';
import '../ledger_violation.dart';
import '../repositories/ledger_repositories.dart';
import '../services/ledger_validator.dart';
import 'drafts.dart';

final class SaveAccount {
  const SaveAccount({
    required this._ledger,
    required this._accounts,
    required this._clock,
    required this._ids,
  });

  final LedgerRepository _ledger;
  final AccountRepository _accounts;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Account>> call(AccountDraft draft) async {
    final ledger = _ledger.current;
    if (ledger == null) return const Err(StorageFailure());

    Account? original;
    if (draft.id case final id?) {
      original = ledger.accountById(id);
      if (original == null) return Err(LedgerViolation.accountMissing.failure);
    }
    final violation = LedgerValidator.account(draft, ledger);
    if (violation != null) return Err(violation.failure);

    final now = _clock.now().toUtc();
    final account = Account(
      id: original?.id ?? _ids.next(),
      name: draft.name.trim(),
      type: draft.type,
      openingBalance: draft.openingBalance,
      institution: draft.institution.trim(),
      isArchived: original?.isArchived ?? false,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );
    return switch (await _accounts.saveAccount(account)) {
      Ok() => Ok(account),
      Err(:final failure) => Err(failure),
    };
  }
}

final class SetAccountArchived {
  const SetAccountArchived({
    required this._ledger,
    required this._accounts,
    required this._clock,
  });

  final LedgerRepository _ledger;
  final AccountRepository _accounts;
  final Clock _clock;

  Future<Result<void>> call(String id, {required bool archived}) async {
    final account = _ledger.current?.accountById(id);
    if (account == null) return Err(LedgerViolation.accountMissing.failure);
    if (account.isArchived == archived) return const Ok(null);
    return _accounts.saveAccount(
      account.copyWith(isArchived: archived, updatedAt: _clock.now().toUtc()),
    );
  }
}

/// Deletes an account that has never been used. Accounts with history must
/// be archived instead, so past reports stay intact.
final class DeleteAccount {
  const DeleteAccount({required this._ledger, required this._accounts});

  final LedgerRepository _ledger;
  final AccountRepository _accounts;

  Future<Result<void>> call(String id) async {
    final ledger = _ledger.current;
    if (ledger == null || ledger.accountById(id) == null) {
      return Err(LedgerViolation.accountMissing.failure);
    }
    if (ledger.accountHasTransactions(id)) {
      return Err(LedgerViolation.accountHasTransactions.failure);
    }
    return _accounts.deleteAccount(id);
  }
}

/// Brings an account's tracked balance in line with its real balance by
/// recording the difference as an adjustment (never income or expense).
final class ReconcileAccount {
  const ReconcileAccount({
    required this._ledger,
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final LedgerRepository _ledger;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  /// Returns the adjustment recorded, or null when the balances already
  /// match.
  Future<Result<Transaction?>> call(String accountId, Money actual) async {
    final ledger = _ledger.current;
    final account = ledger?.accountById(accountId);
    if (ledger == null || account == null) {
      return Err(LedgerViolation.accountMissing.failure);
    }
    if (account.isArchived) return Err(LedgerViolation.accountArchived.failure);
    if (actual.currency != ledger.currency) {
      return Err(LedgerViolation.currencyMismatch.failure);
    }
    final difference = actual - ledger.balanceOf(accountId);
    if (difference.isZero) return const Ok(null);

    final now = _clock.now().toUtc();
    final adjustment = Transaction(
      id: _ids.next(),
      type: TransactionType.adjustment,
      amount: difference,
      accountId: accountId,
      occurredAt: now,
      title: 'Balance reconciled',
      createdAt: now,
      updatedAt: now,
    );
    return switch (await _transactions.saveTransaction(adjustment)) {
      Ok() => Ok(adjustment),
      Err(:final failure) => Err(failure),
    };
  }
}
