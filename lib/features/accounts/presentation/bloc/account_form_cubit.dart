import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/ledger_violation.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/account_usecases.dart';
import '../../../ledger/domain/usecases/drafts.dart';

enum AccountFormStatus { editing, saving, saved, notFound, unavailable }

final class AccountFormState extends Equatable {
  const AccountFormState({
    required this.status,
    this.currency = Currency.inr,
    this.editingId,
    this.name = '',
    this.type = AccountType.savings,
    this.openingText = '',
    this.institution = '',
    this.showErrors = false,
    this.violation,
    this.failure,
    this.savedId,
  });

  final AccountFormStatus status;
  final Currency currency;
  final String? editingId;
  final String name;
  final AccountType type;

  /// Unsigned: liabilities are entered as the amount owed.
  final String openingText;
  final String institution;
  final bool showErrors;
  final LedgerViolation? violation;
  final Failure? failure;

  /// The saved account's id, once saved.
  final String? savedId;

  bool get isEditing => editingId != null;

  /// Empty input means a zero opening balance.
  Money? get openingBalance {
    if (openingText.trim().isEmpty) return Money.zero(currency: currency);
    final value = Money.tryParse(openingText, currency: currency);
    if (value == null) return null;
    return type.isLiability ? -value : value;
  }

  AccountFormState copyWith({
    AccountFormStatus? status,
    String? name,
    AccountType? type,
    String? openingText,
    String? institution,
    bool? showErrors,
    LedgerViolation? Function()? violation,
    Failure? Function()? failure,
    String? savedId,
  }) {
    return AccountFormState(
      status: status ?? this.status,
      currency: currency,
      editingId: editingId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingText: openingText ?? this.openingText,
      institution: institution ?? this.institution,
      showErrors: showErrors ?? this.showErrors,
      violation: violation != null ? violation() : this.violation,
      failure: failure != null ? failure() : this.failure,
      savedId: savedId ?? this.savedId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currency,
    editingId,
    name,
    type,
    openingText,
    institution,
    showErrors,
    violation,
    failure,
    savedId,
  ];
}

class AccountFormCubit extends Cubit<AccountFormState> {
  AccountFormCubit({
    required LedgerRepository ledger,
    required this._save,
    String? accountId,
  }) : super(_initial(ledger, accountId));

  final SaveAccount _save;

  static AccountFormState _initial(LedgerRepository repository, String? id) {
    final ledger = repository.current;
    if (ledger == null) {
      return const AccountFormState(status: AccountFormStatus.unavailable);
    }
    if (id == null) {
      return AccountFormState(
        status: AccountFormStatus.editing,
        currency: ledger.currency,
      );
    }
    final account = ledger.accountById(id);
    if (account == null) {
      return const AccountFormState(status: AccountFormStatus.notFound);
    }
    final opening = account.openingBalance.abs();
    final whole = opening.minorUnits ~/ ledger.currency.minorPerMajor;
    final fraction = opening.minorUnits % ledger.currency.minorPerMajor;
    return AccountFormState(
      status: AccountFormStatus.editing,
      currency: ledger.currency,
      editingId: id,
      name: account.name,
      type: account.type,
      openingText: opening.isZero
          ? ''
          : fraction == 0
          ? '$whole'
          : '$whole.${fraction.toString().padLeft(ledger.currency.decimals, '0')}',
      institution: account.institution,
    );
  }

  void setName(String value) => _update(state.copyWith(name: value));

  void setType(AccountType value) => _update(state.copyWith(type: value));

  void setOpening(String value) => _update(state.copyWith(openingText: value));

  void setInstitution(String value) =>
      _update(state.copyWith(institution: value));

  Future<void> submit() async {
    if (state.status != AccountFormStatus.editing) return;
    final opening = state.openingBalance;
    if (opening == null) {
      emit(state.copyWith(showErrors: true, violation: () => null));
      return;
    }
    emit(
      state.copyWith(
        status: AccountFormStatus.saving,
        violation: () => null,
        failure: () => null,
      ),
    );
    final result = await _save(
      AccountDraft(
        id: state.editingId,
        name: state.name,
        type: state.type,
        openingBalance: opening,
        institution: state.institution,
      ),
    );
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(status: AccountFormStatus.saved, savedId: value.id),
        );
      case Err(:final failure):
        final violation = LedgerViolation.of(failure);
        emit(
          state.copyWith(
            status: AccountFormStatus.editing,
            showErrors: true,
            violation: () => violation,
            failure: () => violation == null ? failure : null,
          ),
        );
    }
  }

  void _update(AccountFormState next) {
    if (state.status != AccountFormStatus.editing) return;
    emit(next.copyWith(violation: () => null, failure: () => null));
  }
}
