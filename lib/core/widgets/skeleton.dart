import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

/// Wraps skeleton placeholders with a single hard-edged scanline that sweeps
/// across all of them. One controller per group, not per box.
class SkeletonGroup extends StatefulWidget {
  const SkeletonGroup({
    super.key,
    required this.child,
    this.semanticLabel = 'Loading',
  });

  final Widget child;
  final String semanticLabel;

  @override
  State<SkeletonGroup> createState() => _SkeletonGroupState();
}

class _SkeletonGroupState extends State<SkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  static const _bandHalfWidth = 0.06;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ExcludeSemantics(child: widget.child);
    final Widget content;
    if (context.reduceMotion) {
      content = child;
    } else {
      final highlight = context.colors.skeletonHighlight;
      content = AnimatedBuilder(
        animation: _controller,
        child: child,
        builder: (context, child) {
          // Travel from just off the left edge to just off the right.
          final center =
              -_bandHalfWidth + _controller.value * (1 + 2 * _bandHalfWidth);
          final from = (center - _bandHalfWidth).clamp(0.0, 1.0);
          final to = (center + _bandHalfWidth).clamp(0.0, 1.0);
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.transparent,
                Colors.transparent,
                highlight,
                highlight,
                Colors.transparent,
                Colors.transparent,
              ],
              stops: [0, from, from, to, to, 1],
            ).createShader(bounds),
            child: child,
          );
        },
      );
    }
    return Semantics(label: widget.semanticLabel, child: content);
  }
}

/// A solid placeholder block. Place inside a [SkeletonGroup].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.skeletonBase,
        borderRadius: context.radii.card,
      ),
    );
  }
}

/// Lines of placeholder text; the last line is shorter, like real copy.
class SkeletonText extends StatelessWidget {
  const SkeletonText({super.key, this.lines = 2, this.lineHeight = 12});

  final int lines;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final gap = context.space.sm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) SizedBox(height: gap),
          FractionallySizedBox(
            widthFactor: i == lines - 1 && lines > 1 ? 0.6 : 1,
            child: SkeletonBox(height: lineHeight),
          ),
        ],
      ],
    );
  }
}
