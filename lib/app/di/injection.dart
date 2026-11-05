import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../core/domain/clock.dart';
import '../../core/domain/id_generator.dart';
import '../../core/formatting/money_formatter.dart';
import '../../core/storage/cipher_key_store.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/utils/uuid_id_generator.dart';
import '../../features/ledger/data/datasources/hive_ledger_collections.dart';
import '../../features/ledger/data/repositories/ledger_store.dart';
import '../../features/profile/data/repositories/hive_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/session_cubit.dart';
import '../../features/settings/data/repositories/hive_appearance_repository.dart';
import '../../features/settings/domain/repositories/appearance_repository.dart';
import '../../features/settings/presentation/bloc/appearance_cubit.dart';
import '../router/app_router.dart';
import 'app_dependencies.dart';

/// Composition root. Only `main.dart` and tests touch [getIt]; widgets and
/// blocs receive their dependencies through constructors or providers.
final GetIt getIt = GetIt.instance;

/// Registers everything the app needs. Requires `Hive.initFlutter()` first.
Future<void> configureDependencies() async {
  // Core
  getIt
    ..registerSingleton<Clock>(const SystemClock())
    ..registerSingleton<IdGenerator>(const UuidIdGenerator())
    ..registerSingleton<MoneyFormatter>(MoneyFormatter());

  // Settings (unencrypted: UI preferences only)
  final preferencesBox = await Hive.openBox<String>(HiveBoxes.preferences);
  getIt
    ..registerSingleton<AppearanceRepository>(
      HiveAppearanceRepository(preferencesBox),
    )
    ..registerSingleton<AppearanceCubit>(
      AppearanceCubit(getIt()),
      dispose: (cubit) => cubit.close(),
    );

  // Encrypted storage. Opening is deferred to first use so keystore errors
  // surface as a recoverable session failure, not a crash at launch.
  const encryptedBoxes = EncryptedBoxOpener(
    SecureCipherKeyStore(FlutterSecureStorage()),
  );
  getIt
    ..registerSingleton<LedgerStore>(
      LedgerStore(const HiveLedgerCollectionsOpener(encryptedBoxes)),
      dispose: (store) => store.dispose(),
    )
    ..registerSingleton<ProfileRepository>(
      HiveProfileRepository(() => encryptedBoxes.open(HiveBoxes.profile)),
    );

  // Session
  getIt.registerSingleton<SessionCubit>(
    SessionCubit(
      profiles: getIt(),
      ledger: getIt<LedgerStore>(),
      clock: getIt(),
    ),
    dispose: (cubit) => cubit.close(),
  );

  // Navigation
  final session = getIt<SessionCubit>();
  getIt
    ..registerSingleton<SessionRouterRefresh>(
      SessionRouterRefresh(session.stream),
      dispose: (refresh) => refresh.dispose(),
    )
    ..registerSingleton<GoRouter>(
      buildAppRouter(session: session, refresh: getIt<SessionRouterRefresh>()),
      dispose: (router) => router.dispose(),
    );
}

/// The widget tree's dependencies, read from the container once.
AppDependencies appDependencies() => AppDependencies.fromStore(
  store: getIt(),
  clock: getIt(),
  ids: getIt(),
  moneyFormatter: getIt(),
  session: getIt(),
  appearance: getIt(),
  router: getIt(),
);
