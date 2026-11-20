import 'package:flutter/material.dart';

/// Official Valley Express Vector Brand Mark & Looping Loader
/// Palette: #FF6B1A, #003893, #FFFFFF
class ValleyLogoMark extends StatelessWidget {
  final double size;

  const ValleyLogoMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.625, size),
      painter: _ValleyLogoPainter(),
    );
  }
}

class ValleyLoaderWidget extends StatefulWidget {
  final double size;
  final String text;

  const ValleyLoaderWidget({
    super.key,
    this.size = 64,
    this.text = 'Loading...',
  });

  @override
  State<ValleyLoaderWidget> createState() => _ValleyLoaderWidgetState();
}

class _ValleyLoaderWidgetState extends State<ValleyLoaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ValleyLoaderPainter(pinOffset: _bounceAnimation.value),
            );
          },
        ),
        if (widget.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            widget.text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2A44),
            ),
          ),
        ],
      ],
    );
  }
}

class _ValleyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 160.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue speed lines on left
    final linePaint = Paint()
      ..color = const Color(0xFF003893)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(10, 52), const Offset(50, 52), linePaint);
    canvas.drawLine(const Offset(22, 80), const Offset(52, 80), linePaint);
    canvas.drawLine(const Offset(10, 108), const Offset(50, 108), linePaint);

    // 2. Orange Rounded Square
    final rectPaint = Paint()
      ..color = const Color(0xFFFF6B1A)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(70, 10, 140, 140),
      const Radius.circular(34),
    );
    canvas.drawRRect(rrect, rectPaint);

    // 3. White 'V' Mark
    final vPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final vPath = Path()
      ..moveTo(104, 56)
      ..lineTo(140, 120)
      ..lineTo(176, 56);
    canvas.drawPath(vPath, vPaint);

    // 4. Blue Location Pin with White Center
    final pinPaint = Paint()
      ..color = const Color(0xFF003893)
      ..style = PaintingStyle.fill;

    final pinPath = Path()
      ..moveTo(140, 68)
      ..cubicTo(135, 61, 131, 56, 131, 49)
      ..arcToPoint(
        const Offset(149, 49),
        radius: const Radius.circular(9),
        clockwise: true,
      )
      ..cubicTo(149, 56, 145, 61, 140, 68)
      ..close();

    canvas.drawPath(pinPath, pinPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(140, 49), 3.5, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ValleyLoaderPainter extends CustomPainter {
  final double pinOffset;

  _ValleyLoaderPainter({this.pinOffset = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 160.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Orange Rounded Square
    final rectPaint = Paint()
      ..color = const Color(0xFFFF6B1A)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 10, 140, 140),
      const Radius.circular(32),
    );
    canvas.drawRRect(rrect, rectPaint);

    // White 'V' Mark
    final vPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final vPath = Path()
      ..moveTo(44, 56)
      ..lineTo(80, 120)
      ..lineTo(116, 56);
    canvas.drawPath(vPath, vPaint);

    // Bouncing Blue Location Pin
    canvas.save();
    canvas.translate(0, pinOffset);

    final pinPaint = Paint()
      ..color = const Color(0xFF003893)
      ..style = PaintingStyle.fill;

    final pinPath = Path()
      ..moveTo(80, 68)
      ..cubicTo(75, 61, 71, 56, 71, 49)
      ..arcToPoint(
        const Offset(89, 49),
        radius: const Radius.circular(9),
        clockwise: true,
      )
      ..cubicTo(89, 56, 85, 61, 80, 68)
      ..close();

    canvas.drawPath(pinPath, pinPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(80, 49), 3.5, dotPaint);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ValleyLoaderPainter oldDelegate) =>
      oldDelegate.pinOffset != pinOffset;
}
