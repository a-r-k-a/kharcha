import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/accounts/presentation/pages/account_details_page.dart';
import '../../features/accounts/presentation/pages/account_form_sheet.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/presentation/pages/reconcile_sheet.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/categories/presentation/pages/category_form_sheet.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/ledger/domain/entities/category.dart';
import '../../features/ledger/domain/entities/transaction.dart';
import '../../features/profile/presentation/bloc/session_cubit.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/session_unavailable_page.dart';
import '../../features/profile/presentation/pages/welcome_page.dart';
import '../../features/transactions/presentation/bloc/transaction_form_cubit.dart';
import '../../features/transactions/presentation/pages/activity_page.dart';
import '../../features/transactions/presentation/pages/transaction_details_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_sheet.dart';
import '../dev/design_catalog_page.dart';
import '../pages/not_found_page.dart';
import '../shell/app_shell.dart';
import '../shell/quick_add_sheet.dart';
import 'activity_link.dart';
import 'app_route.dart';
import 'sheet_page.dart';

/// Builds the app's single [GoRouter]. Called once at the composition root;
/// never inside a `build` method. [session] drives the first-run and
/// storage-error redirects; [refresh] (usually a [SessionRouterRefresh])
/// re-runs them when the session changes. The caller owns both.
GoRouter buildAppRouter({
  required SessionCubit session,
  required Listenable refresh,
  String? initialLocation,
  bool includeDevRoutes = kDebugMode,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? AppRoute.home.path,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (_, state) => sessionRedirect(session.state, state.uri),
    errorBuilder: (_, _) => const NotFoundPage(),
    routes: [
      _route(AppRoute.welcome, (_, _) => const WelcomePage()),
      _route(AppRoute.unavailable, (_, _) => const SessionUnavailablePage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _branch(AppRoute.home, (_, _) => const DashboardPage()),
          _branch(
            AppRoute.activity,
            (_, state) => ActivityPage(
              filters: ActivityLink.parse(state.uri.queryParameters),
            ),
          ),
          _branch(AppRoute.budgets, (_, _) => const BudgetsPage()),
          _branch(AppRoute.insights, (_, _) => const InsightsPage()),
          _branch(AppRoute.profile, (_, _) => const ProfilePage()),
        ],
      ),
      _sheet(AppRoute.quickAdd, (_) => const QuickAddSheet()),
      // `new` must precede `:transactionId` so it isn't read as an id.
      _sheet(
        AppRoute.newTransaction,
        (state) => TransactionFormSheet(
          intent: newTransactionIntent(state.uri.queryParameters),
        ),
      ),
      _route(
        AppRoute.transactionDetails,
        (_, state) => _withId(
          state,
          AppRoute.transactionIdParam,
          (id) => TransactionDetailsPage(transactionId: id),
        ),
      ),
      _sheet(
        AppRoute.editTransaction,
        (state) => _withId(
          state,
          AppRoute.transactionIdParam,
          (id) => TransactionFormSheet(intent: EditTransaction(id)),
        ),
      ),
      _route(AppRoute.accounts, (_, _) => const AccountsPage()),
      _sheet(AppRoute.newAccount, (_) => const AccountFormSheet()),
      _route(
        AppRoute.accountDetails,
        (_, state) => _withId(
          state,
          AppRoute.accountIdParam,
          (id) => AccountDetailsPage(accountId: id),
        ),
      ),
      _sheet(
        AppRoute.editAccount,
        (state) => _withId(
          state,
          AppRoute.accountIdParam,
          (id) => AccountFormSheet(accountId: id),
        ),
      ),
      _sheet(
        AppRoute.reconcileAccount,
        (state) => _withId(
          state,
          AppRoute.accountIdParam,
          (id) => ReconcileSheet(accountId: id),
        ),
      ),
      _route(AppRoute.categories, (_, _) => const CategoriesPage()),
      _sheet(AppRoute.newCategory, (state) {
        final query = state.uri.queryParameters;
        return CategoryFormSheet(
          kind:
              _enumByName(CategoryKind.values, query[RouteQuery.kind]) ??
              CategoryKind.expense,
          parentId: _nonEmpty(query[RouteQuery.parent]),
        );
      }),
      _sheet(
        AppRoute.editCategory,
        (state) => _withId(
          state,
          AppRoute.categoryIdParam,
          (id) => CategoryFormSheet(categoryId: id),
        ),
      ),
      _route(AppRoute.licenses, (_, _) => const LicensePage()),
      if (includeDevRoutes)
        _route(AppRoute.designCatalog, (_, _) => const DesignCatalogPage()),
    ],
  );
}

/// Notifies the router whenever the session changes.
final class SessionRouterRefresh extends ChangeNotifier {
  SessionRouterRefresh(Stream<SessionState> sessions) {
    _subscription = sessions.listen((_) => notifyListeners());
  }

  StreamSubscription<SessionState>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// Where the session state requires the user to be, or null to stay.
@visibleForTesting
String? sessionRedirect(SessionState state, Uri uri) {
  final path = uri.path;
  final atWelcome = path == AppRoute.welcome.path;
  final atUnavailable = path == AppRoute.unavailable.path;
  return switch (state) {
    SessionLoading() => null,
    SessionNeedsSetup() => atWelcome ? null : AppRoute.welcome.path,
    SessionUnavailable() => atUnavailable ? null : AppRoute.unavailable.path,
    SessionReady() => atWelcome || atUnavailable ? AppRoute.home.path : null,
  };
}

/// Reads the new-transaction route's query: `type`, `account`, `from`.
/// Unknown values fall back to a plain new expense.
@visibleForTesting
TransactionFormIntent newTransactionIntent(Map<String, String> query) {
  final from = _nonEmpty(query[RouteQuery.from]);
  if (from != null) return DuplicateTransaction(from);
  final type = _enumByName(TransactionType.values, query[RouteQuery.type]);
  return NewTransaction(
    // Adjustments only come from reconciling, never from a link.
    type: type == null || type == TransactionType.adjustment
        ? TransactionType.expense
        : type,
    accountId: _nonEmpty(query[RouteQuery.account]),
  );
}

GoRoute _route(AppRoute route, GoRouterWidgetBuilder builder) =>
    GoRoute(path: route.path, name: route.name, builder: builder);

GoRoute _sheet(AppRoute route, Widget Function(GoRouterState state) child) =>
    GoRoute(
      path: route.path,
      name: route.name,
      pageBuilder: (_, state) => SheetPage<void>(
        key: state.pageKey,
        name: state.name,
        child: child(state),
      ),
    );

StatefulShellBranch _branch(AppRoute route, GoRouterWidgetBuilder builder) =>
    StatefulShellBranch(routes: [_route(route, builder)]);

/// Builds with a validated path parameter, or the not-found page.
Widget _withId(
  GoRouterState state,
  String param,
  Widget Function(String id) builder,
) {
  final id = _nonEmpty(state.pathParameters[param]);
  return id == null ? const NotFoundPage() : builder(id);
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

T? _enumByName<T extends Enum>(List<T> values, String? name) =>
    values.where((value) => value.name == name).firstOrNull;
