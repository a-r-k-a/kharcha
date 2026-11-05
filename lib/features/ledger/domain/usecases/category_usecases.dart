import '../../../../core/domain/failure.dart';
import '../../../../core/domain/id_generator.dart';
import '../../../../core/domain/result.dart';
import '../default_categories.dart';
import '../entities/category.dart';
import '../ledger_violation.dart';
import '../repositories/ledger_repositories.dart';
import '../services/ledger_validator.dart';
import 'drafts.dart';

/// Creates a custom category or edits one. Built-in categories may change
/// icon and color but keep their name.
final class SaveCategory {
  const SaveCategory({
    required this._ledger,
    required this._categories,
    required this._ids,
  });

  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final IdGenerator _ids;

  Future<Result<Category>> call(CategoryDraft draft) async {
    final ledger = _ledger.current;
    if (ledger == null) return const Err(StorageFailure());

    Category? original;
    if (draft.id case final id?) {
      original = ledger.categoryById(id);
      if (original == null) return Err(LedgerViolation.categoryMissing.failure);
      if (original.kind != draft.kind) {
        return Err(LedgerViolation.categoryKindMismatch.failure);
      }
    }
    final violation = LedgerValidator.category(
      draft,
      ledger,
      original: original,
    );
    if (violation != null) return Err(violation.failure);

    final category =
        original?.copyWith(
          name: draft.name.trim(),
          glyph: draft.glyph,
          tone: draft.tone,
        ) ??
        Category(
          id: 'custom.${_ids.next()}',
          name: draft.name.trim(),
          kind: draft.kind,
          parentId: draft.parentId,
          glyph: draft.glyph,
          tone: draft.tone,
          isCustom: true,
          sortOrder: ledger.categories.length,
        );
    return switch (await _categories.saveCategory(category)) {
      Ok() => Ok(category),
      Err(:final failure) => Err(failure),
    };
  }
}

/// Deletes a custom category. Its transactions move to the parent category
/// (for a subcategory) or to the kind's "Other" category, so no transaction
/// is ever left uncategorized.
final class DeleteCategory {
  const DeleteCategory({required this._ledger, required this._categories});

  final LedgerRepository _ledger;
  final CategoryRepository _categories;

  /// Where [category]'s transactions would go if it were deleted.
  static String replacementFor(Category category) =>
      category.parentId ?? DefaultCategories.fallbackFor(category.kind);

  Future<Result<void>> call(String id) async {
    final category = _ledger.current?.categoryById(id);
    if (category == null) return Err(LedgerViolation.categoryMissing.failure);
    if (!category.isCustom) return Err(LedgerViolation.categoryBuiltIn.failure);
    return _categories.deleteCategory(
      id,
      replacementId: replacementFor(category),
    );
  }
}
