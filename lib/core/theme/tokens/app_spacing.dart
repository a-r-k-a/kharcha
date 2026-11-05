import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// 4-based spacing scale (DESIGN.md §4).
@immutable
final class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xxs = 2,
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
    this.xxxl = 48,
    this.huge = 64,
    this.gutter = 20,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double huge;

  /// Horizontal screen padding.
  final double gutter;

  EdgeInsets get screen => EdgeInsets.symmetric(horizontal: gutter);

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    double? huge,
    double? gutter,
  }) {
    return AppSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      huge: huge ?? this.huge,
      gutter: gutter ?? this.gutter,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    double mix(double a, double b) => lerpDouble(a, b, t) ?? b;
    return AppSpacing(
      xxs: mix(xxs, other.xxs),
      xs: mix(xs, other.xs),
      sm: mix(sm, other.sm),
      md: mix(md, other.md),
      lg: mix(lg, other.lg),
      xl: mix(xl, other.xl),
      xxl: mix(xxl, other.xxl),
      xxxl: mix(xxxl, other.xxxl),
      huge: mix(huge, other.huge),
      gutter: mix(gutter, other.gutter),
    );
  }
}
