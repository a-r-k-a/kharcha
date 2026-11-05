import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/account_usecases.dart';

enum ReconcileStatus { editing, saving, done, notFound }

final class ReconcileState extends Equatable {
  const ReconcileState({
    required this.status,
    this.account,
    this.tracked,
    this.amountText = '',
    this.showErrors = false,
    this.failure,
    this.adjustment,
  });

  final ReconcileStatus status;
  final Account? account;

  /// The balance the app has on record.
  final Money? tracked;

  /// Unsigned real balance; liabilities enter the amount owed.
  final String amountText;
  final bool showErrors;
  final Failure? failure;

  /// The adjustment recorded when done; null if the balance already matched.
  final Money? adjustment;

  Money? get actual {
    final account = this.account;
    final tracked = this.tracked;
    if (account == null || tracked == null) return null;
    final value = Money.tryParse(amountText, currency: tracked.currency);
    if (value == null) return null;
    return account.type.isLiability ? -value : value;
  }

  /// actual − tracked, while the input is readable.
  Money? get difference {
    final actual = this.actual;
    final tracked = this.tracked;
    return actual == null || tracked == null ? null : actual - tracked;
  }

  ReconcileState copyWith({
    ReconcileStatus? status,
    String? amountText,
    bool? showErrors,
    Failure? Function()? failure,
    Money? adjustment,
  }) => ReconcileState(
    status: status ?? this.status,
    account: account,
    tracked: tracked,
    amountText: amountText ?? this.amountText,
    showErrors: showErrors ?? this.showErrors,
    failure: failure != null ? failure() : this.failure,
    adjustment: adjustment ?? this.adjustment,
  );

  @override
  List<Object?> get props => [
    status,
    account,
    tracked,
    amountText,
    showErrors,
    failure,
    adjustment,
  ];
}

class ReconcileCubit extends Cubit<ReconcileState> {
  ReconcileCubit({
    required LedgerRepository ledger,
    required this._reconcile,
    required this._accountId,
  }) : super(_initial(ledger, _accountId));

  final ReconcileAccount _reconcile;
  final String _accountId;

  static ReconcileState _initial(LedgerRepository repository, String id) {
    final ledger = repository.current;
    final account = ledger?.accountById(id);
    if (ledger == null || account == null) {
      return const ReconcileState(status: ReconcileStatus.notFound);
    }
    return ReconcileState(
      status: ReconcileStatus.editing,
      account: account,
      tracked: ledger.balanceOf(id),
    );
  }

  void setAmount(String text) {
    if (state.status != ReconcileStatus.editing) return;
    emit(state.copyWith(amountText: text, failure: () => null));
  }

  Future<void> submit() async {
    if (state.status != ReconcileStatus.editing) return;
    final actual = state.actual;
    if (actual == null) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: ReconcileStatus.saving, failure: () => null));
    final result = await _reconcile(_accountId, actual);
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(
          ReconcileState(
            status: ReconcileStatus.done,
            account: state.account,
            tracked: state.tracked,
            amountText: state.amountText,
            adjustment: value?.amount,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(
            status: ReconcileStatus.editing,
            failure: () => failure,
          ),
        );
    }
  }
}
