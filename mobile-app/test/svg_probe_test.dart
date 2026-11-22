import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The split brand layers must parse with no unhandled elements and must each
/// carry real geometry, otherwise the auth banner renders blank.
void main() {
  for (final name in ['valley', 'express', 'tagline', 'scooter']) {
    testWidgets('brand/$name.svg renders', (tester) async {
      final raw = File('assets/images/brand/$name.svg').readAsStringSync();
      expect(raw.contains('<style'), isFalse, reason: 'no CSS may survive');
      final info = await vg.loadPicture(SvgStringLoader(raw), null);
      debugPrint('$name -> ${info.size}');
      expect(info.size.width, greaterThan(0));
      info.picture.dispose();
    });
  }
}
