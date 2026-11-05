import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/money.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/ledger_analytics.dart';
import '../../../ledger/presentation/bloc/ledger_watcher.dart';

final class AccountBalance extends Equatable {
  const AccountBalance(this.account, this.balance);

  final Account account;
  final Money balance;

  @override
  List<Object?> get props => [account, balance];
}

final class AccountGroupSummary extends Equatable {
  const AccountGroupSummary({
    required this.group,
    required this.accounts,
    required this.total,
  });

  final AccountGroup group;
  final List<AccountBalance> accounts;
  final Money total;

  @override
  List<Object?> get props => [group, accounts, total];
}

final class AccountsState extends Equatable {
  const AccountsState({
    this.isLoading = true,
    this.groups = const [],
    this.archived = const [],
    this.position,
  });

  final bool isLoading;

  /// Active accounts by group; empty groups are omitted.
  final List<AccountGroupSummary> groups;
  final List<AccountBalance> archived;
  final NetPosition? position;

  bool get isEmpty => groups.isEmpty && archived.isEmpty;

  @override
  List<Object?> get props => [isLoading, groups, archived, position];
}

class AccountsCubit extends Cubit<AccountsState> with LedgerWatcher {
  AccountsCubit(LedgerRepository ledger) : super(const AccountsState()) {
    watchLedger(ledger, (ledger) => emit(summarize(ledger)));
  }

  static AccountsState summarize(Ledger ledger) {
    AccountBalance balanceOf(Account a) =>
        AccountBalance(a, ledger.balanceOf(a.id));
    return AccountsState(
      isLoading: false,
      groups: [
        for (final group in AccountGroup.values)
          if (ledger.activeAccounts.where((a) => a.type.group == group).toList()
              case final accounts when accounts.isNotEmpty)
            AccountGroupSummary(
              group: group,
              accounts: accounts.map(balanceOf).toList(),
              total: accounts.fold(
                ledger.zero,
                (sum, a) => sum + ledger.balanceOf(a.id),
              ),
            ),
      ],
      archived: ledger.accounts
          .where((a) => a.isArchived)
          .map(balanceOf)
          .toList(),
      position: LedgerAnalytics.netPosition(ledger),
    );
  }
}
