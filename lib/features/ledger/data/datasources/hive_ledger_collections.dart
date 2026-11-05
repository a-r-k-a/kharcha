import 'package:hive_ce/hive_ce.dart';

import '../../../../core/storage/cipher_key_store.dart';
import '../../../../core/storage/hive_boxes.dart';
import 'record_collection.dart';

final class HiveRecordCollection implements RecordCollection {
  const HiveRecordCollection(this._box);

  final Box<String> _box;

  @override
  Map<String, String> readAll() => {
    for (final key in _box.keys)
      if (key is String) key: ?_box.get(key),
  };

  @override
  Future<void> putAll(Map<String, String> records) => _box.putAll(records);

  @override
  Future<void> deleteAll(Iterable<String> ids) => _box.deleteAll(ids);
}

final class HiveLedgerCollections implements LedgerCollections {
  HiveLedgerCollections._(this._boxes);

  final List<Box<String>> _boxes;

  static const _names = ['accounts', 'categories', 'transactions'];

  @override
  RecordCollection get accounts => HiveRecordCollection(_boxes[0]);

  @override
  RecordCollection get categories => HiveRecordCollection(_boxes[1]);

  @override
  RecordCollection get transactions => HiveRecordCollection(_boxes[2]);

  @override
  Future<void> close() => Future.wait(_boxes.map((box) => box.close()));

  @override
  Future<void> destroy() =>
      Future.wait(_boxes.map((box) => box.deleteFromDisk()));
}

/// Opens an owner's encrypted ledger boxes.
final class HiveLedgerCollectionsOpener implements LedgerCollectionsOpener {
  const HiveLedgerCollectionsOpener(this._boxes);

  final EncryptedBoxOpener _boxes;

  @override
  Future<LedgerCollections> open(String ownerId) async {
    final boxes = <Box<String>>[];
    for (final name in HiveLedgerCollections._names) {
      boxes.add(await _boxes.open(HiveBoxes.ledger(ownerId, name)));
    }
    return HiveLedgerCollections._(boxes);
  }
}
