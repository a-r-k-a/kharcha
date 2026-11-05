import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/domain/money.dart';
import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/session_cubit.dart';

/// First-run setup: what the app does, then a name and a currency.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _name = TextEditingController();

  // Form input before submission is purely local; the session cubit owns
  // everything from the moment the user taps "Get started".
  Currency _currency = Currency.inr;
  bool _attempted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _attempted = true);
    if (_name.text.trim().isEmpty) return;
    context.read<SessionCubit>().completeSetup(
      displayName: _name.text,
      currency: _currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final state = context.watch<SessionCubit>().state;
    final saving = state is SessionNeedsSetup && state.isSaving;
    final failure = state is SessionNeedsSetup ? state.failure : null;
    final formatter = MoneyFormatScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                space.gutter,
                space.xxl,
                space.gutter,
                space.xxl,
              ),
              children: [
                Entrance(
                  child: Text(
                    'KHARCHA',
                    style: context.typeScale.labelLarge.copyWith(
                      color: colors.accentStrong,
                    ),
                  ),
                ),
                SizedBox(height: space.lg),
                Entrance(
                  index: 1,
                  child: Semantics(
                    header: true,
                    child: Text(
                      'See where your money goes, and decide where it '
                      'should.',
                      style: context.typeScale.display.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: space.xxl),
                for (final (index, (icon, title, body)) in const [
                  (
                    AppIcons.accounts,
                    'Every account in one ledger',
                    'Bank, cash, wallets, cards and loans, with balances '
                        'that always add up.',
                  ),
                  (
                    AppIcons.transfer,
                    'Transfers stay transfers',
                    'Moving money between your own accounts never inflates '
                        'income or spending.',
                  ),
                  (
                    AppIcons.lock,
                    'Private by default',
                    'Encrypted on this device. No account or sign-in needed.',
                  ),
                ].indexed)
                  Entrance(
                    index: index + 2,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: space.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: colors.accentStrong),
                          SizedBox(width: space.md),
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
                                  body,
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
                  ),
                SizedBox(height: space.xl),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLength: UserProfile.nameLength,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_attempted) setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'WHAT SHOULD WE CALL YOU?',
                    hintText: 'Your first name',
                    counterText: '',
                    errorText: _attempted && _name.text.trim().isEmpty
                        ? 'Enter a name to continue.'
                        : null,
                  ),
                ),
                SizedBox(height: space.xl),
                Text(
                  'CURRENCY',
                  style: context.typeScale.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: space.sm),
                Wrap(
                  spacing: space.sm,
                  runSpacing: space.sm,
                  children: [
                    for (final currency in Currency.values)
                      AppChip(
                        label: _currencyLabel(
                          formatter.symbolOf(currency),
                          currency,
                        ),
                        selected: currency == _currency,
                        semanticLabel: currency.code,
                        onPressed: () => setState(() => _currency = currency),
                      ),
                  ],
                ),
                SizedBox(height: space.sm),
                Text(
                  'Every amount is kept in this currency. It can’t be '
                  'changed later.',
                  style: context.typeScale.bodySmall.copyWith(
                    color: colors.textTertiary,
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
                SizedBox(height: space.xxl),
                AppButton(
                  label: 'Get started',
                  expand: true,
                  isLoading: saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "₹ INR", or just "AED" where the symbol is the code itself.
String _currencyLabel(String symbol, Currency currency) {
  final trimmed = symbol.trim();
  return trimmed == currency.code ? trimmed : '$trimmed ${currency.code}';
}
