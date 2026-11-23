import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_animations.dart';
import '../../widgets/valley_text_field.dart';

/// Lets the customer correct their own name and email. The mobile number is
/// shown but not editable: it identifies the account and is the reset channel.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;

  final Map<String, String> _errors = {};
  String _banner = '';
  bool _bannerIsError = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final errors = <String, String>{};
    if (_name.text.trim().isEmpty) {
      errors['name'] = 'Enter your full name';
    } else if (_name.text.trim().length < 2) {
      errors['name'] = 'Name looks too short';
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email address';
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

    final result = await context
        .read<AuthProvider>()
        .updateProfile(name: _name.text, email: _email.text);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _bannerIsError = !result.success;
      _banner = result.success ? '' : result.message;
      _errors
        ..clear()
        ..addAll(result.fieldErrors);
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_banner.isNotEmpty) ...[
              ValleyFormBanner(message: _banner, isError: _bannerIsError),
              const SizedBox(height: 16),
            ],

            ValleyTextField(
              controller: _name,
              label: 'Full name',
              hint: 'Your name',
              icon: Icons.person_outline_rounded,
              errorText: _errors['name'],
              keyboardType: TextInputType.name,
              onChanged: (_) => _clear('name'),
            ).authEntrance(index: 0),
            const SizedBox(height: 14),

            ValleyTextField(
              controller: _email,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              errorText: _errors['email'],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onChanged: (_) => _clear('email'),
            ).authEntrance(index: 1),
            const SizedBox(height: 18),

            // Read-only identity row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBgDevice : AppTheme.inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_iphone_rounded,
                      size: 19,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOBILE NUMBER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.phone.isNotEmpty == true ? '+977 ${user!.phone}' : 'Not set',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded,
                      size: 16,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.textSubtle),
                ],
              ),
            ).authEntrance(index: 2),
            const SizedBox(height: 8),
            Text(
              'Your mobile number identifies the account and receives reset codes, so it cannot be changed here. Contact support to move an account to a new number.',
              style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                  height: 1.5),
            ),

            const SizedBox(height: 26),
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
                        'Save changes',
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
