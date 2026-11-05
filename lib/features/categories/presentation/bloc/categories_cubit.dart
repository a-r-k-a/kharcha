import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/presentation/bloc/ledger_watcher.dart';

final class CategoryNode extends Equatable {
  const CategoryNode(this.category, this.children);

  final Category category;
  final List<Category> children;

  @override
  List<Object?> get props => [category, children];
}

final class CategoriesState extends Equatable {
  const CategoriesState({
    this.isLoading = true,
    this.kind = CategoryKind.expense,
    this.ledger,
  });

  final bool isLoading;
  final CategoryKind kind;
  final Ledger? ledger;

  List<CategoryNode> get tree {
    final ledger = this.ledger;
    if (ledger == null) return const [];
    return [
      for (final top in ledger.topLevelCategories(kind))
        CategoryNode(top, ledger.subcategoriesOf(top.id)),
    ];
  }

  @override
  List<Object?> get props => [isLoading, kind, ledger];
}

class CategoriesCubit extends Cubit<CategoriesState> with LedgerWatcher {
  CategoriesCubit(LedgerRepository ledger) : super(const CategoriesState()) {
    watchLedger(
      ledger,
      (ledger) => emit(
        CategoriesState(isLoading: false, kind: state.kind, ledger: ledger),
      ),
    );
  }

  void setKind(CategoryKind kind) => emit(
    CategoriesState(
      isLoading: state.isLoading,
      kind: kind,
      ledger: state.ledger,
    ),
  );
}
