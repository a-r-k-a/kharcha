import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/result.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/ledger_violation.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/category_usecases.dart';
import '../../../ledger/domain/usecases/drafts.dart';

enum CategoryFormStatus { editing, saving, saved, deleted, notFound }

final class CategoryFormState extends Equatable {
  const CategoryFormState({
    required this.status,
    this.ledger,
    this.original,
    this.name = '',
    this.kind = CategoryKind.expense,
    this.parentId,
    this.glyph = CategoryGlyph.other,
    this.tone = CategoryTone.blue,
    this.violation,
    this.failure,
  });

  final CategoryFormStatus status;
  final Ledger? ledger;

  /// The category being edited; null when creating.
  final Category? original;
  final String name;
  final CategoryKind kind;
  final String? parentId;
  final CategoryGlyph glyph;
  final CategoryTone tone;
  final LedgerViolation? violation;
  final Failure? failure;

  bool get isEditing => original != null;
  bool get canRename => original?.isCustom ?? true;
  bool get canDelete => original?.isCustom ?? false;

  /// Transactions currently filed under the edited category or its
  /// subcategories.
  int get usageCount {
    final original = this.original;
    final ledger = this.ledger;
    if (original == null || ledger == null) return 0;
    final ids = {
      original.id,
      for (final c in ledger.subcategoriesOf(original.id)) c.id,
    };
    return ledger.transactions
        .where((t) => t.allocations.any((a) => ids.contains(a.categoryId)))
        .length;
  }

  CategoryFormState copyWith({
    CategoryFormStatus? status,
    String? name,
    String? Function()? parentId,
    CategoryGlyph? glyph,
    CategoryTone? tone,
    LedgerViolation? Function()? violation,
    Failure? Function()? failure,
  }) => CategoryFormState(
    status: status ?? this.status,
    ledger: ledger,
    original: original,
    name: name ?? this.name,
    kind: kind,
    parentId: parentId != null ? parentId() : this.parentId,
    glyph: glyph ?? this.glyph,
    tone: tone ?? this.tone,
    violation: violation != null ? violation() : this.violation,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    ledger,
    original,
    name,
    kind,
    parentId,
    glyph,
    tone,
    violation,
    failure,
  ];
}

class CategoryFormCubit extends Cubit<CategoryFormState> {
  CategoryFormCubit({
    required LedgerRepository ledger,
    required this._save,
    required this._delete,
    String? categoryId,
    CategoryKind kind = CategoryKind.expense,
    String? parentId,
  }) : super(_initial(ledger.current, categoryId, kind, parentId));

  final SaveCategory _save;
  final DeleteCategory _delete;

  static CategoryFormState _initial(
    Ledger? ledger,
    String? id,
    CategoryKind kind,
    String? parentId,
  ) {
    if (ledger == null) {
      return const CategoryFormState(status: CategoryFormStatus.notFound);
    }
    if (id == null) {
      final parent = parentId == null ? null : ledger.categoryById(parentId);
      final validParent = parent != null && parent.isTopLevel ? parent : null;
      return CategoryFormState(
        status: CategoryFormStatus.editing,
        ledger: ledger,
        kind: validParent?.kind ?? kind,
        parentId: validParent?.id,
        glyph: validParent?.glyph ?? CategoryGlyph.other,
        tone: validParent?.tone ?? CategoryTone.blue,
      );
    }
    final category = ledger.categoryById(id);
    if (category == null) {
      return const CategoryFormState(status: CategoryFormStatus.notFound);
    }
    return CategoryFormState(
      status: CategoryFormStatus.editing,
      ledger: ledger,
      original: category,
      name: category.name,
      kind: category.kind,
      parentId: category.parentId,
      glyph: category.glyph,
      tone: category.tone,
    );
  }

  void setName(String value) => _update(state.copyWith(name: value));

  void setParent(String? id) => _update(state.copyWith(parentId: () => id));

  void setGlyph(CategoryGlyph glyph) => _update(state.copyWith(glyph: glyph));

  void setTone(CategoryTone tone) => _update(state.copyWith(tone: tone));

  Future<void> submit() async {
    if (state.status != CategoryFormStatus.editing) return;
    emit(
      state.copyWith(
        status: CategoryFormStatus.saving,
        violation: () => null,
        failure: () => null,
      ),
    );
    final result = await _save(
      CategoryDraft(
        id: state.original?.id,
        name: state.name,
        kind: state.kind,
        parentId: state.parentId,
        glyph: state.glyph,
        tone: state.tone,
      ),
    );
    if (isClosed) return;
    _settle(result, CategoryFormStatus.saved);
  }

  Future<void> delete() async {
    final original = state.original;
    if (original == null || state.status != CategoryFormStatus.editing) return;
    emit(state.copyWith(status: CategoryFormStatus.saving));
    final result = await _delete(original.id);
    if (isClosed) return;
    _settle(result, CategoryFormStatus.deleted);
  }

  void _settle<T>(Result<T> result, CategoryFormStatus success) {
    switch (result) {
      case Ok():
        emit(state.copyWith(status: success));
      case Err(:final failure):
        final violation = LedgerViolation.of(failure);
        emit(
          state.copyWith(
            status: CategoryFormStatus.editing,
            violation: () => violation,
            failure: () => violation == null ? failure : null,
          ),
        );
    }
  }

  void _update(CategoryFormState next) {
    if (state.status != CategoryFormStatus.editing) return;
    emit(next.copyWith(violation: () => null, failure: () => null));
  }
}
