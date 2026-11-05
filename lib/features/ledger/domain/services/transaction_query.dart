import 'package:equatable/equatable.dart';

import '../../../../core/domain/date_range.dart';
import '../entities/ledger.dart';
import '../entities/transaction.dart';

/// Filters for the activity list. Empty sets mean "any".
final class TransactionQuery extends Equatable {
  const TransactionQuery({
    this.text = '',
    this.types = const {},
    this.categoryIds = const {},
    this.accountIds = const {},
    this.range,
  });

  /// Matched case-insensitively against title, note, tags, category and
  /// account names, and the whole-unit amount.
  final String text;
  final Set<TransactionType> types;

  /// Matches a transaction when any allocation is in, or rolls up to, one
  /// of these categories.
  final Set<String> categoryIds;

  /// Matches either side of a transfer.
  final Set<String> accountIds;
  final DateRange? range;

  bool get isEmpty =>
      text.trim().isEmpty &&
      types.isEmpty &&
      categoryIds.isEmpty &&
      accountIds.isEmpty &&
      range == null;

  /// Number of active filters, excluding the search text.
  int get filterCount =>
      (types.isEmpty ? 0 : 1) +
      (categoryIds.isEmpty ? 0 : 1) +
      (accountIds.isEmpty ? 0 : 1) +
      (range == null ? 0 : 1);

  TransactionQuery copyWith({
    String? text,
    Set<TransactionType>? types,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    DateRange? Function()? range,
  }) {
    return TransactionQuery(
      text: text ?? this.text,
      types: types ?? this.types,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      range: range != null ? range() : this.range,
    );
  }

  /// Matching transactions, newest first.
  List<Transaction> apply(Ledger ledger) {
    if (isEmpty) return ledger.transactions;
    final needle = text.trim().toLowerCase();
    return ledger.transactions
        .where((t) => _matches(ledger, t, needle))
        .toList();
  }

  bool _matches(Ledger ledger, Transaction t, String needle) {
    final range = this.range;
    if (range != null && !range.contains(t.occurredAt)) return false;
    if (types.isNotEmpty && !types.contains(t.type)) return false;
    if (accountIds.isNotEmpty &&
        !accountIds.contains(t.accountId) &&
        !accountIds.contains(t.counterpartyAccountId)) {
      return false;
    }
    if (categoryIds.isNotEmpty &&
        !t.allocations.any(
          (a) =>
              categoryIds.contains(a.categoryId) ||
              categoryIds.contains(ledger.topLevelCategoryOf(a.categoryId)?.id),
        )) {
      return false;
    }
    if (needle.isEmpty) return true;
    return _haystack(ledger, t).any((field) => field.contains(needle));
  }

  Iterable<String> _haystack(Ledger ledger, Transaction t) sync* {
    yield t.title.toLowerCase();
    yield t.note.toLowerCase();
    for (final tag in t.tags) {
      yield tag.toLowerCase();
    }
    for (final allocation in t.allocations) {
      final category = ledger.categoryById(allocation.categoryId);
      if (category != null) yield category.name.toLowerCase();
    }
    for (final id in [t.accountId, ?t.counterpartyAccountId]) {
      final account = ledger.accountById(id);
      if (account != null) yield account.name.toLowerCase();
    }
    yield (t.amount.abs().minorUnits ~/ t.amount.currency.minorPerMajor)
        .toString();
  }

  @override
  List<Object?> get props => [text, types, categoryIds, accountIds, range];
}
