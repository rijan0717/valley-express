import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/auth_animations.dart';
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
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
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          AmbientHalo(size: 320),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBrandMark(scale: 1.1),
              SizedBox(height: 36),
              DeliveryRunAnimation(height: 110),
            ],
          ),
        ],
      ),
    );
  }
}
