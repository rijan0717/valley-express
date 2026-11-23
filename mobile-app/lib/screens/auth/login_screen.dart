import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_home_screen.dart';
import '../rider/rider_home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final remember = await _storage.read(key: 'valley_remember_me');
      if (remember == 'true') {
        final savedId = await _storage.read(key: 'valley_remembered_identifier');
        final savedPass = await _storage.read(key: 'valley_remembered_password');
        if (mounted) {
          setState(() {
            _rememberMe = true;
            if (savedId != null && savedId.isNotEmpty) _identifierController.text = savedId;
            if (savedPass != null && savedPass.isNotEmpty) _passwordController.text = savedPass;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showToast('Please enter your mobile number or email and password.');
      return;
    }

    setState(() => _submitting = true);

    // Try rider password login first if it's the rider test or credentials
    bool success = false;
    final res = await auth.loginWithPassword(identifier, password, rememberMe: _rememberMe);
    success = res.success;

    if (!success) {
      // Check if this is a rider account
      success = await auth.riderPasswordLogin(identifier, password, rememberMe: _rememberMe);
    }

    setState(() => _submitting = false);
    if (!mounted) return;

    if (success) {
      if (_rememberMe) {
        await _storage.write(key: 'valley_remember_me', value: 'true');
        await _storage.write(key: 'valley_remembered_identifier', value: identifier);
        await _storage.write(key: 'valley_remembered_password', value: password);
      } else {
        await _storage.delete(key: 'valley_remember_me');
        await _storage.delete(key: 'valley_remembered_identifier');
        await _storage.delete(key: 'valley_remembered_password');
      }

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
      _showToast(res.message.isNotEmpty ? res.message : 'Invalid credentials. Please check your details and try again.');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.navyBrand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 0,
        title: Text(
          'Sign In',
          style: AppTheme.displayFont(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // BRAND LOGO & HEADLINE
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGlow,
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        style: AppTheme.displayFont(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                        children: const [
                          TextSpan(text: 'Valley '),
                          TextSpan(
                            text: 'EXPRESS',
                            style: TextStyle(
                              color: AppTheme.primaryOrange,
                              letterSpacing: 2,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fast to order. Fast to your door.',
                      style: AppTheme.bodyFont(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // LOGIN CARD CONTAINER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome Back',
                      style: AppTheme.displayFont(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to Kathmandu late-night delivery express',
                      style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 18),

                    // MOBILE / EMAIL INPUT
                    Text(
                      'MOBILE NUMBER OR EMAIL',
                      style: AppTheme.displayFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _identifierController,
                        style: AppTheme.bodyFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'email@example.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryOrange, size: 20),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PASSWORD INPUT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PASSWORD',
                          style: AppTheme.displayFont(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: AppTheme.bodyFont(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTheme.bodyFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryOrange, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // REMEMBER ME CHECKBOX
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppTheme.primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            onChanged: (val) {
                              setState(() => _rememberMe = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => _rememberMe = !_rememberMe);
                          },
                          child: Text(
                            'Remember Me',
                            style: AppTheme.bodyFont(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SIGN IN BUTTON
                    ElevatedButton(
                      onPressed: _submitting ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: AppTheme.primaryOrange.withOpacity(0.35),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Sign In',
                              style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SIGN UP LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTheme.bodyFont(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Register here',
                      style: AppTheme.displayFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
