import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/brand_animated_logo.dart';
import 'login_screen.dart';

/// Screen 1 from Prototype: Redesigned Welcome / Splash Action Screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : Colors.white,
      body: SafeArea(
        // Landscape leaves almost no height, and the Spacers then drove the
        // lockup past the bottom. Scroll once the content no longer fits,
        // while the centred layout is kept whenever there is room.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // Shrink-wrap: Center supplies the vertical placement, and a
                    // flex child here would clash with the unbounded height a
                    // scroll view gives.
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    const SizedBox(height: 28),
    
                  // ANIMATED BRAND LOGO
                  Center(
                    child: ValleyAnimatedBrandLogo(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 260,
                    ),
                  ),
    
                    const SizedBox(height: 28),
    
                  // ACTION BUTTONS
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppTheme.primaryOrange.withOpacity(0.35),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sign In / Create Account',
                          style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
