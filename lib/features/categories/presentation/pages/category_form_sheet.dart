import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/ledger_violation.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/usecases/category_usecases.dart';
import '../../../ledger/presentation/category_style.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';
import '../../../transactions/presentation/widgets/form_pickers.dart';
import '../bloc/category_form_cubit.dart';

class CategoryFormSheet extends StatelessWidget {
  const CategoryFormSheet({
    super.key,
    this.categoryId,
    this.kind = CategoryKind.expense,
    this.parentId,
  });

  final String? categoryId;
  final CategoryKind kind;
  final String? parentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryFormCubit(
        ledger: context.read<LedgerRepository>(),
        save: context.read<SaveCategory>(),
        delete: context.read<DeleteCategory>(),
        categoryId: categoryId,
        kind: kind,
        parentId: parentId,
      ),
      child: const _CategoryFormView(),
    );
  }
}

class _CategoryFormView extends StatelessWidget {
  const _CategoryFormView();

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryFormState state,
  ) async {
    final original = state.original;
    final ledger = state.ledger;
    if (original == null || ledger == null) return;
    final replacement = ledger.categoryById(
      DeleteCategory.replacementFor(original),
    );
    final count = state.usageCount;
    final subcategories = ledger.subcategoriesOf(original.id).length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${original.name}?',
      message: [
        if (subcategories > 0)
          'Its $subcategories subcategor${subcategories == 1 ? 'y' : 'ies'} '
              'will be deleted too.',
        if (count > 0)
          '$count transaction${count == 1 ? '' : 's'} will move to '
              '${replacement?.name ?? 'Other'}.',
        'This can’t be undone.',
      ].join(' '),
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<CategoryFormCubit>().delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryFormCubit, CategoryFormState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        final message = switch (state.status) {
          CategoryFormStatus.saved =>
            state.isEditing ? 'Category updated' : 'Category added',
          CategoryFormStatus.deleted => 'Category deleted',
          _ => null,
        };
        if (message == null) return;
        showAppSnackBar(context, message);
        context.pop();
      },
      builder: (context, state) {
        if (state.status == CategoryFormStatus.notFound) {
          return const SheetScaffold(
            title: 'Category not found',
            body: EmptyStateView(
              icon: AppIcons.lost,
              title: 'Category not found',
              message: 'It may have been deleted.',
            ),
          );
        }
        final ledger = state.ledger;
        final parentId = state.parentId;
        final parent = parentId == null ? null : ledger?.categoryById(parentId);
        return SheetScaffold(
          eyebrow: parent == null
              ? '${state.kind.label} category'
              : 'In ${parent.name}',
          title: state.isEditing ? 'Edit category' : 'New category',
          action: AppButton(
            label: state.isEditing ? 'Save changes' : 'Add category',
            expand: true,
            isLoading: state.status == CategoryFormStatus.saving,
            onPressed: () => context.read<CategoryFormCubit>().submit(),
          ),
          body: _Body(
            state: state,
            onDelete: state.canDelete
                ? () => _confirmDelete(context, state)
                : null,
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.onDelete});

  final CategoryFormState state;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CategoryFormCubit>();
    final colors = context.colors;
    final space = context.space;
    final ledger = state.ledger;
    final violation = state.violation;
    final nameError = switch (violation) {
      LedgerViolation.nameEmpty ||
      LedgerViolation.nameTooLong ||
      LedgerViolation.nameTaken ||
      LedgerViolation.categoryBuiltIn => violation?.message,
      _ => null,
    };
    final failure = state.failure;
    final otherError = failure != null
        ? failureMessage(failure)
        : (nameError == null ? violation?.message : null);
    final toneColor = state.tone.colorFrom(colors);
    final hasChildren =
        state.original != null &&
        (ledger?.subcategoriesOf(state.original?.id ?? '').isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ToneTile(icon: state.glyph.icon, tone: toneColor, size: 56),
            SizedBox(width: space.lg),
            Expanded(
              child: TextFormField(
                initialValue: state.name,
                enabled: state.canRename,
                onChanged: cubit.setName,
                autofocus: !state.isEditing,
                textCapitalization: TextCapitalization.words,
                maxLength: LedgerLimits.categoryNameLength,
                decoration: InputDecoration(
                  labelText: 'NAME',
                  helperText: state.canRename
                      ? null
                      : 'Built-in names stay fixed; icon and color can change.',
                  errorText: nameError,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        if (!state.isEditing && ledger != null && !hasChildren) ...[
          SizedBox(height: space.xl),
          FormSection(
            label: 'Inside',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: space.sm),
                    child: AppChip(
                      label: 'Top level',
                      selected: state.parentId == null,
                      onPressed: () => cubit.setParent(null),
                    ),
                  ),
                  for (final top in ledger.topLevelCategories(state.kind))
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: space.sm),
                      child: AppChip(
                        label: top.name,
                        icon: top.glyph.icon,
                        selected: state.parentId == top.id,
                        onPressed: () => cubit.setParent(top.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: space.xl),
        FormSection(
          label: 'Color',
          child: Wrap(
            spacing: space.sm,
            runSpacing: space.sm,
            children: [
              for (final tone in CategoryTone.values)
                _ToneSwatch(
                  tone: tone,
                  selected: tone == state.tone,
                  onPressed: () => cubit.setTone(tone),
                ),
            ],
          ),
        ),
        SizedBox(height: space.xl),
        FormSection(
          label: 'Icon',
          child: Wrap(
            spacing: space.xs,
            runSpacing: space.xs,
            children: [
              for (final glyph in CategoryGlyph.values)
                _GlyphOption(
                  glyph: glyph,
                  selected: glyph == state.glyph,
                  onPressed: () => cubit.setGlyph(glyph),
                ),
            ],
          ),
        ),
        if (otherError != null) ...[
          SizedBox(height: space.lg),
          Text(
            otherError,
            style: context.typeScale.body.copyWith(color: colors.danger),
          ),
        ],
        if (onDelete != null) ...[
          SizedBox(height: space.xxl),
          AppButton(
            label: 'Delete category',
            icon: AppIcons.delete,
            variant: AppButtonVariant.danger,
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}

class _ToneSwatch extends StatelessWidget {
  const _ToneSwatch({
    required this.tone,
    required this.selected,
    required this.onPressed,
  });

  final CategoryTone tone;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: onPressed,
        haptic: PressHaptic.selection,
        semanticLabel: '${tone.label} color',
        child: AnimatedContainer(
          duration: context.motionDuration(context.motion.fast),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tone.colorFrom(colors),
            borderRadius: context.radii.card,
            border: Border.all(
              color: selected ? colors.textPrimary : colors.line,
              width: selected ? 3 : context.elevation.hairline,
            ),
          ),
          child: selected
              ? Icon(AppIcons.check, size: 18, color: colors.canvas)
              : null,
        ),
      ),
    );
  }
}

class _GlyphOption extends StatelessWidget {
  const _GlyphOption({
    required this.glyph,
    required this.selected,
    required this.onPressed,
  });

  final CategoryGlyph glyph;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: onPressed,
        haptic: PressHaptic.selection,
        semanticLabel: '${glyph.name} icon',
        child: AnimatedContainer(
          duration: context.motionDuration(context.motion.fast),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? colors.textPrimary : null,
            borderRadius: context.radii.control,
          ),
          child: Icon(
            glyph.icon,
            size: 22,
            color: selected ? colors.canvas : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
