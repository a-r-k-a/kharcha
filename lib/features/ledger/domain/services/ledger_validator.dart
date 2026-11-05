import '../../../../core/domain/money.dart';
import '../entities/account.dart';
import '../entities/category.dart';
import '../entities/ledger.dart';
import '../entities/transaction.dart';
import '../ledger_violation.dart';
import '../usecases/drafts.dart';

/// Business rules for ledger writes. Returns the first violation found, or
/// null when the draft is valid against [ledger].
abstract final class LedgerValidator {
  static LedgerViolation? transaction(
    TransactionDraft draft,
    Ledger ledger, {
    Transaction? original,
  }) {
    final amount = draft.amount;
    if (amount.currency != ledger.currency) {
      return LedgerViolation.currencyMismatch;
    }
    if (draft.type == TransactionType.adjustment) {
      if (amount.isZero) return LedgerViolation.amountZero;
    } else if (!amount.isPositive) {
      return LedgerViolation.amountNotPositive;
    }

    final accountViolation = _usableAccount(
      draft.accountId,
      ledger,
      allowArchived: original?.touchesAccount(draft.accountId) ?? false,
    );
    if (accountViolation != null) return accountViolation;

    switch (draft.type) {
      case TransactionType.transfer:
        final destination = draft.counterpartyAccountId;
        if (destination == null) {
          return LedgerViolation.transferNeedsDestination;
        }
        if (destination == draft.accountId) {
          return LedgerViolation.transferSameAccount;
        }
        final destinationViolation = _usableAccount(
          destination,
          ledger,
          allowArchived: original?.touchesAccount(destination) ?? false,
        );
        if (destinationViolation != null) return destinationViolation;
      case TransactionType.expense || TransactionType.income:
        final violation = _allocations(draft, ledger);
        if (violation != null) return violation;
      case TransactionType.adjustment:
        break;
    }

    if (draft.title.trim().length > LedgerLimits.titleLength) {
      return LedgerViolation.titleTooLong;
    }
    if (draft.note.trim().length > LedgerLimits.noteLength) {
      return LedgerViolation.noteTooLong;
    }
    final tags = normalizeTags(draft.tags);
    if (tags.length > LedgerLimits.tagCount) return LedgerViolation.tooManyTags;
    if (tags.any((tag) => tag.length > LedgerLimits.tagLength)) {
      return LedgerViolation.tagTooLong;
    }
    return null;
  }

  static LedgerViolation? _usableAccount(
    String id,
    Ledger ledger, {
    required bool allowArchived,
  }) {
    final account = ledger.accountById(id);
    if (account == null) return LedgerViolation.accountMissing;
    if (account.isArchived && !allowArchived) {
      return LedgerViolation.accountArchived;
    }
    return null;
  }

  static LedgerViolation? _allocations(TransactionDraft draft, Ledger ledger) {
    final allocations = draft.allocations;
    if (allocations.isEmpty) return LedgerViolation.categoryMissing;
    final kind = draft.type == TransactionType.expense
        ? CategoryKind.expense
        : CategoryKind.income;
    final seen = <String>{};
    var total = Money.zero(currency: ledger.currency);
    for (final allocation in allocations) {
      final category = ledger.categoryById(allocation.categoryId);
      if (category == null) return LedgerViolation.categoryMissing;
      if (category.kind != kind) return LedgerViolation.categoryKindMismatch;
      if (!seen.add(allocation.categoryId)) {
        return LedgerViolation.splitDuplicateCategory;
      }
      if (allocation.amount.currency != ledger.currency) {
        return LedgerViolation.currencyMismatch;
      }
      if (!allocation.amount.isPositive) {
        return LedgerViolation.splitAmountNotPositive;
      }
      total += allocation.amount;
    }
    if (total != draft.amount) return LedgerViolation.splitDoesNotAddUp;
    return null;
  }

  static LedgerViolation? account(AccountDraft draft, Ledger ledger) {
    final name = draft.name.trim();
    if (name.isEmpty) return LedgerViolation.nameEmpty;
    if (name.length > LedgerLimits.accountNameLength) {
      return LedgerViolation.nameTooLong;
    }
    if (draft.openingBalance.currency != ledger.currency) {
      return LedgerViolation.currencyMismatch;
    }
    final lower = name.toLowerCase();
    final taken = ledger.accounts.any(
      (Account other) =>
          other.id != draft.id && other.name.trim().toLowerCase() == lower,
    );
    return taken ? LedgerViolation.nameTaken : null;
  }

  static LedgerViolation? category(
    CategoryDraft draft,
    Ledger ledger, {
    Category? original,
  }) {
    final name = draft.name.trim();
    if (name.isEmpty) return LedgerViolation.nameEmpty;
    if (name.length > LedgerLimits.categoryNameLength) {
      return LedgerViolation.nameTooLong;
    }
    if (original != null && !original.isCustom && original.name != name) {
      return LedgerViolation.categoryBuiltIn;
    }
    final parentId = original?.parentId ?? draft.parentId;
    if (parentId != null) {
      final parent = ledger.categoryById(parentId);
      if (parent == null || !parent.isTopLevel || parent.kind != draft.kind) {
        return LedgerViolation.categoryParentInvalid;
      }
    }
    final lower = name.toLowerCase();
    final taken = ledger.categories.any(
      (other) =>
          other.id != original?.id &&
          other.kind == draft.kind &&
          other.parentId == parentId &&
          other.name.trim().toLowerCase() == lower,
    );
    return taken ? LedgerViolation.nameTaken : null;
  }

  /// Trimmed, lower-cased, de-duplicated, empties removed; order kept.
  static List<String> normalizeTags(Iterable<String> tags) {
    final seen = <String>{};
    return [
      for (final tag in tags.map((t) => t.trim().toLowerCase()))
        if (tag.isNotEmpty && seen.add(tag)) tag,
    ];
  }
}
