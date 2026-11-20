import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_animations.dart';
import '../../widgets/valley_text_field.dart';
import '../../widgets/valley_snackbar.dart';
import '../customer/customer_home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final Map<String, String> _errors = {};
  String _banner = '';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _rememberMe = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Mirrors the server rules so the customer is told what is wrong before a
  /// round trip. The server validates again regardless.
  bool _validate() {
    final errors = <String, String>{};

    if (_name.text.trim().isEmpty) {
      errors['name'] = 'Enter your full name';
    } else if (_name.text.trim().length < 2) {
      errors['name'] = 'Name looks too short';
    }

    final email = _email.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Enter your email address';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email address';
    }

    if (_password.text.isEmpty) {
      errors['password'] = 'Choose a password';
    } else if (_password.text.length < 8) {
      errors['password'] = 'Use at least 8 characters';
    }

    if (_confirm.text.isEmpty) {
      errors['confirm'] = 'Re-enter your password';
    } else if (_confirm.text != _password.text) {
      errors['confirm'] = 'Passwords do not match';
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

    final result = await context.read<AuthProvider>().register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          rememberMe: _rememberMe,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      // Deferred: this route is about to be removed, so anchor the message
      // to the screen the user actually lands on
      ValleySnack.showAfterNavigation(context, result.message);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
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
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AmbientHalo(size: 170),
                      CheersAnimation(size: 78),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ).authEntrance(index: 0),
              const SizedBox(height: 6),
              const Text(
                'One account for ordering, tracking and support.',
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
                controller: _name,
                label: 'Full name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                errorText: _errors['name'],
                keyboardType: TextInputType.name,
                onChanged: (_) => _clear('name'),
              ).authEntrance(index: 2),
              const SizedBox(height: 14),

              ValleyTextField(
                controller: _email,
                label: 'Email',
                hint: 'Enter your email address',
                icon: Icons.mail_outline_rounded,
                errorText: _errors['email'],
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clear('email'),
              ).authEntrance(index: 3),
              const SizedBox(height: 14),

              ValleyTextField(
                controller: _password,
                label: 'Password',
                hint: 'Create a password (min. 8 characters)',
                icon: Icons.lock_outline_rounded,
                errorText: _errors['password'],
                obscure: _obscure,
                onChanged: (_) => _clear('password'),
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ).authEntrance(index: 4),
              const SizedBox(height: 14),

              ValleyTextField(
                controller: _confirm,
                label: 'Confirm password',
                hint: 'Re-enter your password',
                icon: Icons.lock_person_outlined,
                errorText: _errors['confirm'],
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => _clear('confirm'),
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ).authEntrance(index: 5),

              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          activeColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Remember me on this device',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ).authEntrance(index: 6),

              const SizedBox(height: 18),
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
                          'Create account',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ).authEntrance(index: 7),

              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already registered?  ',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Sign in',
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
