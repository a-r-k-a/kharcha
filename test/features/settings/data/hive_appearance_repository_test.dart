import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:kharcha/core/domain/result.dart';
import 'package:kharcha/features/settings/data/repositories/hive_appearance_repository.dart';
import 'package:kharcha/features/settings/domain/entities/appearance_settings.dart';

void main() {
  late Directory directory;
  late Box<String> box;
  late HiveAppearanceRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('appearance_test');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('preferences');
    repository = HiveAppearanceRepository(box);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  AppearanceSettings loaded(Result<AppearanceSettings> result) =>
      switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => fail('Expected Ok, got $failure'),
      };

  test('returns defaults when nothing is stored', () async {
    expect(loaded(await repository.load()), const AppearanceSettings());
  });

  test('round-trips saved settings', () async {
    const settings = AppearanceSettings(
      themePreference: ThemePreference.system,
      accent: AccentTheme.platinum,
    );
    expect(await repository.save(settings), isA<Ok<void>>());
    expect(loaded(await repository.load()), settings);
  });

  test('falls back per field for unknown stored values', () async {
    await box.putAll({
      'appearance.theme': 'sepia',
      'appearance.accent': 'glacier',
    });
    expect(
      loaded(await repository.load()),
      const AppearanceSettings(accent: AccentTheme.glacier),
    );
  });
}
