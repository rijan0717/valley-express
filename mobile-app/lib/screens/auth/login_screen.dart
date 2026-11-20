import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_animations.dart';
import '../../widgets/valley_text_field.dart';
import '../customer/customer_home_screen.dart';
import '../rider/rider_home_screen.dart';
import 'forgot_password_screen.dart';
import 'phone_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  final Map<String, String> _errors = {};
  String _banner = '';
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <String, String>{};
    final id = _identifier.text.trim();

    if (id.isEmpty) {
      errors['identifier'] = 'Enter your mobile number or email';
    } else if (id.contains('@')) {
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(id)) {
        errors['identifier'] = 'Enter a valid email address';
      }
    } else if (!RegExp(r'^9[78]\d{8}$').hasMatch(id)) {
      errors['identifier'] = 'Enter a valid 10-digit number, or use your email';
    }

    if (_password.text.isEmpty) {
      errors['password'] = 'Enter your password';
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      if (errors.isNotEmpty) _banner = '';
    });
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() {
      _submitting = true;
      _banner = '';
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.loginWithPassword(_identifier.text, _password.text);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      // No success toast here: landing on the home screen is the confirmation,
      // and firing one while this route is being removed leaves it anchored to
      // a Scaffold that no longer exists.
      final isRider = auth.user?.role == 'rider';
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isRider ? const RiderHomeScreen() : const CustomerHomeScreen(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _errors
          ..clear()
          ..addAll(result.fieldErrors);
        _banner = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AmbientHalo(size: 200),
                      DeliveryRunAnimation(height: 120),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ).authEntrance(index: 0),
              const SizedBox(height: 6),
              const Text(
                'Sign in to pick up where you left off.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ).authEntrance(index: 1),
              const SizedBox(height: 22),

              if (_banner.isNotEmpty) ...[
                ValleyFormBanner(message: _banner)
                    .animate()
                    .fadeIn(duration: 220.ms)
                    .shake(hz: 3, offset: const Offset(2, 0)),
                const SizedBox(height: 16),
              ],

              ValleyTextField(
                controller: _identifier,
                label: 'Mobile number or email',
                hint: '98XXXXXXXX or you@example.com',
                icon: Icons.account_circle_outlined,
                errorText: _errors['identifier'],
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clear('identifier'),
              ).authEntrance(index: 2),
              const SizedBox(height: 14),

              ValleyTextField(
                controller: _password,
                label: 'Password',
                hint: 'Your password',
                icon: Icons.lock_outline_rounded,
                errorText: _errors['password'],
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => _clear('password'),
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ).authEntrance(index: 3),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppTheme.brandBlue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).authEntrance(index: 4),

              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ).authEntrance(index: 5),

              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppTheme.textSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.border)),
                ],
              ).authEntrance(index: 6),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                  ),
                  icon: const Icon(Icons.sms_outlined, size: 18),
                  label: const Text(
                    'Sign in with an SMS code',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.brandBlue,
                    side: const BorderSide(color: AppTheme.border, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ).authEntrance(index: 7),

              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: 'New to Valley Express?  ',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Create an account',
                          style: TextStyle(
                            color: AppTheme.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).authEntrance(index: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _clear(String field) {
    if (_errors.containsKey(field)) {
      setState(() => _errors.remove(field));
    }
  }
}
