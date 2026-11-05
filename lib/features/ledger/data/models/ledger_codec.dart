import 'dart:convert';

import '../../../../core/domain/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';

/// Thrown for a stored record that can't be read back. The store logs and
/// skips such records instead of crashing or inventing values.
final class MalformedRecord implements Exception {
  const MalformedRecord(this.field);

  final String field;

  @override
  String toString() => 'MalformedRecord($field)';
}

/// JSON (de)serialization for ledger records.
///
/// This is a persistence format: field names and enum names must not
/// change. Records carry a schema version `v` for future migrations.
/// Amounts are integer minor units; instants are UTC epoch milliseconds.
abstract final class LedgerCodec {
  static const version = 1;

  // Accounts

  static String encodeAccount(Account a) => jsonEncode({
    'v': version,
    'id': a.id,
    'name': a.name,
    'type': a.type.name,
    'opening': a.openingBalance.minorUnits,
    'currency': a.openingBalance.currency.code,
    'institution': a.institution,
    'archived': a.isArchived,
    'created': a.createdAt.millisecondsSinceEpoch,
    'updated': a.updatedAt.millisecondsSinceEpoch,
  });

  static Account decodeAccount(String source) {
    final json = _object(source);
    final currency = _currency(json, 'currency');
    return Account(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      type: _enum(AccountType.values, json, 'type'),
      openingBalance: Money(_int(json, 'opening'), currency: currency),
      institution: _optionalString(json, 'institution'),
      isArchived: _bool(json, 'archived'),
      createdAt: _instant(json, 'created'),
      updatedAt: _instant(json, 'updated'),
    );
  }

  // Categories

  static String encodeCategory(Category c) => jsonEncode({
    'v': version,
    'id': c.id,
    'name': c.name,
    'kind': c.kind.name,
    'parent': c.parentId,
    'glyph': c.glyph.name,
    'tone': c.tone.name,
    'custom': c.isCustom,
    'order': c.sortOrder,
  });

  static Category decodeCategory(String source) {
    final json = _object(source);
    return Category(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      kind: _enum(CategoryKind.values, json, 'kind'),
      parentId: _nullableString(json, 'parent'),
      // Unknown glyphs/tones (e.g. from a newer build) degrade to neutral
      // styling: purely cosmetic, so a fallback is safe here.
      glyph: _enumOr(CategoryGlyph.values, json['glyph'], CategoryGlyph.other),
      tone: _enumOr(CategoryTone.values, json['tone'], CategoryTone.neutral),
      isCustom: _bool(json, 'custom'),
      sortOrder: _int(json, 'order'),
    );
  }

  // Transactions

  static String encodeTransaction(Transaction t) => jsonEncode({
    'v': version,
    'id': t.id,
    'type': t.type.name,
    'amount': t.amount.minorUnits,
    'currency': t.amount.currency.code,
    'account': t.accountId,
    'counterparty': t.counterpartyAccountId,
    'allocations': [
      for (final a in t.allocations)
        {'category': a.categoryId, 'amount': a.amount.minorUnits},
    ],
    'at': t.occurredAt.millisecondsSinceEpoch,
    'title': t.title,
    'note': t.note,
    'tags': t.tags,
    'method': t.paymentMethod?.name,
    'reimbursable': t.isReimbursable,
    'created': t.createdAt.millisecondsSinceEpoch,
    'updated': t.updatedAt.millisecondsSinceEpoch,
  });

  static Transaction decodeTransaction(String source) {
    final json = _object(source);
    final currency = _currency(json, 'currency');
    final rawAllocations = json['allocations'];
    if (rawAllocations is! List<Object?>) {
      throw const MalformedRecord('allocations');
    }
    final rawTags = json['tags'];
    if (rawTags is! List<Object?>) throw const MalformedRecord('tags');
    final method = json['method'];

    return Transaction(
      id: _string(json, 'id'),
      type: _enum(TransactionType.values, json, 'type'),
      amount: Money(_int(json, 'amount'), currency: currency),
      accountId: _string(json, 'account'),
      counterpartyAccountId: _nullableString(json, 'counterparty'),
      allocations: [
        for (final raw in rawAllocations)
          if (raw is Map<String, Object?>)
            CategoryAllocation(
              categoryId: _string(raw, 'category'),
              amount: Money(_int(raw, 'amount'), currency: currency),
            )
          else
            throw const MalformedRecord('allocations'),
      ],
      occurredAt: _instant(json, 'at'),
      title: _optionalString(json, 'title'),
      note: _optionalString(json, 'note'),
      tags: [
        for (final tag in rawTags)
          if (tag is String) tag else throw const MalformedRecord('tags'),
      ],
      paymentMethod: method == null
          ? null
          : _enum(PaymentMethod.values, json, 'method'),
      isReimbursable: _bool(json, 'reimbursable'),
      createdAt: _instant(json, 'created'),
      updatedAt: _instant(json, 'updated'),
    );
  }

  // Field readers

  static Map<String, Object?> _object(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const MalformedRecord('json');
    }
    if (decoded is! Map<String, Object?>) throw const MalformedRecord('json');
    final v = decoded['v'];
    if (v is! int || v > version) throw const MalformedRecord('v');
    return decoded;
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw MalformedRecord(key);
  }

  /// A string field that may legitimately be empty (but must be present).
  static String _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw MalformedRecord(key);
  }

  static String? _nullableString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw MalformedRecord(key);
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw MalformedRecord(key);
  }

  static bool _bool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw MalformedRecord(key);
  }

  static DateTime _instant(Map<String, Object?> json, String key) =>
      DateTime.fromMillisecondsSinceEpoch(_int(json, key), isUtc: true);

  static Currency _currency(Map<String, Object?> json, String key) {
    final value = json[key];
    final currency = value is String ? Currency.tryParse(value) : null;
    if (currency == null) throw MalformedRecord(key);
    return currency;
  }

  static T _enum<T extends Enum>(
    List<T> values,
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    throw MalformedRecord(key);
  }

  static T _enumOr<T extends Enum>(List<T> values, Object? value, T fallback) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    return fallback;
  }
}
