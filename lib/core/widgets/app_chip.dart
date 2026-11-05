import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import 'pressable.dart';

/// Pill-shaped selectable chip in mono caps. Selected chips invert to ink.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.icon,
    this.leading,
    this.trailingIcon,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final IconData? icon;

  /// Custom leading widget; takes precedence over [icon].
  final Widget? leading;
  final IconData? trailingIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final foreground = selected ? colors.canvas : colors.textPrimary;
    final leading = this.leading;
    final icon = this.icon;
    final trailingIcon = this.trailingIcon;

    return Semantics(
      selected: selected,
      child: Pressable(
        onPressed: onPressed,
        haptic: PressHaptic.selection,
        semanticLabel: semanticLabel ?? label,
        focusRadius: context.radii.chip,
        minSize: 44,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: context.motionDuration(context.motion.fast),
            curve: context.motion.standard,
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: space.md),
            decoration: BoxDecoration(
              color: selected ? colors.textPrimary : colors.surface,
              borderRadius: context.radii.chip,
              border: Border.all(
                color: selected ? colors.textPrimary : colors.lineStrong,
                width: context.elevation.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading,
                  SizedBox(width: space.xs),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  SizedBox(width: space.xs),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typeScale.label.copyWith(color: foreground),
                  ),
                ),
                if (trailingIcon != null) ...[
                  SizedBox(width: space.xs),
                  Icon(trailingIcon, size: 14, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
