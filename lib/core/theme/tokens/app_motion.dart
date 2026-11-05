import 'package:material_ui/material_ui.dart';

/// Motion tokens (DESIGN.md §5). Always resolve durations through
/// `context.motionDuration(...)` so reduced-motion is respected.
@immutable
final class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    this.tap = const Duration(milliseconds: 90),
    this.fast = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 240),
    this.slow = const Duration(milliseconds: 420),
    this.reveal = const Duration(milliseconds: 560),
    this.celebrate = const Duration(milliseconds: 1200),
    this.stagger = const Duration(milliseconds: 35),
    this.standard = const Cubic(0.2, 0, 0, 1),
    this.enter = const Cubic(0.05, 0.7, 0.1, 1),
    this.exit = const Cubic(0.3, 0, 0.8, 0.15),
    this.sheetSpring = const SpringDescription(
      mass: 1,
      stiffness: 520,
      damping: 38,
    ),
  });

  final Duration tap;
  final Duration fast;
  final Duration medium;
  final Duration slow;
  final Duration reveal;
  final Duration celebrate;
  final Duration stagger;

  final Curve standard;
  final Curve enter;
  final Curve exit;

  final SpringDescription sheetSpring;

  @override
  AppMotion copyWith({
    Duration? tap,
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Duration? reveal,
    Duration? celebrate,
    Duration? stagger,
    Curve? standard,
    Curve? enter,
    Curve? exit,
    SpringDescription? sheetSpring,
  }) {
    return AppMotion(
      tap: tap ?? this.tap,
      fast: fast ?? this.fast,
      medium: medium ?? this.medium,
      slow: slow ?? this.slow,
      reveal: reveal ?? this.reveal,
      celebrate: celebrate ?? this.celebrate,
      stagger: stagger ?? this.stagger,
      standard: standard ?? this.standard,
      enter: enter ?? this.enter,
      exit: exit ?? this.exit,
      sheetSpring: sheetSpring ?? this.sheetSpring,
    );
  }

  /// Motion tokens are not interpolated; the theme snaps at the midpoint.
  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    if (other is! AppMotion) return this;
    return t < 0.5 ? this : other;
  }
}
