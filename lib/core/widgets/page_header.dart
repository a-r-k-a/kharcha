import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/theme_context.dart';
import 'pressable.dart';

/// Editorial page title with optional back key and trailing actions.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;

  /// Small label above the title.
  final String? eyebrow;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final eyebrow = this.eyebrow;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        showBack ? space.sm : space.gutter,
        space.md,
        space.sm,
        space.lg,
      ),
      child: Row(
        children: [
          if (showBack)
            Pressable(
              onPressed: () => context.pop(),
              tooltip: 'Back',
              semanticLabel: 'Back',
              child: Icon(AppIcons.back, color: colors.textPrimary),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow.toUpperCase(),
                    style: context.typeScale.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.typeScale.display.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// A 48dp icon action for headers and toolbars.
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      tooltip: label,
      semanticLabel: label,
      child: Icon(icon, color: context.colors.textPrimary),
    );
  }
}
