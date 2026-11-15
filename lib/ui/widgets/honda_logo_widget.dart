import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/**
 * High-definition vector emblem for HONDA (with extensible support for additional brands).
 * Features metallic chrome gradients and bevel borders tailored for the 2012 Accord.
 */
class HondaLogoWidget extends StatelessWidget {
  final double width;
  final double height;
  final String brand; // 'honda' (default), 'hyundai', 'toyota', 'nissan'

  const HondaLogoWidget({
    super.key,
    this.width = 44,
    this.height = 36,
    this.brand = 'honda',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _getPainterForBrand(brand),
      ),
    );
  }

  CustomPainter _getPainterForBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'hyundai':
        return HyundaiLogoPainter();
      case 'honda':
      default:
        return HondaLogoPainter();
    }
  }
}

/**
 * Authentic Honda 'H' emblem within rounded trapezoid frame.
 */
class HondaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Chrome Metallic Gradient for Outer Frame
    final framePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
          Color(0xFFF8FAFC),
          Color(0xFF64748B),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer rounded trapezoid boundary for Honda
    final framePath = Path();
    const radius = 6.0;
    // Top is wider than bottom
    framePath.moveTo(w * 0.08 + radius, h * 0.06);
    framePath.lineTo(w * 0.92 - radius, h * 0.06);
    framePath.quadraticBezierTo(w * 0.96, h * 0.08, w * 0.92, h * 0.22);
    framePath.lineTo(w * 0.82, h * 0.88);
    framePath.quadraticBezierTo(w * 0.80, h * 0.96, w * 0.70, h * 0.96);
    framePath.lineTo(w * 0.30, h * 0.96);
    framePath.quadraticBezierTo(w * 0.20, h * 0.96, w * 0.18, h * 0.88);
    framePath.lineTo(w * 0.08, h * 0.22);
    framePath.quadraticBezierTo(w * 0.04, h * 0.08, w * 0.08 + radius, h * 0.06);
    framePath.close();

    canvas.drawPath(framePath, framePaint);

    // 2. Stylized 'H' Paint
    final hPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFCBD5E1),
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Left vertical stroke of 'H' (wider at top, slanted inward)
    final leftLeg = Path()
      ..moveTo(w * 0.22, h * 0.20)
      ..lineTo(w * 0.30, h * 0.20)
      ..lineTo(w * 0.33, h * 0.82)
      ..lineTo(w * 0.26, h * 0.82)
      ..close();
    canvas.drawPath(leftLeg, hPaint);

    // Right vertical stroke of 'H' (wider at top, slanted inward)
    final rightLeg = Path()
      ..moveTo(w * 0.78, h * 0.20)
      ..lineTo(w * 0.70, h * 0.20)
      ..lineTo(w * 0.67, h * 0.82)
      ..lineTo(w * 0.74, h * 0.82)
      ..close();
    canvas.drawPath(rightLeg, hPaint);

    // Horizontal bridge of 'H' (slanted upward curve)
    final bridge = Path()
      ..moveTo(w * 0.28, h * 0.54)
      ..lineTo(w * 0.72, h * 0.54)
      ..lineTo(w * 0.71, h * 0.62)
      ..lineTo(w * 0.29, h * 0.62)
      ..close();
    canvas.drawPath(bridge, hPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/**
 * Optional Hyundai 'H' oval emblem for extensible brand support.
 */
class HyundaiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ovalPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.84, h * 0.76), ovalPaint);

    final hPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    // Slanted H
    canvas.drawLine(Offset(w * 0.32, h * 0.26), Offset(w * 0.40, h * 0.74), hPaint);
    canvas.drawLine(Offset(w * 0.68, h * 0.26), Offset(w * 0.60, h * 0.74), hPaint);
    canvas.drawLine(Offset(w * 0.36, h * 0.50), Offset(w * 0.64, h * 0.50), hPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
