import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_route.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../ledger/presentation/widgets/ledger_avatars.dart';
import '../bloc/categories_cubit.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoriesCubit(context.read<LedgerRepository>()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            final tree = state.tree;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PageHeader(
                    title: 'Categories',
                    showBack: true,
                    actions: [
                      HeaderAction(
                        icon: AppIcons.add,
                        label: 'New category',
                        onPressed: () => context.pushNamed(
                          AppRoute.newCategory.name,
                          queryParameters: {RouteQuery.kind: state.kind.name},
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: space.screen,
                  sliver: SliverToBoxAdapter(
                    child: AppSegmentedControl<CategoryKind>(
                      semanticLabel: 'Category kind',
                      selected: state.kind,
                      onChanged: context.read<CategoriesCubit>().setKind,
                      options: [
                        for (final kind in CategoryKind.values)
                          SegmentOption(kind, kind.label),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: space.lg)),
                SliverPadding(
                  padding: space.screen,
                  sliver: SliverList.builder(
                    itemCount: tree.length,
                    itemBuilder: (context, index) =>
                        _CategoryGroup(node: tree[index]),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: space.xxxl)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({required this.node});

  final CategoryNode node;

  void _edit(BuildContext context, Category category) => context.pushNamed(
    AppRoute.editCategory.name,
    pathParameters: {AppRoute.categoryIdParam: category.id},
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final category = node.category;
    return Container(
      margin: EdgeInsets.only(bottom: space.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radii.card,
        border: Border.all(
          color: colors.line,
          width: context.elevation.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryLine(
            category: category,
            prominent: true,
            onPressed: () => _edit(context, category),
          ),
          for (final child in node.children)
            Padding(
              padding: EdgeInsetsDirectional.only(start: space.xxl),
              child: _CategoryLine(
                category: child,
                onPressed: () => _edit(context, child),
              ),
            ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: space.xxl,
              bottom: space.xs,
            ),
            child: Pressable(
              onPressed: () => context.pushNamed(
                AppRoute.newCategory.name,
                queryParameters: {RouteQuery.parent: category.id},
              ),
              semanticLabel: 'Add subcategory to ${category.name}',
              child: ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: space.lg,
                    vertical: space.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.add, size: 16, color: colors.accentStrong),
                      SizedBox(width: space.sm),
                      Text(
                        'ADD SUBCATEGORY',
                        style: context.typeScale.label.copyWith(
                          color: colors.accentStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({
    required this.category,
    required this.onPressed,
    this.prominent = false,
  });

  final Category category;
  final VoidCallback onPressed;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return Pressable(
      onPressed: onPressed,
      pressedScale: 0.99,
      semanticLabel:
          'Edit ${category.name}${category.isCustom ? ', custom' : ''}',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: space.lg,
            vertical: space.sm,
          ),
          child: Row(
            children: [
              CategoryAvatar(category: category, size: prominent ? 36 : 28),
              SizedBox(width: space.md),
              Expanded(
                child: Text(
                  category.name,
                  style:
                      (prominent
                              ? context.typeScale.bodyStrong
                              : context.typeScale.body)
                          .copyWith(color: colors.textPrimary),
                ),
              ),
              if (category.isCustom)
                Text(
                  'CUSTOM',
                  style: context.typeScale.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              SizedBox(width: space.sm),
              Icon(AppIcons.chevronRight, size: 16, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
