import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_route.dart';
import '../../../../core/domain/clock.dart';
import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/ledger_violation.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/transaction_usecases.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../bloc/transaction_form_cubit.dart';
import '../widgets/form_pickers.dart';

/// Add, edit or duplicate a transaction, presented as a route-backed sheet.
class TransactionFormSheet extends StatelessWidget {
  const TransactionFormSheet({super.key, required this.intent});

  final TransactionFormIntent intent;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionFormCubit(
        ledger: context.read<LedgerRepository>(),
        save: context.read<SaveTransaction>(),
        clock: context.read<Clock>(),
        intent: intent,
      ),
      child: const _TransactionFormView(),
    );
  }
}

class _TransactionFormView extends StatelessWidget {
  const _TransactionFormView();

  String _title(TransactionFormState state) {
    final noun = state.type.label.toLowerCase();
    return state.isEditing ? 'Edit $noun' : 'New $noun';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == TransactionFormStatus.saved,
      listener: (context, state) {
        showAppSnackBar(
          context,
          state.isEditing ? 'Changes saved' : '${state.type.label} recorded',
        );
        context.pop();
      },
      builder: (context, state) {
        final ledger = state.ledger;
        switch (state.status) {
          case TransactionFormStatus.unavailable:
            return const _Unavailable(
              title: 'Your books aren’t open',
              message: 'Finish setting up the app, then try again.',
            );
          case TransactionFormStatus.notFound:
            return const _Unavailable(
              title: 'Transaction not found',
              message: 'It may have been deleted on this device.',
            );
          case TransactionFormStatus.editing ||
              TransactionFormStatus.saving ||
              TransactionFormStatus.saved:
            if (ledger == null) {
              return const _Unavailable(
                title: 'Your books aren’t open',
                message: 'Finish setting up the app, then try again.',
              );
            }
            if (ledger.activeAccounts.isEmpty && !state.isEditing) {
              return const _NeedsAccount();
            }
            return SheetScaffold(
              title: _title(state),
              body: _FormBody(state: state, ledger: ledger),
              action: AppButton(
                label: state.isEditing ? 'Save changes' : 'Save',
                expand: true,
                isLoading: state.status == TransactionFormStatus.saving,
                onPressed: () => context.read<TransactionFormCubit>().submit(),
              ),
            );
        }
      },
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({required this.state, required this.ledger});

  final TransactionFormState state;
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    final space = context.space;
    final isTransfer = state.type == TransactionType.transfer;
    final isAdjustment = state.type == TransactionType.adjustment;
    final general = state.generalError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isAdjustment) ...[
          AppSegmentedControl<TransactionType>(
            semanticLabel: 'Transaction type',
            selected: state.type,
            onChanged: cubit.setType,
            options: const [
              SegmentOption(
                TransactionType.expense,
                'Expense',
                icon: AppIcons.expense,
              ),
              SegmentOption(
                TransactionType.income,
                'Income',
                icon: AppIcons.income,
              ),
              SegmentOption(
                TransactionType.transfer,
                'Transfer',
                icon: AppIcons.transfer,
              ),
            ],
          ),
          SizedBox(height: space.xl),
        ],
        AmountField(
          currency: ledger.currency,
          value: state.amountText,
          onChanged: cubit.setAmount,
          autofocus: !state.isEditing,
          errorText: state.errorFor(TransactionField.amount),
        ),
        SizedBox(height: space.lg),
        TextFormField(
          initialValue: state.title,
          onChanged: cubit.setTitle,
          textCapitalization: TextCapitalization.sentences,
          maxLength: LedgerLimits.titleLength,
          decoration: InputDecoration(
            labelText: switch (state.type) {
              TransactionType.income => 'FROM',
              TransactionType.transfer => 'NOTE FOR THIS TRANSFER',
              _ => 'WHAT FOR',
            },
            hintText: switch (state.type) {
              TransactionType.income => 'e.g. Acme Corp salary',
              TransactionType.transfer => 'e.g. ATM withdrawal',
              _ => 'e.g. Groceries at DMart',
            },
            errorText: state.errorFor(TransactionField.title),
            counterText: '',
          ),
        ),
        if (state.hasCategories) ...[
          SizedBox(height: space.xl),
          FormSection(
            label: state.isSplit ? 'Split across categories' : 'Category',
            errorText: state.errorFor(TransactionField.category),
            trailing: AppChip(
              label: state.isSplit ? 'Single' : 'Split',
              icon: AppIcons.split,
              selected: state.isSplit,
              onPressed: () => cubit.setSplit(!state.isSplit),
              semanticLabel: state.isSplit
                  ? 'Use a single category'
                  : 'Split across categories',
            ),
            child: AnimatedSwitcher(
              duration: context.motionDuration(context.motion.medium),
              child: state.isSplit
                  ? _SplitEditor(
                      key: const ValueKey('split'),
                      state: state,
                      ledger: ledger,
                    )
                  : CategoryPicker(
                      key: ValueKey(state.categoryKind),
                      ledger: ledger,
                      kind: state.categoryKind,
                      selectedId: state.categoryId,
                      onSelected: cubit.setCategory,
                    ),
            ),
          ),
        ],
        SizedBox(height: space.xl),
        FormSection(
          label: switch (state.type) {
            TransactionType.income => 'Received in',
            TransactionType.transfer => 'From',
            TransactionType.adjustment => 'Account',
            TransactionType.expense => 'Paid from',
          },
          errorText: state.errorFor(TransactionField.account),
          child: AccountChoices(
            ledger: ledger,
            selectedId: state.accountId,
            onSelected: cubit.setAccount,
            extraAccountId: state.isEditing ? state.accountId : null,
          ),
        ),
        if (isTransfer) ...[
          SizedBox(height: space.lg),
          FormSection(
            label: 'To',
            errorText: state.errorFor(TransactionField.destination),
            child: AccountChoices(
              ledger: ledger,
              selectedId: state.counterpartyAccountId,
              onSelected: cubit.setDestination,
              extraAccountId: state.isEditing
                  ? state.counterpartyAccountId
                  : null,
            ),
          ),
        ],
        if (!isAdjustment) ...[
          SizedBox(height: space.xl),
          FormSection(
            label: 'Payment method',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final method in PaymentMethod.values)
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: space.sm),
                      child: AppChip(
                        label: method.label,
                        selected: method == state.paymentMethod,
                        onPressed: () => cubit.setPaymentMethod(method),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: space.xl),
        FormSection(
          label: 'Date',
          child: DateChoices(
            value: state.occurredAt,
            now: context.read<Clock>().now(),
            onChanged: cubit.setOccurredAt,
          ),
        ),
        SizedBox(height: space.xl),
        _MoreDetails(state: state),
        if (general != null) ...[
          SizedBox(height: space.lg),
          Semantics(
            liveRegion: true,
            child: Text(
              general,
              style: context.typeScale.body.copyWith(
                color: context.colors.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SplitEditor extends StatelessWidget {
  const _SplitEditor({super.key, required this.state, required this.ledger});

  final TransactionFormState state;
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionFormCubit>();
    final colors = context.colors;
    final space = context.space;
    final remaining = state.splitRemaining;
    final formatter = MoneyFormatScope.of(context);
    final categories = [
      for (final top in ledger.topLevelCategories(state.categoryKind)) ...[
        top,
        ...ledger.subcategoriesOf(top.id),
      ],
    ];

    final (String status, Color statusColor) = switch (remaining) {
      null => ('Enter the total first', colors.textSecondary),
      final r when r.isZero => ('Adds up to the total', colors.accentStrong),
      final r when r.isPositive => (
        '${formatter.format(r)} left to assign',
        colors.textSecondary,
      ),
      final r => ('Over by ${formatter.format(r.abs())}', colors.danger),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < state.splits.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: state.splits[i].categoryId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: 'CATEGORY ${i + 1}'),
                    items: [
                      for (final Category c in categories)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.isTopLevel ? c.name : '   ${c.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null) cubit.setSplitCategory(i, id);
                    },
                  ),
                ),
                SizedBox(width: space.sm),
                Expanded(
                  flex: 2,
                  child: AmountField(
                    currency: ledger.currency,
                    value: state.splits[i].amountText,
                    onChanged: (text) => cubit.setSplitAmount(i, text),
                    size: AmountFieldSize.compact,
                  ),
                ),
                if (state.splits.length > 2)
                  Pressable(
                    onPressed: () => cubit.removeSplitLine(i),
                    tooltip: 'Remove line ${i + 1}',
                    semanticLabel: 'Remove line ${i + 1}',
                    child: Icon(AppIcons.remove, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  style: context.typeScale.bodySmall.copyWith(
                    color: statusColor,
                  ),
                ),
              ),
            ),
            AppButton(
              label: 'Add line',
              icon: AppIcons.add,
              variant: AppButtonVariant.ghost,
              onPressed: cubit.addSplitLine,
            ),
          ],
        ),
      ],
    );
  }
}

/// Note, tags and the reimbursable flag, folded away until wanted.
class _MoreDetails extends StatefulWidget {
  const _MoreDetails({required this.state});

  final TransactionFormState state;

  @override
  State<_MoreDetails> createState() => _MoreDetailsState();
}

class _MoreDetailsState extends State<_MoreDetails> {
  // Purely local disclosure state; open from the start when editing an
  // entry that already has details.
  late bool _expanded =
      widget.state.note.isNotEmpty ||
      widget.state.tags.isNotEmpty ||
      widget.state.isReimbursable;
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(TransactionFormCubit cubit) {
    final text = _tagController.text;
    for (final tag in text.split(',')) {
      if (tag.trim().isNotEmpty) cubit.addTag(tag);
    }
    _tagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<TransactionFormCubit>();
    final colors = context.colors;
    final space = context.space;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onPressed: () => setState(() => _expanded = !_expanded),
          semanticLabel: _expanded ? 'Hide details' : 'Add note, tags',
          child: ExcludeSemantics(
            child: Row(
              children: [
                Text(
                  'NOTE, TAGS & MORE',
                  style: context.typeScale.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: context.motionDuration(context.motion.fast),
                  child: Icon(
                    AppIcons.chevronDown,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: context.motionDuration(context.motion.medium),
          curve: context.motion.enter,
          alignment: AlignmentDirectional.topStart,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: state.note,
                        onChanged: cubit.setNote,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: LedgerLimits.noteLength,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'NOTE',
                          errorText: state.errorFor(TransactionField.note),
                        ),
                      ),
                      SizedBox(height: space.md),
                      TextField(
                        controller: _tagController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addTag(cubit),
                        decoration: InputDecoration(
                          labelText: 'TAGS',
                          hintText: 'Type a tag and press enter',
                          errorText: state.errorFor(TransactionField.tags),
                          suffixIcon: Pressable(
                            onPressed: () => _addTag(cubit),
                            tooltip: 'Add tag',
                            semanticLabel: 'Add tag',
                            child: Icon(
                              AppIcons.add,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (state.tags.isNotEmpty) ...[
                        SizedBox(height: space.sm),
                        Wrap(
                          spacing: space.sm,
                          runSpacing: space.sm,
                          children: [
                            for (final tag in state.tags)
                              AppChip(
                                label: '#$tag',
                                trailingIcon: AppIcons.close,
                                semanticLabel: 'Remove tag $tag',
                                onPressed: () => cubit.removeTag(tag),
                              ),
                          ],
                        ),
                      ],
                      if (state.type == TransactionType.expense) ...[
                        SizedBox(height: space.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: state.isReimbursable,
                          onChanged: cubit.setReimbursable,
                          title: Text(
                            'Reimbursable',
                            style: context.typeScale.bodyStrong.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Paid for someone else. Record the repayment as '
                            'income under Refunds when it arrives.',
                            style: context.typeScale.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _NeedsAccount extends StatelessWidget {
  const _NeedsAccount();

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Add an account first',
      body: EmptyStateView(
        icon: AppIcons.accounts,
        title: 'Where does the money live?',
        message:
            'Transactions belong to an account: a bank account, cash or a '
            'card. Add one, then record this transaction.',
        action: AppButton(
          label: 'Add account',
          icon: AppIcons.add,
          onPressed: () =>
              context.pushReplacementNamed(AppRoute.newAccount.name),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: title,
      body: EmptyStateView(icon: AppIcons.lost, title: title, message: message),
    );
  }
}
