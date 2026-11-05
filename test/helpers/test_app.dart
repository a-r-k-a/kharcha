import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kharcha/app/app.dart';
import 'package:kharcha/app/di/app_dependencies.dart';
import 'package:kharcha/app/router/app_router.dart';
import 'package:kharcha/core/domain/clock.dart';
import 'package:kharcha/core/domain/failure.dart';
import 'package:kharcha/core/domain/id_generator.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/core/domain/result.dart';
import 'package:kharcha/core/formatting/money_formatter.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha/features/profile/domain/repositories/profile_repository.dart';
import 'package:kharcha/features/profile/presentation/bloc/session_cubit.dart';
import 'package:kharcha/features/settings/domain/entities/appearance_settings.dart';
import 'package:kharcha/features/settings/domain/repositories/appearance_repository.dart';
import 'package:kharcha/features/settings/presentation/bloc/appearance_cubit.dart';

import 'in_memory_ledger.dart';

final class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository([this.profile]);

  UserProfile? profile;

  /// When set, every call fails with it.
  Failure? failure;

  @override
  Future<Result<UserProfile?>> load() async =>
      failure == null ? Ok(profile) : Err(failure ?? const StorageFailure());

  @override
  Future<Result<void>> save(UserProfile value) async {
    if (failure case final f?) return Err(f);
    profile = value;
    return const Ok(null);
  }

  @override
  Future<Result<void>> clear() async {
    profile = null;
    return const Ok(null);
  }
}

final class InMemoryAppearanceRepository implements AppearanceRepository {
  AppearanceSettings settings = const AppearanceSettings();

  @override
  Future<Result<AppearanceSettings>> load() async => Ok(settings);

  @override
  Future<Result<void>> save(AppearanceSettings value) async {
    settings = value;
    return const Ok(null);
  }
}

final testProfile = UserProfile(
  ownerId: UserProfile.localOwnerId,
  displayName: 'Asha Rao',
  currency: Currency.inr,
  createdAt: DateTime.utc(2026),
);

/// The real app over in-memory storage, a fixed clock and sequential ids.
final class TestApp {
  TestApp._({
    required this.store,
    required this.profiles,
    required this.session,
    required this.router,
    required this.dependencies,
    required this.clock,
    required this._refresh,
    required this._appearance,
  });

  /// Builds and starts the session. Pass `profile: null` for first run.
  static Future<TestApp> create({
    UserProfile? profile,
    bool withProfile = true,
    String? initialLocation,
    DateTime? now,
  }) async {
    final clock = FixedClock(now ?? DateTime(2026, 11, 4, 10));
    final store = LedgerStore(InMemoryLedgerOpener());
    final profiles = InMemoryProfileRepository(
      withProfile ? (profile ?? testProfile) : null,
    );
    final session = SessionCubit(
      profiles: profiles,
      ledger: store,
      clock: clock,
    );
    await session.start();
    final appearance = AppearanceCubit(InMemoryAppearanceRepository());
    final refresh = SessionRouterRefresh(session.stream);
    final router = buildAppRouter(
      session: session,
      refresh: refresh,
      initialLocation: initialLocation,
      includeDevRoutes: false,
    );
    final dependencies = AppDependencies.fromStore(
      store: store,
      clock: clock,
      ids: SequentialIdGenerator(),
      moneyFormatter: MoneyFormatter(),
      session: session,
      appearance: appearance,
      router: router,
    );
    return TestApp._(
      store: store,
      profiles: profiles,
      session: session,
      router: router,
      dependencies: dependencies,
      clock: clock,
      refresh: refresh,
      appearance: appearance,
    );
  }

  final LedgerStore store;
  final InMemoryProfileRepository profiles;
  final SessionCubit session;
  final GoRouter router;
  final AppDependencies dependencies;
  final FixedClock clock;
  final SessionRouterRefresh _refresh;
  final AppearanceCubit _appearance;

  String get location => router.routeInformationProvider.value.uri.path;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(KharchaApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    router.dispose();
    _refresh.dispose();
    await session.close();
    await _appearance.close();
    await store.dispose();
  }
}
