import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/theme/app_theme.dart';
import 'package:kharcha/core/theme/tokens/accent_palette.dart';
import 'package:kharcha/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.of(Brightness.light, AccentPalette.volt),
  home: Scaffold(body: child),
);

void main() {
  // Regression: AlertDialog sizes its actions with IntrinsicWidth, which used
  // to throw because AppButton laid out its label with a LayoutBuilder.
  testWidgets('lays out as an AlertDialog action', (tester) async {
    await tester.pumpWidget(
      _host(
        AlertDialog(
          title: const Text('Your name'),
          actions: [
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () {},
            ),
            AppButton(
              label: 'Save',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('SAVE'), findsOneWidget);
  });

  testWidgets('hugs its label inside an unbounded Row', (tester) async {
    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [AppButton(label: 'Add', onPressed: () {})],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ADD'), findsOneWidget);
  });

  testWidgets('ellipsizes a long label when width is bounded', (tester) async {
    await tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(
            width: 120,
            child: AppButton(
              label: 'A very long label that cannot possibly fit',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(AppButton)).width,
      lessThanOrEqualTo(120),
    );
  });
}
