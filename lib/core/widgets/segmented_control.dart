import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import 'pressable.dart';

class SegmentOption<T> {
  const SegmentOption(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Equal-width segments in a hairline frame; the selection slides between
/// them.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.semanticLabel,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inset = context.space.xxs;
    final selectedIndex = options.indexWhere((o) => o.value == selected);

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        height: 48,
        padding: EdgeInsets.all(inset),
        decoration: BoxDecoration(
          borderRadius: context.radii.control,
          border: Border.all(
            color: colors.lineStrong,
            width: context.elevation.hairline,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth / options.length;
            return Stack(
              children: [
                if (selectedIndex >= 0)
                  AnimatedPositionedDirectional(
                    duration: context.motionDuration(context.motion.medium),
                    curve: context.motion.enter,
                    start: width * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.textPrimary,
                        borderRadius: BorderRadius.circular(
                          context.radii.controlValue - inset,
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (final option in options)
                      Expanded(
                        child: _Segment(
                          option: option,
                          selected: option.value == selected,
                          onPressed: () => onChanged(option.value),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onPressed,
  });

  final SegmentOption<T> option;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.canvas : colors.textSecondary;
    final icon = option.icon;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: selected ? () {} : onPressed,
        haptic: PressHaptic.selection,
        semanticLabel: option.label,
        minSize: 40,
        focusRadius: context.radii.control,
        child: ExcludeSemantics(
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: context.motionDuration(context.motion.fast),
              style: context.typeScale.label.copyWith(color: foreground),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foreground),
                    SizedBox(width: context.space.xs),
                  ],
                  Flexible(
                    child: Text(
                      option.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
