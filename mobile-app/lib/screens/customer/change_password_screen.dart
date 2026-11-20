import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_animations.dart';
import '../../widgets/valley_text_field.dart';
import '../auth/forgot_password_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  final Map<String, String> _errors = {};
  String _banner = '';
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final errors = <String, String>{};
    if (_current.text.isEmpty) {
      errors['currentPassword'] = 'Enter your current password';
    }
    if (_next.text.isEmpty) {
      errors['newPassword'] = 'Choose a new password';
    } else if (_next.text.length < 8) {
      errors['newPassword'] = 'Use at least 8 characters';
    } else if (_next.text == _current.text) {
      errors['newPassword'] = 'Choose a password different from the current one';
    }
    if (_confirm.text != _next.text) {
      errors['confirm'] = 'Passwords do not match';
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

    final result = await context.read<AuthProvider>().changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
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
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_banner.isNotEmpty) ...[
              ValleyFormBanner(message: _banner),
              const SizedBox(height: 16),
            ],

            ValleyTextField(
              controller: _current,
              label: 'Current password',
              hint: 'Your current password',
              icon: Icons.lock_outline_rounded,
              errorText: _errors['currentPassword'],
              obscure: _obscureCurrent,
              onChanged: (_) => _clear('currentPassword'),
              suffix: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: AppTheme.textMuted,
                ),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ).authEntrance(index: 0),
            const SizedBox(height: 14),

            ValleyTextField(
              controller: _next,
              label: 'New password',
              hint: 'At least 8 characters',
              icon: Icons.lock_reset_rounded,
              errorText: _errors['newPassword'],
              obscure: _obscureNext,
              onChanged: (_) => _clear('newPassword'),
              suffix: IconButton(
                icon: Icon(
                  _obscureNext ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 19,
                  color: AppTheme.textMuted,
                ),
                onPressed: () => setState(() => _obscureNext = !_obscureNext),
              ),
            ).authEntrance(index: 1),
            const SizedBox(height: 14),

            ValleyTextField(
              controller: _confirm,
              label: 'Confirm new password',
              hint: 'Re-enter the new password',
              icon: Icons.lock_person_outlined,
              errorText: _errors['confirm'],
              obscure: _obscureNext,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onChanged: (_) => _clear('confirm'),
            ).authEntrance(index: 2),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: const Text(
                  'Forgotten it? Reset by SMS',
                  style: TextStyle(
                    color: AppTheme.brandBlue,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _save,
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
                        'Update password',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ).authEntrance(index: 3),
          ],
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
