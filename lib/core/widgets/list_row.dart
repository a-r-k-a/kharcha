import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/theme_context.dart';
import 'pressable.dart';

/// A tappable row for settings and navigation lists.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onPressed,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;

  /// Defaults to a chevron when [onPressed] is set.
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final foreground = destructive ? colors.danger : colors.textPrimary;
    final subtitle = this.subtitle;
    final icon = this.icon;
    final onPressed = this.onPressed;
    final leading = this.leading;
    final trailing =
        this.trailing ??
        (onPressed == null
            ? null
            : Icon(
                AppIcons.chevronRight,
                size: 18,
                color: colors.textTertiary,
              ));

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: space.md),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            SizedBox(width: space.md),
          ] else if (icon != null) ...[
            Icon(icon, size: 22, color: foreground),
            SizedBox(width: space.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typeScale.bodyStrong.copyWith(
                    color: foreground,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: context.typeScale.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: space.sm), trailing],
        ],
      ),
    );

    if (onPressed == null) return row;
    return Pressable(
      onPressed: onPressed,
      pressedScale: 0.99,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      child: ExcludeSemantics(child: row),
    );
  }
}
