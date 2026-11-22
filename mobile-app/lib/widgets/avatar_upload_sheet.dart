import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';

/// Attach-a-photo sheet for the customer's profile picture.
///
/// Hands back a `data:` URL rather than a link to somewhere else, so the
/// picture belongs to the account. Images are downscaled on the way in — a
/// phone camera file would otherwise be several megabytes of base64 on every
/// profile read.
class AvatarUploadSheet extends StatefulWidget {
  final bool isDark;
  final ValueChanged<String> onPicked;
  final VoidCallback? onRemoved;

  const AvatarUploadSheet({
    super.key,
    required this.isDark,
    required this.onPicked,
    this.onRemoved,
  });

  /// Longest edge kept, in pixels. A profile picture is never shown larger
  /// than ~120pt, so this is generous and keeps the payload small.
  static const _maxEdge = 512.0;
  static const _quality = 85;

  @override
  State<AvatarUploadSheet> createState() => _AvatarUploadSheetState();
}

class _AvatarUploadSheetState extends State<AvatarUploadSheet> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: AvatarUploadSheet._maxEdge,
        maxHeight: AvatarUploadSheet._maxEdge,
        imageQuality: AvatarUploadSheet._quality,
      );
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? _mimeFor(file.name);
      widget.onPicked('data:$mime;base64,${base64Encode(bytes)}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not read that image. Try another one.';
        });
      }
    }
  }

  static String _mimeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, MediaQuery.of(context).viewInsets.bottom + 22),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Profile Photo',
            style: AppTheme.displayFont(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kIsWeb
                ? 'Drop an image below, or choose one from your computer'
                : 'Take a photo or choose one from your gallery',
            style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 18),
          _DropTarget(
            isDark: isDark,
            busy: _busy,
            onTap: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: AppTheme.bodyFont(fontSize: 11.5, color: AppTheme.danger),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // The camera is a device capability; on web the file dialog
              // already covers both paths, so only one button is shown.
              if (!kIsWeb) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: Text('Camera',
                        style: AppTheme.displayFont(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: Text('Choose file',
                      style: AppTheme.displayFont(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          if (widget.onRemoved != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : widget.onRemoved,
              child: Text(
                'Remove current photo',
                style: AppTheme.displayFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.danger,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders a stored profile photo, whichever form it takes.
///
/// Uploaded pictures are `data:` URLs, which `Image.network` cannot load off
/// the web — it expects an http(s) address. Accounts created before the
/// upload flow may still hold a remote link, so both are handled, and a
/// failure falls back to [fallback] rather than showing a broken image.
class AvatarImage extends StatelessWidget {
  final String url;
  final double size;
  final Widget fallback;

  const AvatarImage({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.substring(url.indexOf(',') + 1));
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// The dashed drop zone. On the web build a file dragged onto it is accepted;
/// elsewhere it behaves as a large tap target for the gallery.
class _DropTarget extends StatelessWidget {
  final bool isDark;
  final bool busy;
  final VoidCallback? onTap;

  const _DropTarget({required this.isDark, required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        isDark: isDark,
        child: SizedBox(
          height: 128,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppTheme.primaryOrange),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 30, color: AppTheme.primaryOrange.withValues(alpha: 0.9)),
                      const SizedBox(height: 8),
                      Text(
                        kIsWeb ? 'Drag an image here' : 'Tap to choose an image',
                        style: AppTheme.displayFont(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PNG, JPG or WEBP',
                        style: AppTheme.bodyFont(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A rounded dashed outline, matching the admin console's product-image
/// drop zone.
class DottedBorderBox extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const DottedBorderBox({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: AppTheme.primaryOrange.withValues(alpha: isDark ? 0.55 : 0.45),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: isDark
              ? AppTheme.primaryOrange.withValues(alpha: 0.06)
              : AppTheme.primaryOrange.withValues(alpha: 0.04),
          child: child,
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;

  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    const dash = 6.0;
    const gap = 5.0;
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + dash).clamp(0.0, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) => old.color != color;
}
