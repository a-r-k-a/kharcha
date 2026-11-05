# Claude Code Project Instructions

These instructions define the architectural, engineering, and UI
standards for this project. Follow them whenever you inspect, create,
modify, or review code.

## 1. Project defaults and priorities

-   This is a **Flutter application written in Dart**.
-   Use **Clean Architecture** with clearly separated `data`, `domain`,
    and `presentation` layers.
-   Use **BLoC** for application state management and **GoRouter** for
    navigation.
-   Prefer readable, maintainable, testable code over clever
    abstractions.
-   Preserve the conventions and dependencies already established in the
    repository. Inspect the project before proposing structural changes.
-   Do not introduce a new package, architectural pattern, or
    code-generation dependency without a clear need.
-   Do not silently change public APIs, persistence formats, routes, or
    business rules.

## 2. Clean Architecture

Keep dependencies pointing inward:

1.  **Presentation** depends on domain.
2.  **Data** implements domain contracts and depends on domain.
3.  **Domain** is independent of Flutter, UI frameworks, storage,
    networking, and data-layer implementations.

Suggested feature-first structure:

``` text
lib/
  app/
    app.dart
    router/
      app_router.dart
    di/
      injection.dart
    theme/
      app_theme.dart
  core/
    error/
    network/
    utils/
    widgets/
  features/
    feature_name/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/
```

Adapt this structure to the existing project when necessary; do not
create empty folders or layers that add no value.

### Domain layer

-   Put business rules and application-specific logic here.
-   Define entities as plain Dart objects. Keep them independent of
    Flutter and serialization packages.
-   Define repository contracts (abstract classes) in the domain layer.
-   Put use cases here when they express a meaningful business operation
    or help isolate complex business logic.
-   Keep domain classes deterministic and straightforward to unit test.
-   Do not import `package:flutter`, widgets, BLoC, GoRouter, HTTP
    clients, or database packages into domain code.

### Data layer

-   Implement domain repository contracts in this layer.
-   Keep API clients, local storage, DTOs, serializers, and data sources
    here.
-   Convert data models to domain entities at repository boundaries. Do
    not leak API/JSON models into presentation or domain.
-   Abstract remote and local data sources behind clear interfaces when
    multiple sources or testability justify it.
-   Handle network, parsing, and persistence errors explicitly. Map
    implementation-specific failures into domain-level failures or typed
    results.
-   Never put UI logic or navigation in repositories or data sources.

### Presentation layer

-   Organize screens and widgets by feature.
-   Keep widgets focused on rendering and user interaction.
-   Use BLoC for feature state and event handling.
-   Keep business rules out of widgets. Delegate them to BLoCs and
    domain use cases.
-   Use immutable state classes and explicit loading, success, empty,
    and failure states where appropriate.
-   Keep reusable design-system components in a shared location only
    when they are genuinely shared.

## 3. State management: BLoC

Use `flutter_bloc` and the BLoC event/state pattern for feature state.

-   Each feature should have a clearly named BLoC, event types, and
    state types (for example, `ProfileBloc`, `ProfileEvent`, and
    `ProfileState`).
-   Events represent user or system intents; states represent the UI
    state.
-   Keep BLoCs free of `BuildContext`, widget references, and direct
    navigation calls.
-   Inject use cases or domain repository abstractions into BLoCs; do
    not instantiate API clients or data sources inside a BLoC.
-   Keep event handlers small and delegate business operations to use
    cases.
-   Emit immutable states. Prefer `Equatable` or the project's
    established equality/code-generation approach to avoid unnecessary
    rebuilds.
-   Model asynchronous operations explicitly. Handle success, expected
    failures, unexpected exceptions, and cancellation where relevant.
-   Avoid duplicate requests and stale-response bugs when a feature can
    issue overlapping requests.
-   Use `BlocBuilder` for rendering state, `BlocListener` for one-off
    effects (navigation, dialogs, snackbars), and `BlocConsumer` only
    when both are needed.
-   Use `buildWhen` and `listenWhen` only when they improve correctness
    or measured performance; do not add them mechanically.
-   Do not use `setState` as a parallel state-management system for
    feature/business state. It is acceptable for small, ephemeral,
    purely local widget state.
-   Close manually created stream controllers and other disposable
    resources. Let `BlocProvider` manage BLoC lifecycle according to
    whether it creates or merely provides the instance.
-   Test BLoCs by asserting emitted states for representative event
    sequences, including failures and edge cases.

## 4. Navigation: GoRouter

Use `go_router` as the single source of truth for app navigation.

-   Define routes centrally (or in feature route modules composed by a
    central router).
-   Use named routes for navigation where practical.
-   Use typed route parameters and query parameters; validate and safely
    parse external or optional input.
-   Pass stable identifiers in paths rather than entire domain objects
    when the destination can load its own data.
-   Use `GoRouter` redirects for authentication and other route-guard
    logic. Keep redirect decisions separate from widget build methods.
-   Handle unknown routes with a deliberate not-found screen.
-   Keep deep links and browser URLs (if applicable) consistent with
    route definitions.
-   Do not mix `Navigator.push`/manual route stacks with GoRouter for
    ordinary app navigation.
-   Do not navigate from a BLoC. Emit a state or one-off effect and let
    the presentation layer perform navigation.
-   Avoid rebuilding or recreating the router on every widget build.
    Keep router configuration stable and refresh it only through an
    intentional mechanism when auth state changes.
-   Add tests for important redirects, route parameters, deep links, and
    not-found behavior.

## 5. Dart quality, const constructors, and null safety

These rules are mandatory. Generated code must be efficient,
predictable, and soundly typed.

### Const constructors

-   Add `const` constructors to immutable classes and widgets whenever
    all instance fields and constructor arguments permit it.
-   Mark widget instantiations `const` whenever their arguments are
    compile-time constants.
-   Prefer `const` for immutable values such as `EdgeInsets`,
    `Duration`, `TextStyle`, `SizedBox`, `Icon`, and static collections
    when valid.
-   Make fields `final` by default. Avoid mutable fields unless mutation
    is an explicit requirement.
-   Use `const` collections (`const []`, `const {}`, `const {}`) when
    their contents are compile-time constants.
-   Do not force `const` where it is invalid or makes code less clear.
    Never change runtime behavior merely to obtain a const constructor.
-   When generating or editing files, review analyzer output for
    avoidable `prefer_const_constructors`, `prefer_const_declarations`,
    and related lint warnings.

### Null safety

-   Keep sound null safety enabled. Never add `// @dart=2.x` overrides
    or disable null-safety checks to work around a type error.
-   Make values non-nullable by default. Add `?` only when absence is a
    valid part of the domain or API contract.
-   Do not use `!` (null assertion) as a shortcut. Prefer explicit
    checks, early returns, null-aware operators, pattern matching, or
    validated conversion.
-   Avoid `late` unless initialization order genuinely requires it and
    the invariant is clear.
-   Do not use `dynamic` for convenience. Prefer concrete types,
    generics, sealed types, and `Object?` at untrusted boundaries.
-   Parse nullable API fields defensively and distinguish missing, null,
    malformed, and defaultable values where the product requires it.
-   Do not silently replace meaningful missing values with arbitrary
    defaults.
-   Model loading, empty, success, and error states explicitly rather
    than encoding them as ambiguous nullable fields.
-   Use `required` for mandatory named parameters and provide defaults
    only when they are semantically correct.
-   Keep generated serializers and model constructors aligned with
    actual API nullability; do not make every field nullable merely to
    silence parsing errors.
-   Check that asynchronous callbacks and streams do not outlive the
    objects they update.

### General Dart conventions

-   Follow `dart format` and the repository's lint configuration.
-   Use descriptive names and avoid abbreviations that obscure intent.
-   Prefer small, single-purpose functions and widgets.
-   Use `final` for local variables unless reassignment is necessary.
-   Avoid force-unwrapping, broad catch-and-ignore blocks, unnecessary
    casts, and unexplained magic values.
-   Add documentation to public APIs when their behavior or constraints
    are not obvious.
-   Do not suppress lints globally. If a suppression is unavoidable,
    keep it narrow and explain why.

## 6. UI and design direction: modern, interactive, animated

The interface should feel polished, contemporary, responsive, and alive.
Use animation purposefully to improve feedback, hierarchy, and
continuity---not as decoration that slows users down.

### Visual design

-   Build a coherent design system: color tokens, typography, spacing,
    radii, elevation, borders, and motion durations.
-   Use Material 3 as a foundation where appropriate, while customizing
    components to match the product's visual identity.
-   Favor clear hierarchy, generous but disciplined spacing, strong
    contrast, refined surfaces, and consistent iconography.
-   Support light and dark themes unless the product requirements
    explicitly exclude one.
-   Design responsive layouts for small phones, large phones, tablets,
    and desktop/web targets that the project supports.
-   Respect safe areas, keyboard insets, text scaling, and system
    accessibility settings.
-   Use reusable components for repeated patterns, but avoid
    over-generalizing one-off UI.

### Animation and interaction

-   Use Flutter's implicit animations (`AnimatedContainer`,
    `AnimatedOpacity`, `AnimatedSwitcher`, `TweenAnimationBuilder`,
    etc.) for straightforward transitions.
-   Use explicit animations (`AnimationController`, `Tween`,
    `CurvedAnimation`, `Hero`, or an appropriate animation package) when
    sequencing, gestures, or fine control is needed.
-   Animate meaningful state changes: selection, expansion, loading,
    success, errors, navigation transitions, and content appearance.
-   Use subtle transitions, coherent easing curves, and consistent
    durations. Avoid excessive bouncing, flashing, or long animations.
-   Provide tactile feedback where appropriate, such as pressed,
    focused, selected, disabled, and loading states.
-   Make interactive elements visibly interactive and ensure their hit
    targets are comfortably large.
-   Use skeletons or purposeful progress indicators for loading, and
    animate empty/error/success transitions without hiding important
    information.
-   Keep scrolling smooth. Use lazy builders for long lists and avoid
    expensive work in `build`.
-   Dispose of animation controllers and other resources correctly,
    preferably with lifecycle-aware patterns.
-   Respect `MediaQuery.disableAnimations` / reduced-motion preferences.
    Provide a reduced-motion alternative for non-essential animation.
-   Never use animation to delay access to essential content or block
    critical actions.

### Accessibility

-   Maintain readable contrast and support text scaling.
-   Give icon-only controls semantic labels and tooltips.
-   Ensure all actions are accessible by keyboard and assistive
    technologies on supported platforms.
-   Do not communicate state through color or animation alone.
-   Preserve focus order and visible focus indicators where applicable.

## 7. Performance

-   Keep `build` methods fast and free of network, database, or
    expensive computation work.
-   Prefer `const` widgets and immutable data to reduce unnecessary
    widget reconstruction.
-   Use `ListView.builder`, `GridView.builder`, and other lazy widgets
    for large collections.
-   Avoid broad BLoC rebuilds; select only the state needed by a widget
    where practical.
-   Cache appropriately and avoid duplicate network requests.
-   Use image sizing, caching, and decoding strategies appropriate to
    the target devices.
-   Avoid unnecessary opacity, clipping, shadows, and complex effects in
    large scrolling areas.
-   Profile before applying complicated optimizations. Do not sacrifice
    clarity for speculative micro-optimizations.
-   Ensure animations remain smooth and do not perform expensive
    synchronous work on the UI isolate.

## 8. Dependency injection and configuration

-   Use the dependency-injection approach already present in the
    repository. If none exists, choose a lightweight, consistent
    approach (for example, `get_it`) only when it provides clear value.
-   Register dependencies at the composition root, not inside widgets or
    BLoCs.
-   Depend on abstractions in domain-facing code.
-   Keep environment-specific configuration outside source code. Never
    commit secrets, API keys, signing credentials, or private endpoints.
-   Keep package versions compatible with the project's Flutter and Dart
    SDK constraints.

## 9. Error handling and observability

-   Represent expected failures explicitly and show actionable,
    user-friendly feedback.
-   Do not expose stack traces, raw server responses, tokens, or
    internal implementation details to users.
-   Log useful diagnostic context without logging credentials or
    sensitive personal data.
-   Avoid swallowing exceptions. Catch only when the code can handle,
    translate, or meaningfully report the failure.
-   Keep error mapping consistent across repositories and features.

## 10. Testing expectations

-   Write unit tests for domain use cases, entities with meaningful
    behavior, and data mapping.
-   Write BLoC tests for initial state, success, failure, edge cases,
    and concurrent/repeated events where relevant.
-   Write widget tests for important interactions, loading/error/empty
    states, and accessibility semantics.
-   Write routing tests for redirects, deep links, parameters, and
    unknown routes.
-   Add integration tests for critical end-to-end flows when practical.
-   Keep tests deterministic; avoid real network calls and wall-clock
    timing where possible. Inject fakes, clocks, and test dependencies.
-   A bug fix should include a regression test when feasible.

## 11. Code generation rules

-   Follow the repository's existing generator conventions (such as
    `build_runner`, `freezed`, or `json_serializable`) rather than
    introducing competing approaches.
-   Treat generated files as generated output. Do not hand-edit them
    unless the generator's documentation explicitly requires it.
-   Update source annotations/models first, then run the appropriate
    generator command.
-   Keep generated models soundly null-safe and use `const` constructors
    wherever supported.
-   Do not commit stale generated output. Verify generated files are in
    sync with source definitions.
-   Do not run destructive generation or cleanup commands without
    understanding their scope.
-   If a generator fails, report the actual failure and do not fabricate
    generated code.

## 12. Working agreement for Claude

Before making changes:

1.  Inspect the repository structure, `pubspec.yaml`, analysis options,
    existing architecture, and relevant feature implementations.
2.  Identify the smallest coherent change that satisfies the request.
3.  Follow existing naming, formatting, dependency-injection, and
    testing conventions unless they conflict with these instructions.
4.  Check whether a similar component, use case, BLoC, route, or design
    token already exists before creating another.

While making changes:

1.  Keep changes scoped to the requested feature.
2.  Maintain the data/domain/presentation dependency direction.
3.  Put state transitions in BLoCs and navigation in the
    presentation/router layer.
4.  Add const constructors and const widget instances wherever valid.
5.  Preserve sound null safety; do not use unsafe shortcuts to silence
    the analyzer.
6.  Build responsive, accessible UI with purposeful animation and
    complete interaction states.
7.  Add or update tests alongside behavior changes.

Before finishing:

1.  Run `dart format` on changed Dart files.
2.  Run `flutter analyze` (or the repository's documented analysis
    command).
3.  Run relevant tests with `flutter test` (or the repository's
    documented test command).
4.  Run code generation if source annotations or generated models
    changed.
5.  Review the diff for accidental changes, dead code, debug statements,
    secrets, missing keys, and avoidable rebuilds.
6.  State what changed, which checks were run, and any checks that could
    not be completed. Never claim a command or test passed unless it was
    actually run.

## 13. Definition of done

A change is complete when:

-   It follows Clean Architecture and the established feature structure.
-   Business logic is outside widgets and infrastructure details are
    outside domain.
-   BLoC owns feature state transitions; GoRouter owns app navigation.
-   Dart code is soundly null-safe and uses `const` wherever valid.
-   UI is responsive, accessible, polished, and animated appropriately.
-   Loading, empty, success, and error states are handled where
    applicable.
-   Relevant tests and static analysis pass, or outstanding failures are
    clearly reported.
-   No secrets, unrelated refactors, or stale generated files are
    introduced.
