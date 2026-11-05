import 'package:equatable/equatable.dart';

import '../../../../core/domain/money.dart';

/// How an account's balance counts toward the user's totals.
enum AccountGroup {
  /// Spendable money: bank accounts, cash and wallets.
  liquid,

  /// Locked-in or invested money.
  savingsAndInvestments,

  /// Money owed: credit cards and loans.
  credit,
}

enum AccountType {
  savings(AccountGroup.liquid),
  current(AccountGroup.liquid),
  cash(AccountGroup.liquid),
  digitalWallet(AccountGroup.liquid),
  creditCard(AccountGroup.credit),
  fixedDeposit(AccountGroup.savingsAndInvestments),
  recurringDeposit(AccountGroup.savingsAndInvestments),
  investment(AccountGroup.savingsAndInvestments),
  loan(AccountGroup.credit);

  const AccountType(this.group);

  final AccountGroup group;

  /// Liability accounts carry a negative balance while money is owed.
  bool get isLiability => group == AccountGroup.credit;
}

/// A place money is kept or owed.
///
/// Balances are signed from the user's point of view: an asset holding
/// ₹5,000 has `+5000`, a credit card with ₹5,000 outstanding has `−5000`.
/// The current balance is never stored; it is derived from
/// [openingBalance] plus the account's transactions, so it can't drift.
final class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.createdAt,
    required this.updatedAt,
    this.institution = '',
    this.isArchived = false,
  });

  final String id;
  final String name;
  final AccountType type;
  final Money openingBalance;

  /// Bank or provider name; empty when not given.
  final String institution;

  /// Archived accounts are hidden from pickers and excluded from totals but
  /// keep their history.
  final bool isArchived;

  final DateTime createdAt;
  final DateTime updatedAt;

  Account copyWith({
    String? name,
    AccountType? type,
    Money? openingBalance,
    String? institution,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      institution: institution ?? this.institution,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    openingBalance,
    institution,
    isArchived,
    createdAt,
    updatedAt,
  ];
}
