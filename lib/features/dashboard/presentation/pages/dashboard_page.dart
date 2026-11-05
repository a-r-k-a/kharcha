import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/activity_link.dart';
import '../../../../app/router/app_route.dart';
import '../../../../core/domain/clock.dart';
import '../../../../core/domain/date_range.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/formatting/date_labels.dart';
import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/app_elevation.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';
import '../../../ledger/presentation/category_style.dart';
import '../../../ledger/presentation/widgets/transaction_tile.dart';
import '../../../profile/presentation/bloc/session_cubit.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/spending_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(
        ledger: context.read<LedgerRepository>(),
        clock: context.read<Clock>(),
      ),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final firstName = context.select<SessionCubit, String?>(
      (cubit) => switch (cubit.state) {
        SessionReady(:final profile) => profile.firstName,
        _ => null,
      },
    );
    final now = context.read<Clock>().now();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            final view = state.view;
            return ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                PageHeader(
                  eyebrow: DateLabels.fullDate(now),
                  title: [
                    DateLabels.greeting(now),
                    if (firstName != null && firstName.isNotEmpty) firstName,
                  ].join(', '),
                  actions: [
                    HeaderAction(
                      icon: state.balancesHidden
                          ? AppIcons.show
                          : AppIcons.hide,
                      label: state.balancesHidden
                          ? 'Show amounts'
                          : 'Hide amounts',
                      onPressed: context.read<DashboardCubit>().toggleBalances,
                    ),
                  ],
                ),
                if (view == null)
                  const _DashboardSkeleton()
                else if (!state.hasAccounts)
                  const _FirstRun()
                else
                  _DashboardBody(state: state, view: view, now: now),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.view,
    required this.now,
  });

  final DashboardState state;
  final DashboardView view;
  final DateTime now;

  String get _periodNoun => switch (view.period.kind) {
    PeriodKind.day => 'today',
    PeriodKind.week => 'this week',
    PeriodKind.month => 'this month',
    PeriodKind.year => 'this year',
  };

  String get _previousNoun => switch (view.period.kind) {
    PeriodKind.day => 'yesterday',
    PeriodKind.week => 'last week',
    PeriodKind.month => 'last month',
    PeriodKind.year => 'last year',
  };

  void _openActivity(
    BuildContext context, {
    TransactionType? type,
    String? categoryId,
  }) {
    context.goNamed(
      AppRoute.activity.name,
      queryParameters: ActivityLink.query(
        type: type,
        categoryId: categoryId,
        accountId: state.accountId,
        range: view.period.range,
      ),
    );
  }

  Future<void> _pickAccount(BuildContext context) async {
    final ledger = state.ledger;
    if (ledger == null) return;
    const all = '';
    final cubit = context.read<DashboardCubit>();
    final choice = await showOptionSheet<String>(
      context,
      title: 'Show figures for',
      selected: state.accountId ?? all,
      options: [
        const SheetOption(value: all, label: 'All accounts'),
        for (final account in ledger.activeAccounts)
          SheetOption(
            value: account.id,
            label: account.name,
            icon: account.type.icon,
          ),
      ],
    );
    if (choice == null) return;
    cubit.setAccount(choice == all ? null : choice);
  }

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final cubit = context.read<DashboardCubit>();
    final hidden = state.balancesHidden;
    final summary = view.summary;
    final ledger = state.ledger;
    final accountId = state.accountId;
    final account = accountId == null ? null : ledger?.accountById(accountId);
    var section = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          child: Padding(
            padding: space.screen,
            child: _BalanceCard(position: view.position, hidden: hidden),
          ),
        ),
        SizedBox(height: space.xl),
        Padding(
          padding: space.screen,
          child: AppSegmentedControl<PeriodKind>(
            semanticLabel: 'Period',
            selected: view.period.kind,
            onChanged: cubit.setPeriod,
            options: const [
              SegmentOption(PeriodKind.day, 'Day'),
              SegmentOption(PeriodKind.week, 'Week'),
              SegmentOption(PeriodKind.month, 'Month'),
              SegmentOption(PeriodKind.year, 'Year'),
            ],
          ),
        ),
        SizedBox(height: space.md),
        Padding(
          padding: space.screen,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppChip(
              label: account?.name ?? 'All accounts',
              icon: AppIcons.accounts,
              trailingIcon: AppIcons.chevronDown,
              selected: account != null,
              onPressed: () => _pickAccount(context),
            ),
          ),
        ),
        SizedBox(height: space.lg),
        Entrance(
          index: 1,
          child: Padding(
            padding: space.screen,
            child: Row(
              children: [
                Expanded(
                  child: _FlowCard(
                    label: 'Income',
                    icon: AppIcons.income,
                    amount: summary.income,
                    previous: view.previous.income,
                    previousNoun: _previousNoun,
                    upIsGood: true,
                    hidden: hidden,
                    onPressed: () =>
                        _openActivity(context, type: TransactionType.income),
                  ),
                ),
                SizedBox(width: space.md),
                Expanded(
                  child: _FlowCard(
                    label: 'Spent',
                    icon: AppIcons.expense,
                    amount: summary.expense,
                    previous: view.previous.expense,
                    previousNoun: _previousNoun,
                    upIsGood: false,
                    hidden: hidden,
                    onPressed: () =>
                        _openActivity(context, type: TransactionType.expense),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: space.md),
        Entrance(
          index: 2,
          child: Padding(
            padding: space.screen,
            child: _NetCard(
              summary: summary,
              hidden: hidden,
              noun: _periodNoun,
            ),
          ),
        ),
        if (!state.hasTransactions) ...[
          SizedBox(height: space.xxl),
          const _NoTransactionsYet(),
        ] else ...[
          SizedBox(height: space.xxl),
          Padding(
            padding: space.screen,
            child: SectionLabel('Spending', index: ++section),
          ),
          SizedBox(height: space.md),
          Padding(
            padding: space.screen,
            child: hidden
                ? const _HiddenNotice()
                : SpendingChart(
                    buckets: view.cashFlow,
                    kind: view.period.kind,
                    now: now,
                  ),
          ),
          SizedBox(height: space.xxl),
          Padding(
            padding: space.screen,
            child: SectionLabel('Where it went', index: ++section),
          ),
          SizedBox(height: space.md),
          Padding(
            padding: space.screen,
            child: view.breakdown.isEmpty
                ? Text(
                    'No spending $_periodNoun yet.',
                    style: context.typeScale.body.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  )
                : CategoryBreakdown(
                    shares: view.breakdown,
                    masked: hidden,
                    onCategoryPressed: (category) => _openActivity(
                      context,
                      type: TransactionType.expense,
                      categoryId: category.id,
                    ),
                  ),
          ),
          SizedBox(height: space.xxl),
          Padding(
            padding: space.screen,
            child: SectionLabel(
              'Recent',
              index: ++section,
              trailing: AppButton(
                label: 'See all',
                variant: AppButtonVariant.ghost,
                onPressed: () => context.goNamed(AppRoute.activity.name),
              ),
            ),
          ),
          if (ledger != null)
            Padding(
              padding: space.screen,
              child: Column(
                children: [
                  for (final (index, t) in view.recent.indexed)
                    Entrance(
                      index: index + 3,
                      child: TransactionTile(
                        transaction: t,
                        ledger: ledger,
                        showDate: true,
                        onPressed: () => context.pushNamed(
                          AppRoute.transactionDetails.name,
                          pathParameters: {AppRoute.transactionIdParam: t.id},
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// The hero: spendable balance in negative print, with net worth beneath.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.position, required this.hidden});

  final NetPosition position;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final ink = colors.canvas;
    final formatter = MoneyFormatScope.of(context);
    final labelStyle = context.typeScale.label.copyWith(
      color: ink.withValues(alpha: 0.72),
    );

    return SurfaceCard(
      tone: SurfaceTone.inverted,
      level: ElevationLevel.flat,
      padding: EdgeInsets.all(space.xl),
      semanticLabel: hidden
          ? 'Cash and bank balance hidden'
          : 'Cash and bank balance ${formatter.format(position.liquid)}, '
                'net worth ${formatter.format(position.netWorth)}',
      onPressed: () => context.pushNamed(AppRoute.accounts.name),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('CASH & BANK', style: labelStyle),
                const Spacer(),
                Icon(AppIcons.chevronRight, size: 18, color: ink),
              ],
            ),
            SizedBox(height: space.sm),
            AnimatedSwitcher(
              duration: context.motionDuration(context.motion.fast),
              child: hidden
                  ? Text(
                      '${formatter.symbolOf(position.liquid.currency)} ••••••',
                      key: const ValueKey('hidden'),
                      style: context.typeScale.moneyLarge.copyWith(color: ink),
                    )
                  : AnimatedMoney(
                      position.liquid,
                      key: const ValueKey('shown'),
                      size: MoneySize.hero,
                      color: ink,
                      precision: MoneyPrecision.whole,
                      countUpOnMount: true,
                    ),
            ),
            SizedBox(height: space.lg),
            Container(
              height: context.elevation.hairline,
              color: ink.withValues(alpha: 0.2),
            ),
            SizedBox(height: space.md),
            Row(
              children: [
                Expanded(
                  child: _InkFigure(
                    label: 'Net worth',
                    money: position.netWorth,
                    hidden: hidden,
                  ),
                ),
                Expanded(
                  child: _InkFigure(
                    label: 'Owed',
                    money: position.liabilities,
                    hidden: hidden,
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

class _InkFigure extends StatelessWidget {
  const _InkFigure({
    required this.label,
    required this.money,
    required this.hidden,
  });

  final String label;
  final Money money;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final ink = context.colors.canvas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.typeScale.label.copyWith(
            color: ink.withValues(alpha: 0.72),
          ),
        ),
        SizedBox(height: context.space.xxs),
        hidden
            ? Text(
                '••••',
                style: context.typeScale.moneySmall.copyWith(color: ink),
              )
            : MoneyText(
                money,
                size: MoneySize.small,
                color: ink,
                precision: MoneyPrecision.whole,
              ),
      ],
    );
  }
}

/// Income or spending for the period, with the change from the previous
/// period. The change carries an arrow and words, not just color.
class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.label,
    required this.icon,
    required this.amount,
    required this.previous,
    required this.previousNoun,
    required this.upIsGood,
    required this.hidden,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Money amount;
  final Money previous;
  final String previousNoun;
  final bool upIsGood;
  final bool hidden;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final formatter = MoneyFormatScope.of(context);
    final change = LedgerAnalytics.percentChange(amount, previous);
    final rounded = change?.round();
    final (
      String delta,
      Color deltaColor,
      IconData? deltaIcon,
    ) = switch (rounded) {
      null => ('Nothing $previousNoun', colors.textTertiary, null),
      0 => ('Same as $previousNoun', colors.textSecondary, null),
      final r => (
        '${r.abs()}% ${r > 0 ? 'more' : 'less'} than $previousNoun',
        (r > 0) == upIsGood ? colors.accentStrong : colors.danger,
        r > 0 ? AppIcons.trendUp : AppIcons.trendDown,
      ),
    };

    return SurfaceCard(
      onPressed: onPressed,
      semanticLabel:
          '$label ${hidden ? 'hidden' : formatter.format(amount)}, $delta',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: colors.textSecondary),
                SizedBox(width: space.xs),
                Text(
                  label.toUpperCase(),
                  style: context.typeScale.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: space.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: hidden
                  ? Text(
                      '••••',
                      style: context.typeScale.moneyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    )
                  : AnimatedMoney(amount, precision: MoneyPrecision.whole),
            ),
            SizedBox(height: space.sm),
            Row(
              children: [
                if (deltaIcon != null) ...[
                  Icon(deltaIcon, size: 14, color: deltaColor),
                  SizedBox(width: space.xxs),
                ],
                Expanded(
                  child: Text(
                    delta,
                    maxLines: 2,
                    style: context.typeScale.bodySmall.copyWith(
                      color: hidden ? colors.textTertiary : deltaColor,
                    ),
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

class _NetCard extends StatelessWidget {
  const _NetCard({
    required this.summary,
    required this.hidden,
    required this.noun,
  });

  final PeriodSummary summary;
  final bool hidden;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final rate = summary.savingsRate;
    final net = summary.netCashFlow;
    final formatter = MoneyFormatScope.of(context);
    final message = switch (rate) {
      null when summary.expense.isZero => 'No money in or out $noun yet.',
      null => 'No income recorded $noun.',
      final r when r >= 0 => 'You kept ${r.round()}% of your income $noun.',
      _ => 'You spent more than you earned $noun.',
    };

    return SurfaceCard(
      tone: SurfaceTone.raised,
      semanticLabel:
          'Net cash flow ${hidden ? 'hidden' : formatter.format(net, signed: true)}. $message',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NET CASH FLOW',
                    style: context.typeScale.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: space.xs),
                  Text(
                    message,
                    style: context.typeScale.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: space.md),
            hidden
                ? Text(
                    '••••',
                    style: context.typeScale.moneyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  )
                : MoneyText(
                    net,
                    signed: true,
                    precision: MoneyPrecision.whole,
                    color: net.isNegative ? colors.danger : colors.textPrimary,
                  ),
          ],
        ),
      ),
    );
  }
}

class _HiddenNotice extends StatelessWidget {
  const _HiddenNotice();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          Icon(AppIcons.hide, color: context.colors.textSecondary),
          SizedBox(width: context.space.md),
          Expanded(
            child: Text(
              'Amounts are hidden. Tap the eye above to show them.',
              style: context.typeScale.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstRun extends StatelessWidget {
  const _FirstRun();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return Padding(
      padding: space.screen,
      child: SurfaceCard(
        level: ElevationLevel.lifted,
        padding: EdgeInsets.all(space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP 1 OF 2',
              style: context.typeScale.label.copyWith(
                color: colors.accentStrong,
              ),
            ),
            SizedBox(height: space.sm),
            Text(
              'Add where your money lives',
              style: context.typeScale.title.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: space.sm),
            Text(
              'Start with your main bank account or the cash in your wallet. '
              'Enter today’s balance; everything you record builds on it.',
              style: context.typeScale.body.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: space.xl),
            AppButton(
              label: 'Add first account',
              icon: AppIcons.add,
              onPressed: () => context.pushNamed(AppRoute.newAccount.name),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTransactionsYet extends StatelessWidget {
  const _NoTransactionsYet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return Padding(
      padding: space.screen,
      child: SurfaceCard(
        padding: EdgeInsets.all(space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP 2 OF 2',
              style: context.typeScale.label.copyWith(
                color: colors.accentStrong,
              ),
            ),
            SizedBox(height: space.sm),
            Text(
              'Record your first transaction',
              style: context.typeScale.title.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: space.sm),
            Text(
              'Charts, category breakdowns and comparisons appear here once '
              'you log what you spend and earn.',
              style: context.typeScale.body.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: space.xl),
            Wrap(
              spacing: space.md,
              runSpacing: space.md,
              children: [
                AppButton(
                  label: 'Add expense',
                  icon: AppIcons.expense,
                  onPressed: () =>
                      context.pushNamed(AppRoute.newTransaction.name),
                ),
                AppButton(
                  label: 'Add income',
                  icon: AppIcons.income,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.pushNamed(
                    AppRoute.newTransaction.name,
                    queryParameters: {
                      RouteQuery.type: TransactionType.income.name,
                    },
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

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return SkeletonGroup(
      semanticLabel: 'Loading your dashboard',
      child: Padding(
        padding: space.screen,
        child: Column(
          children: [
            const SkeletonBox(height: 180),
            SizedBox(height: space.xl),
            const SkeletonBox(height: 48),
            SizedBox(height: space.lg),
            Row(
              children: [
                const Expanded(child: SkeletonBox(height: 110)),
                SizedBox(width: space.md),
                const Expanded(child: SkeletonBox(height: 110)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
