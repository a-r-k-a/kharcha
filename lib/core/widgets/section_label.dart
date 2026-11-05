import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

/// Ledger-style section header: `01 — TODAY ─────────── trailing`.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.index, this.trailing});

  /// Sentence-case text; rendered uppercase, announced as written.
  final String text;

  /// Optional section number, rendered zero-padded in the accent.
  final int? index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.typeScale.label;
    final space = context.space;
    final index = this.index;
    final trailing = this.trailing;

    return Semantics(
      header: true,
      label: text,
      excludeSemantics: trailing == null,
      child: Row(
        children: [
          if (index != null) ...[
            ExcludeSemantics(
              child: Text(
                '${index.toString().padLeft(2, '0')} —',
                style: style.copyWith(color: colors.accentStrong),
              ),
            ),
            SizedBox(width: space.sm),
          ],
          ExcludeSemantics(
            child: Text(
              text.toUpperCase(),
              style: style.copyWith(color: colors.textSecondary),
            ),
          ),
          SizedBox(width: space.md),
          Expanded(
            child: Container(
              height: context.elevation.hairline,
              color: colors.line,
            ),
          ),
          if (trailing != null) ...[SizedBox(width: space.md), trailing],
        ],
      ),
    );
  }
}
