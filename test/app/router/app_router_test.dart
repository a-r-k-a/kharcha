import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/app/pages/not_found_page.dart';
import 'package:kharcha/app/router/activity_link.dart';
import 'package:kharcha/app/router/app_router.dart';
import 'package:kharcha/core/domain/date_range.dart';
import 'package:kharcha/core/domain/failure.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';
import 'package:kharcha/features/profile/presentation/bloc/session_cubit.dart';
import 'package:kharcha/features/transactions/presentation/bloc/transaction_form_cubit.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<TestApp> pumpApp(
    WidgetTester tester, {
    String? initialLocation,
    bool withProfile = true,
  }) async {
    final app = await TestApp.create(
      initialLocation: initialLocation,
      withProfile: withProfile,
    );
    addTearDown(app.dispose);
    await app.pump(tester);
    return app;
  }

  group('navigation', () {
    testWidgets('starts on home with five tabs', (tester) async {
      final app = await pumpApp(tester);
      expect(app.location, '/home');
      for (final tab in [
        'HOME',
        'ACTIVITY',
        'BUDGETS',
        'INSIGHTS',
        'PROFILE',
      ]) {
        expect(find.text(tab), findsOneWidget);
      }
    });

    testWidgets('tapping a tab switches branch', (tester) async {
      final app = await pumpApp(tester);
      await tester.tap(find.text('ACTIVITY'));
      await tester.pumpAndSettle();
      expect(app.location, '/activity');
      await tester.tap(find.text('PROFILE'));
      await tester.pumpAndSettle();
      expect(app.location, '/profile');
    });

    testWidgets('the add key opens the quick-add sheet', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Add'));
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      for (final action in [
        'Add expense',
        'Add income',
        'Transfer money',
        'Add account',
      ]) {
        expect(
          find.descendant(of: sheet, matching: find.text(action)),
          findsOneWidget,
        );
      }
    });

    testWidgets('an unknown transaction deep link says so', (tester) async {
      await pumpApp(tester, initialLocation: '/transactions/abc123');
      expect(find.text('Transaction not found'), findsOneWidget);
    });

    testWidgets('unknown routes show the not-found page', (tester) async {
      await pumpApp(tester, initialLocation: '/does-not-exist');
      expect(find.byType(NotFoundPage), findsOneWidget);
    });

    testWidgets('dev routes are excluded when disabled', (tester) async {
      await pumpApp(tester, initialLocation: '/dev/catalog');
      expect(find.byType(NotFoundPage), findsOneWidget);
    });
  });

  group('session redirects', () {
    testWidgets('first run goes to setup, then home', (tester) async {
      final app = await pumpApp(tester, withProfile: false);
      expect(app.location, '/welcome');

      await tester.enterText(find.byType(TextField), 'Asha');
      await tapVisible(tester, find.text('GET STARTED'));

      expect(app.location, '/home');
      expect(app.profiles.profile?.displayName, 'Asha');
      expect(find.text('Add where your money lives'), findsOneWidget);
    });

    testWidgets('setup requires a name', (tester) async {
      final app = await pumpApp(tester, withProfile: false);
      await tapVisible(tester, find.text('GET STARTED'));
      await tester.scrollUntilVisible(
        find.text('Enter a name to continue.'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Enter a name to continue.'), findsOneWidget);
      expect(app.location, '/welcome');
    });

    test('sessionRedirect', () {
      final home = Uri.parse('/home');
      final welcome = Uri.parse('/welcome');
      expect(sessionRedirect(const SessionLoading(), home), isNull);
      expect(sessionRedirect(const SessionNeedsSetup(), home), '/welcome');
      expect(sessionRedirect(const SessionNeedsSetup(), welcome), isNull);
      expect(
        sessionRedirect(const SessionUnavailable(StorageFailure()), home),
        '/unavailable',
      );
      expect(sessionRedirect(SessionReady(testProfile), welcome), '/home');
      expect(sessionRedirect(SessionReady(testProfile), home), isNull);
    });
  });

  group('route parameters', () {
    test('new-transaction intent', () {
      expect(newTransactionIntent(const {}), const NewTransaction());
      expect(
        newTransactionIntent(const {'type': 'income', 'account': 'a1'}),
        const NewTransaction(type: TransactionType.income, accountId: 'a1'),
      );
      expect(
        newTransactionIntent(const {'from': 't9'}),
        const DuplicateTransaction('t9'),
      );
      // Adjustments can't be created from a link; junk falls back.
      expect(
        newTransactionIntent(const {'type': 'adjustment'}),
        const NewTransaction(),
      );
      expect(
        newTransactionIntent(const {'type': 'bogus'}),
        const NewTransaction(),
      );
    });

    test('activity filters round-trip through the URL', () {
      final range = DateRange.days(DateTime(2026, 11), DateTime(2026, 11, 30));
      final query = ActivityLink.query(
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'bank',
        range: range,
      );
      expect(query['since'], '2026-11-01');
      expect(query['until'], '2026-11-30');
      final parsed = ActivityLink.parse(query);
      expect(parsed.types, {TransactionType.expense});
      expect(parsed.categoryIds, {'food'});
      expect(parsed.accountIds, {'bank'});
      expect(parsed.range, range);
    });

    test('malformed activity filters are ignored', () {
      final parsed = ActivityLink.parse(const {
        'type': 'nope',
        'since': '2026-02-31',
        'until': '2026-03-01',
        'category': '  ',
      });
      expect(parsed.isEmpty, isTrue);
      expect(
        ActivityLink.parse(const {'since': '2026-03-05', 'until': '2026-03-01'})
            .range,
        isNull,
      );
    });
  });
}
