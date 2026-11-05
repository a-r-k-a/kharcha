# Kharcha: Roadmap & status

Last updated 4 Nov 2026. Architecture and accounting rules:
[`ARCHITECTURE.md`](ARCHITECTURE.md).

## Phase 1: Foundation and core finance (done)

| Area | Status |
|---|---|
| Clean Architecture, DI, GoRouter, design system | Done (built on the existing "Night Ledger" system) |
| Navigation | Home · Activity · Budgets · Insights · Profile; centre add key → quick-add sheet; side rail at ≥ 840dp |
| Local database | Encrypted per-owner Hive boxes; key in the platform keystore |
| Session | First-run setup (name, currency), local profile, redirects, "couldn't open your books" recovery, erase all data |
| Accounts | 9 types, opening balance (liabilities as amount owed), details with history, archive/restore, delete-if-unused, reconcile |
| Transactions | Expense / income / transfer; categories and subcategories; splits; payment methods incl. UPI/NEFT/RTGS/IMPS; date; note; tags; reimbursable; edit, duplicate, delete with undo |
| Activity | Day-grouped list with daily net, debounced search (payee, note, tag, category, account, amount), type/date/category/account filters, deep-linkable filters, swipe to delete |
| Categories | Built-in set from the spec, custom categories and subcategories, icon and color picker, delete with reassignment |
| Dashboard | Greeting, cash & bank hero, net worth, owed, day/week/month/year, account filter, income/spent with change vs previous period, net cash flow and savings rate, spending chart, category breakdown, recent, hide amounts |
| Insights (early Phase 3) | Month switcher, summary, category changes, savings-rate change, income share, labeled month-end projection, six-month table |

Tests: 362 (domain calculations, validation, use cases, store and codec,
real encrypted Hive, blocs, routing and redirects, end-to-end widget flows,
contrast). `flutter analyze` is clean.

## Next phases

| Phase | Scope |
|---|---|
| 2 | Budgets (monthly/weekly/custom, category limits, rollover, alerts), savings goals and contributions, recurring transactions, bills, subscriptions, notifications, financial calendar |
| 3 | Reports and exports, loans and debt planner, net worth history |
| 4 | Investments and XIRR, receipt scanning, CSV import/export, shared expenses, tax, backup/restore |
| 5 | AI assistant (server-side key), automated categorization, anomaly detection |

## Known limitations

- **Cloud sign-in and sync aren't available.** Firebase isn't configured
  (no `google-services.json`, `GoogleService-Info.plist` or
  `firebase_options.dart`). The app runs fully on-device and says so in
  Profile. Login, registration and password-reset screens are deferred until
  a backend is set up.
- **Biometric app lock** needs `local_auth`, which isn't a dependency yet.
- **Receipt attachments** need an image picker; deferred to Phase 4.
- **Dashboard customization** (reorder/hide widgets) isn't built.
- **Currency** is chosen once at setup; multi-currency accounts aren't supported.
- **Budgets tab** explains that budgets come next instead of showing fake data.
- Visual: the hero amount's `₹` renders at the baseline rather than raised;
  snackbars on tab pages can sit under the centre add key.
