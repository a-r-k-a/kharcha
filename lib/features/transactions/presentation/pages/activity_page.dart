import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_route.dart';
import '../../../../core/domain/clock.dart';
import '../../../../core/domain/date_range.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/formatting/date_labels.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/transaction_query.dart';
import '../../../ledger/domain/usecases/transaction_usecases.dart';
import '../../../ledger/presentation/category_style.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';
import '../../../ledger/presentation/widgets/transaction_tile.dart';
import '../bloc/activity_bloc.dart';

/// All transactions: search, filters, grouped by day.
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key, this.filters = const TransactionQuery()});

  /// Filters from the route (e.g. a dashboard tap on "Income").
  final TransactionQuery filters;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ActivityBloc(
        ledger: context.read<LedgerRepository>(),
        delete: context.read<DeleteTransaction>(),
        restore: context.read<RestoreTransaction>(),
      )..add(ActivityStarted(filters)),
      child: _ActivityView(filters: filters),
    );
  }
}

class _ActivityView extends StatefulWidget {
  const _ActivityView({required this.filters});

  final TransactionQuery filters;

  @override
  State<_ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<_ActivityView> {
  final _searchController = TextEditingController();

  @override
  void didUpdateWidget(_ActivityView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The branch stays alive across tab switches, so new route filters
    // arrive as widget updates rather than a fresh bloc.
    if (widget.filters != oldWidget.filters) {
      context.read<ActivityBloc>().add(ActivityFiltersChanged(widget.filters));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUndo(BuildContext context, ActivityState state) {
    final deleted = state.lastDeleted;
    if (deleted == null) return;
    final bloc = context.read<ActivityBloc>();
    showAppSnackBar(
      context,
      '${deleted.type.label} deleted',
      actionLabel: 'UNDO',
      onAction: () => bloc.add(ActivityUndoRequested(deleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: MultiBlocListener(
          listeners: [
            BlocListener<ActivityBloc, ActivityState>(
              listenWhen: (a, b) => a.deletionCount != b.deletionCount,
              listener: _showUndo,
            ),
            BlocListener<ActivityBloc, ActivityState>(
              listenWhen: (a, b) => a.failureCount != b.failureCount,
              listener: (context, state) {
                final failure = state.failure;
                if (failure == null) return;
                showAppSnackBar(context, failureMessage(failure));
              },
            ),
          ],
          child: BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) => CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: PageHeader(title: 'Activity')),
                if (state.status == ActivityStatus.loading)
                  const SliverToBoxAdapter(child: _ActivitySkeleton())
                else if (!state.hasAnyTransactions)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: AppIcons.activity,
                      title: 'No transactions yet',
                      message:
                          'Everything you spend, earn and move between '
                          'accounts shows up here, newest first.',
                      action: AppButton(
                        label: 'Add expense',
                        icon: AppIcons.add,
                        onPressed: () =>
                            context.pushNamed(AppRoute.newTransaction.name),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _SearchAndFilters(
                      controller: _searchController,
                      state: state,
                    ),
                  ),
                  if (state.entries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateView(
                        icon: AppIcons.search,
                        title: 'Nothing matches',
                        message:
                            'Try a different search, or clear the filters '
                            'to see everything.',
                        action: AppButton(
                          label: 'Clear filters',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            _searchController.clear();
                            context.read<ActivityBloc>()
                              ..add(const ActivitySearchChanged(''))
                              ..add(
                                const ActivityFiltersChanged(
                                  TransactionQuery(),
                                ),
                              );
                          },
                        ),
                      ),
                    )
                  else
                    _ActivityList(state: state),
                ],
                // Clearance for the floating add key.
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.controller, required this.state});

  final TextEditingController controller;
  final ActivityState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ActivityBloc>();
    final colors = context.colors;
    final space = context.space;
    final query = state.query;
    final ledger = state.ledger;
    if (ledger == null) return const SizedBox.shrink();

    void setFilters(TransactionQuery next) =>
        bloc.add(ActivityFiltersChanged(next));

    final type = query.types.length == 1 ? query.types.first : null;
    final categoryId = query.categoryIds.length == 1
        ? query.categoryIds.first
        : null;
    final accountId = query.accountIds.length == 1
        ? query.accountIds.first
        : null;
    final category = categoryId == null
        ? null
        : ledger.categoryById(categoryId);
    final account = accountId == null ? null : ledger.accountById(accountId);
    final range = query.range;

    return Padding(
      padding: EdgeInsets.fromLTRB(space.gutter, 0, space.gutter, space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: (text) => bloc.add(ActivitySearchChanged(text)),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search payee, note, tag or amount',
              prefixIcon: Icon(AppIcons.search, color: colors.textSecondary),
              suffixIcon: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: Icon(AppIcons.close, color: colors.textSecondary),
                        onPressed: () {
                          controller.clear();
                          bloc.add(const ActivitySearchChanged(''));
                        },
                      ),
              ),
            ),
          ),
          SizedBox(height: space.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in const [
                  null,
                  TransactionType.expense,
                  TransactionType.income,
                  TransactionType.transfer,
                ])
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: space.sm),
                    child: AppChip(
                      label: option == null ? 'All' : '${option.label}s',
                      selected: type == option,
                      onPressed: () =>
                          setFilters(query.copyWith(types: {?option})),
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: space.sm),
                  child: AppChip(
                    label: range == null ? 'Any time' : _rangeLabel(range),
                    icon: AppIcons.calendar,
                    selected: range != null,
                    onPressed: () async {
                      final picked = await _pickRange(context, range);
                      if (picked == null) return;
                      setFilters(query.copyWith(range: () => picked.range));
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: space.sm),
                  child: AppChip(
                    label: category?.name ?? 'Category',
                    icon: AppIcons.categories,
                    selected: category != null,
                    onPressed: () async {
                      final picked = await _pickCategory(
                        context,
                        ledger,
                        categoryId,
                      );
                      if (picked == null) return;
                      setFilters(query.copyWith(categoryIds: {?picked.id}));
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: space.sm),
                  child: AppChip(
                    label: account?.name ?? 'Account',
                    icon: AppIcons.accounts,
                    selected: account != null,
                    onPressed: () async {
                      final picked = await _pickAccount(
                        context,
                        ledger,
                        accountId,
                      );
                      if (picked == null) return;
                      setFilters(query.copyWith(accountIds: {?picked.id}));
                    },
                  ),
                ),
                if (query.filterCount > 0)
                  AppChip(
                    label: 'Clear',
                    icon: AppIcons.close,
                    onPressed: () => setFilters(const TransactionQuery()),
                  ),
              ],
            ),
          ),
          SizedBox(height: space.md),
          Semantics(
            liveRegion: true,
            child: Text(
              state.resultCount == 1
                  ? '1 TRANSACTION'
                  : '${state.resultCount} TRANSACTIONS',
              style: context.typeScale.label.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(DateRange range) {
    final last = range.lastDay;
    final isWholeMonth =
        range.start.day == 1 &&
        range.end == DateTime(range.start.year, range.start.month + 1);
    if (isWholeMonth) return DateLabels.monthYear(range.start);
    return '${DateLabels.dayMonth(range.start)} – ${DateLabels.dayMonth(last)}';
  }

  Future<({DateRange? range})?> _pickRange(
    BuildContext context,
    DateRange? current,
  ) async {
    final now = context.read<Clock>().now();
    final thisMonth = Period(PeriodKind.month, now);
    final presets = <String, DateRange?>{
      'Any time': null,
      'This month': thisMonth.range,
      'Last month': thisMonth.previous.range,
      'Last 3 months': DateRange(
        DateTime(now.year, now.month - 2),
        thisMonth.range.end,
      ),
      'This year': Period(PeriodKind.year, now).range,
    };
    const custom = 'Custom range…';
    final selectedLabel = presets.entries
        .where((e) => e.value == current)
        .map((e) => e.key)
        .firstOrNull;
    final choice = await showOptionSheet<String>(
      context,
      title: 'Show transactions from',
      selected: selectedLabel ?? (current == null ? null : custom),
      options: [
        for (final label in presets.keys)
          SheetOption(value: label, label: label),
        const SheetOption(
          value: custom,
          label: custom,
          icon: AppIcons.calendar,
        ),
      ],
    );
    if (choice == null || !context.mounted) return null;
    if (choice != custom) return (range: presets[choice]);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.start, end: current.lastDay),
    );
    if (picked == null) return null;
    return (range: DateRange.days(picked.start, picked.end));
  }

  Future<({String? id})?> _pickCategory(
    BuildContext context,
    Ledger ledger,
    String? current,
  ) async {
    const any = '';
    final choice = await showOptionSheet<String>(
      context,
      title: 'Filter by category',
      selected: current ?? any,
      options: [
        const SheetOption(value: any, label: 'All categories'),
        for (final kind in CategoryKind.values)
          for (final category in ledger.topLevelCategories(kind))
            SheetOption(
              value: category.id,
              label: category.name,
              subtitle: kind.label,
              leading: CategoryAvatar(category: category, size: 32),
            ),
      ],
    );
    if (choice == null) return null;
    return (id: choice == any ? null : choice);
  }

  Future<({String? id})?> _pickAccount(
    BuildContext context,
    Ledger ledger,
    String? current,
  ) async {
    const any = '';
    final choice = await showOptionSheet<String>(
      context,
      title: 'Filter by account',
      selected: current ?? any,
      options: [
        const SheetOption(value: any, label: 'All accounts'),
        for (final account in ledger.accounts)
          SheetOption(
            value: account.id,
            label: account.name,
            subtitle: account.isArchived
                ? '${account.type.label} · archived'
                : account.type.label,
            icon: account.type.icon,
          ),
      ],
    );
    if (choice == null) return null;
    return (id: choice == any ? null : choice);
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.state});

  final ActivityState state;

  @override
  Widget build(BuildContext context) {
    final ledger = state.ledger;
    if (ledger == null) return const SliverToBoxAdapter();
    final now = context.read<Clock>().now();
    final space = context.space;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: space.gutter),
      sliver: SliverList.builder(
        itemCount: state.entries.length,
        itemBuilder: (context, index) {
          final entry = state.entries[index];
          final Widget child = switch (entry) {
            ActivityDayHeader(:final day, :final net) => _DayHeader(
              label: DateLabels.day(day, now),
              net: net,
            ),
            ActivityItem(:final transaction) => _SwipeToDelete(
              key: ValueKey(transaction.id),
              transaction: transaction,
              child: TransactionTile(
                transaction: transaction,
                ledger: ledger,
                onPressed: () => context.pushNamed(
                  AppRoute.transactionDetails.name,
                  pathParameters: {AppRoute.transactionIdParam: transaction.id},
                ),
              ),
            ),
          };
          return Entrance(index: index, child: child);
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.net});

  final String label;
  final Money net;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return Padding(
      padding: EdgeInsets.only(top: space.lg, bottom: space.xs),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: context.typeScale.label.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(width: space.md),
            Expanded(
              child: Container(
                height: context.elevation.hairline,
                color: colors.line,
              ),
            ),
            SizedBox(width: space.md),
            if (!net.isZero)
              MoneyText(
                net,
                size: MoneySize.small,
                signed: true,
                color: colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    super.key,
    required this.transaction,
    required this.child,
  });

  final Transaction transaction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey('dismiss-${transaction.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<ActivityBloc>().add(
        ActivityDeleteRequested(transaction.id),
      ),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsetsDirectional.only(end: context.space.lg),
        color: colors.danger,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DELETE',
              style: context.typeScale.label.copyWith(color: colors.onDanger),
            ),
            SizedBox(width: context.space.sm),
            Icon(AppIcons.delete, color: colors.onDanger),
          ],
        ),
      ),
      child: Semantics(
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Delete'): () => context
              .read<ActivityBloc>()
              .add(ActivityDeleteRequested(transaction.id)),
        },
        child: child,
      ),
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return SkeletonGroup(
      semanticLabel: 'Loading transactions',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: space.gutter),
        child: Column(
          children: [
            const SkeletonBox(height: 48),
            SizedBox(height: space.lg),
            for (var i = 0; i < 6; i++) ...[
              Row(
                children: [
                  const SkeletonBox(width: 40, height: 40),
                  SizedBox(width: space.md),
                  const Expanded(child: SkeletonText()),
                  SizedBox(width: space.md),
                  const SkeletonBox(width: 64, height: 16),
                ],
              ),
              SizedBox(height: space.lg),
            ],
          ],
        ),
      ),
    );
  }
}
