import 'package:material_ui/material_ui.dart';

import '../../../../core/formatting/date_labels.dart';
import '../../../../core/formatting/money_format_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/presentation/category_style.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';

/// Field caption in mono caps, with an optional error line beneath its
/// content.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.trailing,
  });

  final String label;
  final Widget child;
  final String? errorText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final errorText = this.errorText;
    final trailing = this.trailing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  label.toUpperCase(),
                  style: context.typeScale.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        SizedBox(height: space.sm),
        child,
        AnimatedSize(
          duration: context.motionDuration(context.motion.fast),
          alignment: AlignmentDirectional.topStart,
          child: errorText == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: space.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Icon(AppIcons.warning, size: 16, color: colors.danger),
                        SizedBox(width: space.xs),
                        Expanded(
                          child: Text(
                            errorText,
                            style: context.typeScale.bodySmall.copyWith(
                              color: colors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Grid of top-level categories; picking one with subcategories reveals
/// them as chips beneath.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.ledger,
    required this.kind,
    required this.selectedId,
    required this.onSelected,
  });

  final Ledger ledger;
  final CategoryKind kind;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final topLevel = ledger.topLevelCategories(kind);
    final selectedId = this.selectedId;
    final selectedTop = selectedId == null
        ? null
        : ledger.topLevelCategoryOf(selectedId);
    final subcategories = selectedTop == null
        ? const <Category>[]
        : ledger.subcategoriesOf(selectedTop.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 6 : 4;
            final width =
                (constraints.maxWidth - space.sm * (columns - 1)) / columns;
            return Wrap(
              spacing: space.sm,
              runSpacing: space.sm,
              children: [
                for (final category in topLevel)
                  SizedBox(
                    width: width,
                    child: _CategoryCell(
                      category: category,
                      selected: selectedTop?.id == category.id,
                      onPressed: () => onSelected(category.id),
                    ),
                  ),
              ],
            );
          },
        ),
        AnimatedSize(
          duration: context.motionDuration(context.motion.medium),
          curve: context.motion.enter,
          alignment: AlignmentDirectional.topStart,
          child: subcategories.isEmpty || selectedTop == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: space.md),
                  child: Wrap(
                    spacing: space.sm,
                    runSpacing: space.sm,
                    children: [
                      AppChip(
                        label: 'Any ${selectedTop.name}',
                        selected: selectedId == selectedTop.id,
                        onPressed: () => onSelected(selectedTop.id),
                      ),
                      for (final sub in subcategories)
                        AppChip(
                          label: sub.name,
                          icon: sub.glyph.icon,
                          selected: selectedId == sub.id,
                          onPressed: () => onSelected(sub.id),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.selected,
    required this.onPressed,
  });

  final Category category;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: onPressed,
        haptic: PressHaptic.selection,
        semanticLabel: category.name,
        pressedScale: 0.95,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: context.motionDuration(context.motion.fast),
            padding: EdgeInsets.symmetric(
              vertical: space.sm,
              horizontal: space.xs,
            ),
            decoration: BoxDecoration(
              color: selected ? colors.surfaceRaised : null,
              borderRadius: context.radii.control,
              border: Border.all(
                color: selected ? colors.textPrimary : colors.line,
                width: selected
                    ? context.elevation.focusRingWidth
                    : context.elevation.hairline,
              ),
            ),
            child: Column(
              children: [
                CategoryAvatar(category: category, size: 36),
                SizedBox(height: space.xs),
                // Long names ("Transportation") shrink to fit rather than
                // being cut off.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.name,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: context.typeScale.bodySmall.copyWith(
                      color: selected
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling account chips, each showing its balance.
class AccountChoices extends StatelessWidget {
  const AccountChoices({
    super.key,
    required this.ledger,
    required this.selectedId,
    required this.onSelected,
    this.extraAccountId,
  });

  final Ledger ledger;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  /// An archived account to keep visible because the edited transaction
  /// already uses it.
  final String? extraAccountId;

  @override
  Widget build(BuildContext context) {
    final formatter = MoneyFormatScope.of(context);
    final extra = switch (extraAccountId) {
      final id? => ledger.accountById(id),
      null => null,
    };
    final accounts = [
      ...ledger.activeAccounts,
      if (extra != null && extra.isArchived) extra,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final Account account in accounts)
            Padding(
              padding: EdgeInsetsDirectional.only(end: context.space.sm),
              child: AppChip(
                label: account.name,
                icon: account.type.icon,
                selected: account.id == selectedId,
                semanticLabel:
                    '${account.name}, balance '
                    '${formatter.format(ledger.balanceOf(account.id))}',
                onPressed: () => onSelected(account.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// Today / Yesterday / a picked date. Keeps the time of day when the date
/// changes.
class DateChoices extends StatelessWidget {
  const DateChoices({
    super.key,
    required this.value,
    required this.now,
    required this.onChanged,
  });

  final DateTime value;
  final DateTime now;
  final ValueChanged<DateTime> onChanged;

  DateTime _onDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, value.hour, value.minute);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) onChanged(_onDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final isToday = _sameDay(value, now);
    final isYesterday = _sameDay(value, yesterday);
    final isOther = !isToday && !isYesterday;
    return Wrap(
      spacing: context.space.sm,
      runSpacing: context.space.sm,
      children: [
        AppChip(
          label: 'Today',
          selected: isToday,
          onPressed: () => onChanged(_onDay(now)),
        ),
        AppChip(
          label: 'Yesterday',
          selected: isYesterday,
          onPressed: () => onChanged(_onDay(yesterday)),
        ),
        AppChip(
          label: isOther ? DateLabels.fullDate(value) : 'Pick a date',
          icon: AppIcons.calendar,
          selected: isOther,
          onPressed: () => _pick(context),
        ),
      ],
    );
  }
}
