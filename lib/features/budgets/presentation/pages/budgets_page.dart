import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_route.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/state_views.dart';

/// Budgets are the next roadmap phase. Until then this tab says so plainly
/// and points at what already works, rather than showing fake budgets.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            const PageHeader(title: 'Budgets'),
            EmptyStateView(
              icon: AppIcons.budgets,
              title: 'Budgets are coming next',
              message:
                  'Monthly and per-category limits, rollovers and '
                  'overspending alerts are the next part of the app. '
                  'Everything you record now becomes the history your first '
                  'budget is built from.',
              action: AppButton(
                label: 'See this month’s spending',
                variant: AppButtonVariant.secondary,
                icon: AppIcons.insights,
                onPressed: () => context.goNamed(AppRoute.insights.name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
