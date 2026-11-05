import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/theme/tokens/accent_palette.dart';
import 'package:kharcha/core/theme/tokens/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Enforces DESIGN.md §7: text ≥ 4.5:1, interactive borders ≥ 3:1, for every
/// brightness × accent combination.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  for (final palette in AccentPalette.all) {
    for (final brightness in Brightness.values) {
      final colors = brightness == Brightness.dark
          ? AppColors.dark(palette)
          : AppColors.light(palette);
      final surfaces = {
        'canvas': colors.canvas,
        'surface': colors.surface,
        'surfaceRaised': colors.surfaceRaised,
      };

      group('${palette.id} / ${brightness.name}', () {
        final textTokens = {
          'textPrimary': colors.textPrimary,
          'textSecondary': colors.textSecondary,
          'textTertiary': colors.textTertiary,
          'accentStrong': colors.accentStrong,
          'watch': colors.watch,
          'warning': colors.warning,
          'danger': colors.danger,
        };

        for (final MapEntry(key: textName, value: text) in textTokens.entries) {
          for (final MapEntry(key: surfaceName, value: surface)
              in surfaces.entries) {
            test('$textName on $surfaceName ≥ 4.5', () {
              expect(contrast(text, surface), greaterThanOrEqualTo(4.5));
            });
          }
        }

        for (final MapEntry(key: surfaceName, value: surface)
            in surfaces.entries) {
          test('lineStrong on $surfaceName ≥ 3', () {
            expect(
              contrast(colors.lineStrong, surface),
              greaterThanOrEqualTo(3),
            );
          });
        }

        test('content on fills ≥ 4.5', () {
          expect(
            contrast(colors.onAccent, colors.accent),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(colors.onActionFill, colors.actionFill),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(colors.onDanger, colors.danger),
            greaterThanOrEqualTo(4.5),
          );
          // Inverted cards put canvas-colored text on textPrimary.
          expect(
            contrast(colors.canvas, colors.textPrimary),
            greaterThanOrEqualTo(4.5),
          );
        });
      });
    }
  }
}
