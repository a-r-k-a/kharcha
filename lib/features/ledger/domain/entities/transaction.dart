import 'package:equatable/equatable.dart';

import '../../../../core/domain/money.dart';

enum TransactionType {
  /// Money leaving the user's accounts.
  expense,

  /// Money entering the user's accounts.
  income,

  /// Money moving between two of the user's own accounts. Never counts as
  /// income or expense.
  transfer,

  /// A balance correction from reconciling an account. Changes the balance
  /// but never counts as income or expense.
  adjustment,
}

enum PaymentMethod {
  cash,
  upi,
  debitCard,
  creditCard,
  bankTransfer,
  neft,
  rtgs,
  imps,
  digitalWallet,
  other,
}

/// The part of a transaction assigned to one category. A transaction split
/// across categories has several; their amounts sum to the transaction's.
final class CategoryAllocation extends Equatable {
  const CategoryAllocation({required this.categoryId, required this.amount});

  final String categoryId;
  final Money amount;

  @override
  List<Object?> get props => [categoryId, amount];
}

/// One money movement.
///
/// Invariants (enforced by `TransactionValidator`):
/// - expense / income / transfer: [amount] is positive.
/// - adjustment: [amount] is non-zero and signed (+ raises the balance).
/// - expense / income: at least one allocation; allocations sum to [amount].
/// - transfer: [counterpartyAccountId] is set and differs from [accountId];
///   no allocations. It is a single balanced record: [amount] leaves
///   [accountId] and enters [counterpartyAccountId].
final class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.counterpartyAccountId,
    this.allocations = const [],
    this.title = '',
    this.note = '',
    this.tags = const [],
    this.paymentMethod,
    this.isReimbursable = false,
  });

  final String id;
  final TransactionType type;
  final Money amount;

  /// Expense and transfer: the source account. Income: the destination.
  /// Adjustment: the reconciled account.
  final String accountId;

  /// Transfer destination; null for every other type.
  final String? counterpartyAccountId;

  final List<CategoryAllocation> allocations;

  /// When the money moved. Stored and compared as an absolute instant;
  /// displayed in the device's time zone.
  final DateTime occurredAt;

  /// Payee, merchant or source, e.g. "Swiggy". May be empty.
  final String title;
  final String note;
  final List<String> tags;
  final PaymentMethod? paymentMethod;

  /// Paid on someone else's behalf and expected back. Still an expense when
  /// paid; the repayment is recorded as income under "Refunds".
  final bool isReimbursable;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSplit => allocations.length > 1;

  String? get primaryCategoryId =>
      allocations.isEmpty ? null : allocations.first.categoryId;

  /// True for expense and income: the types that count toward cash flow.
  bool get isCashFlow =>
      type == TransactionType.expense || type == TransactionType.income;

  /// The signed change this transaction makes to [accountIdToCheck]'s
  /// balance; zero when it doesn't touch that account.
  Money effectOn(String accountIdToCheck) {
    final zero = Money.zero(currency: amount.currency);
    return switch (type) {
      TransactionType.expense => accountId == accountIdToCheck ? -amount : zero,
      TransactionType.income => accountId == accountIdToCheck ? amount : zero,
      TransactionType.adjustment =>
        accountId == accountIdToCheck ? amount : zero,
      TransactionType.transfer =>
        accountId == accountIdToCheck
            ? -amount
            : (counterpartyAccountId == accountIdToCheck ? amount : zero),
    };
  }

  bool touchesAccount(String id) =>
      accountId == id || counterpartyAccountId == id;

  Transaction copyWith({
    String? id,
    TransactionType? type,
    Money? amount,
    String? accountId,
    String? Function()? counterpartyAccountId,
    List<CategoryAllocation>? allocations,
    DateTime? occurredAt,
    String? title,
    String? note,
    List<String>? tags,
    PaymentMethod? Function()? paymentMethod,
    bool? isReimbursable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      counterpartyAccountId: counterpartyAccountId != null
          ? counterpartyAccountId()
          : this.counterpartyAccountId,
      allocations: allocations ?? this.allocations,
      occurredAt: occurredAt ?? this.occurredAt,
      title: title ?? this.title,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      paymentMethod: paymentMethod != null
          ? paymentMethod()
          : this.paymentMethod,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    accountId,
    counterpartyAccountId,
    allocations,
    occurredAt,
    title,
    note,
    tags,
    paymentMethod,
    isReimbursable,
    createdAt,
    updatedAt,
  ];
}
