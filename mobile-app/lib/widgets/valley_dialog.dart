import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

/// Branded dialogs. Replaces the stock Material AlertDialog, which stacks its
/// actions and inherits none of the app's shape, spacing or colour.
class ValleyDialog {
  /// Asks for confirmation. Resolves to true only if the action was confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    bool isDestructive = false,
  }) async {
    final accent = isDestructive ? AppTheme.danger : AppTheme.accent;

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _Shell(
        icon: icon,
        accent: accent,
        title: title,
        message: message,
        actions: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMain,
                    side: const BorderSide(color: AppTheme.border, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  /// Shows a single-button informational dialog.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Got it',
    IconData icon = Icons.info_outline_rounded,
    Color accent = AppTheme.brandBlue,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _Shell(
        icon: icon,
        accent: accent,
        title: title,
        message: message,
        actions: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final Widget actions;

  const _Shell({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: accent),
            )
                .animate()
                .scale(
                  duration: 320.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 180.ms),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            actions,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms)
        .scale(
          duration: 220.ms,
          curve: Curves.easeOutCubic,
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
        );
  }
}
