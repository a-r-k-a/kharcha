import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Surface treatment levels (DESIGN.md §4). No blurred shadows anywhere.
enum ElevationLevel { flat, outlined, lifted }

@immutable
final class AppElevation extends ThemeExtension<AppElevation> {
  const AppElevation({
    this.hairline = 1,
    this.liftOffset = 4,
    this.focusRingWidth = 2,
  });

  /// Border width for `outlined` and `lifted` surfaces.
  final double hairline;

  /// Vertical offset of the hard block behind `lifted` surfaces. Pressing a
  /// lifted surface translates it by this amount and collapses the block.
  final double liftOffset;

  final double focusRingWidth;

  /// Hard, unblurred offset block. [pressedFraction] goes 0 → 1 as the
  /// element sinks.
  List<BoxShadow> liftShadow(Color color, {double pressedFraction = 0}) {
    final offset = liftOffset * (1 - pressedFraction);
    if (offset <= 0) return const [];
    return [BoxShadow(color: color, offset: Offset(0, offset))];
  }

  @override
  AppElevation copyWith({
    double? hairline,
    double? liftOffset,
    double? focusRingWidth,
  }) {
    return AppElevation(
      hairline: hairline ?? this.hairline,
      liftOffset: liftOffset ?? this.liftOffset,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    );
  }

  @override
  AppElevation lerp(ThemeExtension<AppElevation>? other, double t) {
    if (other is! AppElevation) return this;
    double mix(double a, double b) => lerpDouble(a, b, t) ?? b;
    return AppElevation(
      hairline: mix(hairline, other.hairline),
      liftOffset: mix(liftOffset, other.liftOffset),
      focusRingWidth: mix(focusRingWidth, other.focusRingWidth),
    );
  }
}
