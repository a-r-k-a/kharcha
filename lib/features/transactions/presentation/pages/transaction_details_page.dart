import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_route.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/formatting/date_labels.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/transaction_usecases.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';
import '../../../ledger/presentation/widgets/transaction_tile.dart';
import '../bloc/transaction_details_cubit.dart';

class TransactionDetailsPage extends StatelessWidget {
  const TransactionDetailsPage({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionDetailsCubit(
        ledger: context.read<LedgerRepository>(),
        delete: context.read<DeleteTransaction>(),
        id: transactionId,
      ),
      child: const _DetailsView(),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView();

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this transaction?',
      message:
          'It will be removed from your history and balances. You can undo '
          'right after.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<TransactionDetailsCubit>().delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionDetailsCubit, TransactionDetailsState>(
      listenWhen: (a, b) => a.status != b.status || a.failure != b.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          showAppSnackBar(context, failureMessage(failure));
          return;
        }
        final deleted = state.transaction;
        if (state.status == TransactionDetailsStatus.deleted &&
            deleted != null) {
          // Capture before popping: this page's context goes away.
          final restore = context.read<RestoreTransaction>();
          showAppSnackBar(
            context,
            '${deleted.type.label} deleted',
            actionLabel: 'UNDO',
            onAction: () => restore(deleted),
          );
          context.pop();
        }
      },
      builder: (context, state) {
        final transaction = state.transaction;
        final ledger = state.ledger;
        return Scaffold(
          body: SafeArea(
            child: switch (state.status) {
              TransactionDetailsStatus.loading => const SizedBox.shrink(),
              TransactionDetailsStatus.missing => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(title: '', showBack: true),
                  EmptyStateView(
                    icon: AppIcons.lost,
                    title: 'Transaction not found',
                    message: 'It may have been deleted.',
                    action: AppButton(
                      label: 'See all activity',
                      onPressed: () => context.goNamed(AppRoute.activity.name),
                    ),
                  ),
                ],
              ),
              TransactionDetailsStatus.found ||
              TransactionDetailsStatus.deleted =>
                transaction == null || ledger == null
                    ? const SizedBox.shrink()
                    : _DetailsBody(
                        transaction: transaction,
                        ledger: ledger,
                        onDelete: () => _confirmDelete(context),
                      ),
            },
          ),
        );
      },
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.transaction,
    required this.ledger,
    required this.onDelete,
  });

  final Transaction transaction;
  final Ledger ledger;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final t = transaction;
    final description = TransactionTile.describe(t, ledger);
    final idParam = {AppRoute.transactionIdParam: t.id};
    final canEdit = t.type != TransactionType.adjustment;

    String accountName(String? id) =>
        (id == null ? null : ledger.accountById(id)?.name) ?? 'Unknown account';

    final rows = <(String, String)>[
      if (t.type == TransactionType.transfer) ...[
        ('From', accountName(t.accountId)),
        ('To', accountName(t.counterpartyAccountId)),
      ] else
        (
          t.type == TransactionType.income ? 'Received in' : 'Account',
          accountName(t.accountId),
        ),
      (
        'Date',
        '${DateLabels.fullDate(t.occurredAt)}, ${DateLabels.time(t.occurredAt)}',
      ),
      if (t.paymentMethod case final method?) ('Payment method', method.label),
      if (t.tags.isNotEmpty) ('Tags', t.tags.map((tag) => '#$tag').join('  ')),
      if (t.isReimbursable) ('Reimbursable', 'Yes, expected back'),
      if (t.note.isNotEmpty) ('Note', t.note),
    ];

    final (Money amount, bool signed) = switch (t.type) {
      TransactionType.expense => (-t.amount, false),
      TransactionType.income || TransactionType.adjustment => (t.amount, true),
      TransactionType.transfer => (t.amount, false),
    };

    return ListView(
      padding: EdgeInsets.only(bottom: space.xxxl),
      children: [
        PageHeader(
          title: '',
          showBack: true,
          actions: [
            if (canEdit)
              HeaderAction(
                icon: AppIcons.duplicate,
                label: 'Duplicate',
                onPressed: () => context.pushNamed(
                  AppRoute.newTransaction.name,
                  queryParameters: {RouteQuery.from: t.id},
                ),
              ),
            HeaderAction(
              icon: AppIcons.delete,
              label: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
        Padding(
          padding: space.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.type.label.toUpperCase(),
                style: context.typeScale.label.copyWith(
                  color: t.type == TransactionType.income
                      ? colors.accentStrong
                      : colors.textSecondary,
                ),
              ),
              SizedBox(height: space.sm),
              MoneyText(amount, size: MoneySize.hero, signed: signed),
              SizedBox(height: space.md),
              Text(
                description.title,
                style: context.typeScale.title.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: space.xl),
              if (t.allocations.isNotEmpty) ...[
                SectionLabel(t.isSplit ? 'Split' : 'Category'),
                SizedBox(height: space.md),
                for (final allocation in t.allocations)
                  Padding(
                    padding: EdgeInsets.only(bottom: space.sm),
                    child: Row(
                      children: [
                        CategoryAvatar(
                          category: ledger.categoryById(allocation.categoryId),
                          size: 36,
                        ),
                        SizedBox(width: space.md),
                        Expanded(
                          child: Text(
                            _categoryPath(allocation.categoryId),
                            style: context.typeScale.bodyStrong.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (t.isSplit)
                          MoneyText(allocation.amount, size: MoneySize.small),
                      ],
                    ),
                  ),
                SizedBox(height: space.lg),
              ],
              const SectionLabel('Details'),
              SizedBox(height: space.sm),
              SurfaceCard(
                padding: EdgeInsets.symmetric(horizontal: space.lg),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const Divider(),
                      _DetailRow(label: rows[i].$1, value: rows[i].$2),
                    ],
                  ],
                ),
              ),
              SizedBox(height: space.xl),
              if (canEdit)
                AppButton(
                  label: 'Edit transaction',
                  icon: AppIcons.edit,
                  expand: true,
                  onPressed: () => context.pushNamed(
                    AppRoute.editTransaction.name,
                    pathParameters: idParam,
                  ),
                )
              else
                Text(
                  'Balance adjustments come from reconciling an account. '
                  'Delete this one and reconcile again to change it.',
                  style: context.typeScale.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              SizedBox(height: space.md),
              Text(
                'Added ${DateLabels.fullDate(t.createdAt)}'
                '${t.updatedAt != t.createdAt ? ' · edited ${DateLabels.fullDate(t.updatedAt)}' : ''}',
                style: context.typeScale.label.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _categoryPath(String id) {
    final category = ledger.categoryById(id);
    if (category == null) return 'Deleted category';
    final parentId = category.parentId;
    final parent = parentId == null ? null : ledger.categoryById(parentId);
    return parent == null ? category.name : '${parent.name} › ${category.name}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.space.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label.toUpperCase(),
                style: context.typeScale.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: context.typeScale.body.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
