import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/theme_context.dart';
import 'app_button.dart';

/// Left-aligned, editorial empty state. Every list screen designs its own
/// copy; this widget only fixes the layout.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.empty,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;

  /// Usually an [AppButton].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: context.colors.accentStrong,
      title: title,
      message: message,
      action: action,
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon = AppIcons.error,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
    return _StateLayout(
      icon: icon,
      iconColor: context.colors.danger,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Try again',
              icon: AppIcons.retry,
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
            ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final action = this.action;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: space.gutter,
        vertical: space.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: context.radii.card,
              border: Border.all(
                color: colors.lineStrong,
                width: context.elevation.hairline,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          SizedBox(height: space.xl),
          Semantics(
            header: true,
            child: Text(
              title,
              style: context.typeScale.title.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: space.sm),
          Text(
            message,
            style: context.typeScale.body.copyWith(color: colors.textSecondary),
          ),
          if (action != null) ...[SizedBox(height: space.xl), action],
        ],
      ),
    );
  }
}
