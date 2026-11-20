import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Renders either remote HTTP/HTTPS images or Base64 Data URL images
/// Handles errors cleanly without throwing
class ValleyProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ValleyProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }

    final url = imageUrl!;

    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64String = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 32,
          color: AppTheme.brandBlue,
        ),
      ),
    );
  }
}
