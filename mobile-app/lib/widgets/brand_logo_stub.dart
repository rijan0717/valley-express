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
      child: ValleySplashLogo(width: width * 0.8),
    ),
  );
}
