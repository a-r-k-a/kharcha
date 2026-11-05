import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/clock.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

final class SessionLoading extends SessionState {
  const SessionLoading();
}

/// No profile yet: first-run setup is needed.
final class SessionNeedsSetup extends SessionState {
  const SessionNeedsSetup({this.isSaving = false, this.failure});

  final bool isSaving;

  /// Set when the last setup attempt failed.
  final Failure? failure;

  @override
  List<Object?> get props => [isSaving, failure];
}

/// A profile exists and its books are open.
final class SessionReady extends SessionState {
  const SessionReady(this.profile, {this.saveFailure});

  final UserProfile profile;

  /// Set when the last profile edit could not be saved.
  final Failure? saveFailure;

  @override
  List<Object?> get props => [profile, saveFailure];
}

/// The profile or books could not be opened.
final class SessionUnavailable extends SessionState {
  const SessionUnavailable(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Owns who is using the app and opens their books. The router redirects
/// on this state; it is the only gate in front of the ledger.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required this._profiles,
    required this._ledger,
    required this._clock,
  }) : super(const SessionLoading());

  final ProfileRepository _profiles;
  final LedgerRepository _ledger;
  final Clock _clock;

  /// Loads the stored profile and opens its books. Call before the first
  /// frame so the right screen shows immediately.
  Future<void> start() async {
    emit(const SessionLoading());
    switch (await _profiles.load()) {
      case Err(:final failure):
        _emitSafely(SessionUnavailable(failure));
      case Ok(value: null):
        _emitSafely(const SessionNeedsSetup());
      case Ok(value: final UserProfile profile):
        await _openBooks(profile);
    }
  }

  /// First-run setup for on-device use.
  Future<void> completeSetup({
    required String displayName,
    required Currency currency,
  }) async {
    final current = state;
    if (current is! SessionNeedsSetup || current.isSaving) return;
    if (displayName.trim().isEmpty) return;
    emit(const SessionNeedsSetup(isSaving: true));
    final profile = UserProfile(
      ownerId: UserProfile.localOwnerId,
      displayName: displayName.trim(),
      currency: currency,
      createdAt: _clock.now().toUtc(),
    );
    switch (await _profiles.save(profile)) {
      case Err(:final failure):
        _emitSafely(SessionNeedsSetup(failure: failure));
      case Ok():
        await _openBooks(profile);
    }
  }

  Future<void> rename(String displayName) async {
    final current = state;
    if (current is! SessionReady) return;
    final trimmed = displayName.trim();
    if (trimmed.isEmpty || trimmed == current.profile.displayName) return;
    final updated = current.profile.copyWith(displayName: trimmed);
    final result = await _profiles.save(updated);
    _emitSafely(
      SessionReady(
        result is Ok ? updated : current.profile,
        saveFailure: switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        },
      ),
    );
  }

  /// Permanently deletes the books and profile on this device.
  Future<Result<void>> eraseEverything() async {
    final erased = await _ledger.eraseAll();
    if (erased is Err<void>) return erased;
    final cleared = await _profiles.clear();
    if (cleared is Err<void>) return cleared;
    _emitSafely(const SessionNeedsSetup());
    return const Ok(null);
  }

  Future<void> _openBooks(UserProfile profile) async {
    final opened = await _ledger.open(
      ownerId: profile.ownerId,
      currency: profile.currency,
    );
    _emitSafely(switch (opened) {
      Ok() => SessionReady(profile),
      Err(:final failure) => SessionUnavailable(failure),
    });
  }

  void _emitSafely(SessionState next) {
    if (!isClosed) emit(next);
  }
}
