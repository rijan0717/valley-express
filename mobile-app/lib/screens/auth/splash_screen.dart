import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/auth_animations.dart';
import '../../widgets/valley_brand.dart';
import 'welcome_screen.dart';
import '../customer/customer_home_screen.dart';
import '../rider/rider_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.init();
    // Long enough for the logo to finish assembling before we move on
    await Future.delayed(const Duration(milliseconds: 2400));

    if (!mounted) return;

    if (auth.isAuthenticated) {
      if (auth.user?.role == 'rider') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          (route) => false,
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      body: Stack(
        alignment: Alignment.center,
        children: [
          const AmbientHalo(size: 320),
          // The official logo animation, rebuilt from
          // valley-express-logo-animated.svg. Scaled to fit so landscape,
          // where there is far less height, cannot clip it.
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: const ValleySplashLogo(width: 260),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
