import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/domain/money.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/app_elevation.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/budget_ring.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../features/settings/presentation/widgets/appearance_controls.dart';

/// Debug-only living style guide: every token and core component on one
/// scrolling page, in the current theme. Registered only in debug builds.
class DesignCatalogPage extends StatefulWidget {
  const DesignCatalogPage({super.key});

  @override
  State<DesignCatalogPage> createState() => _DesignCatalogPageState();
}

class _DesignCatalogPageState extends State<DesignCatalogPage> {
  final _random = math.Random();
  Money _balance = Money.fromMajor(48250.5);
  double _ringProgress = 0.42;
  bool _loading = false;

  void _shuffleBalance() {
    setState(() => _balance = Money(_random.nextInt(25000000)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    final type = context.typeScale;
    final gap = SizedBox(height: space.xxl);
    final tone = BudgetTone.fromProgress(_ringProgress);

    return Scaffold(
      appBar: AppBar(title: const Text('Design catalog')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          space.gutter,
          space.lg,
          space.gutter,
          space.huge,
        ),
        children: [
          Text(
            'Night Ledger',
            style: type.display.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: space.xs),
          Text(
            'Dark luxury, neo-brutal. See lib/core/theme/DESIGN.md.',
            style: type.body.copyWith(color: colors.textSecondary),
          ),
          gap,
          const SectionLabel('Theme', index: 1),
          SizedBox(height: space.lg),
          const ThemeModeToggle(),
          SizedBox(height: space.lg),
          const AccentPicker(level: 99),
          gap,
          SectionLabel(
            'Money',
            index: 2,
            trailing: AppButton(
              label: 'Shuffle',
              variant: AppButtonVariant.ghost,
              onPressed: _shuffleBalance,
            ),
          ),
          SizedBox(height: space.lg),
          AnimatedMoney(_balance, size: MoneySize.hero, countUpOnMount: true),
          SizedBox(height: space.md),
          MoneyText(Money.fromMajor(1240), size: MoneySize.large),
          SizedBox(height: space.sm),
          MoneyText(Money.fromMajor(312.75)),
          SizedBox(height: space.sm),
          MoneyText(
            Money.fromMajor(-1850),
            size: MoneySize.small,
            color: colors.danger,
          ),
          gap,
          const SectionLabel('Budget ring', index: 3),
          SizedBox(height: space.lg),
          Center(
            child: BudgetRing(
              progress: _ringProgress,
              semanticLabel: 'Sample daily budget',
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_ringProgress * 100).round()}%',
                    style: type.moneyLarge.copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    tone.label.toUpperCase(),
                    style: type.label.copyWith(color: tone.colorFrom(colors)),
                  ),
                ],
              ),
            ),
          ),
          Slider(
            value: _ringProgress,
            max: 1.4,
            label: '${(_ringProgress * 100).round()}%',
            onChanged: (value) => setState(() => _ringProgress = value),
          ),
          gap,
          const SectionLabel('Actions', index: 4),
          SizedBox(height: space.lg),
          AppButton(
            label: 'Accept challenge',
            icon: AppIcons.forward,
            expand: true,
            isLoading: _loading,
            onPressed: () => setState(() => _loading = !_loading),
          ),
          SizedBox(height: space.md),
          Wrap(
            spacing: space.md,
            runSpacing: space.md,
            children: [
              AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                label: 'Ghost',
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                label: 'Delete',
                variant: AppButtonVariant.danger,
                onPressed: () {},
              ),
              const AppButton(label: 'Disabled', onPressed: null),
            ],
          ),
          gap,
          const SectionLabel('Surfaces', index: 5),
          SizedBox(height: space.lg),
          _SurfaceSample(
            label: 'Outlined — default card',
            child: Text(
              'Hairline border, no shadow.',
              style: type.body.copyWith(color: colors.textSecondary),
            ),
          ),
          SizedBox(height: space.md),
          SurfaceCard(
            level: ElevationLevel.lifted,
            onPressed: () {},
            semanticLabel: 'Lifted card sample',
            child: Text(
              'Lifted — press me, I sink.',
              style: type.bodyStrong.copyWith(color: colors.textPrimary),
            ),
          ),
          SizedBox(height: space.md),
          SurfaceCard(
            tone: SurfaceTone.accent,
            level: ElevationLevel.flat,
            child: Text(
              'Accent — the one thing going well.',
              style: type.bodyStrong.copyWith(color: colors.onAccent),
            ),
          ),
          SizedBox(height: space.md),
          SurfaceCard(
            tone: SurfaceTone.inverted,
            level: ElevationLevel.flat,
            child: Text(
              'Inverted — negative print for hero moments.',
              style: type.bodyStrong.copyWith(color: colors.canvas),
            ),
          ),
          gap,
          const SectionLabel('Loading', index: 6),
          SizedBox(height: space.lg),
          SkeletonGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 180, height: 48),
                SizedBox(height: space.lg),
                const SkeletonText(lines: 3),
                SizedBox(height: space.lg),
                const SkeletonBox(height: 72),
              ],
            ),
          ),
          gap,
          const SectionLabel('Empty & error', index: 7),
          EmptyStateView(
            title: 'No expenses yet',
            message: 'Log your first one. It takes about five seconds.',
            action: AppButton(label: 'Add expense', onPressed: () {}),
          ),
          ErrorStateView(
            title: "Couldn't load reports",
            message: "We'll keep trying when you're back online.",
            icon: AppIcons.offline,
            onRetry: () {},
          ),
          const SectionLabel('Type scale', index: 8),
          SizedBox(height: space.lg),
          for (final (name, style) in [
            ('display', type.display),
            ('title', type.title),
            ('titleSmall', type.titleSmall),
            ('body', type.body),
            ('bodyStrong', type.bodyStrong),
            ('bodySmall', type.bodySmall),
            ('LABEL', type.label),
            ('LABEL LARGE', type.labelLarge),
          ]) ...[
            Text(name, style: style.copyWith(color: colors.textPrimary)),
            SizedBox(height: space.sm),
          ],
          gap,
          const SectionLabel('Color tokens', index: 9),
          SizedBox(height: space.lg),
          Wrap(
            spacing: space.sm,
            runSpacing: space.sm,
            children: [
              for (final (name, color) in [
                ('canvas', colors.canvas),
                ('surface', colors.surface),
                ('raised', colors.surfaceRaised),
                ('line', colors.line),
                ('lineStrong', colors.lineStrong),
                ('text1', colors.textPrimary),
                ('text2', colors.textSecondary),
                ('text3', colors.textTertiary),
                ('accent', colors.accent),
                ('accentStrong', colors.accentStrong),
                ('watch', colors.watch),
                ('warning', colors.warning),
                ('danger', colors.danger),
              ])
                _Swatch(name: name, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceSample extends StatelessWidget {
  const _SurfaceSample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.typeScale.label.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: context.space.sm),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: context.radii.card,
              border: Border.all(
                color: context.colors.line,
                width: context.elevation.hairline,
              ),
            ),
          ),
          SizedBox(height: context.space.xs),
          Text(
            name,
            style: context.typeScale.label.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
