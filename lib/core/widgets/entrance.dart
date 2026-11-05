import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

/// Fades and lifts its child into place on first build. [index] staggers
/// siblings. Renders immediately under reduced motion.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  /// Beyond this many siblings the stagger stops growing, so long lists
  /// never wait on their entrance.
  static const _maxStaggered = 8;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    final motion = context.motion;
    final delay =
        motion.stagger * (index < _maxStaggered ? index : _maxStaggered);
    final total = motion.medium + delay;
    final start = delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: motion.enter),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
