import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/clock.dart';
import '../../../../core/domain/date_range.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';
import '../../../ledger/domain/usecases/account_usecases.dart';
import '../../../ledger/presentation/bloc/ledger_watcher.dart';

enum AccountDetailsStatus { loading, found, missing, deleted }

final class AccountDetailsState extends Equatable {
  const AccountDetailsState({
    this.status = AccountDetailsStatus.loading,
    this.ledger,
    this.account,
    this.balance,
    this.thisMonth,
    this.transactions = const [],
    this.failure,
    this.failureCount = 0,
  });

  final AccountDetailsStatus status;
  final Ledger? ledger;
  final Account? account;
  final Money? balance;

  /// Money in and out of this account in the current month.
  final PeriodSummary? thisMonth;

  /// Every transaction touching the account, newest first.
  final List<Transaction> transactions;
  final Failure? failure;
  final int failureCount;

  AccountDetailsState copyWith({
    AccountDetailsStatus? status,
    Failure? failure,
    int? failureCount,
  }) => AccountDetailsState(
    status: status ?? this.status,
    ledger: ledger,
    account: account,
    balance: balance,
    thisMonth: thisMonth,
    transactions: transactions,
    failure: failure ?? this.failure,
    failureCount: failureCount ?? this.failureCount,
  );

  @override
  List<Object?> get props => [
    status,
    ledger,
    account,
    balance,
    thisMonth,
    transactions,
    failure,
    failureCount,
  ];
}

class AccountDetailsCubit extends Cubit<AccountDetailsState>
    with LedgerWatcher {
  AccountDetailsCubit({
    required LedgerRepository ledger,
    required this._setArchived,
    required this._delete,
    required this._clock,
    required this._id,
  }) : super(const AccountDetailsState()) {
    watchLedger(ledger, _onLedger);
  }

  final SetAccountArchived _setArchived;
  final DeleteAccount _delete;
  final Clock _clock;
  final String _id;

  void _onLedger(Ledger ledger) {
    if (state.status == AccountDetailsStatus.deleted) return;
    final account = ledger.accountById(_id);
    if (account == null) {
      emit(const AccountDetailsState(status: AccountDetailsStatus.missing));
      return;
    }
    emit(
      AccountDetailsState(
        status: AccountDetailsStatus.found,
        ledger: ledger,
        account: account,
        balance: ledger.balanceOf(_id),
        thisMonth: LedgerAnalytics.summarize(
          ledger,
          Period(PeriodKind.month, _clock.now()).range,
          accountId: _id,
        ),
        transactions: ledger.transactions
            .where((t) => t.touchesAccount(_id))
            .toList(),
        failureCount: state.failureCount,
      ),
    );
  }

  Future<void> setArchived(bool archived) async {
    final result = await _setArchived(_id, archived: archived);
    if (result case Err(:final failure)) _report(failure);
  }

  Future<void> delete() async {
    final result = await _delete(_id);
    if (isClosed) return;
    switch (result) {
      case Ok():
        emit(state.copyWith(status: AccountDetailsStatus.deleted));
      case Err(:final failure):
        _report(failure);
    }
  }

  void _report(Failure failure) {
    if (isClosed) return;
    emit(
      state.copyWith(failure: failure, failureCount: state.failureCount + 1),
    );
  }
}
