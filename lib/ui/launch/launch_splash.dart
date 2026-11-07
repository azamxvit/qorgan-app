import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/colors.dart';
import 'brand_mark.dart';

/// The mint ground closes into a circle around the mark and then behind it.
///
/// Never owns or delays application initialization. With [holdMark] the mark
/// stays at the screen centre, turned mint, where the welcome page draws the
/// same mark; otherwise it closes together with the circle.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({
    required this.onComplete,
    this.holdMark = false,
    super.key,
  });
  final VoidCallback onComplete;
  final bool holdMark;

  static const duration = Duration(milliseconds: 1400);

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  static const _collapse = Cubic(.65, 0, .25, 1);
  static const _close = Cubic(.5, 0, .75, 0);

  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: LaunchSplash.duration,
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress of [curve] between [from] and [to] milliseconds.
  static double _span(double ms, double from, double to, [Curve? curve]) {
    final t = ((ms - from) / (to - from)).clamp(0.0, 1.0);
    return curve?.transform(t) ?? t;
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final ms = reducedMotion
            ? 0.0
            : _controller.value * LaunchSplash.duration.inMilliseconds;
        final collapse = _span(ms, 400, 1000, _collapse);
        final close = _span(ms, 1100, 1400, _close);
        final click = _span(ms, 980, 1280);
        final pulse = ms >= 1000 && ms < 1400 ? _span(ms, 1000, 1400) : 0.0;

        var markSize = 128 - 32 * collapse;
        if (!widget.holdMark) markSize *= 1 - close;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _GroundPainter(collapse: collapse, close: close),
            ),
            Center(
              child: BrandMark(
                key: const ValueKey('launch-mark'),
                size: markSize,
                color: Color.lerp(
                  QorganColors.mintInk,
                  QorganColors.mint,
                  _span(ms, 1100, 1400),
                )!,
                coreScale: 1 + .3 * math.sin(math.pi * click),
                ring: pulse,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter({required this.collapse, required this.close});
  final double collapse;
  final double close;

  /// Radius of the settled circle around the 96 px mark.
  static const _settled = 76.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final cover = centre.distance + 1;
    final radius = (cover + (_settled - cover) * collapse) * (1 - close);
    if (radius <= 0) return;
    canvas.drawCircle(centre, radius, Paint()..color = QorganColors.mint);
  }

  @override
  bool shouldRepaint(_GroundPainter oldDelegate) =>
      oldDelegate.collapse != collapse || oldDelegate.close != close;
}
