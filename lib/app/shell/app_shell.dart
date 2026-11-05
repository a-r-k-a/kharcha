import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/pressable.dart';
import '../router/app_route.dart';

/// Root layout for the five navigation branches, plus the centre add key
/// that opens the quick-add sheet from any tab.
///
/// Phones get a bottom bar with the key floating above its centre; wide
/// windows (tablets, desktop) get a side rail and a capped content width.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _Destination('Home', AppIcons.home, AppIcons.homeActive),
    _Destination('Activity', AppIcons.activity, AppIcons.activityActive),
    _Destination('Budgets', AppIcons.budgets, AppIcons.budgetsActive),
    _Destination('Insights', AppIcons.insights, AppIcons.insightsActive),
    _Destination('Profile', AppIcons.profile, AppIcons.profileActive),
  ];

  /// Width from which the rail replaces the bottom bar.
  static const wideBreakpoint = 840.0;

  /// Content never stretches beyond this on wide windows.
  static const _maxContentWidth = 760.0;

  void _onSelect(int index) {
    // Re-tapping the active tab returns it to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _openQuickAdd(BuildContext context) =>
      context.pushNamed(AppRoute.quickAdd.name);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _LedgerNavRail(
              destinations: _destinations,
              currentIndex: navigationShell.currentIndex,
              onSelect: _onSelect,
              onAdd: () => _openQuickAdd(context),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: navigationShell,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _LedgerNavBar(
        destinations: _destinations,
        currentIndex: navigationShell.currentIndex,
        onSelect: _onSelect,
      ),
      floatingActionButton: _QuickAddKey(
        onPressed: () => _openQuickAdd(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Hairline-topped strip; the active tab gets an accent tick on its top
/// edge instead of a pill (DESIGN.md §6).
class _LedgerNavBar extends StatelessWidget {
  const _LedgerNavBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<_Destination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.line,
            width: context.elevation.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  onPressed: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Vertical counterpart of [_LedgerNavBar] for wide windows; the active
/// tab's tick sits on the leading edge.
class _LedgerNavRail extends StatelessWidget {
  const _LedgerNavRail({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final List<_Destination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(
          end: BorderSide(
            color: colors.line,
            width: context.elevation.hairline,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 96,
          child: Column(
            children: [
              SizedBox(height: space.xl),
              _QuickAddKey(onPressed: onAdd),
              SizedBox(height: space.xl),
              for (var i = 0; i < destinations.length; i++)
                _NavItem(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  onPressed: () => onSelect(i),
                  vertical: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onPressed,
    this.vertical = false,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onPressed;

  /// Rail layout: the selection tick sits on the leading edge.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = context.motion;
    final foreground = selected ? colors.textPrimary : colors.textTertiary;

    final tick = AnimatedContainer(
      duration: context.motionDuration(motion.medium),
      curve: motion.enter,
      height: vertical ? (selected ? 24 : 0) : 2,
      width: vertical ? 2 : (selected ? 24 : 0),
      color: colors.accentStrong,
    );
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: selected && !context.reduceMotion ? 1.08 : 1,
          duration: context.motionDuration(motion.fast),
          curve: motion.standard,
          child: Icon(
            selected ? destination.activeIcon : destination.icon,
            size: 22,
            color: foreground,
          ),
        ),
        SizedBox(height: context.space.xs),
        Text(
          destination.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: context.typeScale.label.copyWith(color: foreground),
        ),
      ],
    );

    return Semantics(
      selected: selected,
      child: Pressable(
        onPressed: onPressed,
        haptic: PressHaptic.selection,
        pressedScale: 0.92,
        semanticLabel: '${destination.label} tab',
        child: ExcludeSemantics(
          child: SizedBox(
            height: vertical ? 72 : 64,
            child: vertical
                ? Row(
                    children: [
                      tick,
                      Expanded(child: content),
                    ],
                  )
                : Column(
                    children: [
                      tick,
                      Expanded(child: content),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Square accent key with a hard offset block; sinks when pressed.
class _QuickAddKey extends StatelessWidget {
  const _QuickAddKey({required this.onPressed});

  final VoidCallback onPressed;

  static const double _size = 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevation = context.elevation;

    return Pressable.builder(
      onPressed: onPressed,
      haptic: PressHaptic.medium,
      tooltip: 'Add',
      semanticLabel: 'Add transaction or account',
      builder: (context, pressed) {
        final sink = pressed && !context.reduceMotion ? 1.0 : 0.0;
        return AnimatedContainer(
          duration: context.motion.tap,
          curve: context.motion.standard,
          width: _size,
          height: _size,
          transform: Matrix4.translationValues(
            0,
            elevation.liftOffset * sink,
            0,
          ),
          decoration: BoxDecoration(
            color: colors.actionFill,
            borderRadius: context.radii.action,
            boxShadow: elevation.liftShadow(
              colors.actionLift,
              pressedFraction: sink,
            ),
          ),
          child: Icon(AppIcons.add, color: colors.onActionFill, size: 26),
        );
      },
    );
  }
}
