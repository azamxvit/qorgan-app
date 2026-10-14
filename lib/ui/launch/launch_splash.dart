import 'package:flutter/material.dart';

import '../core/colors.dart';
import 'brand_mark.dart';

/// One second of branding; never owns or delays application initialization.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({required this.onComplete, super.key});
  final VoidCallback onComplete;
  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
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

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final enter = Curves.easeOutCubic.transform((t / .36).clamp(0, 1));
        final exit = Curves.easeInOut.transform(((t - .8) / .2).clamp(0, 1));
        return Opacity(
          opacity: reducedMotion ? 1 : 1 - exit,
          child: ColoredBox(
            color: QorganColors.canvas,
            child: Center(
              child: Opacity(
                opacity: reducedMotion ? 1 : enter,
                child: Transform.scale(
                  scale: reducedMotion ? 1 : .94 + .06 * enter,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(),
          const SizedBox(height: 18),
          Text(
            'Qorğan',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontSize: 32),
          ),
        ],
      ),
    );
  }
}
