import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Role-based radii. Deliberately unequal (DESIGN.md §4).
@immutable
final class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({
    this.cardValue = 4,
    this.controlValue = 8,
    this.sheetValue = 20,
    this.actionValue = 4,
  });

  final double cardValue;
  final double controlValue;
  final double sheetValue;
  final double actionValue;

  BorderRadius get card => BorderRadius.circular(cardValue);
  BorderRadius get control => BorderRadius.circular(controlValue);
  BorderRadius get action => BorderRadius.circular(actionValue);
  BorderRadius get chip => const BorderRadius.all(Radius.circular(999));
  BorderRadius get sheet =>
      BorderRadius.vertical(top: Radius.circular(sheetValue));

  @override
  AppRadii copyWith({
    double? cardValue,
    double? controlValue,
    double? sheetValue,
    double? actionValue,
  }) {
    return AppRadii(
      cardValue: cardValue ?? this.cardValue,
      controlValue: controlValue ?? this.controlValue,
      sheetValue: sheetValue ?? this.sheetValue,
      actionValue: actionValue ?? this.actionValue,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    double mix(double a, double b) => lerpDouble(a, b, t) ?? b;
    return AppRadii(
      cardValue: mix(cardValue, other.cardValue),
      controlValue: mix(controlValue, other.controlValue),
      sheetValue: mix(sheetValue, other.sheetValue),
      actionValue: mix(actionValue, other.actionValue),
    );
  }
}
