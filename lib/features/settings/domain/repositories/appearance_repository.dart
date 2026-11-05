import '../../../../core/domain/result.dart';
import '../entities/appearance_settings.dart';

abstract interface class AppearanceRepository {
  /// Returns stored settings, or defaults when nothing has been stored yet.
  Future<Result<AppearanceSettings>> load();

  Future<Result<void>> save(AppearanceSettings settings);
}
