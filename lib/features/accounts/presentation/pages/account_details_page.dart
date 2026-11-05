import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_route.dart';
import '../../../../core/domain/clock.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/account_usecases.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';
import '../../../ledger/presentation/widgets/transaction_tile.dart';
import '../bloc/account_details_cubit.dart';

class AccountDetailsPage extends StatelessWidget {
  const AccountDetailsPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountDetailsCubit(
        ledger: context.read<LedgerRepository>(),
        setArchived: context.read<SetAccountArchived>(),
        delete: context.read<DeleteAccount>(),
        clock: context.read<Clock>(),
        id: accountId,
      ),
      child: const _AccountDetailsView(),
    );
  }
}

enum _AccountAction { archive, unarchive, delete }

class _AccountDetailsView extends StatelessWidget {
  const _AccountDetailsView();

  Future<void> _more(BuildContext context, AccountDetailsState state) async {
    final account = state.account;
    if (account == null) return;
    final cubit = context.read<AccountDetailsCubit>();
    final hasHistory = state.transactions.isNotEmpty;
    final action = await showOptionSheet<_AccountAction>(
      context,
      title: account.name,
      options: [
        if (account.isArchived)
          const SheetOption(
            value: _AccountAction.unarchive,
            label: 'Restore account',
            subtitle: 'Show it in pickers and totals again',
            icon: AppIcons.unarchive,
          )
        else
          const SheetOption(
            value: _AccountAction.archive,
            label: 'Archive account',
            subtitle: 'Hide it; keep its history',
            icon: AppIcons.archive,
          ),
        if (!hasHistory)
          const SheetOption(
            value: _AccountAction.delete,
            label: 'Delete account',
            subtitle: 'It has no transactions',
            icon: AppIcons.delete,
          ),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _AccountAction.unarchive:
        await cubit.setArchived(false);
      case _AccountAction.archive:
        final balance = state.balance;
        final confirmed = await showConfirmDialog(
          context,
          title: 'Archive ${account.name}?',
          message: balance == null || balance.isZero
              ? 'It will be hidden from pickers. Its history stays in your '
                    'reports.'
              : 'It still holds a balance, which will no longer count '
                    'toward your totals. Its history stays in your reports.',
          confirmLabel: 'Archive',
        );
        if (confirmed) await cubit.setArchived(true);
      case _AccountAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete ${account.name}?',
          message: 'This can’t be undone.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (confirmed) await cubit.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountDetailsCubit, AccountDetailsState>(
      listenWhen: (a, b) =>
          a.failureCount != b.failureCount || a.status != b.status,
      listener: (context, state) {
        if (state.status == AccountDetailsStatus.deleted) {
          showAppSnackBar(context, 'Account deleted');
          context.pop();
          return;
        }
        final failure = state.failure;
        if (failure != null) {
          showAppSnackBar(context, failureMessage(failure));
        }
      },
      builder: (context, state) {
        final account = state.account;
        return Scaffold(
          body: SafeArea(
            child: switch (state.status) {
              AccountDetailsStatus.loading ||
              AccountDetailsStatus.deleted => const SizedBox.shrink(),
              AccountDetailsStatus.missing => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(title: '', showBack: true),
                  EmptyStateView(
                    icon: AppIcons.lost,
                    title: 'Account not found',
                    message: 'It may have been deleted.',
                    action: AppButton(
                      label: 'All accounts',
                      onPressed: () => context.goNamed(AppRoute.accounts.name),
                    ),
                  ),
                ],
              ),
              AccountDetailsStatus.found =>
                account == null
                    ? const SizedBox.shrink()
                    : _Body(
                        state: state,
                        account: account,
                        onMore: () => _more(context, state),
                      ),
            },
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.account,
    required this.onMore,
  });

  final AccountDetailsState state;
  final Account account;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final ledger = state.ledger;
    final balance = state.balance;
    final month = state.thisMonth;
    final idParam = {AppRoute.accountIdParam: account.id};
    final subtitle = [
      account.type.label,
      if (account.institution.isNotEmpty) account.institution,
      if (account.isArchived) 'Archived',
    ].join(' · ');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: account.name,
            eyebrow: subtitle,
            showBack: true,
            actions: [
              HeaderAction(
                icon: AppIcons.edit,
                label: 'Edit account',
                onPressed: () => context.pushNamed(
                  AppRoute.editAccount.name,
                  pathParameters: idParam,
                ),
              ),
              HeaderAction(
                icon: AppIcons.more,
                label: 'More actions',
                onPressed: onMore,
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: space.screen,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AccountAvatar(type: account.type, size: 48),
                    SizedBox(width: space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.type.isLiability
                                ? 'OUTSTANDING'
                                : 'BALANCE',
                            style: context.typeScale.label.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          if (balance != null)
                            AnimatedMoney(balance, size: MoneySize.large),
                        ],
                      ),
                    ),
                  ],
                ),
                if (month != null) ...[
                  SizedBox(height: space.xl),
                  SurfaceCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MonthFigure(
                            label: 'In this month',
                            money: month.income,
                          ),
                        ),
                        Expanded(
                          child: _MonthFigure(
                            label: 'Out this month',
                            money: month.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: space.xl),
                if (!account.isArchived)
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Add',
                          icon: AppIcons.add,
                          expand: true,
                          onPressed: () => context.pushNamed(
                            AppRoute.newTransaction.name,
                            queryParameters: {RouteQuery.account: account.id},
                          ),
                        ),
                      ),
                      SizedBox(width: space.md),
                      Expanded(
                        child: AppButton(
                          label: 'Reconcile',
                          icon: AppIcons.reconcile,
                          variant: AppButtonVariant.secondary,
                          expand: true,
                          onPressed: () => context.pushNamed(
                            AppRoute.reconcileAccount.name,
                            pathParameters: idParam,
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: space.xxl),
                SectionLabel(
                  'Transactions',
                  trailing: Text(
                    '${state.transactions.length}',
                    style: context.typeScale.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                SizedBox(height: space.sm),
              ],
            ),
          ),
        ),
        if (state.transactions.isEmpty || ledger == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: space.screen,
              child: Text(
                'Nothing recorded for this account yet.',
                style: context.typeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: space.screen,
            sliver: SliverList.builder(
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                return TransactionTile(
                  transaction: transaction,
                  ledger: ledger,
                  showDate: true,
                  onPressed: () => context.pushNamed(
                    AppRoute.transactionDetails.name,
                    pathParameters: {
                      AppRoute.transactionIdParam: transaction.id,
                    },
                  ),
                );
              },
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: space.xxxl)),
      ],
    );
  }
}

class _MonthFigure extends StatelessWidget {
  const _MonthFigure({required this.label, required this.money});

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
          MoneyText(money),
        ],
      ),
    );
  }
}
