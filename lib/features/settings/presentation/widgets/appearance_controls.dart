import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/theme_reveal.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/appearance_settings.dart';
import '../appearance_mapping.dart';
import '../bloc/appearance_cubit.dart';

/// Segmented System / Light / Dark control. Switching brightness plays the
/// circular reveal from the tapped segment.
class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.select(
      (AppearanceCubit cubit) => cubit.state.settings.themePreference,
    );
    final colors = context.colors;
    final hairline = context.elevation.hairline;

    return Semantics(
      label: 'Theme',
      container: true,
      child: Container(
        padding: EdgeInsets.all(context.space.xxs),
        decoration: BoxDecoration(
          borderRadius: context.radii.control,
          border: Border.all(color: colors.lineStrong, width: hairline),
        ),
        child: Row(
          children: [
            for (final preference in ThemePreference.values)
              Expanded(
                child: _ThemeSegment(
                  preference: preference,
                  selected: preference == current,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({required this.preference, required this.selected});

  final ThemePreference preference;
  final bool selected;

  IconData get _icon => switch (preference) {
    ThemePreference.system => AppIcons.themeSystem,
    ThemePreference.light => AppIcons.themeLight,
    ThemePreference.dark => AppIcons.themeDark,
  };

  void _select(BuildContext context) {
    if (selected) return;
    final cubit = context.read<AppearanceCubit>();
    final platform = MediaQuery.platformBrightnessOf(context);
    final from = cubit.state.settings.themePreference.resolve(platform);
    void change() => unawaited(cubit.setThemePreference(preference));

    // No visible change (e.g. Dark → System while the OS is dark): skip the
    // wipe, it would reveal an identical frame.
    if (from == preference.resolve(platform)) {
      change();
      return;
    }
    unawaited(
      ThemeReveal.of(context).reveal(originContext: context, change: change),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.canvas : colors.textSecondary;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: () => _select(context),
        haptic: PressHaptic.selection,
        semanticLabel: '${preference.label} theme',
        focusRadius: context.radii.control,
        child: AnimatedContainer(
          duration: context.motionDuration(context.motion.fast),
          curve: context.motion.standard,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? colors.textPrimary : colors.surface,
            borderRadius: BorderRadius.circular(
              context.radii.controlValue - context.space.xxs,
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, size: 16, color: foreground),
                SizedBox(width: context.space.xs),
                Flexible(
                  child: Text(
                    preference.label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: context.typeScale.label.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accent swatches. Locked accents show the level that unlocks them.
class AccentPicker extends StatelessWidget {
  const AccentPicker({super.key, this.level});

  /// The user's current level, which decides what is unlocked. Null when
  /// level gating is off: every accent is available.
  final int? level;

  @override
  Widget build(BuildContext context) {
    final current = context.select(
      (AppearanceCubit cubit) => cubit.state.settings.accent,
    );
    return Wrap(
      spacing: context.space.md,
      runSpacing: context.space.md,
      children: [
        for (final accent in AccentTheme.values)
          _AccentSwatch(
            accent: accent,
            selected: accent == current,
            unlocked: switch (level) {
              final level? => accent.isUnlockedAt(level),
              null => true,
            },
          ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.unlocked,
  });

  final AccentTheme accent;
  final bool selected;
  final bool unlocked;

  static const double _size = 56;

  void _select(BuildContext context) {
    if (selected) return;
    final cubit = context.read<AppearanceCubit>();
    unawaited(
      ThemeReveal.of(context).reveal(
        originContext: context,
        change: () => unawaited(cubit.setAccent(accent)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = accent.palette;
    final elevation = context.elevation;
    final status = unlocked
        ? (selected ? 'selected' : null)
        : 'locked, unlocks at level ${accent.unlockLevel}';

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: unlocked ? () => _select(context) : null,
        haptic: PressHaptic.selection,
        semanticLabel: ['${accent.label} accent', ?status].join(', '),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: context.motionDuration(context.motion.fast),
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: unlocked
                      ? palette.fill
                      : palette.fill.withValues(alpha: 0.25),
                  borderRadius: context.radii.card,
                  border: Border.all(
                    color: selected ? colors.textPrimary : colors.line,
                    width: selected
                        ? elevation.focusRingWidth
                        : elevation.hairline,
                  ),
                ),
                child: unlocked
                    ? null
                    : Icon(AppIcons.lock, size: 18, color: colors.textPrimary),
              ),
              SizedBox(height: context.space.xs),
              Text(
                unlocked
                    ? accent.label.toUpperCase()
                    : 'LV ${accent.unlockLevel}',
                style: context.typeScale.label.copyWith(
                  color: selected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
