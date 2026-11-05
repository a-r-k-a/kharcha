import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/result.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/transaction_usecases.dart';
import '../../../ledger/presentation/bloc/ledger_watcher.dart';

enum TransactionDetailsStatus { loading, found, missing, deleted }

final class TransactionDetailsState extends Equatable {
  const TransactionDetailsState({
    this.status = TransactionDetailsStatus.loading,
    this.ledger,
    this.transaction,
    this.failure,
  });

  final TransactionDetailsStatus status;
  final Ledger? ledger;

  /// The live transaction, or the deleted one after a delete.
  final Transaction? transaction;
  final Failure? failure;

  @override
  List<Object?> get props => [status, ledger, transaction, failure];
}

class TransactionDetailsCubit extends Cubit<TransactionDetailsState>
    with LedgerWatcher {
  TransactionDetailsCubit({
    required LedgerRepository ledger,
    required this._delete,
    required this._id,
  }) : super(const TransactionDetailsState()) {
    watchLedger(ledger, _onLedger);
  }

  final DeleteTransaction _delete;
  final String _id;

  void _onLedger(Ledger ledger) {
    if (state.status == TransactionDetailsStatus.deleted) return;
    final transaction = ledger.transactionById(_id);
    emit(
      TransactionDetailsState(
        status: transaction == null
            ? TransactionDetailsStatus.missing
            : TransactionDetailsStatus.found,
        ledger: ledger,
        transaction: transaction,
      ),
    );
  }

  Future<void> delete() async {
    if (state.status != TransactionDetailsStatus.found) return;
    final result = await _delete(_id);
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(
          TransactionDetailsState(
            status: TransactionDetailsStatus.deleted,
            ledger: state.ledger,
            transaction: value,
          ),
        );
      case Err(:final failure):
        emit(
          TransactionDetailsState(
            status: state.status,
            ledger: state.ledger,
            transaction: state.transaction,
            failure: failure,
          ),
        );
    }
  }
}
