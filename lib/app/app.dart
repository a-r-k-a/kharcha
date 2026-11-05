import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../core/domain/clock.dart';
import '../core/formatting/money_format_scope.dart';
import '../core/formatting/money_formatter.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_reveal.dart';
import '../features/ledger/domain/repositories/ledger_repositories.dart';
import '../features/profile/presentation/bloc/session_cubit.dart';
import '../features/settings/presentation/appearance_mapping.dart';
import '../features/settings/presentation/bloc/appearance_cubit.dart';
import 'di/app_dependencies.dart';

class KharchaApp extends StatelessWidget {
  const KharchaApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  static const title = 'Kharcha';

  @override
  Widget build(BuildContext context) {
    final d = dependencies;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Clock>.value(value: d.clock),
        RepositoryProvider<LedgerRepository>.value(value: d.ledger),
        RepositoryProvider.value(value: d.saveTransaction),
        RepositoryProvider.value(value: d.deleteTransaction),
        RepositoryProvider.value(value: d.restoreTransaction),
        RepositoryProvider.value(value: d.saveAccount),
        RepositoryProvider.value(value: d.setAccountArchived),
        RepositoryProvider.value(value: d.deleteAccount),
        RepositoryProvider.value(value: d.reconcileAccount),
        RepositoryProvider.value(value: d.saveCategory),
        RepositoryProvider.value(value: d.deleteCategory),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppearanceCubit>.value(value: d.appearance),
          BlocProvider<SessionCubit>.value(value: d.session),
        ],
        child: _ThemedApp(dependencies: d),
      ),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp({required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final router = dependencies.router;
    final moneyFormatter = dependencies.moneyFormatter;
    return BlocBuilder<AppearanceCubit, AppearanceState>(
      buildWhen: (previous, current) => previous.settings != current.settings,
      builder: (context, state) {
        final palette = state.settings.accent.palette;
        return MaterialApp.router(
          title: KharchaApp.title,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.of(Brightness.light, palette),
          darkTheme: AppTheme.of(Brightness.dark, palette),
          themeMode: state.settings.themePreference.themeMode,
          // The circular reveal animates theme changes; MaterialApp's own
          // cross-fade would fight it.
          themeAnimationDuration: Duration.zero,
          builder: (context, child) => _AppChrome(
            moneyFormatter: moneyFormatter,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// App-wide wrappers that need the resolved theme.
class _AppChrome extends StatelessWidget {
  const _AppChrome({required this.moneyFormatter, required this.child});

  final MoneyFormatter moneyFormatter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
      child: MoneyFormatScope(
        formatter: moneyFormatter,
        child: ThemeReveal(child: child),
      ),
    );
  }
}
