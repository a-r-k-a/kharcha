import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/domain/clock.dart';
import 'package:kharcha/core/domain/failure.dart';
import 'package:kharcha/core/domain/money.dart';
import 'package:kharcha/features/ledger/data/repositories/ledger_store.dart';
import 'package:kharcha/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha/features/profile/presentation/bloc/session_cubit.dart';

import '../../helpers/in_memory_ledger.dart';
import '../../helpers/test_app.dart';

void main() {
  late LedgerStore store;
  late InMemoryProfileRepository profiles;
  final clock = FixedClock(DateTime.utc(2026, 11, 4));

  setUp(() {
    store = LedgerStore(InMemoryLedgerOpener());
    profiles = InMemoryProfileRepository();
  });

  tearDown(() => store.dispose());

  SessionCubit build() =>
      SessionCubit(profiles: profiles, ledger: store, clock: clock);

  blocTest<SessionCubit, SessionState>(
    'no profile means setup is needed',
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [SessionLoading(), SessionNeedsSetup()],
  );

  blocTest<SessionCubit, SessionState>(
    'a stored profile opens its books',
    setUp: () => profiles.profile = testProfile,
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const SessionLoading(), SessionReady(testProfile)],
    verify: (_) => expect(store.current, isNotNull),
  );

  blocTest<SessionCubit, SessionState>(
    'a storage failure makes the session unavailable',
    setUp: () => profiles.failure = const StorageFailure(),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [
      SessionLoading(),
      SessionUnavailable(StorageFailure()),
    ],
  );

  blocTest<SessionCubit, SessionState>(
    'setup saves a local profile and opens the books',
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.completeSetup(displayName: ' Ravi ', currency: Currency.usd);
    },
    skip: 2,
    expect: () => [
      const SessionNeedsSetup(isSaving: true),
      SessionReady(
        UserProfile(
          ownerId: UserProfile.localOwnerId,
          displayName: 'Ravi',
          currency: Currency.usd,
          createdAt: clock.now(),
        ),
      ),
    ],
    verify: (_) => expect(store.current?.currency, Currency.usd),
  );

  blocTest<SessionCubit, SessionState>(
    'erasing deletes the books and returns to setup',
    setUp: () => profiles.profile = testProfile,
    build: build,
    act: (cubit) async {
      await cubit.start();
      await store.saveAccount(testAccount('bank'));
      await cubit.eraseEverything();
    },
    skip: 2,
    expect: () => const [SessionNeedsSetup()],
    verify: (_) {
      expect(profiles.profile, isNull);
      expect(store.current, isNull);
    },
  );

  test('firstName takes the first word', () {
    expect(testProfile.firstName, 'Asha');
  });
}
