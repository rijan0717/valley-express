import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme.dart';
import '../../widgets/valley_brand.dart';
import 'phone_login_screen.dart';

/// Screen 1 from Prototype: Redesigned Welcome / Splash Action Screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // BRAND LOGO ART WITH GLOW
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // TITLE & SUBTITLE (MATCHING PROTOTYPE SCREEN 1)
              Text(
                'Valley',
                style: AppTheme.displayFont(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'EXPRESS',
                style: AppTheme.displayFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 7,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Kathmandu's Dedicated 8 PM–4 AM Night Delivery",
                textAlign: TextAlign.center,
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // SCOOTER BANNER
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ValleyRideStrip(height: 56),
                ),
              ),

              const Spacer(),

              // ACTION BUTTONS
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
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
    );
  }
}
