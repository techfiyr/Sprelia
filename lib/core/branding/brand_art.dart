import 'package:flutter/material.dart';

/// Warm, original Hermione brand artwork drawn in code (no bundled files, no third-party art).
///
/// Everything here is generic: a speech bubble holding an open book, and a friendly tutor
/// mascot. Nothing imitates any book, film or game franchise.
abstract final class BrandPalette {
  static const plum = Color(0xFF5B2F8F);
  static const plumDeep = Color(0xFF3C1F66);
  static const violet = Color(0xFF7656D9);
  static const coral = Color(0xFFFF7A6B);
  /// Darker coral for text on cream (WCAG AA).
  static const coralText = Color(0xFFC4402F);
  static const sun = Color(0xFFFFC857);
  static const cream = Color(0xFFFFF7EC);
  static const peach = Color(0xFFFFE3D0);
  static const teal = Color(0xFF2FA39A);
  static const skin = Color(0xFFF2B98F);
  static const hair = Color(0xFF4A2A2F);
  static const ink = Color(0xFF2A1B3D);
}

/// Logo mark: a plum speech bubble with an open book and a sun-yellow spark.
class HermioneMarkPainter extends CustomPainter {
  const HermioneMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final tile = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(s * 0.3));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandPalette.violet, BrandPalette.plum],
        ).createShader(Offset.zero & size),
    );

    // Speech bubble.
    final bubble = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.17, s * 0.2, s * 0.66, s * 0.5), Radius.circular(s * 0.16)))
      ..moveTo(s * 0.3, s * 0.68)
      ..lineTo(s * 0.26, s * 0.84)
      ..lineTo(s * 0.46, s * 0.7)
      ..close();
    canvas.drawPath(bubble, Paint()..color = BrandPalette.cream);

    // Open book inside the bubble.
    final page = Paint()..color = BrandPalette.peach;
    final left = Path()
      ..moveTo(s * 0.5, s * 0.55)
      ..quadraticBezierTo(s * 0.4, s * 0.4, s * 0.27, s * 0.44)
      ..lineTo(s * 0.27, s * 0.57)
      ..quadraticBezierTo(s * 0.4, s * 0.53, s * 0.5, s * 0.63)
      ..close();
    final right = Path()
      ..moveTo(s * 0.5, s * 0.55)
      ..quadraticBezierTo(s * 0.6, s * 0.4, s * 0.73, s * 0.44)
      ..lineTo(s * 0.73, s * 0.57)
      ..quadraticBezierTo(s * 0.6, s * 0.53, s * 0.5, s * 0.63)
      ..close();
    canvas.drawPath(left, page);
    canvas.drawPath(right, page);
    final outline = Paint()
      ..color = BrandPalette.plum
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(left, outline);
    canvas.drawPath(right, outline);

    // Spark above the book.
    final c = Offset(s * 0.5, s * 0.33);
    final r = s * 0.085;
    final spark = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(spark, Paint()..color = BrandPalette.sun);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A friendly generic tutor: round face, hair bun, rectangular glasses, teal cardigan, an open
/// book and a speech bubble. Decorative; callers provide the semantics.
class TutorMascotPainter extends CustomPainter {
  const TutorMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(w * x, h * y);
    final fill = Paint();

    // Soft sun-glow backdrop.
    canvas.drawCircle(p(0.5, 0.52), w * 0.46, fill..color = BrandPalette.peach);
    canvas.drawCircle(p(0.5, 0.52), w * 0.34, fill..color = BrandPalette.cream);

    // Speech bubble with "hello" dots.
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.58, h * 0.06, w * 0.34, h * 0.17),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(bubble, fill..color = BrandPalette.coral);
    final tail = Path()
      ..moveTo(w * 0.64, h * 0.22)
      ..lineTo(w * 0.6, h * 0.3)
      ..lineTo(w * 0.72, h * 0.22)
      ..close();
    canvas.drawPath(tail, fill..color = BrandPalette.coral);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(p(0.67 + i * 0.07, 0.145), w * 0.016, fill..color = Colors.white);
    }

    // Body (cardigan) and collar.
    final body = Path()
      ..moveTo(w * 0.22, h * 0.98)
      ..quadraticBezierTo(w * 0.22, h * 0.66, w * 0.5, h * 0.64)
      ..quadraticBezierTo(w * 0.78, h * 0.66, w * 0.78, h * 0.98)
      ..close();
    canvas.drawPath(body, fill..color = BrandPalette.teal);
    final shirt = Path()
      ..moveTo(w * 0.42, h * 0.65)
      ..lineTo(w * 0.5, h * 0.8)
      ..lineTo(w * 0.58, h * 0.65)
      ..close();
    canvas.drawPath(shirt, fill..color = BrandPalette.cream);

    // Hair bun and back hair.
    canvas.drawCircle(p(0.5, 0.17), w * 0.09, fill..color = BrandPalette.hair);
    canvas.drawCircle(p(0.5, 0.4), w * 0.235, fill..color = BrandPalette.hair);

    // Face.
    canvas.drawOval(Rect.fromCenter(center: p(0.5, 0.45), width: w * 0.38, height: h * 0.3), fill..color = BrandPalette.skin);
    // Fringe.
    final fringe = Path()
      ..moveTo(w * 0.31, h * 0.42)
      ..quadraticBezierTo(w * 0.5, h * 0.22, w * 0.69, h * 0.42)
      ..quadraticBezierTo(w * 0.5, h * 0.33, w * 0.31, h * 0.42)
      ..close();
    canvas.drawPath(fringe, fill..color = BrandPalette.hair);

    // Rectangular glasses.
    final glass = Paint()
      ..color = BrandPalette.plumDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014;
    for (final cx in [0.42, 0.58]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p(cx, 0.46), width: w * 0.13, height: h * 0.075), Radius.circular(w * 0.02)),
        glass,
      );
    }
    canvas.drawLine(p(0.485, 0.46), p(0.515, 0.46), glass);

    // Eyes, cheeks, smile.
    canvas.drawCircle(p(0.42, 0.46), w * 0.011, fill..color = BrandPalette.ink);
    canvas.drawCircle(p(0.58, 0.46), w * 0.011, fill..color = BrandPalette.ink);
    canvas.drawCircle(p(0.37, 0.53), w * 0.025, fill..color = BrandPalette.coral.withValues(alpha: 0.35));
    canvas.drawCircle(p(0.63, 0.53), w * 0.025, fill..color = BrandPalette.coral.withValues(alpha: 0.35));
    final smile = Path()
      ..moveTo(w * 0.44, h * 0.54)
      ..quadraticBezierTo(w * 0.5, h * 0.6, w * 0.56, h * 0.54);
    canvas.drawPath(
      smile,
      Paint()
        ..color = BrandPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeCap = StrokeCap.round,
    );

    // Open book held in front.
    final book = Path()
      ..moveTo(w * 0.5, h * 0.84)
      ..quadraticBezierTo(w * 0.36, h * 0.74, w * 0.24, h * 0.79)
      ..lineTo(w * 0.24, h * 0.95)
      ..quadraticBezierTo(w * 0.36, h * 0.91, w * 0.5, h * 0.98)
      ..quadraticBezierTo(w * 0.64, h * 0.91, w * 0.76, h * 0.95)
      ..lineTo(w * 0.76, h * 0.79)
      ..quadraticBezierTo(w * 0.64, h * 0.74, w * 0.5, h * 0.84)
      ..close();
    canvas.drawPath(book, fill..color = BrandPalette.cream);
    canvas.drawPath(
      book,
      Paint()
        ..color = BrandPalette.plum
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(p(0.5, 0.84), p(0.5, 0.98), Paint()..color = BrandPalette.plum..strokeWidth = w * 0.012);

    // Floating sparkles.
    for (final s in [(0.16, 0.3, 0.03), (0.86, 0.5, 0.024), (0.2, 0.7, 0.02)]) {
      canvas.drawCircle(p(s.$1, s.$2), w * s.$3, fill..color = BrandPalette.sun);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TutorMascot extends StatelessWidget {
  const TutorMascot({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(width: size, height: size, child: const CustomPaint(painter: TutorMascotPainter())),
      );
}
