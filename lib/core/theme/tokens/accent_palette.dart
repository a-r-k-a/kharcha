import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// One accent hue expressed for both brightness modes.
///
/// See DESIGN.md §2.2: [fill] is for large areas and always carries [onFill]
/// content; the `strong*` variants are for text/strokes directly on a surface
/// and are guaranteed ≥ 4.5:1 against that mode's surfaces.
@immutable
final class AccentPalette {
  const AccentPalette({
    required this.id,
    required this.fill,
    required this.onFill,
    required this.strongOnDark,
    required this.strongOnLight,
    required this.liftOnLight,
    required this.onInk,
  });

  /// Stable identifier; matches the persisted accent name.
  final String id;
  final Color fill;
  final Color onFill;
  final Color strongOnDark;
  final Color strongOnLight;

  /// Offset-block color behind ink primary buttons in light mode.
  final Color liftOnLight;

  /// Label color on the ink primary button in light mode.
  final Color onInk;

  static const volt = AccentPalette(
    id: 'volt',
    fill: Color(0xFFD7FF3A),
    onFill: Color(0xFF0A0A0B),
    strongOnDark: Color(0xFFD7FF3A),
    strongOnLight: Color(0xFF4A6600),
    liftOnLight: Color(0xFFD7FF3A),
    onInk: Color(0xFFD7FF3A),
  );

  static const glacier = AccentPalette(
    id: 'glacier',
    fill: Color(0xFF6FE3FF),
    onFill: Color(0xFF0A0A0B),
    strongOnDark: Color(0xFF6FE3FF),
    strongOnLight: Color(0xFF00708A),
    liftOnLight: Color(0xFF6FE3FF),
    onInk: Color(0xFF6FE3FF),
  );

  static const platinum = AccentPalette(
    id: 'platinum',
    fill: Color(0xFFEDEDED),
    onFill: Color(0xFF0A0A0B),
    strongOnDark: Color(0xFFEDEDED),
    strongOnLight: Color(0xFF1A1A1A),
    liftOnLight: Color(0xFFB9B6AC),
    onInk: Color(0xFFF4F3EE),
  );

  static const flamingo = AccentPalette(
    id: 'flamingo',
    fill: Color(0xFFFF8FD1),
    onFill: Color(0xFF0A0A0B),
    strongOnDark: Color(0xFFFF8FD1),
    strongOnLight: Color(0xFFB0246F),
    liftOnLight: Color(0xFFFF8FD1),
    onInk: Color(0xFFFF8FD1),
  );

  static const all = [volt, glacier, platinum, flamingo];

  @override
  bool operator ==(Object other) => other is AccentPalette && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
