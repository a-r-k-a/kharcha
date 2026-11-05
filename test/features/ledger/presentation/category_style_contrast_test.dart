import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/theme/tokens/accent_palette.dart';
import 'package:kharcha/core/theme/tokens/app_colors.dart';
import 'package:kharcha/features/ledger/domain/entities/category.dart';
import 'package:kharcha/features/ledger/presentation/category_style.dart';
import 'package:material_ui/material_ui.dart';

/// Category tiles draw an ink glyph on a tone tint (see `ToneTile`). The
/// tint carries identity only; the glyph must stay readable on every tone.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  for (final brightness in Brightness.values) {
    final colors = brightness == Brightness.dark
        ? AppColors.dark(AccentPalette.volt)
        : AppColors.light(AccentPalette.volt);
    for (final tone in CategoryTone.values) {
      test('${brightness.name} / ${tone.name}: glyph on tint ≥ 4.5:1', () {
        final tint = Color.alphaBlend(
          tone.colorFrom(colors).withValues(alpha: colors.isDark ? 0.22 : 0.16),
          colors.surface,
        );
        expect(contrast(colors.textPrimary, tint), greaterThanOrEqualTo(4.5));
      });
    }

    test('${brightness.name}: the eight hues are distinct', () {
      final hues = {
        for (final tone in CategoryTone.values)
          if (tone != CategoryTone.neutral) tone.colorFrom(colors),
      };
      expect(hues, hasLength(8));
    });
  }
}
