import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/core/domain/result.dart';
import 'package:kharcha/core/storage/cipher_key_store.dart';
import 'package:kharcha/core/storage/hive_boxes.dart';
import 'package:kharcha/features/ledger/data/datasources/hive_ledger_collections.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/profile/data/repositories/hive_profile_repository.dart';
import 'package:kharcha/features/profile/domain/entities/user_profile.dart';

import '../../../helpers/in_memory_ledger.dart';
import '../../../helpers/test_app.dart';

final class _MemoryKeys implements CipherKeyStore {
  final Map<String, List<int>> keys = {};

  @override
  Future<List<int>> loadOrCreate(String name) async =>
      keys.putIfAbsent(name, Hive.generateSecureKey);

  @override
  Future<void> delete(String name) async => keys.remove(name);
}

void main() {
  late Directory directory;
  late _MemoryKeys keys;
  late EncryptedBoxOpener boxes;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kharcha_hive_test');
    Hive.init(directory.path);
    keys = _MemoryKeys();
    boxes = EncryptedBoxOpener(keys);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('ledger survives a restart in encrypted per-owner boxes', () async {
    final first = LedgerStore(HiveLedgerCollectionsOpener(boxes));
    await first.open(ownerId: 'device', currency: Currency.inr);
    await first.saveAccount(testAccount('bank', opening: 750.25));
    await first.saveTransaction(
      testExpense('t', amount: 50, at: DateTime.utc(2026, 11, 4)),
    );
    await first.dispose();

    final second = LedgerStore(HiveLedgerCollectionsOpener(boxes));
    await second.open(ownerId: 'device', currency: Currency.inr);
    expect(second.current?.balanceOf('bank'), inr(700.25));
    expect(second.current?.transactions.single.id, 't');
    await second.dispose();
  });

  test('records are unreadable without the key', () async {
    final store = LedgerStore(HiveLedgerCollectionsOpener(boxes));
    await store.open(ownerId: 'device', currency: Currency.inr);
    await store.saveAccount(testAccount('bank', name: 'Secret Savings'));
    await store.dispose();

    final raw = await File(
      '${directory.path}/${HiveBoxes.ledger('device', 'accounts')}.hive',
    ).readAsBytes();
    expect(String.fromCharCodes(raw).contains('Secret Savings'), isFalse);
  });

  test('erasing removes the owner\'s boxes from disk', () async {
    final store = LedgerStore(HiveLedgerCollectionsOpener(boxes));
    await store.open(ownerId: 'device', currency: Currency.inr);
    await store.saveAccount(testAccount('bank'));
    expect(await store.eraseAll(), isA<Ok<void>>());
    expect(
      await Hive.boxExists(HiveBoxes.ledger('device', 'accounts')),
      isFalse,
    );
    await store.dispose();
  });

  group('profile', () {
    HiveProfileRepository repository() =>
        HiveProfileRepository(() => boxes.open(HiveBoxes.profile));

    UserProfile? loaded(Result<UserProfile?> result) => switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('Expected Ok, got $failure'),
    };

    test('is null before setup, then round-trips', () async {
      final repo = repository();
      expect(loaded(await repo.load()), isNull);
      expect(await repo.save(testProfile), isA<Ok<void>>());
      expect(loaded(await repository().load()), testProfile);
      expect(await repo.clear(), isA<Ok<void>>());
      expect(loaded(await repo.load()), isNull);
    });

    test('a corrupt record is a failure, not a missing profile', () async {
      final box = await boxes.open(HiveBoxes.profile);
      await box.put('profile', '{"v":1,"owner":""}');
      expect(await repository().load(), isA<Err<UserProfile?>>());
    });

    test('an opening failure is reported and can be retried', () async {
      var attempts = 0;
      final repo = HiveProfileRepository(() async {
        attempts++;
        if (attempts == 1) throw HiveError('locked');
        return boxes.open(HiveBoxes.profile);
      });
      expect(await repo.load(), isA<Err<UserProfile?>>());
      expect(await repo.load(), isA<Ok<UserProfile?>>());
    });
  });
}
