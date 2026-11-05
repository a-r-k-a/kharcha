import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/app/router/app_route.dart';
import 'package:kharcha/core/theme/tokens/app_colors.dart';
import 'package:kharcha/features/profile/presentation/pages/profile_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  // Regression: the page once built its Scaffold and rename dialog from
  // package:flutter/material.dart, whose Theme is distinct from material_ui's,
  // so they rendered with stock light colors under the dark theme.
  testWidgets('profile page and rename dialog follow the dark theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await TestApp.create(initialLocation: AppRoute.profile.path);
    addTearDown(app.dispose);
    await app.pump(tester);

    final page = find.byType(ProfilePage);
    final colors = Theme.of(tester.element(page)).extension<AppColors>();
    expect(colors?.isDark, isTrue);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(of: page, matching: find.byType(Scaffold)),
    );
    final scaffoldTheme = Theme.of(tester.element(find.text('Profile')));
    expect(
      scaffold.backgroundColor ?? scaffoldTheme.scaffoldBackgroundColor,
      colors?.canvas,
    );

    await tester.tap(find.text(testProfile.displayName));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(
      Theme.of(tester.element(dialog)).dialogTheme.backgroundColor,
      colors?.surface,
    );
    expect(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      findsOneWidget,
    );
  });
}
