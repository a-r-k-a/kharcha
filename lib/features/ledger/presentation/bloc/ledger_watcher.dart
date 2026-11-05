import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ledger.dart';
import '../../domain/repositories/ledger_repositories.dart';

/// Subscribes a cubit to ledger snapshots for exactly its lifetime.
mixin LedgerWatcher<S> on BlocBase<S> {
  StreamSubscription<Ledger>? _ledgerSubscription;

  /// Calls [onLedger] with the current snapshot and every later one.
  void watchLedger(
    LedgerRepository repository,
    void Function(Ledger ledger) onLedger,
  ) {
    unawaited(_ledgerSubscription?.cancel());
    _ledgerSubscription = repository.watch().listen((ledger) {
      if (!isClosed) onLedger(ledger);
    });
  }

  @override
  Future<void> close() async {
    await _ledgerSubscription?.cancel();
    return super.close();
  }
}
