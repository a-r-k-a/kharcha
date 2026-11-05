import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

enum PressHaptic { none, selection, light, medium, heavy }

typedef PressableBuilder = Widget Function(BuildContext context, bool pressed);

/// The single tappable primitive: press-scale, haptics, keyboard activation,
/// focus ring, semantics and a 48dp minimum hit area.
///
/// Under reduced motion the scale is replaced by an opacity dip.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onPressed,
    required Widget this._child,
    this.onLongPress,
    this.semanticLabel,
    this.tooltip,
    this.haptic = PressHaptic.light,
    this.pressedScale = 0.97,
    this.minSize = 48,
    this.focusRadius,
  }) : _builder = null;

  /// Variant that exposes the pressed state, for widgets that animate
  /// something other than scale (e.g. the lifted sink in `AppButton`).
  const Pressable.builder({
    super.key,
    required this.onPressed,
    required PressableBuilder this._builder,
    this.onLongPress,
    this.semanticLabel,
    this.tooltip,
    this.haptic = PressHaptic.light,
    this.pressedScale = 1,
    this.minSize = 48,
    this.focusRadius,
  }) : _child = null;

  /// Null disables the control.
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? tooltip;
  final PressHaptic haptic;
  final double pressedScale;
  final double minSize;
  final BorderRadius? focusRadius;

  final Widget? _child;
  final PressableBuilder? _builder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _activate() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    _playHaptic();
    onPressed();
  }

  void _playHaptic() {
    final feedback = switch (widget.haptic) {
      PressHaptic.none => null,
      PressHaptic.selection => HapticFeedback.selectionClick(),
      PressHaptic.light => HapticFeedback.lightImpact(),
      PressHaptic.medium => HapticFeedback.mediumImpact(),
      PressHaptic.heavy => HapticFeedback.heavyImpact(),
    };
    if (feedback != null) unawaited(feedback);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final content = switch (widget._builder) {
      final builder? => builder(context, _pressed),
      null => widget._child ?? const SizedBox.shrink(),
    };

    Widget result = context.reduceMotion
        ? Opacity(opacity: _pressed ? 0.72 : 1, child: content)
        : AnimatedScale(
            scale: _pressed ? widget.pressedScale : 1,
            duration: motion.tap,
            curve: motion.standard,
            child: content,
          );

    if (_focused) {
      result = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.focusRadius ?? context.radii.card,
          border: Border.all(
            color: context.colors.accentStrong,
            width: context.elevation.focusRingWidth,
          ),
        ),
        child: result,
      );
    }

    result = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: _enabled ? _activate : null,
          onLongPress: widget.onLongPress,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.minSize,
              minHeight: widget.minSize,
            ),
            child: result,
          ),
        ),
      ),
    );

    final tooltip = widget.tooltip;
    return tooltip == null ? result : Tooltip(message: tooltip, child: result);
  }
}
