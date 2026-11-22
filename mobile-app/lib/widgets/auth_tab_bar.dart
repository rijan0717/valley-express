import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/phone_login_screen.dart';
import '../screens/auth/register_screen.dart';

/// Which of the four auth screens is showing.
enum AuthTab { signIn, smsOtp, createAccount, forgot }

/// The segmented switcher that sits under the app bar on every auth screen.
///
/// Each destination replaces the current route rather than stacking, so
/// moving between sign-in, OTP, sign-up and reset does not build up a back
/// stack the customer has to unwind.
class AuthTabBar extends StatelessWidget {
  final AuthTab current;

  const AuthTabBar({super.key, required this.current});

  static const _labels = {
    AuthTab.signIn: 'Sign In',
    AuthTab.smsOtp: 'SMS OTP',
    AuthTab.createAccount: 'Create Account',
    AuthTab.forgot: 'Forgot',
  };

  static Widget _destination(AuthTab tab) {
    switch (tab) {
      case AuthTab.signIn:
        return const LoginScreen();
      case AuthTab.smsOtp:
        return const PhoneLoginScreen();
      case AuthTab.createAccount:
        return const RegisterScreen();
      case AuthTab.forgot:
        return const ForgotPasswordScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Row(
        children: [
          for (final tab in AuthTab.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: tab == current
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => _destination(tab)),
                        ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: tab == current ? AppTheme.primaryOrange : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _labels[tab]!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.displayFont(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tab == current
                          ? Colors.white
                          : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
