import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_views.dart';
import '../router/app_route.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: EmptyStateView(
            icon: AppIcons.lost,
            title: 'Nothing filed here',
            message:
                "This page isn't in the ledger. It may have moved, or the "
                'link is out of date.',
            action: AppButton(
              label: 'Back to home',
              onPressed: () => context.goNamed(AppRoute.home.name),
            ),
          ),
        ),
      ),
    );
  }
}
