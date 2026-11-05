import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'features/profile/presentation/bloc/session_cubit.dart';
import 'features/settings/presentation/bloc/appearance_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'Flutter error',
      name: 'app',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    developer.log(
      'Uncaught error',
      name: 'app',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  LicenseRegistry.addLicense(_fontLicenses);
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  await Hive.initFlutter();
  await initializeDateFormatting();
  await configureDependencies();

  // Load appearance and open the user's books before the first frame, so
  // neither the theme nor the first screen ever flashes.
  await getIt<AppearanceCubit>().load();
  await getIt<SessionCubit>().start();

  runApp(KharchaApp(dependencies: appDependencies()));
}

Stream<LicenseEntry> _fontLicenses() async* {
  const licenses = {
    'Space Grotesk': 'assets/licenses/OFL-SpaceGrotesk.txt',
    'IBM Plex': 'assets/licenses/OFL-IBMPlex.txt',
    'Phosphor Icons': 'assets/licenses/MIT-Phosphor.txt',
  };
  for (final MapEntry(key: package, value: path) in licenses.entries) {
    yield LicenseEntryWithLineBreaks([
      package,
    ], await rootBundle.loadString(path));
  }
}
