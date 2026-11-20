import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Small counter pill for unread messages. Renders nothing at zero and
/// animates in so a reply arriving while the screen is open is noticeable.
class UnreadBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const UnreadBadge({
    super.key,
    required this.count,
    this.background = AppTheme.danger,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: count > 0 ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: count > 0 ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          constraints: const BoxConstraints(minWidth: 20),
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
