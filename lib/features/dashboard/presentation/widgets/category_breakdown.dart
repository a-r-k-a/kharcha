import 'package:material_ui/material_ui.dart';

import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';
import '../../../ledger/presentation/category_style.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';

/// A segmented bar (one whole, split into categories) above labeled rows.
/// Segments are separated by a 2px surface gap; colors follow each
/// category, and every segment is named in the rows below.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.shares,
    required this.onCategoryPressed,
    this.masked = false,
  });

  final List<CategoryShare> shares;
  final ValueChanged<Category> onCategoryPressed;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final formatter = MoneyFormatScope.of(context);

    Color colorOf(CategoryShare share) =>
        share.category?.tone.colorFrom(colors) ?? colors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: context.motionDuration(context.motion.slow),
            curve: context.motion.enter,
            builder: (context, t, _) => ClipRRect(
              borderRadius: context.radii.card,
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (var i = 0; i < shares.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: (shares[i].share * 1000 * t).round().clamp(
                          1,
                          1000,
                        ),
                        child: ColoredBox(color: colorOf(shares[i])),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: space.md),
        for (final share in shares)
          _ShareRow(
            share: share,
            masked: masked,
            onPressed: switch (share.category) {
              final category? => () => onCategoryPressed(category),
              null => null,
            },
            semanticLabel:
                '${share.category?.name ?? 'Everything else'}, '
                '${masked ? 'amount hidden' : formatter.format(share.amount)}, '
                '${(share.share * 100).round()} percent',
          ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.share,
    required this.masked,
    required this.onPressed,
    required this.semanticLabel,
  });

  final CategoryShare share;
  final bool masked;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: space.xs),
      child: Row(
        children: [
          CategoryAvatar(category: share.category, size: 32),
          SizedBox(width: space.md),
          Expanded(
            child: Text(
              share.category?.name ?? 'Everything else',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typeScale.body.copyWith(color: colors.textPrimary),
            ),
          ),
          Text(
            '${(share.share * 100).round()}%',
            style: context.typeScale.label.copyWith(color: colors.textTertiary),
          ),
          SizedBox(width: space.md),
          masked
              ? Text(
                  '••••',
                  style: context.typeScale.moneySmall.copyWith(
                    color: colors.textPrimary,
                  ),
                )
              : MoneyText(share.amount, size: MoneySize.small),
        ],
      ),
    );
    final onPressed = this.onPressed;
    return Pressable(
      onPressed: onPressed,
      pressedScale: 0.985,
      semanticLabel: semanticLabel,
      child: ExcludeSemantics(child: row),
    );
  }
}
