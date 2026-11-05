import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

abstract final class AppFonts {
  static const display = 'SpaceGrotesk';
  static const text = 'IBMPlexSans';
  static const mono = 'IBMPlexMono';
}

/// Type scale (DESIGN.md §3). Styles are colorless; widgets apply a color
/// token. Every `money*` style enables tabular figures.
@immutable
final class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.moneyHero,
    required this.moneyLarge,
    required this.moneyMedium,
    required this.moneySmall,
    required this.display,
    required this.title,
    required this.titleSmall,
    required this.body,
    required this.bodyStrong,
    required this.bodySmall,
    required this.label,
    required this.labelLarge,
  });

  factory AppTypography.standard() {
    const tabular = [FontFeature.tabularFigures()];
    return AppTypography(
      moneyHero: _style(
        AppFonts.display,
        64,
        500,
        height: 0.95,
        letterSpacing: -2.4,
        features: tabular,
      ),
      moneyLarge: _style(
        AppFonts.display,
        40,
        500,
        height: 1,
        letterSpacing: -1.2,
        features: tabular,
      ),
      moneyMedium: _style(
        AppFonts.display,
        24,
        500,
        height: 1.1,
        letterSpacing: -0.4,
        features: tabular,
      ),
      moneySmall: _style(
        AppFonts.display,
        16,
        500,
        height: 1.2,
        features: tabular,
      ),
      display: _style(
        AppFonts.display,
        34,
        600,
        height: 1.05,
        letterSpacing: -1,
      ),
      title: _style(
        AppFonts.display,
        22,
        600,
        height: 1.15,
        letterSpacing: -0.4,
      ),
      titleSmall: _style(
        AppFonts.display,
        17,
        600,
        height: 1.2,
        letterSpacing: -0.2,
      ),
      body: _style(AppFonts.text, 15, 400, height: 1.45),
      bodyStrong: _style(AppFonts.text, 15, 600, height: 1.45),
      bodySmall: _style(AppFonts.text, 13, 400, height: 1.4),
      label: _style(
        AppFonts.mono,
        11,
        500,
        height: 1.3,
        letterSpacing: 1.2,
        variable: false,
      ),
      labelLarge: _style(
        AppFonts.mono,
        13,
        500,
        height: 1.3,
        letterSpacing: 0.8,
        variable: false,
      ),
    );
  }

  final TextStyle moneyHero;
  final TextStyle moneyLarge;
  final TextStyle moneyMedium;
  final TextStyle moneySmall;
  final TextStyle display;
  final TextStyle title;
  final TextStyle titleSmall;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle labelLarge;

  /// Maps the scale onto Material's [TextTheme] so stock widgets that we
  /// still use (dialogs, text fields) inherit the right fonts.
  TextTheme toTextTheme(AppColors colors) {
    TextStyle primary(TextStyle s) => s.copyWith(color: colors.textPrimary);
    TextStyle secondary(TextStyle s) => s.copyWith(color: colors.textSecondary);
    return TextTheme(
      displayLarge: primary(moneyHero),
      displayMedium: primary(moneyLarge),
      displaySmall: primary(display),
      headlineLarge: primary(display),
      headlineMedium: primary(title),
      headlineSmall: primary(title),
      titleLarge: primary(title),
      titleMedium: primary(titleSmall),
      titleSmall: primary(bodyStrong),
      bodyLarge: primary(body),
      bodyMedium: primary(body),
      bodySmall: secondary(bodySmall),
      labelLarge: primary(labelLarge),
      labelMedium: secondary(label),
      labelSmall: secondary(label),
    );
  }

  static TextStyle _style(
    String family,
    double size,
    int weight, {
    double? height,
    double letterSpacing = 0,
    List<FontFeature> features = const [],
    bool variable = true,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      // FontWeight.values is ordered w100…w900.
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      // Variable fonts need the axis set explicitly; fontWeight alone does
      // not drive the `wght` axis on every platform.
      fontVariations: variable
          ? [FontVariation('wght', weight.toDouble())]
          : null,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? moneyHero,
    TextStyle? moneyLarge,
    TextStyle? moneyMedium,
    TextStyle? moneySmall,
    TextStyle? display,
    TextStyle? title,
    TextStyle? titleSmall,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? labelLarge,
  }) {
    return AppTypography(
      moneyHero: moneyHero ?? this.moneyHero,
      moneyLarge: moneyLarge ?? this.moneyLarge,
      moneyMedium: moneyMedium ?? this.moneyMedium,
      moneySmall: moneySmall ?? this.moneySmall,
      display: display ?? this.display,
      title: title ?? this.title,
      titleSmall: titleSmall ?? this.titleSmall,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
      labelLarge: labelLarge ?? this.labelLarge,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t) ?? b;
    return AppTypography(
      moneyHero: mix(moneyHero, other.moneyHero),
      moneyLarge: mix(moneyLarge, other.moneyLarge),
      moneyMedium: mix(moneyMedium, other.moneyMedium),
      moneySmall: mix(moneySmall, other.moneySmall),
      display: mix(display, other.display),
      title: mix(title, other.title),
      titleSmall: mix(titleSmall, other.titleSmall),
      body: mix(body, other.body),
      bodyStrong: mix(bodyStrong, other.bodyStrong),
      bodySmall: mix(bodySmall, other.bodySmall),
      label: mix(label, other.label),
      labelLarge: mix(labelLarge, other.labelLarge),
    );
  }
}
