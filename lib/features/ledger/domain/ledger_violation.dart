import '../../../core/domain/failure.dart';

/// Business-rule violations for the ledger. Carried as
/// `ValidationFailure.reason` (the enum name) so the shared failure type
/// stays unchanged; read back with [LedgerViolation.of].
enum LedgerViolation {
  amountNotPositive,
  amountZero,
  currencyMismatch,
  accountMissing,
  accountArchived,
  transferNeedsDestination,
  transferSameAccount,
  categoryMissing,
  categoryKindMismatch,
  splitDoesNotAddUp,
  splitDuplicateCategory,
  splitAmountNotPositive,
  titleTooLong,
  noteTooLong,
  tooManyTags,
  tagTooLong,
  nameEmpty,
  nameTooLong,
  nameTaken,
  accountHasTransactions,
  categoryBuiltIn,
  categoryParentInvalid,
  transactionMissing;

  ValidationFailure get failure => ValidationFailure(name);

  /// The violation behind [failure], or null for any other failure.
  static LedgerViolation? of(Failure failure) {
    if (failure is! ValidationFailure) return null;
    for (final value in values) {
      if (value.name == failure.reason) return value;
    }
    return null;
  }
}

/// Field limits shared by validation and form inputs.
abstract final class LedgerLimits {
  static const titleLength = 80;
  static const noteLength = 500;
  static const tagCount = 10;
  static const tagLength = 24;
  static const accountNameLength = 40;
  static const categoryNameLength = 30;
}
