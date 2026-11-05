import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/presentation/bloc/ledger_watcher.dart';

final class ProfileSummary extends Equatable {
  const ProfileSummary({this.activeAccounts = 0, this.customCategories = 0});

  final int activeAccounts;
  final int customCategories;

  @override
  List<Object?> get props => [activeAccounts, customCategories];
}

/// Live counts shown on the profile tab.
class ProfileSummaryCubit extends Cubit<ProfileSummary> with LedgerWatcher {
  ProfileSummaryCubit(LedgerRepository ledger) : super(const ProfileSummary()) {
    watchLedger(
      ledger,
      (ledger) => emit(
        ProfileSummary(
          activeAccounts: ledger.activeAccounts.length,
          customCategories: ledger.categories.where((c) => c.isCustom).length,
        ),
      ),
    );
  }
}
