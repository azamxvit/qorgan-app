import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/colors.dart';
import 'brand_mark.dart';

/// First-run screen. The mark sits where [LaunchSplash] leaves it, at the
/// centre of the screen; the name and the actions rise once [revealed].
class WelcomePage extends StatefulWidget {
  const WelcomePage({
    required this.supported,
    required this.onSetup,
    required this.onManual,
    required this.onPrivacy,
    this.busy = false,
    this.revealed = true,
    super.key,
  });
  final bool supported;
  final bool busy;

  /// False while the launch splash still covers the screen.
  final bool revealed;
  final VoidCallback onSetup;
  final VoidCallback onManual;
  final VoidCallback onPrivacy;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  static const _name = 'Qorğan';
  static const _total = 1050.0;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _total.round()),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startIfRevealed();
  }

  @override
  void didUpdateWidget(WelcomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startIfRevealed();
  }

  void _startIfRevealed() {
    if (_started || !widget.revealed) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Rises [distance] px and fades in between [from] and [from] + [length] ms.
  Widget _rise(
    Widget child, {
    required double from,
    required double length,
    required double distance,
  }) {
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        from / _total,
        (from + length) / _total,
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, distance * (1 - curve.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letters = _name.characters.toList();
    final actions = <Widget>[
      const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: QorganColors.mintInk,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Текст SMS не отправляется на сервер',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: QorganColors.mintInk),
              ),
            ),
          ],
        ),
      ),
      FilledButton(
        onPressed: widget.busy
            ? null
            : widget.supported
            ? widget.onSetup
            : widget.onManual,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            widget.supported ? 'Настроить защиту' : 'Проверить SMS',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      if (widget.supported)
        OutlinedButton(
          onPressed: widget.busy ? null : widget.onManual,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Проверить SMS вручную', textAlign: TextAlign.center),
          ),
        ),
      TextButton(
        onPressed: widget.onPrivacy,
        child: const Text(
          'Как обрабатываются данные',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: QorganColors.muted),
        ),
      ),
    ];

    return Scaffold(
      key: const ValueKey('welcome'),
      body: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: _WelcomeLayout(
            viewport: viewport.maxHeight,
            padding: MediaQuery.paddingOf(context),
            children: [
              const BrandMark(key: ValueKey('welcome-mark'), size: 96),
              Semantics(
                key: const ValueKey('welcome-name'),
                label: _name,
                header: true,
                child: ExcludeSemantics(
                  // A logo: grows with the text size until it meets the edges.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < letters.length; i++)
                          _rise(
                            Text(
                              letters[i],
                              style: const TextStyle(
                                fontSize: 34,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.2,
                              ),
                            ),
                            from: 40.0 * i,
                            length: 380,
                            distance: 12,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !widget.revealed,
                child: Column(
                  key: const ValueKey('welcome-actions'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    for (var i = 0; i < actions.length; i++)
                      _rise(
                        actions[i],
                        from: 550.0 + 50 * i,
                        length: 350,
                        distance: 16,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out the mark, the name and the actions, in that order.
///
/// The mark stays at the centre of the [viewport], where the splash leaves
/// it, unless the name would then run into the actions; then the mark moves
/// up. When even that does not fit, the page grows taller than the viewport
/// and scrolls.
class _WelcomeLayout extends MultiChildRenderObjectWidget {
  const _WelcomeLayout({
    required this.viewport,
    required this.padding,
    required super.children,
  });
  final double viewport;
  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWelcomeLayout(viewport: viewport, padding: padding);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWelcomeLayout renderObject,
  ) {
    renderObject
      ..viewport = viewport
      ..padding = padding;
  }
}

class _WelcomeParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderWelcomeLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _WelcomeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _WelcomeParentData> {
  _RenderWelcomeLayout({required this._viewport, required this._padding});

  static const _mark = 96.0;
  static const _side = 24.0;
  static const _bottom = 26.0;
  static const _gap = 16.0;

  double _viewport;
  set viewport(double value) {
    if (value == _viewport) return;
    _viewport = value;
    markNeedsLayout();
  }

  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (value == _padding) return;
    _padding = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WelcomeParentData) {
      child.parentData = _WelcomeParentData();
    }
  }

  @override
  void performLayout() {
    final mark = firstChild!;
    final name = childAfter(mark)!;
    final actions = childAfter(name)!;
    final width = constraints.maxWidth;
    final inner = width - _side * 2;

    mark.layout(BoxConstraints.tight(const Size.square(_mark)));
    name.layout(BoxConstraints(maxWidth: inner), parentUsesSize: true);
    actions.layout(BoxConstraints.tightFor(width: inner), parentUsesSize: true);

    final group = _mark + _gap + name.size.height;
    final needed =
        _padding.top +
        _gap +
        group +
        _gap +
        actions.size.height +
        _bottom +
        _padding.bottom;
    final height = _viewport > needed ? _viewport : needed;
    final actionsTop = height - _padding.bottom - _bottom - actions.size.height;
    final highest = _padding.top + _gap + _mark / 2;
    final lowest = actionsTop - _gap - name.size.height - _gap - _mark / 2;
    final centre = (_viewport / 2).clamp(highest, math.max(highest, lowest));

    size = constraints.constrain(Size(width, height));
    _place(mark, Offset((width - _mark) / 2, centre - _mark / 2));
    _place(
      name,
      Offset((width - name.size.width) / 2, centre + _mark / 2 + _gap),
    );
    _place(actions, Offset(_side, actionsTop));
  }

  static void _place(RenderBox child, Offset offset) =>
      (child.parentData! as _WelcomeParentData).offset = offset;

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
