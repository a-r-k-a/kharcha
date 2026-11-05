import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/failure.dart';
import 'package:kharcha/core/domain/result.dart';
import 'package:kharcha/features/settings/domain/entities/appearance_settings.dart';
import 'package:kharcha/features/settings/domain/repositories/appearance_repository.dart';
import 'package:kharcha/features/settings/presentation/bloc/appearance_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppearanceRepository extends Mock implements AppearanceRepository {}

void main() {
  late _MockAppearanceRepository repository;

  const stored = AppearanceSettings(
    themePreference: ThemePreference.light,
    accent: AccentTheme.glacier,
  );

  setUpAll(() => registerFallbackValue(const AppearanceSettings()));

  setUp(() {
    repository = _MockAppearanceRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  test('starts with dark Volt defaults', () {
    expect(AppearanceCubit(repository).state, const AppearanceState());
  });

  blocTest<AppearanceCubit, AppearanceState>(
    'load emits stored settings',
    setUp: () =>
        when(() => repository.load()).thenAnswer((_) async => const Ok(stored)),
    build: () => AppearanceCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => const [AppearanceState(settings: stored)],
  );

  blocTest<AppearanceCubit, AppearanceState>(
    'load failure keeps defaults',
    setUp: () =>
        when(() => repository.load())
            .thenAnswer((_) async => const Err(StorageFailure())),
    build: () => AppearanceCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => const <AppearanceState>[],
  );

  blocTest<AppearanceCubit, AppearanceState>(
    'setThemePreference applies immediately and persists',
    build: () => AppearanceCubit(repository),
    act: (cubit) => cubit.setThemePreference(ThemePreference.system),
    expect: () => const [
      AppearanceState(
        settings: AppearanceSettings(themePreference: ThemePreference.system),
      ),
    ],
    verify: (_) => verify(
      () => repository.save(
        const AppearanceSettings(themePreference: ThemePreference.system),
      ),
    ).called(1),
  );

  blocTest<AppearanceCubit, AppearanceState>(
    'setting the current value is a no-op',
    build: () => AppearanceCubit(repository),
    act: (cubit) => cubit.setAccent(AccentTheme.volt),
    expect: () => const <AppearanceState>[],
    verify: (_) => verifyNever(() => repository.save(any())),
  );

  blocTest<AppearanceCubit, AppearanceState>(
    'save failure keeps the change and reports it',
    setUp: () =>
        when(() => repository.save(any()))
            .thenAnswer((_) async => const Err(StorageFailure())),
    build: () => AppearanceCubit(repository),
    act: (cubit) => cubit.setAccent(AccentTheme.flamingo),
    expect: () => const [
      AppearanceState(
        settings: AppearanceSettings(accent: AccentTheme.flamingo),
      ),
      AppearanceState(
        settings: AppearanceSettings(accent: AccentTheme.flamingo),
        saveFailure: StorageFailure(),
      ),
    ],
  );

  test('accent unlock levels', () {
    expect(AccentTheme.volt.isUnlockedAt(1), isTrue);
    expect(AccentTheme.glacier.isUnlockedAt(4), isFalse);
    expect(AccentTheme.glacier.isUnlockedAt(5), isTrue);
  });
}
