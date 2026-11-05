import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import '../theme/tokens/app_colors.dart';

/// Budget tone scale (DESIGN.md §2.3).
enum BudgetTone {
  calm,
  watch,
  warning,
  over;

  static BudgetTone fromProgress(
    double progress, {
    double watchAt = 0.5,
    double warnAt = 0.8,
  }) {
    if (progress >= 1) return over;
    if (progress >= warnAt) return warning;
    if (progress >= watchAt) return watch;
    return calm;
  }

  /// Text paired with the tone color, so state never relies on color alone.
  String get label => switch (this) {
    calm => 'On track',
    watch => 'Watch',
    warning => 'Close to limit',
    over => 'Over budget',
  };

  Color colorFrom(AppColors colors) => switch (this) {
    calm => colors.accentStrong,
    watch => colors.watch,
    warning => colors.warning,
    over => colors.danger,
  };
}

/// Square-capped progress ring with threshold notches and an outer overflow
/// lap past 100%. The color is derived from the *animated* value, so the ring
/// visibly crosses into amber/red as it fills.
class BudgetRing extends StatelessWidget {
  const BudgetRing({
    super.key,
    required this.progress,
    required this.semanticLabel,
    this.watchAt = 0.5,
    this.warnAt = 0.8,
    this.size = 200,
    this.strokeWidth = 14,
    this.center,
  });

  /// Spent ÷ budget. May exceed 1.
  final double progress;
  final String semanticLabel;
  final double watchAt;
  final double warnAt;
  final double size;
  final double strokeWidth;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clamped = progress.isFinite ? math.max(0.0, progress) : 0.0;

    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()} percent used',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clamped),
        duration: context.motionDuration(context.motion.slow),
        curve: context.motion.enter,
        builder: (context, value, child) {
          final tone = BudgetTone.fromProgress(
            value,
            watchAt: watchAt,
            warnAt: warnAt,
          );
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: tone.colorFrom(colors),
              trackColor: colors.line,
              notchColor: colors.canvas,
              overflowColor: colors.danger,
              notches: [watchAt, warnAt],
              strokeWidth: strokeWidth,
            ),
            child: child,
          );
        },
        child: SizedBox.square(
          dimension: size,
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.notchColor,
    required this.overflowColor,
    required this.notches,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final Color notchColor;
  final Color overflowColor;
  final List<double> notches;
  final double strokeWidth;

  static const _start = -math.pi / 2;
  static const _overflowGap = 6.0;
  static const _overflowStroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius =
        size.shortestSide / 2 -
        strokeWidth / 2 -
        _overflowGap -
        _overflowStroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, stroke..color = trackColor);

    final sweep = math.min(progress, 1.0) * 2 * math.pi;
    if (sweep > 0) {
      canvas.drawArc(rect, _start, sweep, false, stroke..color = color);
    }

    // Notches cut through the ring at each threshold.
    final notch = Paint()
      ..color = notchColor
      ..strokeWidth = 2;
    for (final at in notches) {
      final angle = _start + at * 2 * math.pi;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - strokeWidth / 2 - 1),
        center + direction * (radius + strokeWidth / 2 + 1),
        notch,
      );
    }

    if (progress > 1) {
      final overflowRadius =
          radius + strokeWidth / 2 + _overflowGap + _overflowStroke / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: overflowRadius),
        _start,
        math.min(progress - 1, 1.0) * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _overflowStroke
          ..strokeCap = StrokeCap.butt
          ..color = overflowColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.notchColor != notchColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      !_sameNotches(oldDelegate.notches);

  bool _sameNotches(List<double> other) {
    if (other.length != notches.length) return false;
    for (var i = 0; i < notches.length; i++) {
      if (other[i] != notches[i]) return false;
    }
    return true;
  }
}
