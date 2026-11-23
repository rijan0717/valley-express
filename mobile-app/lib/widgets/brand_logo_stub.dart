import 'package:flutter/material.dart';
import 'valley_brand.dart';

Widget buildAnimatedBrandLogo({
  required double width,
  required double height,
  required BuildContext context,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: Center(
      // The lockup sizes itself from its width, so a caller-supplied height
      // can be shorter than the stack needs and the Column overflows. Scaling
      // to fit matches the `object-fit: contain` the web variant uses.
      child: FittedBox(
        fit: BoxFit.contain,
        child: ValleySplashLogo(width: width * 0.8),
      ),
    ),
  );
}
