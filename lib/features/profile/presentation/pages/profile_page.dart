import 'package:flutter/material.dart' hide ScaffoldMessenger;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kharcha/app/router/app_route.dart';
import 'package:kharcha/core/domain/result.dart';
import 'package:kharcha/core/theme/app_icons.dart';
import 'package:kharcha/core/theme/theme_context.dart';
import 'package:kharcha/core/widgets/app_button.dart';
import 'package:kharcha/core/widgets/app_snack_bar.dart';
import 'package:kharcha/core/widgets/confirm_dialog.dart';
import 'package:kharcha/core/widgets/list_row.dart';
import 'package:kharcha/core/widgets/page_header.dart';
import 'package:kharcha/core/widgets/section_label.dart';
import 'package:kharcha/core/widgets/surface_card.dart';
import 'package:kharcha/features/ledger/domain/repositories/ledger_repositories.dart';
import 'package:kharcha/features/ledger/presentation/ledger_labels.dart';
import 'package:kharcha/features/profile/domain/entities/user_profile.dart';
import 'package:kharcha/features/profile/presentation/bloc/profile_summary_cubit.dart';
import 'package:kharcha/features/profile/presentation/bloc/session_cubit.dart';
import 'package:kharcha/features/settings/presentation/widgets/appearance_controls.dart';
import 'package:material_ui/material_ui.dart'
    hide showDialog, Scaffold, AlertDialog, TextField, InputDecoration;

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _rename(BuildContext context, UserProfile profile) async {
    final cubit = context.read<SessionCubit>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: profile.displayName),
    );
    if (name != null) await cubit.rename(name);
  }

  Future<void> _erase(BuildContext context) async {
    final cubit = context.read<SessionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Erase everything?',
      message:
          'This permanently deletes every account, transaction, category and '
          'your profile from this device. It can’t be undone.',
      confirmLabel: 'Erase all data',
      destructive: true,
    );
    if (!confirmed) return;
    final result = await cubit.eraseEverything();
    if (result case Err(:final failure)) {
      // The page may be gone by now: erasing resets the session.
      messenger.showMessage(failureMessage(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.colors;
    final profile = context.select<SessionCubit, UserProfile?>(
      (cubit) => switch (cubit.state) {
        SessionReady(:final profile) => profile,
        _ => null,
      },
    );
    return BlocProvider(
      create: (context) =>
          ProfileSummaryCubit(context.read<LedgerRepository>()),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocListener<SessionCubit, SessionState>(
            listenWhen: (a, b) =>
                b is SessionReady && b.saveFailure != null && a != b,
            listener: (context, state) {
              if (state case SessionReady(saveFailure: final failure?)) {
                showAppSnackBar(context, failureMessage(failure));
              }
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const PageHeader(title: 'Profile'),
                if (profile != null)
                  Padding(
                    padding: space.screen,
                    child: SurfaceCard(
                      onPressed: () => _rename(context, profile),
                      semanticLabel: '${profile.displayName}. Edit name',
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: context.radii.card,
                            ),
                            child: Text(
                              profile.firstName.isEmpty
                                  ? '?'
                                  : profile.firstName.characters.first
                                        .toUpperCase(),
                              style: context.typeScale.title.copyWith(
                                color: colors.onAccent,
                              ),
                            ),
                          ),
                          SizedBox(width: space.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.displayName,
                                  style: context.typeScale.titleSmall.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: space.xxs),
                                Text(
                                  'On this device · ${profile.currency.code}',
                                  style: context.typeScale.bodySmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(AppIcons.edit, color: colors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                const _Section(
                  index: 1,
                  title: 'Money',
                  children: [_MoneyRows()],
                ),
                _Section(
                  index: 2,
                  title: 'Appearance',
                  children: [
                    const ThemeModeToggle(),
                    SizedBox(height: space.lg),
                    const AccentPicker(),
                  ],
                ),
                _Section(
                  index: 3,
                  title: 'Privacy & data',
                  children: [
                    const ListRow(
                      title: 'Stored on this device',
                      subtitle:
                          'Your books are encrypted with a key kept in the '
                          'device keystore. Nothing is uploaded.',
                      icon: AppIcons.lock,
                    ),
                    const ListRow(
                      title: 'Cloud backup & sync',
                      subtitle:
                          'Not available in this build yet. Until then, data '
                          'lives only on this device.',
                      icon: AppIcons.offline,
                    ),
                    SizedBox(height: space.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton(
                        label: 'Erase all data',
                        icon: AppIcons.delete,
                        variant: AppButtonVariant.danger,
                        onPressed: () => _erase(context),
                      ),
                    ),
                  ],
                ),
                _Section(
                  index: 4,
                  title: 'About',
                  children: [
                    ListRow(
                      title: 'Open-source licences',
                      icon: AppIcons.info,
                      onPressed: () =>
                          context.pushNamed(AppRoute.licenses.name),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyRows extends StatelessWidget {
  const _MoneyRows();

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProfileSummaryCubit>().state;
    final accounts = summary.activeAccounts;
    final custom = summary.customCategories;
    return Column(
      children: [
        ListRow(
          title: 'Accounts',
          subtitle: accounts == 1
              ? '1 active account'
              : '$accounts active accounts',
          icon: AppIcons.accounts,
          onPressed: () => context.pushNamed(AppRoute.accounts.name),
        ),
        ListRow(
          title: 'Categories',
          subtitle: custom == 0
              ? 'Built-in set'
              : 'Built-in plus $custom custom',
          icon: AppIcons.categories,
          onPressed: () => context.pushNamed(AppRoute.categories.name),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.index,
    required this.title,
    required this.children,
  });

  final int index;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Padding(
      padding: EdgeInsets.fromLTRB(space.gutter, space.xxl, space.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(title, index: index),
          SizedBox(height: space.md),
          ...children,
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: UserProfile.nameLength,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(labelText: 'NAME', counterText: ''),
      ),
      actionsPadding: EdgeInsets.all(context.space.lg),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => AppButton(
            label: 'Save',
            variant: AppButtonVariant.secondary,
            onPressed: value.text.trim().isEmpty ? null : _submit,
          ),
        ),
      ],
    );
  }
}
