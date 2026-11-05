import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/sheet_scaffold.dart';
import '../../features/ledger/domain/entities/transaction.dart';
import '../router/app_route.dart';

/// The centre key's action menu. Each action replaces this sheet with its
/// own, so back returns to where the user was.
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        AppIcons.expense,
        'Add expense',
        'Something you paid for',
        () => context.pushReplacementNamed(AppRoute.newTransaction.name),
      ),
      (
        AppIcons.income,
        'Add income',
        'Salary, freelance, interest, refunds',
        () => context.pushReplacementNamed(
          AppRoute.newTransaction.name,
          queryParameters: {RouteQuery.type: TransactionType.income.name},
        ),
      ),
      (
        AppIcons.transfer,
        'Transfer money',
        'Between your own accounts; not spending',
        () => context.pushReplacementNamed(
          AppRoute.newTransaction.name,
          queryParameters: {RouteQuery.type: TransactionType.transfer.name},
        ),
      ),
      (
        AppIcons.accounts,
        'Add account',
        'Bank, cash, wallet, card or loan',
        () => context.pushReplacementNamed(AppRoute.newAccount.name),
      ),
    ];

    return SheetScaffold(
      title: 'Add',
      body: Column(
        children: [
          for (final (index, (icon, title, subtitle, onPressed))
              in actions.indexed)
            Entrance(
              index: index,
              child: _ActionTile(
                icon: icon,
                title: title,
                subtitle: subtitle,
                onPressed: onPressed,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return Padding(
      padding: EdgeInsets.only(bottom: space.sm),
      child: Pressable(
        onPressed: onPressed,
        haptic: PressHaptic.medium,
        semanticLabel: '$title. $subtitle',
        child: ExcludeSemantics(
          child: Container(
            padding: EdgeInsets.all(space.lg),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: context.radii.card,
              border: Border.all(
                color: colors.line,
                width: context.elevation.hairline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.textPrimary,
                    borderRadius: context.radii.card,
                  ),
                  child: Icon(icon, color: colors.canvas),
                ),
                SizedBox(width: space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.typeScale.bodyStrong.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: context.typeScale.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
