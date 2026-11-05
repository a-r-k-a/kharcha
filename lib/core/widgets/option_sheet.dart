import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/theme_context.dart';
import 'list_row.dart';

class SheetOption<T> {
  const SheetOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.leading,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
}

/// A transient single-choice picker. Resolves to the picked value, or null
/// when dismissed. For filters and choices, not navigation.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final colors = sheetContext.colors;
      final space = sheetContext.space;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                space.gutter,
                space.xl,
                space.gutter,
                space.sm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: sheetContext.typeScale.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  space.gutter,
                  0,
                  space.gutter,
                  space.xl,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option.value == selected;
                  return Semantics(
                    selected: isSelected,
                    child: ListRow(
                      title: option.label,
                      subtitle: option.subtitle,
                      icon: option.icon,
                      leading: option.leading,
                      trailing: isSelected
                          ? Icon(AppIcons.check, color: colors.accentStrong)
                          : const SizedBox.shrink(),
                      onPressed: () => Navigator.of(context).pop(option.value),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
