import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/valley_logo.dart';
import 'phone_login_screen.dart';
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
    await Future.delayed(const Duration(seconds: 2));

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
        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValleyLoaderWidget(size: 80, text: ''),
            SizedBox(height: 20),
            Text(
              'Valley',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.brandBlue,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            Text(
              'EXPRESS',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fast to order. Fast to your door.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.textMain,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
