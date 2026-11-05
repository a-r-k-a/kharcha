import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/account_usecases.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../bloc/reconcile_cubit.dart';

/// Match the tracked balance to the real one (e.g. from a bank statement).
class ReconcileSheet extends StatelessWidget {
  const ReconcileSheet({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReconcileCubit(
        ledger: context.read<LedgerRepository>(),
        reconcile: context.read<ReconcileAccount>(),
        accountId: accountId,
      ),
      child: BlocConsumer<ReconcileCubit, ReconcileState>(
        listenWhen: (a, b) => a.status != b.status,
        listener: (context, state) {
          if (state.status != ReconcileStatus.done) return;
          final adjustment = state.adjustment;
          final formatter = MoneyFormatScope.of(context);
          showAppSnackBar(
            context,
            adjustment == null
                ? 'Already in balance. Nothing to adjust.'
                : 'Adjusted by ${formatter.format(adjustment, signed: true)}',
          );
          context.pop();
        },
        builder: (context, state) {
          final account = state.account;
          final tracked = state.tracked;
          if (account == null || tracked == null) {
            return const SheetScaffold(
              title: 'Account not found',
              body: EmptyStateView(
                icon: AppIcons.lost,
                title: 'Account not found',
                message: 'It may have been deleted on this device.',
              ),
            );
          }
          final cubit = context.read<ReconcileCubit>();
          final colors = context.colors;
          final space = context.space;
          final difference = state.difference;
          final failure = state.failure;
          return SheetScaffold(
            eyebrow: account.name,
            title: 'Reconcile balance',
            action: AppButton(
              label: 'Update balance',
              expand: true,
              isLoading: state.status == ReconcileStatus.saving,
              onPressed: cubit.submit,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TRACKED BALANCE',
                  style: context.typeScale.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: space.xs),
                MoneyText(tracked, size: MoneySize.large),
                SizedBox(height: space.xl),
                AmountField(
                  currency: tracked.currency,
                  value: state.amountText,
                  onChanged: cubit.setAmount,
                  autofocus: true,
                  label: account.type.isLiability
                      ? 'Actually owed'
                      : 'Actual balance',
                  errorText: state.showErrors && state.actual == null
                      ? 'Enter the balance shown by your bank or wallet.'
                      : null,
                ),
                SizedBox(height: space.md),
                if (difference != null && !difference.isZero)
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Text(
                          'ADJUSTMENT ',
                          style: context.typeScale.label.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        MoneyText(
                          difference,
                          size: MoneySize.small,
                          signed: true,
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: space.md),
                Text(
                  'The difference is recorded as a balance adjustment. It '
                  'changes this balance but never counts as income or '
                  'spending.',
                  style: context.typeScale.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (failure != null) ...[
                  SizedBox(height: space.lg),
                  Text(
                    failureMessage(failure),
                    style: context.typeScale.body.copyWith(
                      color: colors.danger,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
