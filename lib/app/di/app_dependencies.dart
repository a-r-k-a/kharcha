import 'package:go_router/go_router.dart';

import '../../core/domain/clock.dart';
import '../../core/domain/id_generator.dart';
import '../../core/formatting/money_formatter.dart';
import '../../features/ledger/data/repositories/ledger_store.dart';
import '../../features/ledger/domain/repositories/ledger_repositories.dart';
import '../../features/ledger/domain/usecases/account_usecases.dart';
import '../../features/ledger/domain/usecases/category_usecases.dart';
import '../../features/ledger/domain/usecases/transaction_usecases.dart';
import '../../features/profile/presentation/bloc/session_cubit.dart';
import '../../features/settings/presentation/bloc/appearance_cubit.dart';

/// Everything the widget tree needs, handed to `KharchaApp` by the
/// composition root (or a test). Widgets read these through providers,
/// never through the service locator.
final class AppDependencies {
  AppDependencies({
    required this.clock,
    required this.moneyFormatter,
    required this.ledger,
    required this.saveTransaction,
    required this.deleteTransaction,
    required this.restoreTransaction,
    required this.saveAccount,
    required this.setAccountArchived,
    required this.deleteAccount,
    required this.reconcileAccount,
    required this.saveCategory,
    required this.deleteCategory,
    required this.session,
    required this.appearance,
    required this.router,
  });

  /// Wires every ledger use case to one [LedgerStore].
  factory AppDependencies.fromStore({
    required LedgerStore store,
    required Clock clock,
    required IdGenerator ids,
    required MoneyFormatter moneyFormatter,
    required SessionCubit session,
    required AppearanceCubit appearance,
    required GoRouter router,
  }) {
    return AppDependencies(
      clock: clock,
      moneyFormatter: moneyFormatter,
      ledger: store,
      saveTransaction: SaveTransaction(
        ledger: store,
        transactions: store,
        clock: clock,
        ids: ids,
      ),
      deleteTransaction: DeleteTransaction(ledger: store, transactions: store),
      restoreTransaction: RestoreTransaction(store),
      saveAccount: SaveAccount(
        ledger: store,
        accounts: store,
        clock: clock,
        ids: ids,
      ),
      setAccountArchived: SetAccountArchived(
        ledger: store,
        accounts: store,
        clock: clock,
      ),
      deleteAccount: DeleteAccount(ledger: store, accounts: store),
      reconcileAccount: ReconcileAccount(
        ledger: store,
        transactions: store,
        clock: clock,
        ids: ids,
      ),
      saveCategory: SaveCategory(ledger: store, categories: store, ids: ids),
      deleteCategory: DeleteCategory(ledger: store, categories: store),
      session: session,
      appearance: appearance,
      router: router,
    );
  }

  final Clock clock;
  final MoneyFormatter moneyFormatter;
  final LedgerRepository ledger;
  final SaveTransaction saveTransaction;
  final DeleteTransaction deleteTransaction;
  final RestoreTransaction restoreTransaction;
  final SaveAccount saveAccount;
  final SetAccountArchived setAccountArchived;
  final DeleteAccount deleteAccount;
  final ReconcileAccount reconcileAccount;
  final SaveCategory saveCategory;
  final DeleteCategory deleteCategory;
  final SessionCubit session;
  final AppearanceCubit appearance;
  final GoRouter router;
}
