import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import 'theme_context.dart';

/// Circular reveal for theme changes (DESIGN.md §6).
///
/// Snapshots the current frame, applies the theme change underneath, then
/// wipes the snapshot away with a growing circle from [ThemeRevealState.reveal]'s
/// origin. Install once, in `MaterialApp.builder`, and set
/// `themeAnimationDuration: Duration.zero` so the theme swaps instantly under
/// the snapshot.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({super.key, required this.child});

  final Widget child;

  static ThemeRevealState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ThemeRevealState>();
    if (state == null) {
      throw StateError('No ThemeReveal above this context.');
    }
    return state;
  }

  @override
  State<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  late final AnimationController _controller = AnimationController(vsync: this);
  ui.Image? _snapshot;
  Offset _origin = Offset.zero;

  /// Runs [change] behind a circular wipe centred on [originContext]
  /// (typically the toggle that was tapped). Falls back to an instant change
  /// under reduced motion or when a snapshot can't be taken.
  Future<void> reveal({
    required BuildContext originContext,
    required VoidCallback change,
  }) async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    final self = context.findRenderObject();
    final origin = originContext.findRenderObject();
    if (_snapshot != null ||
        context.reduceMotion ||
        boundary is! RenderRepaintBoundary ||
        self is! RenderBox ||
        origin is! RenderBox) {
      change();
      return;
    }

    final centre = self.globalToLocal(
      origin.localToGlobal(origin.size.center(Offset.zero)),
    );
    final image = await boundary.toImage(
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    if (!mounted) {
      image.dispose();
      return;
    }

    setState(() {
      _snapshot = image;
      _origin = centre;
    });
    change();

    _controller.duration = context.motion.reveal;
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposed mid-reveal; nothing left to clean up but the image.
    } finally {
      image.dispose();
      if (mounted) setState(() => _snapshot = null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (snapshot != null)
          Positioned.fill(
            // Swallow input while the old frame is still on screen.
            child: AbsorbPointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _RevealPainter(
                    image: snapshot,
                    origin: _origin,
                    progress: context.motion.enter.transform(_controller.value),
                    edgeColor: context.colors.accentStrong,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealPainter extends CustomPainter {
  const _RevealPainter({
    required this.image,
    required this.origin,
    required this.progress,
    required this.edgeColor,
  });

  final ui.Image image;
  final Offset origin;
  final double progress;
  final Color edgeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxRadius = corners
        .map((corner) => (corner - origin).distance)
        .reduce(math.max);
    final radius = maxRadius * progress;
    final bounds = Offset.zero & size;

    final hole = Path()
      ..addOval(Rect.fromCircle(center: origin, radius: radius));
    final remaining = Path.combine(
      PathOperation.difference,
      Path()..addRect(bounds),
      hole,
    );

    canvas
      ..save()
      ..clipPath(remaining);
    paintImage(canvas: canvas, rect: bounds, image: image, fit: BoxFit.fill);
    canvas.restore();

    if (radius > 0 && progress < 1) {
      canvas.drawCircle(
        origin,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = edgeColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RevealPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.image != image ||
      oldDelegate.edgeColor != edgeColor;
}
