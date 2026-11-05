import 'package:flutter/widgets.dart';

/// Semantic icon map. Swap the icon set here, nowhere else.
///
/// Glyphs come from the bundled Phosphor icon fonts (MIT, see
/// assets/licenses). Codepoints are identical across weights; regular is the
/// default, bold marks the active state. Codepoints were taken from
/// `@phosphor-icons/web` 2.1.1 and checked against both bundled fonts.
abstract final class AppIcons {
  static const _regular = 'PhosphorRegular';
  static const _bold = 'PhosphorBold';

  // Navigation
  static const home = IconData(0xe2c2, fontFamily: _regular);
  static const homeActive = IconData(0xe2c2, fontFamily: _bold);
  static const activity = IconData(0xe3ec, fontFamily: _regular);
  static const activityActive = IconData(0xe3ec, fontFamily: _bold);
  static const budgets = IconData(0xe47c, fontFamily: _regular);
  static const budgetsActive = IconData(0xe47c, fontFamily: _bold);
  static const insights = IconData(0xe156, fontFamily: _regular);
  static const insightsActive = IconData(0xe156, fontFamily: _bold);
  static const profile = IconData(0xe4c4, fontFamily: _regular);
  static const profileActive = IconData(0xe4c4, fontFamily: _bold);

  // Actions
  static const add = IconData(0xe3d4, fontFamily: _bold);
  static const settings = IconData(0xe272, fontFamily: _regular);
  static const back = IconData(
    0xe058,
    fontFamily: _regular,
    matchTextDirection: true,
  );
  static const forward = IconData(
    0xe06c,
    fontFamily: _regular,
    matchTextDirection: true,
  );
  static const chevronRight = IconData(
    0xe13a,
    fontFamily: _regular,
    matchTextDirection: true,
  );
  static const chevronLeft = IconData(
    0xe138,
    fontFamily: _regular,
    matchTextDirection: true,
  );
  static const chevronDown = IconData(0xe136, fontFamily: _regular);
  static const chevronUp = IconData(0xe13c, fontFamily: _regular);
  static const retry = IconData(0xe036, fontFamily: _regular);
  static const close = IconData(0xe4f6, fontFamily: _regular);
  static const search = IconData(0xe30c, fontFamily: _regular);
  static const filter = IconData(0xe268, fontFamily: _regular);
  static const edit = IconData(0xe3b4, fontFamily: _regular);
  static const duplicate = IconData(0xe1ca, fontFamily: _regular);
  static const delete = IconData(0xe4a6, fontFamily: _regular);
  static const archive = IconData(0xe00c, fontFamily: _regular);
  static const unarchive = IconData(0xe038, fontFamily: _regular);
  static const check = IconData(0xe182, fontFamily: _bold);
  static const remove = IconData(0xe32a, fontFamily: _regular);
  static const more = IconData(0xe1fe, fontFamily: _regular);
  static const show = IconData(0xe220, fontFamily: _regular);
  static const hide = IconData(0xe224, fontFamily: _regular);
  static const calendar = IconData(0xe10a, fontFamily: _regular);
  static const note = IconData(0xe34c, fontFamily: _regular);
  static const tag = IconData(0xe478, fontFamily: _regular);
  static const split = IconData(0xe15a, fontFamily: _regular);
  static const reconcile = IconData(0xe538, fontFamily: _regular);
  static const signOut = IconData(0xe42a, fontFamily: _regular);
  static const info = IconData(0xe2ce, fontFamily: _regular);
  static const device = IconData(0xe1e0, fontFamily: _regular);

  // Money movement
  static const expense = IconData(0xe092, fontFamily: _regular);
  static const income = IconData(0xe040, fontFamily: _regular);
  static const transfer = IconData(0xe0a0, fontFamily: _regular);
  static const adjustment = IconData(0xe3d8, fontFamily: _regular);
  static const trendUp = IconData(0xe4ae, fontFamily: _regular);
  static const trendDown = IconData(0xe4ac, fontFamily: _regular);
  static const reimbursable = IconData(0xe08a, fontFamily: _regular);

  // Accounts
  static const bank = IconData(0xe0b4, fontFamily: _regular);
  static const cash = IconData(0xe588, fontFamily: _regular);
  static const wallet = IconData(0xe68a, fontFamily: _regular);
  static const creditCard = IconData(0xe1d2, fontFamily: _regular);
  static const deposit = IconData(0xe76e, fontFamily: _regular);
  static const investment = IconData(0xe156, fontFamily: _regular);
  static const loan = IconData(0xea8c, fontFamily: _regular);
  static const accounts = IconData(0xe5fa, fontFamily: _regular);
  static const categories = IconData(0xe464, fontFamily: _regular);

  // Categories
  static const food = IconData(0xe262, fontFamily: _regular);
  static const groceries = IconData(0xe964, fontFamily: _regular);
  static const delivery = IconData(0xe824, fontFamily: _regular);
  static const transport = IconData(0xe112, fontFamily: _regular);
  static const fuel = IconData(0xe768, fontFamily: _regular);
  static const cab = IconData(0xe902, fontFamily: _regular);
  static const transit = IconData(0xe4a0, fontFamily: _regular);
  static const housing = IconData(0xe2c4, fontFamily: _regular);
  static const maintenance = IconData(0xe5d4, fontFamily: _regular);
  static const utilities = IconData(0xe2de, fontFamily: _regular);
  static const shopping = IconData(0xe416, fontFamily: _regular);
  static const clothing = IconData(0xe670, fontFamily: _regular);
  static const electronics = IconData(0xe586, fontFamily: _regular);
  static const health = IconData(0xe56e, fontFamily: _regular);
  static const medicine = IconData(0xe700, fontFamily: _regular);
  static const doctor = IconData(0xe7ea, fontFamily: _regular);
  static const entertainment = IconData(0xe8c2, fontFamily: _regular);
  static const subscriptions = IconData(0xe754, fontFamily: _regular);
  static const education = IconData(0xe62c, fontFamily: _regular);
  static const books = IconData(0xe0e6, fontFamily: _regular);
  static const insurance = IconData(0xe40c, fontFamily: _regular);
  static const personal = IconData(0xe4c2, fontFamily: _regular);
  static const grooming = IconData(0xeae0, fontFamily: _regular);
  static const travel = IconData(0xe5d6, fontFamily: _regular);
  static const other = IconData(0xe200, fontFamily: _regular);
  static const salary = IconData(0xe0ee, fontFamily: _regular);
  static const freelance = IconData(0xe1bc, fontFamily: _regular);
  static const business = IconData(0xe470, fontFamily: _regular);
  static const interest = IconData(0xe3b6, fontFamily: _regular);
  static const dividends = IconData(0xe78e, fontFamily: _regular);
  static const gift = IconData(0xe276, fontFamily: _regular);
  static const savings = IconData(0xea04, fontFamily: _regular);
  static const coffee = IconData(0xe1c2, fontFamily: _regular);
  static const pets = IconData(0xe648, fontFamily: _regular);
  static const fitness = IconData(0xe0b6, fontFamily: _regular);
  static const games = IconData(0xe26e, fontFamily: _regular);
  static const internet = IconData(0xe4ea, fontFamily: _regular);
  static const water = IconData(0xe210, fontFamily: _regular);
  static const heart = IconData(0xe2a8, fontFamily: _regular);
  static const sparkle = IconData(0xe6a2, fontFamily: _regular);

  // Appearance
  static const themeLight = IconData(0xe472, fontFamily: _regular);
  static const themeDark = IconData(0xe330, fontFamily: _regular);
  static const themeSystem = IconData(0xe1e0, fontFamily: _regular);
  static const lock = IconData(0xe308, fontFamily: _regular);

  // States
  static const empty = IconData(0xe602, fontFamily: _regular);
  static const error = IconData(0xe4e4, fontFamily: _regular);
  static const warning = IconData(0xe4e2, fontFamily: _regular);
  static const success = IconData(0xe184, fontFamily: _regular);
  static const offline = IconData(0xe1b6, fontFamily: _regular);
  static const lost = IconData(0xe1c8, fontFamily: _regular);
}
