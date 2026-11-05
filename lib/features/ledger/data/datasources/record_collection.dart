/// A keyed collection of serialized records: the only storage operations
/// the ledger needs, so the store can run on Hive or in memory.
abstract interface class RecordCollection {
  /// Every stored record, keyed by id.
  Map<String, String> readAll();

  /// Writes all [records] in one batch.
  Future<void> putAll(Map<String, String> records);

  Future<void> deleteAll(Iterable<String> ids);
}

/// The three collections that make up one owner's books.
abstract interface class LedgerCollections {
  RecordCollection get accounts;
  RecordCollection get categories;
  RecordCollection get transactions;

  Future<void> close();

  /// Closes and permanently removes the collections.
  Future<void> destroy();
}

abstract interface class LedgerCollectionsOpener {
  Future<LedgerCollections> open(String ownerId);
}
