import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Consistent transient messages.
///
/// Use [show] for a message on the screen the user is staying on, and
/// [showAfterNavigation] when the current route is about to be replaced: a
/// floating SnackBar positions itself against the Scaffold it was attached to,
/// so firing one immediately before tearing that Scaffold down lays it out
/// against stale geometry (full-bleed, unrounded, floating mid-screen).
class ValleySnack {
  static SnackBar _build(String message, Color colour, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colour,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      duration: const Duration(seconds: 3),
    );
  }

  static void show(
    BuildContext context,
    String message, {
    Color colour = AppTheme.darkNavy,
    IconData icon = Icons.info_outline_rounded,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_build(message, colour, icon));
  }

  static void success(BuildContext context, String message) => show(
        context,
        message,
        colour: AppTheme.success,
        icon: Icons.check_circle_outline_rounded,
      );

  static void error(BuildContext context, String message) => show(
        context,
        message,
        colour: AppTheme.danger,
        icon: Icons.error_outline_rounded,
      );

  /// Defers the message until after the incoming route has been laid out, so
  /// it anchors to the new screen's Scaffold instead of the one being removed.
  static void showAfterNavigation(
    BuildContext context,
    String message, {
    Color colour = AppTheme.success,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(_build(message, colour, icon));
    });
  }
}

/// Convenience alias
typedef ValleySnackbar = ValleySnack;

