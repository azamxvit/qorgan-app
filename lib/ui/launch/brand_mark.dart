import 'package:flutter/material.dart';

import '../core/colors.dart';

/// Original Qorğan website icon, converted from src/app/icon.svg.
///
/// [coreScale] and [ring] let the launch animation click the centre square
/// and send a pulse out of it; at their defaults the mark is drawn at rest.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 96,
    this.color = QorganColors.mint,
    this.coreScale = 1,
    this.ring = 0,
  });
  final double size;
  final Color color;
  final double coreScale;

  /// Pulse progress from 0 (none) to 1 (fully spread and faded).
  final double ring;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Логотип Qorğan',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandPainter(color: color, coreScale: coreScale, ring: ring),
      ),
    ),
  );
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter({
    required this.color,
    required this.coreScale,
    required this.ring,
  });
  final Color color;
  final double coreScale;
  final double ring;

  static const _coreCentre = Offset(351.36, 385.47);
  static final _ringBox = RRect.fromRectAndRadius(
    Rect.fromCenter(center: _coreCentre, width: 34.4, height: 34.4),
    const Radius.circular(5),
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 320, size.height / 320);
    canvas.translate(-202, -224);
    final paint = Paint()..color = color;
    canvas
      ..drawPath(_MarkGeometry.top, paint)
      ..drawPath(_MarkGeometry.left, paint)
      ..drawPath(_MarkGeometry.tail, paint);
    if (ring > 0 && ring < 1) {
      final spread = 1 + 2.6 * Curves.easeOutCubic.transform(ring);
      canvas
        ..save()
        ..translate(_coreCentre.dx, _coreCentre.dy)
        ..scale(spread)
        ..translate(-_coreCentre.dx, -_coreCentre.dy)
        ..drawRRect(
          _ringBox,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = color.withValues(alpha: .7 * (1 - ring)),
        )
        ..restore();
    }
    canvas
      ..save()
      ..translate(_coreCentre.dx, _coreCentre.dy)
      ..scale(coreScale)
      ..translate(-_coreCentre.dx, -_coreCentre.dy)
      ..drawPath(_MarkGeometry.core, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_BrandPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.coreScale != coreScale ||
      oldDelegate.ring != ring;
}

/// The four parts of the mark in the icon's 320-unit space, built once.
abstract final class _MarkGeometry {
  static final top = _top();
  static final left = _left();
  static final tail = _tail();
  static final core = _core();

  static Path _top() {
    final path = Path();
    path.moveTo(349.792, 250.37);
    path.cubicTo(389.368, 249.135, 405.529, 267.196, 431.277, 293.149);
    path.lineTo(463.83799999999997, 325.73199999999997);
    path.cubicTo(
      498.712,
      360.895,
      499.32199999999995,
      410.575,
      463.80499999999995,
      445.58299999999997,
    );
    path.cubicTo(
      449.77099999999996,
      430.76899999999995,
      433.62999999999994,
      416.02399999999994,
      420.03499999999997,
      401.147,
    );
    path.cubicTo(431.941, 364.224, 405.849, 355.251, 385.253, 331.262);
    path.cubicTo(367.678, 310.791, 344.728, 308.366, 325.506, 328.597);
    path.cubicTo(
      320.361,
      334.013,
      314.60299999999995,
      339.71299999999997,
      309.33,
      345.137,
    );
    path.cubicTo(
      296.69399999999996,
      331.51800000000003,
      280.727,
      316.205,
      267.474,
      302.625,
    );
    path.cubicTo(
      296.11699999999996,
      276.413,
      306.456,
      252.998,
      349.792,
      250.37,
    );
    return path;
  }

  static Path _left() {
    final path = Path();
    path.moveTo(253.606, 316.159);
    path.cubicTo(257.817, 318.271, 290.347, 351.956, 296.002, 357.698);
    path.arcToPoint(
      Offset(292.812, 361.53),
      radius: Radius.elliptical(111.0, 111.0),
      rotation: 0.0,
      largeArc: false,
      clockwise: false,
    );
    path.cubicTo(
      286.043,
      369.972,
      282.557,
      379.31899999999996,
      283.844,
      390.25899999999996,
    );
    path.arcToPoint(
      Offset(289.241, 405.45899999999995),
      radius: Radius.elliptical(35.45, 35.45),
      rotation: 0.0,
      largeArc: false,
      clockwise: false,
    );
    path.cubicTo(
      295.174,
      414.82399999999996,
      319.166,
      437.1979999999999,
      328.209,
      445.7099999999999,
    );
    path.cubicTo(
      335.105,
      452.20199999999994,
      346.305,
      453.6479999999999,
      355.79,
      452.4599999999999,
    );
    path.cubicTo(
      370.274,
      467.8259999999999,
      386.732,
      482.53399999999993,
      400.932,
      498.30299999999994,
    );
    path.cubicTo(
      391.781,
      505.8759999999999,
      384.276,
      510.0369999999999,
      373.18100000000004,
      513.8539999999999,
    );
    path.arcToPoint(
      Offset(347.67100000000005, 517.6089999999999),
      radius: Radius.elliptical(82.6, 82.6),
      rotation: 0.0,
      largeArc: false,
      clockwise: true,
    );
    path.cubicTo(
      313.38200000000006,
      517.1759999999999,
      295.49600000000004,
      498.8539999999999,
      273.49100000000004,
      475.9119999999999,
    );
    path.cubicTo(
      263.01900000000006,
      465.7699999999999,
      252.84200000000004,
      454.7629999999999,
      242.34000000000003,
      444.71899999999994,
    );
    path.cubicTo(
      216.67100000000002,
      420.1719999999999,
      209.94800000000004,
      381.8109999999999,
      225.56300000000005,
      349.8949999999999,
    );
    path.cubicTo(
      232.16700000000006,
      336.3949999999999,
      242.77100000000004,
      326.59099999999995,
      253.60600000000005,
      316.15899999999993,
    );
    return path;
  }

  static Path _tail() {
    final path = Path();
    path.moveTo(403.097, 410.304);
    path.cubicTo(
      413.854,
      421.979,
      428.289,
      435.705,
      439.844,
      447.08099999999996,
    );
    path.cubicTo(
      462.48699999999997,
      469.37299999999993,
      484.729,
      492.64199999999994,
      507.502,
      514.6379999999999,
    );
    path.lineTo(476.10900000000004, 514.6179999999999);
    path.lineTo(444.00600000000003, 514.6239999999999);
    path.arcToPoint(
      Offset(371.62300000000005, 442.0079999999999),
      radius: Radius.elliptical(7929.0, 7929.0),
      rotation: 0.0,
      largeArc: false,
      clockwise: true,
    );
    path.cubicTo(
      381.41200000000003,
      431.4459999999999,
      392.98100000000005,
      421.1789999999999,
      403.09700000000004,
      410.3039999999999,
    );
    return path;
  }

  static Path _core() {
    final path = Path();
    path.moveTo(334.14, 368.167);
    path.quadraticBezierTo(351.358, 368.268, 368.577, 368.13399999999996);
    path.cubicTo(
      368.411,
      379.609,
      368.886,
      391.41299999999995,
      368.625,
      402.74699999999996,
    );
    path.quadraticBezierTo(
      351.399,
      402.80999999999995,
      334.172,
      402.67499999999995,
    );
    path.close();
    return path;
  }
}
