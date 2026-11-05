import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/ledger_violation.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/account_usecases.dart';
import '../../../ledger/presentation/category_style.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../transactions/presentation/widgets/form_pickers.dart';
import '../bloc/account_form_cubit.dart';

class AccountFormSheet extends StatelessWidget {
  const AccountFormSheet({super.key, this.accountId});

  /// Null to create a new account.
  final String? accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountFormCubit(
        ledger: context.read<LedgerRepository>(),
        save: context.read<SaveAccount>(),
        accountId: accountId,
      ),
      child: const _AccountFormView(),
    );
  }
}

class _AccountFormView extends StatelessWidget {
  const _AccountFormView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountFormCubit, AccountFormState>(
      listenWhen: (a, b) =>
          a.status != b.status && b.status == AccountFormStatus.saved,
      listener: (context, state) {
        showAppSnackBar(
          context,
          state.isEditing ? 'Account updated' : 'Account added',
        );
        context.pop();
      },
      builder: (context, state) {
        switch (state.status) {
          case AccountFormStatus.notFound || AccountFormStatus.unavailable:
            return const SheetScaffold(
              title: 'Account not found',
              body: EmptyStateView(
                icon: AppIcons.lost,
                title: 'Account not found',
                message: 'It may have been deleted on this device.',
              ),
            );
          case AccountFormStatus.editing ||
              AccountFormStatus.saving ||
              AccountFormStatus.saved:
            return SheetScaffold(
              title: state.isEditing ? 'Edit account' : 'New account',
              body: _AccountFormBody(state: state),
              action: AppButton(
                label: state.isEditing ? 'Save changes' : 'Add account',
                expand: true,
                isLoading: state.status == AccountFormStatus.saving,
                onPressed: () => context.read<AccountFormCubit>().submit(),
              ),
            );
        }
      },
    );
  }
}

class _AccountFormBody extends StatelessWidget {
  const _AccountFormBody({required this.state});

  final AccountFormState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountFormCubit>();
    final space = context.space;
    final violation = state.showErrors ? state.violation : null;
    final nameError = switch (violation) {
      LedgerViolation.nameEmpty ||
      LedgerViolation.nameTooLong ||
      LedgerViolation.nameTaken => violation?.message,
      _ => null,
    };
    final openingError = state.showErrors && state.openingBalance == null
        ? 'Enter a valid amount, like 25000 or 25000.50.'
        : null;
    final failure = state.failure;
    final otherError = failure != null
        ? failureMessage(failure)
        : (nameError == null ? violation?.message : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: state.name,
          onChanged: cubit.setName,
          autofocus: !state.isEditing,
          textCapitalization: TextCapitalization.words,
          maxLength: LedgerLimits.accountNameLength,
          decoration: InputDecoration(
            labelText: 'NAME',
            hintText: 'e.g. HDFC Savings',
            errorText: nameError,
            counterText: '',
          ),
        ),
        SizedBox(height: space.xl),
        FormSection(
          label: 'Type',
          child: Wrap(
            spacing: space.sm,
            runSpacing: space.sm,
            children: [
              for (final type in AccountType.values)
                AppChip(
                  label: type.shortLabel,
                  icon: type.icon,
                  selected: type == state.type,
                  semanticLabel: type.label,
                  onPressed: () => cubit.setType(type),
                ),
            ],
          ),
        ),
        SizedBox(height: space.xl),
        AmountField(
          currency: state.currency,
          value: state.openingText,
          onChanged: cubit.setOpening,
          label: state.type.isLiability
              ? 'Amount owed today'
              : (state.isEditing ? 'Opening balance' : 'Current balance'),
          errorText: openingError,
        ),
        SizedBox(height: space.sm),
        Text(
          state.type.isLiability
              ? 'What you owe on it right now. Spending on it adds to this; '
                    'payments from another account reduce it.'
              : 'Leave empty to start at zero. Transactions you record are '
                    'added on top.',
          style: context.typeScale.bodySmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: space.xl),
        TextFormField(
          initialValue: state.institution,
          onChanged: cubit.setInstitution,
          textCapitalization: TextCapitalization.words,
          maxLength: LedgerLimits.accountNameLength,
          decoration: const InputDecoration(
            labelText: 'BANK OR PROVIDER (OPTIONAL)',
            hintText: 'e.g. HDFC Bank',
            counterText: '',
          ),
        ),
        if (otherError != null) ...[
          SizedBox(height: space.lg),
          Text(
            otherError,
            style: context.typeScale.body.copyWith(
              color: context.colors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
