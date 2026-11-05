import 'package:equatable/equatable.dart';

enum ThemePreference { system, light, dark }

/// Accent themes. Everything beyond the default is unlocked through
/// gamification levels.
enum AccentTheme {
  volt(unlockLevel: 1),
  glacier(unlockLevel: 5),
  platinum(unlockLevel: 10),
  flamingo(unlockLevel: 20);

  const AccentTheme({required this.unlockLevel});

  final int unlockLevel;

  bool isUnlockedAt(int level) => level >= unlockLevel;
}

final class AppearanceSettings extends Equatable {
  const AppearanceSettings({
    this.themePreference = ThemePreference.dark,
    this.accent = AccentTheme.volt,
  });

  /// Dark is the flagship look, so it is the default rather than `system`.
  final ThemePreference themePreference;
  final AccentTheme accent;

  AppearanceSettings copyWith({
    ThemePreference? themePreference,
    AccentTheme? accent,
  }) {
    return AppearanceSettings(
      themePreference: themePreference ?? this.themePreference,
      accent: accent ?? this.accent,
    );
  }

  @override
  List<Object?> get props => [themePreference, accent];
}
