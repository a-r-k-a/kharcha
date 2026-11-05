import '../../../../core/domain/result.dart';
import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  /// The stored profile, or `Ok(null)` before first-run setup.
  Future<Result<UserProfile?>> load();

  Future<Result<void>> save(UserProfile profile);

  Future<Result<void>> clear();
}
