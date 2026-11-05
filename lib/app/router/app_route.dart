/// Every route in the app. Navigate by name (`context.goNamed(AppRoute.home.name)`)
/// so paths can change without touching call sites.
enum AppRoute {
  /// First-run setup.
  welcome('/welcome'),

  /// The user's books could not be opened.
  unavailable('/unavailable'),

  // Bottom-navigation branches.
  home('/home'),

  /// Query: `type`, `category`, `account`, `since`, `until`.
  activity('/activity'),
  budgets('/budgets'),
  insights('/insights'),
  profile('/profile'),

  /// Quick-add action sheet behind the centre key.
  quickAdd('/add'),

  /// Query: `type` (expense | income | transfer), `account` (preselected
  /// account id), `from` (id of a transaction to duplicate).
  newTransaction('/transactions/new'),
  transactionDetails('/transactions/:${AppRoute.transactionIdParam}'),
  editTransaction('/transactions/:${AppRoute.transactionIdParam}/edit'),

  accounts('/accounts'),
  newAccount('/accounts/new'),
  accountDetails('/accounts/:${AppRoute.accountIdParam}'),
  editAccount('/accounts/:${AppRoute.accountIdParam}/edit'),
  reconcileAccount('/accounts/:${AppRoute.accountIdParam}/reconcile'),

  categories('/categories'),

  /// Query: `kind` (expense | income), `parent` (top-level category id).
  newCategory('/categories/new'),
  editCategory('/categories/:${AppRoute.categoryIdParam}/edit'),

  licenses('/about/licenses'),

  /// Debug-only living style guide.
  designCatalog('/dev/catalog');

  const AppRoute(this.path);

  final String path;

  static const transactionIdParam = 'transactionId';
  static const accountIdParam = 'accountId';
  static const categoryIdParam = 'categoryId';
}

/// Query parameter names, shared by routes and the pages that read them.
abstract final class RouteQuery {
  static const type = 'type';
  static const account = 'account';
  static const category = 'category';
  static const from = 'from';
  static const kind = 'kind';
  static const parent = 'parent';

  /// Inclusive local dates, `yyyy-mm-dd`.
  static const since = 'since';
  static const until = 'until';
}
