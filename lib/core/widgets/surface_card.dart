import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import '../theme/tokens/app_elevation.dart';
import 'pressable.dart';

enum SurfaceTone {
  surface,
  raised,

  /// Accent fill. Children must use `onAccent` colors.
  accent,

  /// Text-primary fill; the "negative print" used for hero moments.
  inverted,
}

/// The base container for grouped content. Pass [onPressed] to make it
/// tappable; lifted cards then sink into their offset block.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.level = ElevationLevel.outlined,
    this.tone = SurfaceTone.surface,
    this.padding,
    this.onPressed,
    this.semanticLabel,
  });

  final Widget child;
  final ElevationLevel level;
  final SurfaceTone tone;

  /// Defaults to `space.lg`.
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevation = context.elevation;
    final lifted = level == ElevationLevel.lifted;

    final background = switch (tone) {
      SurfaceTone.surface => colors.surface,
      SurfaceTone.raised => colors.surfaceRaised,
      SurfaceTone.accent => colors.accent,
      SurfaceTone.inverted => colors.textPrimary,
    };
    final borderColor = switch (level) {
      ElevationLevel.flat => null,
      ElevationLevel.outlined => colors.line,
      ElevationLevel.lifted => colors.lineStrong,
    };

    Widget card(double sink) => AnimatedContainer(
      duration: context.motion.tap,
      curve: context.motion.standard,
      transform: Matrix4.translationValues(0, elevation.liftOffset * sink, 0),
      padding: padding ?? EdgeInsets.all(context.space.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: context.radii.card,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: elevation.hairline),
        boxShadow: lifted
            ? elevation.liftShadow(colors.line, pressedFraction: sink)
            : null,
      ),
      child: child,
    );

    final onPressed = this.onPressed;
    final Widget content = onPressed == null
        ? Semantics(container: true, label: semanticLabel, child: card(0))
        : Pressable.builder(
            onPressed: onPressed,
            semanticLabel: semanticLabel,
            pressedScale: lifted ? 1 : 0.985,
            builder: (context, pressed) =>
                card(lifted && pressed && !context.reduceMotion ? 1 : 0),
          );

    return Padding(
      padding: EdgeInsets.only(bottom: lifted ? elevation.liftOffset : 0),
      child: content,
    );
  }
}
