import 'package:material_ui/material_ui.dart';

import '../../../core/theme/tokens/accent_palette.dart';
import '../domain/entities/appearance_settings.dart';

extension ThemePreferenceMapping on ThemePreference {
  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  Brightness resolve(Brightness platformBrightness) => switch (this) {
    ThemePreference.system => platformBrightness,
    ThemePreference.light => Brightness.light,
    ThemePreference.dark => Brightness.dark,
  };

  String get label => switch (this) {
    ThemePreference.system => 'System',
    ThemePreference.light => 'Light',
    ThemePreference.dark => 'Dark',
  };
}

extension AccentThemeMapping on AccentTheme {
  AccentPalette get palette => switch (this) {
    AccentTheme.volt => AccentPalette.volt,
    AccentTheme.glacier => AccentPalette.glacier,
    AccentTheme.platinum => AccentPalette.platinum,
    AccentTheme.flamingo => AccentPalette.flamingo,
  };

  String get label => switch (this) {
    AccentTheme.volt => 'Volt',
    AccentTheme.glacier => 'Glacier',
    AccentTheme.platinum => 'Platinum',
    AccentTheme.flamingo => 'Flamingo',
  };
}
