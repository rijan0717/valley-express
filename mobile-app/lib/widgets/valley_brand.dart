import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The official animated brand lockup, rebuilt from `valley-express-animated.svg`.
///
/// The supplied artwork drives its motion from a CSS `<style>` block, which
/// flutter_svg drops outright ("unhandled element <style/>") — keyframes and
/// the `opacity:0` start states go with it. So the export is split into its
/// four layers under `assets/images/brand/` and the timeline is reproduced
/// here instead. The three wordmark layers share the source viewBox, so
/// stacking them reproduces the original lockup exactly.
///
/// Timings below mirror the SVG's own keyframes: a 5s loop, `up` for the
/// wordmark layers (staggered by their negative animation-delays), `ride` for
/// the scooter, plus `bob` and `spin`.
class _Brand {
  static const loop = Duration(seconds: 5);

  /// Source viewBox of the wordmark layers, used to convert the keyframes'
  /// 18px rise into rendered pixels.
  static const textCanvas = Size(317, 191);

  /// The scooter's travel, in the 880-wide coordinate space of the export.
  static const rideFrom = 345.0;
  static const rideTo = 900.0;
  static const rideCanvas = 880.0;

  /// `@keyframes up` — hold, rise and fade in, hold, fade out.
  /// Returns (opacity, dy) in source units.
  static (double, double) up(double p) {
    if (p < 0.28) return (0, 18);
    if (p < 0.40) {
      final k = Curves.easeOut.transform((p - 0.28) / 0.12);
      return (k, 18 * (1 - k));
    }
    if (p < 0.93) return (1, 0);
    if (p < 0.98) return (1 - (p - 0.93) / 0.05, 0);
    return (0, 0);
  }

  /// `@keyframes ride` — pop in at the start mark, hold, then accelerate off
  /// to the right. Returns (opacity, x, scale) with x in source units.
  static (double, double, double) ride(double p) {
    if (p < 0.18) return (0, rideFrom, 0.6);
    if (p < 0.23) {
      final k = (p - 0.18) / 0.05;
      return (k, rideFrom, 0.6 + 0.4 * k);
    }
    if (p < 0.26) return (1, rideFrom, 1);
    if (p < 0.46) {
      final k = Curves.easeIn.transform((p - 0.26) / 0.20);
      return (1, rideFrom + (rideTo - rideFrom) * k, 1);
    }
    return (1, rideTo, 1);
  }

  /// Advances a layer by its negative `animation-delay`, as a fraction of the
  /// 5s loop.
  static double phase(double t, double delaySeconds) =>
      (t + delaySeconds / 5.0) % 1.0;
}

/// The wordmark lockup — "Valley", "EXPRESS" and the tagline — rendered from
/// the split brand layers.
///
/// With [animate] false (or when the platform asks for reduced motion) the
/// layers are simply shown, matching the export's own
/// `prefers-reduced-motion` rule.
class ValleyWordmark extends StatefulWidget {
  final double width;
  final bool animate;

  const ValleyWordmark({super.key, this.width = 240, this.animate = true});

  @override
  State<ValleyWordmark> createState() => _ValleyWordmarkState();
}

class _ValleyWordmarkState extends State<ValleyWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: _Brand.loop);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _loop.repeat();
  }

  @override
  void didUpdateWidget(covariant ValleyWordmark old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!widget.animate && _loop.isAnimating) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * _Brand.textCanvas.height / _Brand.textCanvas.width;
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    final unit = height / _Brand.textCanvas.height;

    Widget layer(String name) => SvgPicture.asset(
          'assets/images/brand/$name.svg',
          width: widget.width,
          height: height,
        );

    if (still) {
      return SizedBox(
        width: widget.width,
        height: height,
        child: Stack(
          children: [layer('valley'), layer('express'), layer('tagline')],
        ),
      );
    }

    // Negative animation-delays from the export: -.9s, -.82s, -.74s.
    const delays = {'valley': 0.9, 'express': 0.82, 'tagline': 0.74};

    return SizedBox(
      width: widget.width,
      height: height,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (_, __) => Stack(
          children: [
            for (final entry in delays.entries)
              Builder(builder: (_) {
                final (opacity, dy) =
                    _Brand.up(_Brand.phase(_loop.value, entry.value));
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, dy * unit),
                    child: layer(entry.key),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// The delivery scooter riding across its track, from the same export.
///
/// Replaces the old static `scooter-banner.svg` strip. Reproduces `ride`
/// along with the `spin` wheels and the rider's `bob`; under reduced motion
/// the scooter is hidden, exactly as the export's media query specifies.
class ValleyRideStrip extends StatefulWidget {
  final double height;

  const ValleyRideStrip({super.key, this.height = 56});

  @override
  State<ValleyRideStrip> createState() => _ValleyRideStripState();
}

class _ValleyRideStripState extends State<ValleyRideStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: _Brand.loop)..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The export hides the scooter entirely when motion is reduced, so the
    // strip collapses rather than showing a stranded graphic.
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final track = constraints.maxWidth;
          final scale = track / _Brand.rideCanvas;

          return ClipRect(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, __) {
                final (opacity, x, pop) =
                    _Brand.ride(_Brand.phase(_loop.value, 0.9));
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: x * scale,
                      bottom: 0,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: pop,
                          child: _Scooter(
                            height: widget.height * 0.92,
                            t: _loop.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// The scooter with its two sub-animations: the body bobs over the bumps
/// (`bob`, .45s) and both wheels spin (`spin`, .5s).
///
/// The spokes were lifted out of the body into `spoke.svg` so they can be
/// rotated on their own — left inside the body asset they could only turn by
/// rotating the whole scooter.
class _Scooter extends StatelessWidget {
  final double height;
  final double t;

  const _Scooter({required this.height, required this.t});

  /// Source viewBox of `scooter.svg`, needed to place the wheels.
  static const _origin = Offset(-34, -4);
  static const _canvas = Size(161, 99);
  static const _wheels = [Offset(38, 76), Offset(108, 76)];
  static const _spokeBox = 22.0;

  @override
  Widget build(BuildContext context) {
    final unit = height / _canvas.height;
    final millis = t * _Brand.loop.inMilliseconds;

    // bob: a 2px triangle wave with a .45s period.
    final bobPhase = (millis / 450.0) % 1.0;
    final bob = -2 * (1 - (2 * bobPhase - 1).abs());
    // spin: one full turn every .5s.
    final spin = (millis / 500.0) % 1.0;

    return Transform.translate(
      offset: Offset(0, bob * unit),
      child: SizedBox(
        width: _canvas.width * unit,
        height: height,
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/images/brand/scooter.svg',
              width: _canvas.width * unit,
              height: height,
              semanticsLabel: 'Valley Express delivery scooter',
            ),
            for (final wheel in _wheels)
              Positioned(
                left: (wheel.dx - _origin.dx - _spokeBox / 2) * unit,
                top: (wheel.dy - _origin.dy - _spokeBox / 2) * unit,
                child: Transform.rotate(
                  angle: spin * 2 * 3.141592653589793,
                  child: SvgPicture.asset(
                    'assets/images/brand/spoke.svg',
                    width: _spokeBox * unit,
                    height: _spokeBox * unit,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The full brand logo animation from `valley-express-logo-animated.svg`:
/// the speed lines sweep through, the orange square pops in, the "V" draws
/// itself, the pin hops, the wordmark rises and the scooter rides away.
///
/// The mark is painted rather than loaded as an asset because its "V" is a
/// `stroke-dashoffset` reveal, which flutter_svg cannot animate — and because
/// the artwork is four primitives whose coordinates are known exactly.
class ValleySplashLogo extends StatefulWidget {
  final double width;

  const ValleySplashLogo({super.key, this.width = 240});

  @override
  State<ValleySplashLogo> createState() => _ValleySplashLogoState();
}

class _ValleySplashLogoState extends State<ValleySplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: _Brand.loop)..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final markWidth = widget.width * 0.62;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: markWidth,
          height: markWidth * _MarkPainter.canvas.height / _MarkPainter.canvas.width,
          child: AnimatedBuilder(
            animation: _loop,
            builder: (_, __) => CustomPaint(
              painter: _MarkPainter(still ? 0.5 : _loop.value, still: still),
            ),
          ),
        ),
        SizedBox(height: widget.width * 0.05),
        ValleyWordmark(width: widget.width, animate: !still),
        SizedBox(height: widget.width * 0.02),
        SizedBox(width: widget.width, child: ValleyRideStrip(height: widget.width * 0.28)),
      ],
    );
  }
}

/// Paints the brand mark and runs its four keyframe tracks: `slide` on the
/// speed lines, `pop` on the square, `draw` on the "V" and `hop`/`dotin` on
/// the pin. Geometry is taken straight from the export's mark group.
class _MarkPainter extends CustomPainter {
  final double t;
  final bool still;

  _MarkPainter(this.t, {this.still = false});

  static const canvas = Size(220, 160);
  static const _navy = Color(0xFF003893);
  static const _orange = Color(0xFFFF6B1A);

  // `@keyframes slide` — in from the right, pause, then out to the left.
  static (double, double) _slide(double p) {
    if (p < 0.06) return (0, 30);
    if (p < 0.12) {
      final k = (p - 0.06) / 0.06;
      return (k, 30 * (1 - k));
    }
    if (p < 0.24) {
      final k = (p - 0.12) / 0.12;
      return (1 - k, -26 * k);
    }
    return (0, -26);
  }

  // `@keyframes pop` — overshoot to 1.06 then settle.
  static (double, double) _pop(double p) {
    if (p < 0.08) {
      final k = Curves.easeOut.transform(p / 0.08);
      return (k, 0.6 + 0.46 * k);
    }
    if (p < 0.12) {
      final k = (p - 0.08) / 0.04;
      return (1, 1.06 - 0.06 * k);
    }
    if (p < 0.94) return (1, 1);
    return (1 - (p - 0.94) / 0.06, 1);
  }

  // `@keyframes draw` — the stroke-dashoffset reveal, as a 0..1 fraction.
  static (double, double) _draw(double p) {
    if (p < 0.04) return (1, 0);
    if (p < 0.16) return (1, Curves.easeInOut.transform((p - 0.04) / 0.12));
    if (p < 0.93) return (1, 1);
    if (p < 0.98) return (1 - (p - 0.93) / 0.05, 1);
    return (0, 1);
  }

  @override
  void paint(Canvas c, Size size) {
    final scale = size.width / canvas.width;
    c.save();
    c.scale(scale);

    // Speed lines, each offset by its own animation-delay (.06s, .12s).
    const lines = [
      (Offset(10, 52), Offset(50, 52), 0.0),
      (Offset(22, 80), Offset(52, 80), 0.06),
      (Offset(10, 108), Offset(50, 108), 0.12),
    ];
    for (final (a, b, delay) in lines) {
      final (opacity, dx) = still ? (0.9, 0.0) : _slide((t + delay / 5.0) % 1.0);
      if (opacity <= 0) continue;
      c.drawLine(
        a.translate(dx, 0),
        b.translate(dx, 0),
        Paint()
          ..color = _navy.withValues(alpha: opacity)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }

    final (squareOpacity, squareScale) = still ? (1.0, 1.0) : _pop(t);
    c.save();
    // transform-origin: 140px 80px — the square's own centre.
    c.translate(140, 80);
    c.scale(squareScale);
    c.translate(-140, -80);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 10, 140, 140),
        const Radius.circular(34),
      ),
      Paint()..color = _orange.withValues(alpha: squareOpacity),
    );

    // The "V", revealed along its own length.
    final (vOpacity, vProgress) = still ? (1.0, 1.0) : _draw(t);
    if (vProgress > 0 && vOpacity > 0) {
      final v = Path()
        ..moveTo(104, 56)
        ..lineTo(140, 120)
        ..lineTo(176, 56);
      final stroke = Paint()
        ..color = Colors.white.withValues(alpha: vOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (vProgress >= 1) {
        c.drawPath(v, stroke);
      } else {
        for (final metric in v.computeMetrics()) {
          c.drawPath(metric.extractPath(0, metric.length * vProgress), stroke);
        }
      }
    }
    c.restore();

    // Drop pin: hops on a 1.2s cycle, fading in with `dotin`.
    final hopPhase = (t * _Brand.loop.inMilliseconds / 1200.0) % 1.0;
    final hop = still ? 0.0 : -7 * (1 - (2 * hopPhase - 1).abs());
    final pinOpacity = still
        ? 1.0
        : (t < 0.08 ? 0.0 : (t < 0.12 ? (t - 0.08) / 0.04 : (t < 0.94 ? 1.0 : 1 - (t - 0.94) / 0.06)));
    if (pinOpacity > 0) {
      c.save();
      c.translate(0, hop);
      final pin = Path()
        ..moveTo(140, 68)
        ..cubicTo(135, 61, 131, 56, 131, 49)
        ..arcToPoint(const Offset(149, 49), radius: const Radius.circular(9))
        ..cubicTo(149, 56, 145, 61, 140, 68)
        ..close();
      c.drawPath(pin, Paint()..color = _navy.withValues(alpha: pinOpacity.clamp(0.0, 1.0)));
      c.drawCircle(
        const Offset(140, 49),
        3.5,
        Paint()..color = Colors.white.withValues(alpha: pinOpacity.clamp(0.0, 1.0)),
      );
      c.restore();
    }

    c.restore();
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.t != t || old.still != still;
}
