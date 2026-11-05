import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/state_views.dart';
import '../bloc/session_cubit.dart';

/// Shown when the profile or books can't be opened (e.g. storage error).
class SessionUnavailablePage extends StatelessWidget {
  const SessionUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ErrorStateView(
            title: 'Couldn’t open your books',
            message:
                'The data on this device couldn’t be read. Make sure there '
                'is free storage, then try again. Nothing has been deleted.',
            onRetry: () => context.read<SessionCubit>().start(),
          ),
        ),
      ),
    );
  }
}
