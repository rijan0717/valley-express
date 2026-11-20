import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_animations.dart';
import '../../widgets/valley_text_field.dart';
import '../../widgets/valley_snackbar.dart';
import '../customer/customer_home_screen.dart';

/// Two-step reset: confirm the mobile number, then enter the SMS code and a
/// new password. Signs the customer straight in once the password is changed.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();

  final Map<String, String> _errors = {};
  String _banner = '';
  bool _bannerIsError = true;
  bool _codeSent = false;
  bool _obscure = true;
  bool _submitting = false;

  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn -= 1);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    final phone = _phone.text.trim();

    if (phone.isEmpty) {
      return _setFieldError('phone', 'Enter your registered mobile number');
    }
    if (!RegExp(r'^9[78]\d{8}$').hasMatch(phone)) {
      return _setFieldError('phone', 'Enter a valid 10-digit number starting 97 or 98');
    }

    setState(() {
      _submitting = true;
      _errors.clear();
      _banner = '';
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.forgotPassword(phone);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _codeSent = result.success;
      _bannerIsError = !result.success;
      _banner = result.success && auth.lastDevOtp != null
          ? '${result.message} Test code: ${auth.lastDevOtp}'
          : result.message;
    });

    if (result.success) _startResendCountdown();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    final errors = <String, String>{};
    if (_otp.text.trim().length != 6) {
      errors['otp'] = 'Enter the 6-digit code from the SMS';
    }
    if (_password.text.isEmpty) {
      errors['password'] = 'Choose a new password';
    } else if (_password.text.length < 8) {
      errors['password'] = 'Use at least 8 characters';
    }

    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
        _banner = '';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errors.clear();
      _banner = '';
    });

    final result = await context.read<AuthProvider>().resetPassword(
          phone: _phone.text,
          otp: _otp.text,
          password: _password.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      // Deferred: this route is about to be removed, so anchor the
      // message to the screen the user actually lands on
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
        _bannerIsError = true;
        _banner = result.message;
      });
    }
  }

  void _setFieldError(String field, String message) {
    setState(() {
      _errors
        ..clear()
        ..[field] = message;
      _banner = '';
    });
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
              Center(
                child: SizedBox(
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const AmbientHalo(size: 180, color: AppTheme.brandBlue),
                      Icon(
                        _codeSent
                            ? Icons.mark_email_read_outlined
                            : Icons.lock_reset_rounded,
                        size: 62,
                        color: AppTheme.brandBlue,
                      )
                          .animate(key: ValueKey(_codeSent))
                          .scale(
                            duration: 460.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                          )
                          .fadeIn(duration: 240.ms),
                    ],
                  ),
                ),
              ),
              Text(
                _codeSent ? 'Set a new password' : 'Reset your password',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ).authEntrance(index: 0),
              const SizedBox(height: 6),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to ${_phone.text.trim()} and choose a new password.'
                    : 'We will text a 6-digit code to the mobile number on your account.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ).authEntrance(index: 1),
              const SizedBox(height: 22),

              if (_banner.isNotEmpty) ...[
                ValleyFormBanner(message: _banner, isError: _bannerIsError)
                    .animate()
                    .fadeIn(duration: 220.ms),
                const SizedBox(height: 16),
              ],

              ValleyTextField(
                controller: _phone,
                label: 'Registered mobile number',
                hint: '98XXXXXXXX',
                icon: Icons.phone_iphone_rounded,
                errorText: _errors['phone'],
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _clear('phone'),
              ).authEntrance(index: 2),

              if (_codeSent) ...[
                const SizedBox(height: 14),
                ValleyTextField(
                  controller: _otp,
                  label: 'Verification code',
                  hint: '6-digit code',
                  icon: Icons.pin_outlined,
                  errorText: _errors['otp'],
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _clear('otp'),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 14),
                ValleyTextField(
                  controller: _password,
                  label: 'New password',
                  hint: 'At least 8 characters',
                  icon: Icons.lock_outline_rounded,
                  errorText: _errors['password'],
                  obscure: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _resetPassword(),
                  onChanged: (_) => _clear('password'),
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resendIn > 0 || _submitting ? null : _requestCode,
                    child: Text(
                      _resendIn > 0 ? 'Resend code in ${_resendIn}s' : 'Resend code',
                      style: TextStyle(
                        color: _resendIn > 0 ? AppTheme.textSubtle : AppTheme.brandBlue,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _submitting ? null : (_codeSent ? _resetPassword : _requestCode),
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
                      : Text(
                          _codeSent ? 'Update password' : 'Send reset code',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ).authEntrance(index: 3),
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
