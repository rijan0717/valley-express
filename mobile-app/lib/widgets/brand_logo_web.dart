import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

bool _registered = false;

Widget buildAnimatedBrandLogo({
  required double width,
  required double height,
  required BuildContext context,
}) {
  if (!_registered) {
    ui_web.platformViewRegistry.registerViewFactory(
      'valley-animated-logo-view',
      (int viewId) {
        final img = web.document.createElement('img') as web.HTMLImageElement;
        img.src = 'valley-express-logo-animated.svg';
        img.style.width = '100%';
        img.style.height = '100%';
        img.style.objectFit = 'contain';
        img.style.backgroundColor = 'transparent';
        img.style.border = 'none';
        return img;
      },
    );
    _registered = true;
  }

  return SizedBox(
    width: width,
    height: height,
    child: const HtmlElementView(viewType: 'valley-animated-logo-view'),
  );
}
