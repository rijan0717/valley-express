import 'package:flutter/material.dart';
import 'brand_logo_stub.dart'
    if (dart.library.js_interop) 'brand_logo_web.dart';

class ValleyAnimatedBrandLogo extends StatelessWidget {
  final double width;
  final double height;

  const ValleyAnimatedBrandLogo({
    super.key,
    this.width = 340,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return buildAnimatedBrandLogo(
      width: width,
      height: height,
      context: context,
    );
  }
}
