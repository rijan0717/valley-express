import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Animates a small marker from a tapped "add" button to the cart, so the
/// count change is visibly tied to the product that caused it.
///
/// Call [FlyToCart.run] with the GlobalKeys of the source widget and the cart
/// target. If either key is not laid out, nothing happens and the add still
/// goes through — the animation is decoration, never a dependency.
class FlyToCart {
  /// Variant for a source widget that has no GlobalKey: pass the BuildContext
  /// of the button itself (via a Builder), which is cheaper than keying every
  /// card in a long list.
  static void runFromContext({
    required BuildContext sourceContext,
    required GlobalKey targetKey,
    IconData icon = Icons.local_drink_rounded,
  }) {
    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(sourceContext);
    if (sourceBox == null || targetBox == null || overlay == null) return;
    if (!sourceBox.hasSize || !targetBox.hasSize) return;

    _insert(
      overlay: overlay,
      start: sourceBox.localToGlobal(sourceBox.size.center(Offset.zero)),
      end: targetBox.localToGlobal(targetBox.size.center(Offset.zero)),
      icon: icon,
    );
  }

  static void run({
    required BuildContext context,
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    IconData icon = Icons.local_drink_rounded,
  }) {
    final sourceBox = sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context);
    if (sourceBox == null || targetBox == null || overlay == null) return;
    if (!sourceBox.hasSize || !targetBox.hasSize) return;

    _insert(
      overlay: overlay,
      start: sourceBox.localToGlobal(sourceBox.size.center(Offset.zero)),
      end: targetBox.localToGlobal(targetBox.size.center(Offset.zero)),
      icon: icon,
    );
  }

  static void _insert({
    required OverlayState overlay,
    required Offset start,
    required Offset end,
    required IconData icon,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingMarker(
        start: start,
        end: end,
        icon: icon,
        onDone: entry.remove,
      ),
    );
    overlay.insert(entry);
  }
}

class _FlyingMarker extends StatefulWidget {
  final Offset start;
  final Offset end;
  final IconData icon;
  final VoidCallback onDone;

  const _FlyingMarker({
    required this.start,
    required this.end,
    required this.icon,
    required this.onDone,
  });

  @override
  State<_FlyingMarker> createState() => _FlyingMarkerState();
}

class _FlyingMarkerState extends State<_FlyingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Arc upward on the way across, rather than sliding in a straight line
    final control = Offset(
      (widget.start.dx + widget.end.dx) / 2,
      widget.start.dy - 110,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        final inv = 1 - t;
        // Quadratic Bezier from start to end through the control point
        final position = Offset(
          inv * inv * widget.start.dx +
              2 * inv * t * control.dx +
              t * t * widget.end.dx,
          inv * inv * widget.start.dy +
              2 * inv * t * control.dy +
              t * t * widget.end.dy,
        );
        final scale = 1.0 - (0.55 * t);
        final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2);

        return Positioned(
          left: position.dx - 18,
          top: position.dy - 18,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 19, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
