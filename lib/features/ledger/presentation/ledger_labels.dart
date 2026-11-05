import '../../../core/domain/failure.dart';
import '../domain/entities/account.dart';
import '../domain/entities/category.dart';
import '../domain/entities/transaction.dart';
import '../domain/ledger_violation.dart';

extension AccountTypeLabel on AccountType {
  String get label => switch (this) {
    AccountType.savings => 'Savings account',
    AccountType.current => 'Current account',
    AccountType.cash => 'Cash',
    AccountType.digitalWallet => 'Digital wallet',
    AccountType.creditCard => 'Credit card',
    AccountType.fixedDeposit => 'Fixed deposit',
    AccountType.recurringDeposit => 'Recurring deposit',
    AccountType.investment => 'Investment account',
    AccountType.loan => 'Loan',
  };

  String get shortLabel => switch (this) {
    AccountType.savings => 'Savings',
    AccountType.current => 'Current',
    AccountType.cash => 'Cash',
    AccountType.digitalWallet => 'Wallet',
    AccountType.creditCard => 'Credit card',
    AccountType.fixedDeposit => 'FD',
    AccountType.recurringDeposit => 'RD',
    AccountType.investment => 'Investment',
    AccountType.loan => 'Loan',
  };

  /// The payment method an expense from this account most likely used.
  PaymentMethod get defaultPaymentMethod => switch (this) {
    AccountType.cash => PaymentMethod.cash,
    AccountType.creditCard => PaymentMethod.creditCard,
    AccountType.digitalWallet => PaymentMethod.digitalWallet,
    AccountType.savings || AccountType.current => PaymentMethod.upi,
    _ => PaymentMethod.bankTransfer,
  };
}

extension AccountGroupLabel on AccountGroup {
  String get label => switch (this) {
    AccountGroup.liquid => 'Cash & bank',
    AccountGroup.savingsAndInvestments => 'Savings & investments',
    AccountGroup.credit => 'Credit & loans',
  };
}

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
    TransactionType.transfer => 'Transfer',
    TransactionType.adjustment => 'Adjustment',
  };
}

extension CategoryKindLabel on CategoryKind {
  String get label => switch (this) {
    CategoryKind.expense => 'Expense',
    CategoryKind.income => 'Income',
  };
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.upi => 'UPI',
    PaymentMethod.debitCard => 'Debit card',
    PaymentMethod.creditCard => 'Credit card',
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.neft => 'NEFT',
    PaymentMethod.rtgs => 'RTGS',
    PaymentMethod.imps => 'IMPS',
    PaymentMethod.digitalWallet => 'Wallet',
    PaymentMethod.other => 'Other',
  };
}

extension LedgerViolationMessage on LedgerViolation {
  String get message => switch (this) {
    LedgerViolation.amountNotPositive => 'Enter an amount greater than zero.',
    LedgerViolation.amountZero => 'The adjustment can’t be zero.',
    LedgerViolation.currencyMismatch =>
      'This amount is in a different currency from your books.',
    LedgerViolation.accountMissing => 'Choose an account.',
    LedgerViolation.accountArchived =>
      'That account is archived. Restore it or pick another.',
    LedgerViolation.transferNeedsDestination =>
      'Choose the account the money goes to.',
    LedgerViolation.transferSameAccount =>
      'Pick two different accounts for a transfer.',
    LedgerViolation.categoryMissing => 'Choose a category.',
    LedgerViolation.categoryKindMismatch =>
      'That category doesn’t match this kind of transaction.',
    LedgerViolation.splitDoesNotAddUp =>
      'The split amounts must add up to the total.',
    LedgerViolation.splitDuplicateCategory =>
      'Each category can appear only once in a split.',
    LedgerViolation.splitAmountNotPositive =>
      'Every split line needs an amount above zero.',
    LedgerViolation.titleTooLong =>
      'Keep the description under ${LedgerLimits.titleLength} characters.',
    LedgerViolation.noteTooLong =>
      'Keep the note under ${LedgerLimits.noteLength} characters.',
    LedgerViolation.tooManyTags => 'Use at most ${LedgerLimits.tagCount} tags.',
    LedgerViolation.tagTooLong =>
      'Keep each tag under ${LedgerLimits.tagLength} characters.',
    LedgerViolation.nameEmpty => 'Give it a name.',
    LedgerViolation.nameTooLong => 'That name is too long.',
    LedgerViolation.nameTaken => 'You already have one with that name.',
    LedgerViolation.accountHasTransactions =>
      'This account has transactions. Archive it instead to keep your history.',
    LedgerViolation.categoryBuiltIn =>
      'Built-in categories can’t be renamed or deleted.',
    LedgerViolation.categoryParentInvalid =>
      'Choose a top-level category of the same kind.',
    LedgerViolation.transactionMissing => 'That transaction no longer exists.',
  };
}

/// User-facing copy for any failure. Never exposes [Failure.cause].
String failureMessage(Failure failure) {
  final violation = LedgerViolation.of(failure);
  if (violation != null) return violation.message;
  return switch (failure) {
    StorageFailure() =>
      'Couldn’t save to this device. Check free storage and try again.',
    NetworkFailure() => 'You’re offline. Try again when connected.',
    PermissionFailure() => 'You don’t have permission to do that.',
    NotFoundFailure() => 'That item no longer exists.',
    ValidationFailure() => 'Something in the form needs another look.',
    UnexpectedFailure() => 'Something went wrong. Please try again.',
  };
}
