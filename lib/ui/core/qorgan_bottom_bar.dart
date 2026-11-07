import 'package:flutter/material.dart';

import 'colors.dart';

class QorganBottomBar extends StatelessWidget {
  const QorganBottomBar({
    this.onSms,
    this.selectedIndex = 0,
    this.onSelected,
    super.key,
  });
  final VoidCallback? onSms;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  static const _labels = ['Защита', 'Проверить SMS', 'Сообщения'];
  static const _keys = ['tab-protection', 'tab-check', 'tab-messages'];
  // One outlined Material family, already bundled with the application.
  static const _icons = [
    Icons.shield_outlined,
    Icons.fact_check_outlined,
    Icons.chat_bubble_outline,
  ];

  void _select(int index) {
    if (onSelected != null) {
      onSelected!(index);
    } else if (index == 2) {
      onSms?.call();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: QorganColors.surface,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: QorganColors.ink.withValues(alpha: .07),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: QorganColors.surface,
            borderRadius: BorderRadius.circular(36),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _animatedTabs(context, constraints.maxWidth),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _animatedTabs(BuildContext context, double width) {
    final target = List.generate(3, (i) => i == selectedIndex ? 1.0 : 0.0);
    final labelWidth = width * .6 - 56;
    const textStyle = TextStyle(
      fontSize: 13,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: QorganColors.mintInk,
    );
    // All destinations share the same track height. Measuring every label
    // keeps the panel stable when Russian text wraps at accessibility sizes.
    var height = 52.0;
    for (final label in _labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: labelWidth);
      if (painter.height + 24 > height) height = painter.height + 24;
      painter.dispose();
    }
    return TweenAnimationBuilder<List<double>>(
      tween: _SelectionTween(begin: target, end: target),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      builder: (context, weights, _) => SizedBox(
        height: height,
        child: Stack(
          children: [
            PositionedDirectional(
              start: width * .2 * (weights[1] + 2 * weights[2]),
              top: 0,
              bottom: 0,
              width: width * .6,
              child: DecoratedBox(
                key: const ValueKey('tab-active-pill'),
                decoration: BoxDecoration(
                  color: QorganColors.backdrop,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    width: width * (.2 + .4 * weights[i]),
                    height: height,
                    child: _destination(context, i, weights[i], labelWidth),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _destination(
    BuildContext context,
    int index,
    double progress,
    double labelWidth,
  ) => Semantics(
    label: _labels[index],
    button: true,
    selected: selectedIndex == index,
    onTap: () => _select(index),
    excludeSemantics: true,
    child: Tooltip(
      message: _labels[index],
      excludeFromSemantics: true,
      child: InkWell(
        key: ValueKey(_keys[index]),
        borderRadius: BorderRadius.circular(30),
        onTap: () => _select(index),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icons[index],
              size: 24,
              color: Color.lerp(
                QorganColors.muted,
                QorganColors.mintInk,
                progress,
              ),
            ),
            if (progress > 0) ...[
              SizedBox(width: 8 * progress),
              ClipRect(
                child: Align(
                  widthFactor: progress,
                  child: Opacity(
                    opacity: progress,
                    child: SizedBox(
                      width: labelWidth,
                      child: Text(
                        _labels[index],
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: QorganColors.mintInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// One tween drives both the sliding pill and every tab's expansion. When
/// interrupted, TweenAnimationBuilder retargets from the current weights,
/// preserving continuity even for fast taps between non-adjacent tabs.
class _SelectionTween extends Tween<List<double>> {
  _SelectionTween({required super.begin, required super.end});

  @override
  List<double> lerp(double t) => [
    for (var i = 0; i < 3; i++) begin![i] + (end![i] - begin![i]) * t,
  ];
}
