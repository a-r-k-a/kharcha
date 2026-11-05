import 'dart:developer' as developer;
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/result.dart';
import '../../domain/entities/appearance_settings.dart';
import '../../domain/repositories/appearance_repository.dart';

/// Device-local appearance store.
///
/// Values are stored as enum names, so renaming an enum value is a
/// persistence-format change. Unknown names (e.g. written by a newer build)
/// fall back to the default for that field and are logged.
final class HiveAppearanceRepository implements AppearanceRepository {
  const HiveAppearanceRepository(this._box);

  final Box<String> _box;

  static const _themeKey = 'appearance.theme';
  static const _accentKey = 'appearance.accent';

  @override
  Future<Result<AppearanceSettings>> load() => _guard('read', () async {
    const defaults = AppearanceSettings();
    return AppearanceSettings(
      themePreference: _parse(
        ThemePreference.values,
        _box.get(_themeKey),
        defaults.themePreference,
      ),
      accent: _parse(AccentTheme.values, _box.get(_accentKey), defaults.accent),
    );
  });

  @override
  Future<Result<void>> save(AppearanceSettings settings) => _guard(
    'write',
    () => _box.putAll({
      _themeKey: settings.themePreference.name,
      _accentKey: settings.accent.name,
    }),
  );

  Future<Result<T>> _guard<T>(
    String operation,
    Future<T> Function() body,
  ) async {
    try {
      return Ok(await body());
    } on HiveError catch (error, stackTrace) {
      _log(operation, error, stackTrace);
      return Err(StorageFailure(cause: error));
    } on FileSystemException catch (error, stackTrace) {
      _log(operation, error, stackTrace);
      return Err(StorageFailure(cause: error));
    }
  }

  void _log(String operation, Object error, StackTrace stackTrace) {
    developer.log(
      'Appearance $operation failed',
      name: 'settings',
      error: error,
      stackTrace: stackTrace,
    );
  }

  T _parse<T extends Enum>(List<T> values, String? stored, T fallback) {
    if (stored == null) return fallback;
    for (final value in values) {
      if (value.name == stored) return value;
    }
    developer.log('Unknown stored value "$stored"', name: 'settings');
    return fallback;
  }
}
