import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_route.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';
import '../bloc/accounts_cubit.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountsCubit(context.read<LedgerRepository>()),
      child: const _AccountsView(),
    );
  }
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  void _add(BuildContext context) =>
      context.pushNamed(AppRoute.newAccount.name);

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, state) {
            final position = state.position;
            return ListView(
              padding: EdgeInsets.only(bottom: space.xxxl),
              children: [
                PageHeader(
                  title: 'Accounts',
                  showBack: true,
                  actions: [
                    HeaderAction(
                      icon: AppIcons.add,
                      label: 'Add account',
                      onPressed: () => _add(context),
                    ),
                  ],
                ),
                if (state.isLoading)
                  const SizedBox.shrink()
                else if (state.isEmpty)
                  EmptyStateView(
                    icon: AppIcons.accounts,
                    title: 'No accounts yet',
                    message:
                        'Add the places your money lives: bank accounts, '
                        'cash, wallets, cards and loans. Balances update as '
                        'you record transactions.',
                    action: AppButton(
                      label: 'Add account',
                      icon: AppIcons.add,
                      onPressed: () => _add(context),
                    ),
                  )
                else ...[
                  if (position != null)
                    Padding(
                      padding: space.screen,
                      child: SurfaceCard(
                        tone: SurfaceTone.raised,
                        child: Row(
                          children: [
                            Expanded(
                              child: _Figure(
                                label: 'Net worth',
                                money: position.netWorth,
                              ),
                            ),
                            Expanded(
                              child: _Figure(
                                label: 'Owned',
                                money: position.assets,
                              ),
                            ),
                            Expanded(
                              child: _Figure(
                                label: 'Owed',
                                money: position.liabilities,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final (index, group) in state.groups.indexed)
                    Entrance(
                      index: index,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          space.gutter,
                          space.xxl,
                          space.gutter,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionLabel(
                              group.group.label,
                              index: index + 1,
                              trailing: MoneyText(
                                group.total,
                                size: MoneySize.small,
                              ),
                            ),
                            SizedBox(height: space.sm),
                            for (final item in group.accounts)
                              AccountRow(item: item),
                          ],
                        ),
                      ),
                    ),
                  if (state.archived.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        space.gutter,
                        space.xxl,
                        space.gutter,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionLabel('Archived'),
                          SizedBox(height: space.xs),
                          Text(
                            'Hidden from pickers and left out of totals. '
                            'Their history stays in your reports.',
                            style: context.typeScale.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: space.sm),
                          for (final item in state.archived)
                            AccountRow(item: item),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.money});

  final String label;
  final Money money;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.typeScale.label.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: context.space.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: MoneyText(money, precision: MoneyPrecision.whole),
          ),
        ],
      ),
    );
  }
}

/// One account with its balance; opens the account's page.
class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.item});

  final AccountBalance item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final account = item.account;
    final owed = account.type.isLiability && item.balance.isNegative;
    final subtitle = [
      account.type.label,
      if (account.institution.isNotEmpty) account.institution,
    ].join(' · ');
    return Pressable(
      onPressed: () => context.pushNamed(
        AppRoute.accountDetails.name,
        pathParameters: {AppRoute.accountIdParam: account.id},
      ),
      pressedScale: 0.985,
      semanticLabel: '${account.name}, $subtitle',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: space.sm),
        child: Row(
          children: [
            AccountAvatar(type: account.type),
            SizedBox(width: space.md),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typeScale.bodyStrong.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typeScale.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: space.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(item.balance, size: MoneySize.small),
                if (owed)
                  Text(
                    'OWED',
                    style: context.typeScale.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
