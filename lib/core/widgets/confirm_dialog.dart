import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import 'app_button.dart';

/// Asks the user to confirm an action. Resolves to true only on confirm.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: EdgeInsets.all(dialogContext.space.lg),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: destructive
              ? AppButtonVariant.danger
              : AppButtonVariant.secondary,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
