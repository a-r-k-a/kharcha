import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/theme_context.dart';
import 'pressable.dart';

/// Layout for route-backed bottom sheets: grab handle, title row with a
/// close key, scrolling body and an optional action pinned above the
/// keyboard.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.eyebrow,
  });

  final String title;

  /// Small label above the title, e.g. "Edit".
  final String? eyebrow;
  final Widget body;

  /// Usually an expanded primary `AppButton`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final eyebrow = this.eyebrow;
    final action = this.action;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: space.sm),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.lineStrong,
                borderRadius: context.radii.chip,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(space.gutter, space.md, space.sm, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null)
                        Text(
                          eyebrow.toUpperCase(),
                          style: context.typeScale.label.copyWith(
                            color: colors.accentStrong,
                          ),
                        ),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: context.typeScale.title.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Pressable(
                  onPressed: () => context.pop(),
                  tooltip: 'Close',
                  semanticLabel: 'Close',
                  child: Icon(AppIcons.close, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                space.gutter,
                space.lg,
                space.gutter,
                space.lg,
              ),
              child: body,
            ),
          ),
          if (action != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(
                    color: colors.line,
                    width: context.elevation.hairline,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    space.gutter,
                    space.md,
                    space.gutter,
                    space.md,
                  ),
                  child: action,
                ),
              ),
            )
          else
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
