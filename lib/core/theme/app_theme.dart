import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

import 'tokens/accent_palette.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_elevation.dart';
import 'tokens/app_motion.dart';
import 'tokens/app_radii.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_typography.dart';

/// Builds [ThemeData] from design tokens. Stock Material components are
/// restyled so anything we don't replace still matches DESIGN.md.
abstract final class AppTheme {
  static final Map<(Brightness, String), ThemeData> _cache = {};

  /// Themes are memoized: there are only 2 × 4 combinations and building one
  /// is not free, so `MaterialApp` rebuilds stay cheap.
  static ThemeData of(Brightness brightness, AccentPalette accent) {
    return _cache.putIfAbsent((
      brightness,
      accent.id,
    ), () => _build(brightness, accent));
  }

  static ThemeData _build(Brightness brightness, AccentPalette accent) {
    final colors = brightness == Brightness.dark
        ? AppColors.dark(accent)
        : AppColors.light(accent);
    final type = AppTypography.standard();
    const radii = AppRadii();
    const elevation = AppElevation();
    const space = AppSpacing();
    const motion = AppMotion();

    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.actionFill,
      onPrimary: colors.onActionFill,
      secondary: colors.accentStrong,
      onSecondary: colors.canvas,
      tertiary: colors.accent,
      onTertiary: colors.onAccent,
      error: colors.danger,
      onError: colors.onDanger,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      surfaceContainerLowest: colors.canvas,
      surfaceContainerLow: colors.canvas,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surfaceRaised,
      surfaceContainerHighest: colors.surfaceRaised,
      outline: colors.lineStrong,
      outlineVariant: colors.line,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.canvas,
      inversePrimary: colors.accent,
      shadow: Colors.transparent,
      scrim: colors.scrim,
      surfaceTint: Colors.transparent,
    );

    final textTheme = type.toTextTheme(colors);
    final hairline = BorderSide(color: colors.line, width: elevation.hairline);
    final strongHairline = BorderSide(
      color: colors.lineStrong,
      width: elevation.hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      fontFamily: AppFonts.text,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: colors.textPrimary.withValues(alpha: 0.04),
      focusColor: colors.accentStrong.withValues(alpha: 0.12),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [colors, type, space, radii, elevation, motion],
      iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: elevation.hairline,
        space: elevation.hairline,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.canvas,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: type.titleSmall.copyWith(color: colors.textPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: colors.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: radii.sheet,
          side: hairline,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radii.card,
          side: strongHairline,
        ),
        titleTextStyle: type.title.copyWith(color: colors.textPrimary),
        contentTextStyle: type.body.copyWith(color: colors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceRaised,
        contentTextStyle: type.body.copyWith(color: colors.textPrimary),
        actionTextColor: colors.accentStrong,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radii.card,
          side: strongHairline,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surfaceRaised,
        contentPadding: EdgeInsets.symmetric(
          horizontal: space.lg,
          vertical: space.md,
        ),
        labelStyle: type.label.copyWith(color: colors.textSecondary),
        floatingLabelStyle: type.label.copyWith(color: colors.accentStrong),
        hintStyle: type.body.copyWith(color: colors.textTertiary),
        helperStyle: type.bodySmall.copyWith(color: colors.textSecondary),
        errorStyle: type.bodySmall.copyWith(color: colors.danger),
        border: OutlineInputBorder(
          borderRadius: radii.control,
          borderSide: strongHairline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radii.control,
          borderSide: strongHairline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radii.control,
          borderSide: BorderSide(
            color: colors.accentStrong,
            width: elevation.focusRingWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radii.control,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radii.control,
          borderSide: BorderSide(
            color: colors.danger,
            width: elevation.focusRingWidth,
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accentStrong,
        selectionColor: colors.accent.withValues(alpha: 0.35),
        selectionHandleColor: colors.accentStrong,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onAccent
              : colors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.surfaceRaised,
        ),
        trackOutlineColor: WidgetStatePropertyAll(colors.lineStrong),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colors.onAccent),
        side: strongHairline,
        shape: RoundedRectangleBorder(borderRadius: radii.card),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accentStrong,
        inactiveTrackColor: colors.line,
        thumbColor: colors.accentStrong,
        overlayColor: colors.accentStrong.withValues(alpha: 0.12),
        valueIndicatorColor: colors.surfaceRaised,
        valueIndicatorTextStyle: type.labelLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: radii.card,
        ),
        textStyle: type.label.copyWith(color: colors.canvas),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accentStrong,
        linearTrackColor: colors.line,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
