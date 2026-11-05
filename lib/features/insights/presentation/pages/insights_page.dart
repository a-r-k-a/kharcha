import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/activity_link.dart';
import '../../../../app/router/app_route.dart';
import '../../../../core/domain/clock.dart';
import '../../../../core/formatting/date_labels.dart';
import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../dashboard/presentation/widgets/category_breakdown.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/insight_engine.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';
import '../bloc/insights_cubit.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InsightsCubit(
        ledger: context.read<LedgerRepository>(),
        clock: context.read<Clock>(),
      ),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<InsightsCubit, InsightsState>(
          builder: (context, state) {
            final summary = state.summary;
            return ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const PageHeader(title: 'Insights'),
                if (state.isLoading)
                  const SizedBox.shrink()
                else if (!state.hasAnyTransactions)
                  const EmptyStateView(
                    icon: AppIcons.insights,
                    title: 'Insights need history',
                    message:
                        'Record a few weeks of spending and income. Trends, '
                        'comparisons and observations appear here, worked '
                        'out from your own transactions.',
                  )
                else if (summary != null) ...[
                  Padding(
                    padding: space.screen,
                    child: _MonthSwitcher(state: state),
                  ),
                  SizedBox(height: space.lg),
                  Padding(
                    padding: space.screen,
                    child: _SummaryGrid(summary: summary),
                  ),
                  SizedBox(height: space.xxl),
                  Padding(
                    padding: space.screen,
                    child: const SectionLabel('What changed', index: 1),
                  ),
                  SizedBox(height: space.sm),
                  Padding(
                    padding: space.screen,
                    child: Text(
                      'Compared with ${DateLabels.monthYear(state.period.previous.range.start)}. '
                      'Worked out from your recorded transactions only.',
                      style: context.typeScale.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: space.md),
                  if (state.insights.isEmpty)
                    Padding(
                      padding: space.screen,
                      child: Text(
                        'Nothing stands out this month: no category moved '
                        'by more than ${InsightEngine.categoryChangeThreshold.round()}%.',
                        style: context.typeScale.body.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    for (final insight in state.insights)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          space.gutter,
                          0,
                          space.gutter,
                          space.md,
                        ),
                        child: _InsightCard(insight: insight),
                      ),
                  SizedBox(height: space.xl),
                  Padding(
                    padding: space.screen,
                    child: const SectionLabel('Where it went', index: 2),
                  ),
                  SizedBox(height: space.md),
                  Padding(
                    padding: space.screen,
                    child: state.breakdown.isEmpty
                        ? Text(
                            'No spending recorded this month.',
                            style: context.typeScale.body.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          )
                        : CategoryBreakdown(
                            shares: state.breakdown,
                            onCategoryPressed: (category) => context.goNamed(
                              AppRoute.activity.name,
                              queryParameters: ActivityLink.query(
                                type: TransactionType.expense,
                                categoryId: category.id,
                                range: state.period.range,
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: space.xxl),
                  Padding(
                    padding: space.screen,
                    child: const SectionLabel('Six months', index: 3),
                  ),
                  SizedBox(height: space.md),
                  Padding(
                    padding: space.screen,
                    child: _HistoryTable(history: state.history),
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

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InsightsCubit>();
    final colors = context.colors;
    return Row(
      children: [
        HeaderAction(
          icon: AppIcons.chevronLeft,
          label: 'Previous month',
          onPressed: cubit.previousMonth,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              DateLabels.monthYear(state.period.range.start),
              textAlign: TextAlign.center,
              style: context.typeScale.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        HeaderAction(
          icon: AppIcons.chevronRight,
          label: 'Next month',
          onPressed: state.canGoForward ? cubit.nextMonth : null,
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final rate = summary.savingsRate;
    final tiles = <(String, Widget)>[
      ('Income', MoneyText(summary.income, precision: MoneyPrecision.whole)),
      ('Spent', MoneyText(summary.expense, precision: MoneyPrecision.whole)),
      (
        'Net',
        MoneyText(
          summary.netCashFlow,
          signed: true,
          precision: MoneyPrecision.whole,
        ),
      ),
      (
        'Saved of income',
        Text(
          rate == null ? '—' : '${rate.round()}%',
          style: context.typeScale.moneyMedium.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        final width =
            (constraints.maxWidth - space.md * (columns - 1)) / columns;
        return Wrap(
          spacing: space.md,
          runSpacing: space.md,
          children: [
            for (final (label, value) in tiles)
              SizedBox(
                width: width,
                child: SurfaceCard(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: context.typeScale.label.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: space.xs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final f = MoneyFormatScope.of(context);
    final (
      IconData icon,
      String headline,
      String working,
      String? tag,
    ) = switch (insight) {
      CategoryChangeInsight(
        :final category,
        :final current,
        :final previous,
        :final percentChange,
      ) =>
        (
          percentChange > 0 ? AppIcons.trendUp : AppIcons.trendDown,
          '${category.name} spending ${percentChange > 0 ? 'rose' : 'fell'} '
              '${percentChange.abs().round()}%',
          '${f.format(current)} this month vs ${f.format(previous)} last '
              'month (${f.format((current - previous).abs())} '
              '${percentChange > 0 ? 'more' : 'less'}).',
          null,
        ),
      SavingsRateInsight(:final current, :final previous) => (
        current > previous ? AppIcons.trendUp : AppIcons.trendDown,
        'Savings rate ${current > previous ? 'improved' : 'dropped'} from '
            '${previous.round()}% to ${current.round()}%',
        'Savings rate is (income − spending) ÷ income. Transfers between '
            'your accounts are not counted.',
        null,
      ),
      IncomeShareInsight(:final category, :final amount, :final income) => (
        AppIcons.split,
        '${category.name} took ${(amount.ratioOf(income) * 100).round()}% '
            'of your income',
        '${f.format(amount)} of ${f.format(income)} earned this month.',
        null,
      ),
      SpendingPaceInsight(
        :final spentSoFar,
        :final projected,
        :final previousTotal,
        :final daysElapsed,
        :final daysInPeriod,
      ) =>
        (
          AppIcons.calendar,
          'On pace to spend about ${f.format(projected, precision: MoneyPrecision.whole)} '
              'this month',
          '${f.format(spentSoFar)} in the first $daysElapsed of '
              '$daysInPeriod days, extended at the same daily rate'
              '${previousTotal.isPositive ? '. Last month: ${f.format(previousTotal)}' : ''}.',
          'PROJECTION',
        ),
    };

    return SurfaceCard(
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.textPrimary),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: space.xxs),
                      child: Text(
                        tag,
                        style: context.typeScale.label.copyWith(
                          color: colors.watch,
                        ),
                      ),
                    ),
                  Text(
                    headline,
                    style: context.typeScale.bodyStrong.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: space.xxs),
                  Text(
                    working,
                    style: context.typeScale.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.history});

  final List<PeriodSummary> history;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final header = context.typeScale.label.copyWith(
      color: colors.textSecondary,
    );

    Widget cell(Widget child) => Padding(
      padding: EdgeInsets.symmetric(vertical: space.sm),
      child: Align(alignment: AlignmentDirectional.centerEnd, child: child),
    );

    return Table(
      columnWidths: const {0: FlexColumnWidth(1.2)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(horizontalInside: BorderSide(color: colors.line)),
      children: [
        TableRow(
          children: [
            Text('MONTH', style: header),
            cell(Text('IN', style: header)),
            cell(Text('OUT', style: header)),
            cell(Text('NET', style: header)),
          ],
        ),
        for (final month in history)
          TableRow(
            children: [
              Text(
                DateLabels.shortMonth(month.range.start).toUpperCase(),
                style: context.typeScale.label.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              cell(
                MoneyText(
                  month.income,
                  size: MoneySize.small,
                  precision: MoneyPrecision.whole,
                ),
              ),
              cell(
                MoneyText(
                  month.expense,
                  size: MoneySize.small,
                  precision: MoneyPrecision.whole,
                ),
              ),
              cell(
                MoneyText(
                  month.netCashFlow,
                  size: MoneySize.small,
                  signed: true,
                  precision: MoneyPrecision.whole,
                  color: month.netCashFlow.isNegative
                      ? colors.danger
                      : colors.textPrimary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
