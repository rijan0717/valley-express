import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

/// The Valley Express brand loader, reproducing
/// `valley-express-logos/valley-express-loader.svg` in Dart.
///
/// flutter_svg does not run the CSS keyframes declared inside that SVG, so
/// both animations are driven here with the same values as the source:
///
///   .sq  breathe  scale 1 -> 1.045 -> 1   2.0s  ease-in-out
///   .v   trace    dasharray .62/.38, dashoffset 1 -> 0   1.6s  linear
///
/// Honours the platform "reduce motion" setting, matching the
/// `prefers-reduced-motion` block in the SVG.
class ValleyLoader extends StatefulWidget {
  final double size;
  final String? label;

  const ValleyLoader({super.key, this.size = 72, this.label});

  @override
  State<ValleyLoader> createState() => _ValleyLoaderState();
}

class _ValleyLoaderState extends State<ValleyLoader>
    with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _trace;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _trace = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _breathe.stop();
      _trace.stop();
    } else {
      if (!_breathe.isAnimating) _breathe.repeat(reverse: true);
      if (!_trace.isAnimating) _trace.repeat();
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      label: widget.label ?? 'Loading',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_breathe, _trace]),
              builder: (_, __) {
                // breathe: 1 -> 1.045 across a half cycle, eased
                final scale = reduceMotion
                    ? 1.0
                    : 1 + 0.045 * Curves.easeInOut.transform(_breathe.value);
                return Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    painter: _LoaderPainter(
                      dashStart: reduceMotion ? null : _trace.value,
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.label != null) ...[
            SizedBox(height: widget.size * 0.22),
            Text(
              widget.label!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3D4A6B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  /// 0..1 position of the traced dash. Null renders the static mark.
  final double? dashStart;

  // Matches stroke-dasharray: .62 .38 in the source SVG
  static const _dashFraction = 0.62;

  _LoaderPainter({required this.dashStart});

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry expressed against the 160x160 viewBox of the source SVG
    final k = size.width / 160.0;

    final square = RRect.fromRectAndRadius(
      Rect.fromLTWH(10 * k, 10 * k, 140 * k, 140 * k),
      Radius.circular(34 * k),
    );
    canvas.drawRRect(square, Paint()..color = const Color(0xFFFF6B1A));

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

    if (dashStart == null) {
      canvas.drawPath(v, stroke);
      return;
    }

    for (final metric in v.computeMetrics()) {
      final len = metric.length;
      // dashoffset animates 1 -> 0, so the dash travels forward along the path
      final start = (1 - dashStart!) * len;
      final end = start + _dashFraction * len;

      canvas.drawPath(metric.extractPath(start, end.clamp(0, len)), stroke);
      // Wrap the remainder back to the start of the path
      if (end > len) {
        canvas.drawPath(metric.extractPath(0, end - len), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter old) =>
      old.dashStart != dashStart;
}

/// Pull-to-refresh that shows the brand mark instead of the Material spinner.
///
/// Flutter's own RefreshIndicator does not allow a custom indicator widget,
/// so this wraps CustomRefreshIndicator: the mark scales up as the list is
/// pulled, then animates normally while the refresh runs.
class ValleyRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const ValleyRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: 92,
      builder: (context, child, controller) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => SizedBox(
                height: 92 * controller.value.clamp(0.0, 1.3),
                width: double.infinity,
                child: Center(
                  child: Opacity(
                    opacity: controller.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.5 + 0.5 * controller.value.clamp(0.0, 1.0),
                      child: const ValleyLoader(size: 46),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (_, builderChild) => Transform.translate(
                offset: Offset(0, 92 * controller.value.clamp(0.0, 1.3)),
                child: builderChild,
              ),
              child: child,
            ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Full-screen centred loader. Use this wherever a screen is waiting on its
/// first load, so the brand mark always sits in the middle of the screen.
class ValleyLoaderScreen extends StatelessWidget {
  final String? label;
  final Color background;

  const ValleyLoaderScreen({
    super.key,
    this.label,
    this.background = const Color(0xFFFAFBFC),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: ValleyLoader(size: 84, label: label),
    );
  }
}
