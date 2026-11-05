import 'package:material_ui/material_ui.dart';

/// Shows [message], replacing any snackbar already on screen so feedback
/// for the latest action is never queued behind an older one.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) =>
    ScaffoldMessenger.of(context)
        .showMessage(message, actionLabel: actionLabel, onAction: onAction);

extension AppSnackBars on ScaffoldMessengerState {
  /// [showAppSnackBar] for a messenger captured before an async gap.
  void showMessage(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final action = actionLabel != null && onAction != null
        ? SnackBarAction(label: actionLabel, onPressed: onAction)
        : null;
    this
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }
}
