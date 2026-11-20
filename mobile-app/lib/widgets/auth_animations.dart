import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme.dart';

/// Brand colours taken from the official logo artboard
/// (`valley-express-logos/Main.dc.html` and `valley-express-mark.svg`).
class ValleyBrand {
  static const square = Color(0xFFFF6B1A);
  static const wordValley = Color(0xFF003893);
  static const wordExpress = Color(0xFFE8590C);
  static const tagline = Color(0xFF3D4A6B);
}

/// The official Valley Express logo mark, rendered from the shipped brand
/// asset `assets/images/logo.svg` (speed lines, orange square, white "V" and
/// the drop pin) rather than being redrawn in Dart.
///
/// flutter_svg does not run animations declared inside an SVG, so motion is
/// driven from Dart by the widgets that use this.
class ValleyLogoMark extends StatelessWidget {
  final double height;

  const ValleyLogoMark({super.key, this.height = 92});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      height: height,
      semanticsLabel: 'Valley Express',
    );
  }
}

/// The branded delivery scooter from `assets/images/scooter.svg`.
class ValleyScooter extends StatelessWidget {
  final double height;

  const ValleyScooter({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/scooter.svg',
      height: height,
      semanticsLabel: 'Valley Express delivery scooter',
    );
  }
}

/// Square-only variant of the mark, drawn in Dart so the "V" can be traced on
/// entry the way the brand's animated export does. Geometry matches
/// `valley-express-mark.svg` (160×160 viewBox).
class ValleyMark extends StatelessWidget {
  final double size;
  final double drawProgress;

  const ValleyMark({super.key, this.size = 76, this.drawProgress = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ValleyMarkPainter(drawProgress)),
    );
  }
}

class _ValleyMarkPainter extends CustomPainter {
  final double progress;

  _ValleyMarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Everything below is expressed against the 160x160 source viewBox
    final k = size.width / 160.0;

    final square = RRect.fromRectAndRadius(
      Rect.fromLTWH(10 * k, 10 * k, 140 * k, 140 * k),
      Radius.circular(34 * k),
    );
    canvas.drawRRect(square, Paint()..color = ValleyBrand.square);

    final v = Path()
      ..moveTo(42 * k, 54 * k)
      ..lineTo(80 * k, 122 * k)
      ..lineTo(118 * k, 54 * k);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (progress >= 1) {
      canvas.drawPath(v, stroke);
      return;
    }

    // Trace the V rather than fading it, so it draws like the brand animation
    for (final metric in v.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ValleyMarkPainter old) =>
      old.progress != progress;
}

/// Valley Express logo that assembles itself: the square pops in, the V draws
/// through it, the two words slide in, then the tagline rises.
class AnimatedBrandMark extends StatefulWidget {
  final double scale;
  final bool showTagline;

  const AnimatedBrandMark({super.key, this.scale = 1, this.showTagline = true});

  @override
  State<AnimatedBrandMark> createState() => _AnimatedBrandMarkState();
}

class _AnimatedBrandMarkState extends State<AnimatedBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _draw,
          builder: (_, __) => ValleyMark(
            size: 76 * scale,
            // Hold briefly, then trace the V
            drawProgress: Curves.easeInOut.transform(
              ((_draw.value - 0.18) / 0.72).clamp(0.0, 1.0),
            ),
          ),
        )
            .animate()
            .scale(
              duration: 520.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.6, 0.6),
              end: const Offset(1, 1),
            )
            .fadeIn(duration: 240.ms),
        SizedBox(height: 14 * scale),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Valley',
              style: TextStyle(
                color: ValleyBrand.wordValley,
                fontSize: 34 * scale,
                fontWeight: FontWeight.w700,
                // Artboard uses -2px at 92px; scaled to this size
                letterSpacing: -0.74 * scale,
              ),
            )
                .animate(delay: 220.ms)
                .fadeIn(duration: 380.ms)
                .slideX(begin: -0.35, end: 0, curve: Curves.easeOutCubic),
            SizedBox(width: 8 * scale),
            Padding(
              padding: EdgeInsets.only(bottom: 5 * scale),
              child: Text(
                'EXPRESS',
                style: TextStyle(
                  color: ValleyBrand.wordExpress,
                  fontSize: 13 * scale,
                  // Artboard: Poppins 500 with 14px tracking at 28px
                  fontWeight: FontWeight.w500,
                  letterSpacing: 6.5 * scale,
                ),
              ),
            )
                .animate(delay: 220.ms)
                .fadeIn(duration: 380.ms)
                .slideX(begin: 0.45, end: 0, curve: Curves.easeOutCubic),
          ],
        ),
        if (widget.showTagline) ...[
          SizedBox(height: 10 * scale),
          Text(
            'Fast to order. Fast to your door.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ValleyBrand.tagline,
              fontSize: 12.5 * scale,
              fontWeight: FontWeight.w500,
            ),
          ).animate(delay: 560.ms).fadeIn(duration: 420.ms).slideY(begin: 0.4, end: 0),
        ],
      ],
    );
  }
}

/// A scooter running a delivery across the screen: the road streaks past, the
/// wheels spin and the rider bobs over the bumps.
class DeliveryRunAnimation extends StatelessWidget {
  final double height;

  const DeliveryRunAnimation({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Road surface
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Container(height: 2, color: AppTheme.border),
          ),
          // Dashes streaking past to sell the forward motion
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                7,
                (i) => Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.textSubtle.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .slideX(
                      begin: 0.9,
                      end: -0.9,
                      duration: 900.ms,
                      delay: (i * 120).ms,
                      curve: Curves.linear,
                    )
                    .fadeIn(duration: 150.ms)
                    .fadeOut(delay: 700.ms, duration: 200.ms),
              ),
            ),
          ),
          // The scooter itself, riding in then bobbing in place
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ValleyScooter(height: height * 0.72)
                .animate()
                .slideX(begin: -1.6, end: 0, duration: 900.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 400.ms)
                .then()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -5, duration: 620.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

/// Two glasses swinging together for a toast, with a sparkle on the clink.
class CheersAnimation extends StatelessWidget {
  final double size;

  const CheersAnimation({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.18,
            child: _Glass(size: size, flip: false)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -0.09, end: 0.02, duration: 760.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            right: size * 0.18,
            child: _Glass(size: size, flip: true)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: 0.09, end: -0.02, duration: 760.ms, curve: Curves.easeInOut),
          ),
          // Sparkle timed to the moment the glasses meet
          Positioned(
            top: size * 0.08,
            child: Icon(Icons.auto_awesome, size: size * 0.26, color: AppTheme.warning)
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: 700.ms, duration: 120.ms)
                .scale(
                  delay: 700.ms,
                  duration: 220.ms,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1.25, 1.25),
                )
                .fadeOut(delay: 980.ms, duration: 300.ms),
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final double size;
  final bool flip;

  const _Glass({required this.size, required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()..scale(flip ? -1.0 : 1.0, 1.0),
      child: CustomPaint(
        size: Size(size * 0.46, size * 0.72),
        painter: _GlassPainter(),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(size.width * 0.12, 0)
      ..lineTo(size.width * 0.88, 0)
      ..lineTo(size.width * 0.74, size.height)
      ..lineTo(size.width * 0.26, size.height)
      ..close();

    // Drink
    canvas.drawPath(body, Paint()..color = AppTheme.warning);

    // Foam head
    final foam = Path()
      ..moveTo(size.width * 0.12, 0)
      ..lineTo(size.width * 0.88, 0)
      ..lineTo(size.width * 0.84, size.height * 0.2)
      ..lineTo(size.width * 0.16, size.height * 0.2)
      ..close();
    canvas.drawPath(foam, Paint()..color = const Color(0xFFFFF4D6));

    // Outline
    canvas.drawPath(
      body,
      Paint()
        ..color = AppTheme.darkNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Handle
    final handle = Path()
      ..moveTo(size.width * 0.86, size.height * 0.26)
      ..quadraticBezierTo(
        size.width * 1.25,
        size.height * 0.45,
        size.width * 0.78,
        size.height * 0.68,
      );
    canvas.drawPath(
      handle,
      Paint()
        ..color = AppTheme.darkNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft rotating glow behind the hero art. Kept very low contrast so it reads
/// as depth rather than decoration.
class AmbientHalo extends StatelessWidget {
  final double size;
  final Color color;

  const AmbientHalo({super.key, this.size = 240, this.color = AppTheme.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0)],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1.08, 1.08),
          duration: 2600.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Convenience extension for the staggered entrance used by the auth forms.
extension AuthEntrance on Widget {
  Widget authEntrance({int index = 0}) => animate(delay: (90 * index).ms)
      .fadeIn(duration: 380.ms)
      .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
}

/// Angle helper kept for painters that need degrees.
double degToRad(double deg) => deg * math.pi / 180;
