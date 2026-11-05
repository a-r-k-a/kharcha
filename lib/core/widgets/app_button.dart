import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import 'pressable.dart';

enum AppButtonVariant {
  /// Lifted: hard offset block, sinks on press. One per screen.
  primary,

  /// Outlined with a strong hairline.
  secondary,

  /// Text only, for tertiary actions.
  ghost,

  /// Outlined in the danger tone, for destructive actions.
  danger,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  /// Sentence-case label; rendered uppercase, announced as written.
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Fill the available width.
  final bool expand;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevation = context.elevation;
    final lifted = variant == AppButtonVariant.primary;
    final enabled = onPressed != null && !isLoading;
    final disabled = onPressed == null && !isLoading;

    final (
      Color background,
      Color foreground,
      Color? border,
    ) = switch (variant) {
      _ when disabled => (
        colors.surfaceRaised,
        colors.textTertiary,
        colors.line,
      ),
      AppButtonVariant.primary => (
        colors.actionFill,
        colors.onActionFill,
        null,
      ),
      AppButtonVariant.secondary => (
        Colors.transparent,
        colors.textPrimary,
        colors.lineStrong,
      ),
      AppButtonVariant.ghost => (Colors.transparent, colors.accentStrong, null),
      AppButtonVariant.danger => (
        Colors.transparent,
        colors.danger,
        colors.danger,
      ),
    };

    final button = Pressable.builder(
      onPressed: enabled ? onPressed : null,
      haptic: lifted ? PressHaptic.medium : PressHaptic.light,
      pressedScale: lifted ? 1 : 0.97,
      focusRadius: context.radii.action,
      semanticLabel: isLoading ? '$label, in progress' : label,
      builder: (context, pressed) {
        final sink = lifted && pressed && !context.reduceMotion ? 1.0 : 0.0;
        return AnimatedContainer(
          duration: context.motion.tap,
          curve: context.motion.standard,
          height: _height,
          transform: Matrix4.translationValues(
            0,
            elevation.liftOffset * sink,
            0,
          ),
          padding: EdgeInsets.symmetric(horizontal: context.space.xl),
          decoration: BoxDecoration(
            color: background,
            borderRadius: context.radii.action,
            border: border == null
                ? null
                : Border.all(color: border, width: elevation.hairline),
            boxShadow: lifted && !disabled
                ? elevation.liftShadow(colors.actionLift, pressedFraction: sink)
                : null,
          ),
          // The label may shrink (ellipsis) whenever width is bounded, so
          // long labels and large text sizes never overflow. Under unbounded
          // width a loose Flexible in a min-size Row just hugs its content.
          // No LayoutBuilder here: dialogs measure actions via IntrinsicWidth,
          // which LayoutBuilder can't answer.
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: isLoading
                  ? [_LoadingTicks(color: foreground)]
                  : [
                      if (icon case final icon?) ...[
                        Icon(icon, size: 18, color: foreground),
                        SizedBox(width: context.space.sm),
                      ],
                      Flexible(child: _label(context, foreground)),
                    ],
            ),
          ),
        );
      },
    );

    // Reserve room for the offset block so it never overlaps neighbours.
    return Padding(
      padding: EdgeInsets.only(bottom: lifted ? elevation.liftOffset : 0),
      child: button,
    );
  }

  Widget _label(BuildContext context, Color color) => Text(
    label.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: context.typeScale.labelLarge.copyWith(color: color),
  );
}

/// Three square ticks lighting in sequence. Static under reduced motion.
class _LoadingTicks extends StatefulWidget {
  const _LoadingTicks({required this.color});

  final Color color;

  @override
  State<_LoadingTicks> createState() => _LoadingTicksState();
}

class _LoadingTicksState extends State<_LoadingTicks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.space.xs;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final active = (_controller.value * 3).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gap / 2),
                child: SizedBox.square(
                  dimension: 6,
                  child: ColoredBox(
                    color: widget.color.withValues(
                      alpha: context.reduceMotion || i == active ? 1 : 0.3,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
