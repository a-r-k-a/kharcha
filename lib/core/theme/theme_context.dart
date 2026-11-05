import 'package:material_ui/material_ui.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_elevation.dart';
import 'tokens/app_motion.dart';
import 'tokens/app_radii.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_typography.dart';

/// Token accessors. Widgets read every visual value through these.
extension AppThemeContext on BuildContext {
  AppColors get colors => _extension<AppColors>();
  AppTypography get typeScale => _extension<AppTypography>();
  AppSpacing get space => _extension<AppSpacing>();
  AppRadii get radii => _extension<AppRadii>();
  AppElevation get elevation => _extension<AppElevation>();
  AppMotion get motion => _extension<AppMotion>();

  /// True when the platform asks for reduced motion.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// Resolves a motion token, collapsing to zero under reduced motion.
  Duration motionDuration(Duration duration) =>
      reduceMotion ? Duration.zero : duration;

  T _extension<T extends ThemeExtension<T>>() {
    final extension = Theme.of(this).extension<T>();
    if (extension == null) {
      throw StateError(
        '$T is missing from ThemeData.extensions. Build themes with AppTheme.of.',
      );
    }
    return extension;
  }
}
