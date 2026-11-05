import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/result.dart';
import '../../domain/entities/appearance_settings.dart';
import '../../domain/repositories/appearance_repository.dart';

final class AppearanceState extends Equatable {
  const AppearanceState({
    this.settings = const AppearanceSettings(),
    this.saveFailure,
  });

  final AppearanceSettings settings;

  /// Set when the last change applied in memory but could not be persisted.
  final Failure? saveFailure;

  @override
  List<Object?> get props => [settings, saveFailure];
}

/// Owns the app's theme mode and accent. Changes apply immediately and are
/// persisted in the background.
class AppearanceCubit extends Cubit<AppearanceState> {
  AppearanceCubit(this._repository) : super(const AppearanceState());

  final AppearanceRepository _repository;

  /// Call once before the first frame so the app never flashes the wrong
  /// theme. A read failure keeps the defaults.
  Future<void> load() async {
    final result = await _repository.load();
    if (isClosed) return;
    if (result case Ok(:final value)) {
      emit(AppearanceState(settings: value));
    }
  }

  Future<void> setThemePreference(ThemePreference preference) =>
      _apply(state.settings.copyWith(themePreference: preference));

  Future<void> setAccent(AccentTheme accent) =>
      _apply(state.settings.copyWith(accent: accent));

  Future<void> _apply(AppearanceSettings next) async {
    if (next == state.settings) return;
    emit(AppearanceState(settings: next));
    final result = await _repository.save(next);
    // Ignore results for a change that has since been superseded.
    if (isClosed || state.settings != next) return;
    if (result case Err(:final failure)) {
      emit(AppearanceState(settings: next, saveFailure: failure));
    }
  }
}
