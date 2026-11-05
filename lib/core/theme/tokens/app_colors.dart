import 'package:material_ui/material_ui.dart';

import 'accent_palette.dart';

/// Color tokens. Values and rationale: DESIGN.md §2.
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.lineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentStrong,
    required this.actionFill,
    required this.onActionFill,
    required this.actionLift,
    required this.watch,
    required this.warning,
    required this.danger,
    required this.onDanger,
    required this.scrim,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  factory AppColors.dark(AccentPalette accent) {
    const canvas = Color(0xFF0A0A0B);
    return AppColors(
      brightness: Brightness.dark,
      canvas: canvas,
      surface: const Color(0xFF131315),
      surfaceRaised: const Color(0xFF1B1B1E),
      line: const Color(0xFF26262A),
      lineStrong: const Color(0xFF6B6B73),
      textPrimary: const Color(0xFFF4F3EE),
      textSecondary: const Color(0xFFA8A7A0),
      textTertiary: const Color(0xFF8C8B85),
      accent: accent.fill,
      onAccent: accent.onFill,
      accentStrong: accent.strongOnDark,
      actionFill: accent.fill,
      onActionFill: accent.onFill,
      actionLift: Color.alphaBlend(accent.fill.withValues(alpha: 0.28), canvas),
      watch: const Color(0xFFFFD37A),
      warning: const Color(0xFFFF9F2E),
      danger: const Color(0xFFFF5A4E),
      onDanger: canvas,
      scrim: const Color(0xCC000000),
      skeletonBase: const Color(0xFF1B1B1E),
      skeletonHighlight: const Color(0xFF2A2A2F),
    );
  }

  factory AppColors.light(AccentPalette accent) {
    const ink = Color(0xFF0B0B0C);
    return AppColors(
      brightness: Brightness.light,
      canvas: const Color(0xFFF2F0EA),
      surface: const Color(0xFFFAF9F5),
      surfaceRaised: const Color(0xFFFFFFFF),
      line: const Color(0xFFDDDAD2),
      lineStrong: const Color(0xFF86827A),
      textPrimary: ink,
      textSecondary: const Color(0xFF55534D),
      textTertiary: const Color(0xFF6A6862),
      accent: accent.fill,
      onAccent: accent.onFill,
      accentStrong: accent.strongOnLight,
      // Primary actions invert in light mode: ink key, accent label.
      actionFill: ink,
      onActionFill: accent.onInk,
      actionLift: accent.liftOnLight,
      watch: const Color(0xFF7D5A00),
      warning: const Color(0xFFA34700),
      danger: const Color(0xFFC2261B),
      onDanger: const Color(0xFFFFFFFF),
      scrim: const Color(0x99000000),
      skeletonBase: const Color(0xFFE7E4DC),
      skeletonHighlight: const Color(0xFFF6F4EE),
    );
  }

  final Brightness brightness;

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;

  /// Decorative hairlines. Not for borders that identify a control.
  final Color line;

  /// Borders that identify interactive controls (≥ 3:1).
  final Color lineStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Large accent areas; always pair with [onAccent].
  final Color accent;
  final Color onAccent;

  /// Accent used directly as text or stroke on surfaces (≥ 4.5:1).
  final Color accentStrong;

  /// Primary button fill and label.
  final Color actionFill;
  final Color onActionFill;

  /// Hard offset block behind lifted primary actions.
  final Color actionLift;

  /// Budget tones (DESIGN.md §2.3). `calm` is [accentStrong].
  final Color watch;
  final Color warning;
  final Color danger;
  final Color onDanger;

  final Color scrim;
  final Color skeletonBase;
  final Color skeletonHighlight;

  bool get isDark => brightness == Brightness.dark;

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? lineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? accentStrong,
    Color? actionFill,
    Color? onActionFill,
    Color? actionLift,
    Color? watch,
    Color? warning,
    Color? danger,
    Color? onDanger,
    Color? scrim,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentStrong: accentStrong ?? this.accentStrong,
      actionFill: actionFill ?? this.actionFill,
      onActionFill: onActionFill ?? this.onActionFill,
      actionLift: actionLift ?? this.actionLift,
      watch: watch ?? this.watch,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      scrim: scrim ?? this.scrim,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      line: mix(line, other.line),
      lineStrong: mix(lineStrong, other.lineStrong),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentStrong: mix(accentStrong, other.accentStrong),
      actionFill: mix(actionFill, other.actionFill),
      onActionFill: mix(onActionFill, other.onActionFill),
      actionLift: mix(actionLift, other.actionLift),
      watch: mix(watch, other.watch),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      onDanger: mix(onDanger, other.onDanger),
      scrim: mix(scrim, other.scrim),
      skeletonBase: mix(skeletonBase, other.skeletonBase),
      skeletonHighlight: mix(skeletonHighlight, other.skeletonHighlight),
    );
  }
}
