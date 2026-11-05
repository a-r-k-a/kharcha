import 'package:equatable/equatable.dart';

import '../../../../core/domain/money.dart';
import '../entities/account.dart';
import '../entities/category.dart';
import '../entities/transaction.dart';

/// User input for creating ([id] null) or editing a transaction.
final class TransactionDraft extends Equatable {
  const TransactionDraft({
    required this.type,
    required this.amount,
    required this.accountId,
    required this.occurredAt,
    this.id,
    this.counterpartyAccountId,
    this.allocations = const [],
    this.title = '',
    this.note = '',
    this.tags = const [],
    this.paymentMethod,
    this.isReimbursable = false,
  });

  factory TransactionDraft.fromTransaction(Transaction t) => TransactionDraft(
    id: t.id,
    type: t.type,
    amount: t.amount,
    accountId: t.accountId,
    counterpartyAccountId: t.counterpartyAccountId,
    allocations: t.allocations,
    occurredAt: t.occurredAt,
    title: t.title,
    note: t.note,
    tags: t.tags,
    paymentMethod: t.paymentMethod,
    isReimbursable: t.isReimbursable,
  );

  /// A new entry copying [t], dated [now].
  factory TransactionDraft.duplicateOf(Transaction t, DateTime now) =>
      TransactionDraft(
        type: t.type,
        amount: t.amount,
        accountId: t.accountId,
        counterpartyAccountId: t.counterpartyAccountId,
        allocations: t.allocations,
        occurredAt: now,
        title: t.title,
        note: t.note,
        tags: t.tags,
        paymentMethod: t.paymentMethod,
        isReimbursable: t.isReimbursable,
      );

  final String? id;
  final TransactionType type;
  final Money amount;
  final String accountId;
  final String? counterpartyAccountId;
  final List<CategoryAllocation> allocations;
  final DateTime occurredAt;
  final String title;
  final String note;
  final List<String> tags;
  final PaymentMethod? paymentMethod;
  final bool isReimbursable;

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
  ];
}

/// User input for creating ([id] null) or editing an account.
final class AccountDraft extends Equatable {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.openingBalance,
    this.id,
    this.institution = '',
  });

  final String? id;
  final String name;
  final AccountType type;

  /// Signed like `Account.openingBalance`: negative while money is owed.
  final Money openingBalance;
  final String institution;

  @override
  List<Object?> get props => [id, name, type, openingBalance, institution];
}

/// User input for creating ([id] null) or editing a category.
final class CategoryDraft extends Equatable {
  const CategoryDraft({
    required this.name,
    required this.kind,
    required this.glyph,
    required this.tone,
    this.id,
    this.parentId,
  });

  final String? id;
  final String name;
  final CategoryKind kind;
  final String? parentId;
  final CategoryGlyph glyph;
  final CategoryTone tone;

  @override
  List<Object?> get props => [id, name, kind, parentId, glyph, tone];
}
