# Kharcha: Architecture

Offline-first personal finance tracker. Flutter 3.47 / Dart 3.13.
Visual design: [`lib/core/theme/DESIGN.md`](lib/core/theme/DESIGN.md).

## Setup

The repo holds `lib/`, `test/`, `assets/` and config. Platform folders and
Firebase config are generated:

```sh
flutter create . --org com.kharcha --platforms android,ios --project-name kharcha
rm test/widget_test.dart             # template test; references a MyApp that doesn't exist
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure                # writes lib/firebase_options.dart (needed for cloud sync, not yet used)
flutter test
flutter run
```

> **Material lives in a package now.** Material and Cupertino were decoupled
> from the SDK into `material_ui` / `cupertino_ui`, and go_router 18 builds its
> pages with them. Always import `package:material_ui/material_ui.dart`, never
> `package:flutter/material.dart`. The two define *distinct* `ThemeData`
> types, and mixing them silently drops the app theme from routes.

## Layers

```
presentation  ──▶  domain  ◀──  data
 (widgets, blocs)  (entities, use cases,   (Hive / Firestore sources,
                    repository contracts)   DTOs, repository impls)
```

- **Domain** is pure Dart: no Flutter, Hive, Firebase or intl imports.
  Business rules (balances, cash flow, validation, insights) live
  here as plain classes with unit tests.
- **Data** implements domain repository interfaces and maps every
  implementation error to a `Failure` at the boundary. Callers receive a
  `Result<T>` (`Ok` / `Err`), never a raw exception.
- **Presentation** holds widgets plus BLoCs/Cubits. Blocs get use cases or
  repository interfaces through their constructors, never `getIt` and never
  `BuildContext`. Widgets read dependencies from `RepositoryProvider`s that
  `KharchaApp` installs from `AppDependencies`.

## Folder structure

`●` exists now, `○` arrives in a later phase. Status per feature: [`ROADMAP.md`](ROADMAP.md).

```
lib/
├── main.dart                         ● bootstrap: error hooks, Hive, DI, session start, first frame
├── app/
│   ├── app.dart                      ● providers + MaterialApp.router
│   ├── di/                           ● get_it composition root, AppDependencies
│   ├── router/                       ● AppRoute enum, GoRouter, session redirects, ActivityLink, SheetPage
│   ├── shell/                        ● 5-tab shell (bottom bar / wide rail), quick-add sheet
│   ├── pages/                        ● not-found
│   └── dev/design_catalog_page.dart  ● debug-only living style guide
├── core/
│   ├── domain/                       ● Money, Result, Failure, Clock, IdGenerator, DateRange/Period
│   ├── formatting/                   ● MoneyFormatter (en_IN lakh/crore), DateLabels
│   ├── storage/                      ● box names, CipherKeyStore (keystore AES keys), EncryptedBoxOpener
│   ├── theme/                        ● DESIGN.md, tokens, AppTheme, AppIcons
│   ├── utils/                        ● UUID ids, debounce event transformer
│   └── widgets/                      ● Pressable, AppButton, MoneyText, AmountField, AppChip,
│                                       segmented control, SheetScaffold, option sheet, snackbars, …
└── features/
    ├── ledger/                       ● the shared finance core
    │   ├── domain/                   ● Account, Category, Transaction, Ledger snapshot,
    │   │                               LedgerAnalytics, InsightEngine, TransactionQuery,
    │   │                               LedgerValidator, use cases, default categories
    │   ├── data/                     ● LedgerStore (cache + snapshot stream), JSON codec,
    │   │                               Hive / in-memory record collections
    │   └── presentation/             ● labels, category styling, tiles, LedgerWatcher mixin
    ├── dashboard/presentation/       ● DashboardCubit, dashboard page, spending chart, breakdown
    ├── transactions/presentation/    ● ActivityBloc, form cubit, details cubit, pages
    ├── accounts/presentation/        ● overview, form, details, reconcile
    ├── categories/presentation/      ● list, form (custom categories, icon/color)
    ├── insights/presentation/        ● month-by-month analysis
    ├── budgets/presentation/         ● tab only; budgets are Phase 2
    ├── profile/                      ● UserProfile, encrypted repository, SessionCubit,
    │                                   welcome/setup, profile tab
    └── settings/                     ● appearance (theme mode, accent)
```

Features that only present ledger data (dashboard, transactions, accounts,
categories, insights) have no `domain/` or `data/` of their own: they read
the one `ledger` aggregate, so balances and reports can never disagree.

## Accounting rules

| Rule | Implementation |
|---|---|
| Money | Integer minor units (`Money`); input parsed exactly with `Money.tryParse`, never via `double` |
| Balances | Never stored. `opening balance + Σ transaction effects`, recomputed per snapshot |
| Sign | User's point of view: liabilities (cards, loans) carry negative balances |
| Transfers | One record, two legs: leaves `accountId`, enters `counterpartyAccountId`. Excluded from income and expense |
| Adjustments | From reconciling; change one balance, never count as income or expense |
| Net cash flow | Income − expenses (transfers and adjustments excluded) |
| Savings rate | (income − expenses) ÷ income × 100; undefined (not 0) without income |
| Net worth | Σ active balances; each account is an asset or liability by the sign of its balance |
| Investments / debt payments | Moving money into an investment account or paying a card is a transfer: the spend was counted when it happened, so nothing is double-counted |
| Reimbursements | Expense when paid; repayment recorded as income under "Refunds & reimbursements" |
| Splits | Allocations must sum to the amount exactly; reports roll subcategories up to their parent |
| Time | Instants stored in UTC; periods and day grouping use the device's local time; weeks start Monday |
| Archived accounts | Hidden from pickers and totals; history stays in reports. Accounts with history can't be deleted |
| Deleting a category | Custom only; its transactions move to the parent (or "Other") in the same write |

## Key decisions

| Concern | Choice | Why |
|---|---|---|
| State | `flutter_bloc`: Cubit for simple state, Bloc where events matter | Explicit, testable state transitions |
| DI | `get_it`, manual registration | No codegen; registration is short and readable |
| Routing | go_router, `StatefulShellRoute.indexedStack` | Tabs keep their own stacks; setup/unavailable redirects via `refreshListenable` on the session |
| Sheets | `SheetPage` (a `Page` that builds `ModalBottomSheetRoute`) | Every form (transaction, account, category, reconcile, quick add) is deep-linkable and back-dismissable |
| Money | `Money` in integer minor units | No float drift in budget arithmetic; `tryParse` for exact keypad input |
| Local store | `hive_ce`, JSON strings in AES-encrypted boxes, one set of boxes per owner | Maintained Hive fork, no codegen; Isar is unmaintained. Drift would add build_runner; the ledger is small enough to hold in memory, and a transfer is a single record, so writes stay atomic |
| Encryption | 256-bit key generated on first use, kept in the platform keystore via `flutter_secure_storage` | Financial data is unreadable from the raw files (tested) |
| Session | Local profile (`owner = device`) opened before the first frame; router redirects on `SessionCubit` | Works offline with no account. Cloud sign-in needs Firebase configuration that this repo doesn't have yet |
| Sync (planned) | Local-first writes + outbox; Firestore in background; last-write-wins on `updatedAt` | Instant UI, offline by default |
| Time | Injected `Clock` | Date rules (month length, streaks, rollover) are deterministic in tests |
| Icons | Phosphor fonts bundled in `assets/fonts`, exposed as `const IconData` in `AppIcons` | Distinct from stock Material. The `phosphor_flutter` package doesn't compile on 3.47 (it subclasses `IconData`, now `final`) |
| Fonts | Bundled Space Grotesk / IBM Plex Sans / IBM Plex Mono | Works offline; `tnum` verified for numerals |

## Conventions

- Widgets read every visual value from tokens (`context.colors`, `context.space`,
  …). Durations go through `context.motionDuration()` for reduced motion.
- All taps go through `Pressable` (haptics, focus, semantics, 48dp minimum).
- Every screen designs loading (skeleton), empty and error states.
- Navigation by route name (`context.goNamed(AppRoute.x.name)`); blocs never
  navigate.
- Tests: domain logic gets unit tests, blocs get `bloc_test`, key flows get
  widget tests. `test/core/theme/contrast_test.dart` guards accessibility of
  every palette.
