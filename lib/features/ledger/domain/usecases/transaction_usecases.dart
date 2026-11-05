import '../../../../core/domain/clock.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/id_generator.dart';
import '../../../../core/domain/result.dart';
import '../entities/ledger.dart';
import '../entities/transaction.dart';
import '../ledger_violation.dart';
import '../repositories/ledger_repositories.dart';
import '../services/ledger_validator.dart';
import 'drafts.dart';

/// Validates and stores a new or edited transaction.
final class SaveTransaction {
  const SaveTransaction({
    required this._ledger,
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final LedgerRepository _ledger;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Transaction>> call(TransactionDraft draft) async {
    final ledger = _ledger.current;
    if (ledger == null) return const Err(StorageFailure());

    Transaction? original;
    if (draft.id case final id?) {
      original = ledger.transactionById(id);
      if (original == null) {
        return Err(LedgerViolation.transactionMissing.failure);
      }
    }
    final violation = LedgerValidator.transaction(
      draft,
      ledger,
      original: original,
    );
    if (violation != null) return Err(violation.failure);

    final now = _clock.now().toUtc();
    final isTransfer = draft.type == TransactionType.transfer;
    final hasCategories =
        draft.type == TransactionType.expense ||
        draft.type == TransactionType.income;
    final transaction = Transaction(
      id: original?.id ?? _ids.next(),
      type: draft.type,
      amount: draft.amount,
      accountId: draft.accountId,
      counterpartyAccountId: isTransfer ? draft.counterpartyAccountId : null,
      allocations: hasCategories ? draft.allocations : const [],
      occurredAt: draft.occurredAt.toUtc(),
      title: draft.title.trim(),
      note: draft.note.trim(),
      tags: LedgerValidator.normalizeTags(draft.tags),
      paymentMethod: draft.type == TransactionType.adjustment
          ? null
          : draft.paymentMethod,
      isReimbursable:
          draft.type == TransactionType.expense && draft.isReimbursable,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );

    return switch (await _transactions.saveTransaction(transaction)) {
      Ok() => Ok(transaction),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Deletes a transaction and returns it, so the caller can offer undo via
/// [RestoreTransaction].
final class DeleteTransaction {
  const DeleteTransaction({required this._ledger, required this._transactions});

  final LedgerRepository _ledger;
  final TransactionRepository _transactions;

  Future<Result<Transaction>> call(String id) async {
    final Ledger? ledger = _ledger.current;
    final transaction = ledger?.transactionById(id);
    if (transaction == null) {
      return Err(LedgerViolation.transactionMissing.failure);
    }
    return switch (await _transactions.deleteTransaction(id)) {
      Ok() => Ok(transaction),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Puts back a transaction removed by [DeleteTransaction], unchanged.
final class RestoreTransaction {
  const RestoreTransaction(this._transactions);

  final TransactionRepository _transactions;

  Future<Result<void>> call(Transaction transaction) =>
      _transactions.saveTransaction(transaction);
}
