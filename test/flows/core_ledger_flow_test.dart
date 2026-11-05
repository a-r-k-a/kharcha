import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/ledger/domain/entities/account.dart';
import 'package:kharcha/features/ledger/domain/entities/transaction.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/in_memory_ledger.dart';
import '../helpers/test_app.dart';

void main() {
  Future<TestApp> pumpApp(WidgetTester tester) async {
    // A phone-sized surface, so layouts match what users see.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await TestApp.create();
    addTearDown(app.dispose);
    await app.pump(tester);
    return app;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(BottomSheet), matching: finder);

  testWidgets('add an account, record an expense, delete and undo', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    // First run: the dashboard asks for an account.
    await tapVisible(tester, find.text('ADD FIRST ACCOUNT'));
    expect(inSheet(find.text('New account')), findsOneWidget);
    await tester.enterText(
      inSheet(find.widgetWithText(TextFormField, 'NAME')),
      'HDFC Savings',
    );
    await tester.enterText(
      inSheet(find.widgetWithText(TextField, 'CURRENT BALANCE')),
      '50000',
    );
    await tapVisible(tester, inSheet(find.text('ADD ACCOUNT')));

    final account = app.store.current?.accounts.single;
    expect(account?.name, 'HDFC Savings');
    expect(account?.openingBalance, inr(50000));
    expect(
      find.bySemanticsLabel(RegExp('Cash and bank balance ₹50,000')),
      findsOneWidget,
    );

    // Record an expense through the quick-add sheet.
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('New expense')), findsOneWidget);

    // Saving with nothing filled in explains what's missing.
    await tapVisible(tester, inSheet(find.text('SAVE')));
    expect(find.text('Enter an amount.'), findsOneWidget);

    await tester.enterText(
      inSheet(find.widgetWithText(TextField, 'AMOUNT')),
      '1250.50',
    );
    await tapVisible(tester, inSheet(find.text('SAVE')));
    expect(find.text('Choose a category.'), findsOneWidget);

    await tapVisible(tester, inSheet(find.text('Food')));
    await tapVisible(tester, inSheet(find.text('GROCERIES')));
    await tapVisible(tester, inSheet(find.text('SAVE')));

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Expense recorded'), findsOneWidget);
    final expense = app.store.current?.transactions.single;
    expect(expense?.amount, inr(1250.50));
    expect(expense?.allocations.single.categoryId, 'food.groceries');
    expect(expense?.paymentMethod, PaymentMethod.upi);
    expect(app.store.current?.balanceOf(account?.id ?? ''), inr(48749.50));

    // It shows in Activity; swipe to delete, then undo.
    await tester.tap(find.text('ACTIVITY'));
    await tester.pumpAndSettle();
    final tile = find.bySemanticsLabel(RegExp('^Expense, Groceries'));
    expect(tile, findsOneWidget);
    await tester.drag(tile, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(app.store.current?.transactions, isEmpty);
    expect(find.text('Expense deleted'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(app.store.current?.transactions.single, expense);
  });

  testWidgets('a transfer moves money but is not spending', (tester) async {
    final app = await pumpApp(tester);
    await app.store.saveAccount(testAccount('bank', opening: 20000));
    await app.store.saveAccount(
      testAccount('cash', type: AccountType.cash, name: 'Wallet cash'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer money'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('New transfer')), findsOneWidget);

    await tester.enterText(
      inSheet(find.widgetWithText(TextField, 'AMOUNT')),
      '5000',
    );
    await tapVisible(tester, inSheet(find.text('SAVE')));

    final transfer = app.store.current?.transactions.single;
    expect(transfer?.type, TransactionType.transfer);
    expect(transfer?.accountId, 'bank');
    expect(transfer?.counterpartyAccountId, 'cash');
    expect(app.store.current?.balanceOf('bank'), inr(15000));
    expect(app.store.current?.balanceOf('cash'), inr(5000));

    // Spending this month is still zero, and the total is unchanged.
    expect(find.bySemanticsLabel(RegExp(r'^Spent ₹0,')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Cash and bank balance ₹20,000')),
      findsOneWidget,
    );
  });

  testWidgets('the dashboard can hide amounts', (tester) async {
    final app = await pumpApp(tester);
    await app.store.saveAccount(testAccount('bank', opening: 1234));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Cash and bank balance ₹1,234')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Hide amounts'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Cash and bank balance hidden'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('1,234')), findsNothing);
  });

  test('Money stays exact for the amounts used above', () {
    expect(Money.tryParse('1250.50'), inr(1250.50));
  });
}
