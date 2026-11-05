import 'package:material_ui/material_ui.dart';

import '../../../../core/domain/money.dart';
import '../../../../core/formatting/date_labels.dart';
import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/transaction.dart';
import '../ledger_labels.dart';
import 'ledger_avatars.dart';

/// One ledger line: category tile, description, where the money moved, and
/// a signed amount. Direction is shown by sign and icon, not color alone.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.ledger,
    required this.onPressed,
    this.showDate = false,
  });

  final Transaction transaction;
  final Ledger ledger;
  final VoidCallback onPressed;

  /// Show the date in the subtitle (for lists not grouped by day).
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final t = transaction;
    final description = describe(t, ledger);
    final subtitle = [
      description.detail,
      if (showDate) DateLabels.day(t.occurredAt, DateTime.now()),
    ].join(' · ');

    final (Color amountColor, bool signed, Money amount) = switch (t.type) {
      TransactionType.income => (colors.accentStrong, true, t.amount),
      TransactionType.expense => (colors.textPrimary, false, -t.amount),
      TransactionType.transfer => (colors.textSecondary, false, t.amount),
      TransactionType.adjustment => (colors.textSecondary, true, t.amount),
    };
    final formatted = MoneyFormatScope.of(context)
        .format(amount, signed: signed);

    return Pressable(
      onPressed: onPressed,
      pressedScale: 0.985,
      semanticLabel:
          '${t.type.label}, ${description.title}, $formatted, $subtitle'
          '${t.isReimbursable ? ', reimbursable' : ''}',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: space.sm),
          child: Row(
            children: [
              _leading(context),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typeScale.bodyStrong.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        if (t.isSplit) ...[
                          Icon(
                            AppIcons.split,
                            size: 12,
                            color: colors.textTertiary,
                          ),
                          SizedBox(width: space.xxs),
                        ],
                        if (t.isReimbursable) ...[
                          Icon(
                            AppIcons.reimbursable,
                            size: 12,
                            color: colors.textTertiary,
                          ),
                          SizedBox(width: space.xxs),
                        ],
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.typeScale.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: space.md),
              MoneyText(
                amount,
                size: MoneySize.small,
                color: amountColor,
                signed: signed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading(BuildContext context) {
    final t = transaction;
    return switch (t.type) {
      TransactionType.expense || TransactionType.income => CategoryAvatar(
        category: switch (t.primaryCategoryId) {
          final id? => ledger.categoryById(id),
          null => null,
        },
      ),
      TransactionType.transfer => ToneTile(
        icon: AppIcons.transfer,
        tone: context.colors.lineStrong,
      ),
      TransactionType.adjustment => ToneTile(
        icon: AppIcons.adjustment,
        tone: context.colors.lineStrong,
      ),
    };
  }

  /// Title and detail lines for [t], shared with the details page.
  static ({String title, String detail}) describe(
    Transaction t,
    Ledger ledger,
  ) {
    String accountName(String? id) =>
        (id == null ? null : ledger.accountById(id)?.name) ?? 'Unknown account';
    final categoryName = switch (t.primaryCategoryId) {
      final id? => ledger.categoryById(id)?.name,
      null => null,
    };
    final category = t.isSplit
        ? 'Split · ${t.allocations.length} categories'
        : (categoryName ?? 'Uncategorized');

    return switch (t.type) {
      TransactionType.expense || TransactionType.income => (
        title: t.title.isNotEmpty ? t.title : category,
        detail: t.title.isNotEmpty
            ? '$category · ${accountName(t.accountId)}'
            : accountName(t.accountId),
      ),
      TransactionType.transfer => (
        title: t.title.isNotEmpty ? t.title : 'Transfer',
        detail:
            '${accountName(t.accountId)} → ${accountName(t.counterpartyAccountId)}',
      ),
      TransactionType.adjustment => (
        title: t.title.isNotEmpty ? t.title : 'Balance adjustment',
        detail: accountName(t.accountId),
      ),
    };
  }
}
