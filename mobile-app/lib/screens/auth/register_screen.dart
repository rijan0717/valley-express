import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import 'phone_login_screen.dart';
import '../../widgets/valley_brand.dart';
import '../customer/customer_home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  // Pre-ticked to match the prototype; the API rejects sign-up without it.
  bool _ageConfirmed = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || (phone.isEmpty && email.isEmpty) || password.isEmpty) {
      _showToast('Please fill in your name, email/mobile number and password.');
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showToast('Please enter a valid email address (e.g. name@example.com).');
      return;
    }
    if (password.length < 8) {
      _showToast('Your password needs at least 8 characters.');
      return;
    }
    if (!_ageConfirmed) {
      _showToast('Please confirm you are 18 or older to order.');
      return;
    }

    setState(() => _submitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      ageConfirmed: _ageConfirmed,
    );
    setState(() => _submitting = false);
    if (!mounted) return;

    if (res.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (route) => false,
      );
    } else {
      final errorMsg = res.fieldErrors.isNotEmpty
          ? res.fieldErrors.values.first
          : (res.message.isNotEmpty ? res.message : 'Registration failed. Try again.');
      _showToast(errorMsg);
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
          'Create Account',
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
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
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

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGlow,
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/images/valley-express-loader.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: AppTheme.displayFont(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One account for orders, tracking & support',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      label: 'FULL NAME',
                      hint: 'e.g. Prajina Maharjan',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'EMAIL ADDRESS',
                      hint: 'email@example.com',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildPhoneField(isDark),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'PASSWORD (MIN. 8 CHARACTERS)',
                      hint: 'Create a strong password',
                      icon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      isDark: isDark,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAgeGate(isDark),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _submitting ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: AppTheme.primaryOrange.withOpacity(0.35),
                      ),
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Create Free Account',
                                    style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w800)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ValleyRideStrip(height: 44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTheme.bodyFont(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    child: Text(
                      'Sign In',
                      style: AppTheme.displayFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.sms_outlined, size: 16, color: AppTheme.navyBrand),
                  label: Text(
                    'Sign in with SMS OTP',
                    style: AppTheme.displayFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navyBrand,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return _labelled(
      label,
      isDark,
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTheme.bodyFont(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryOrange, size: 20),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  /// Mobile number with the fixed Nepali dialling code alongside it, as in
  /// the prototype: the country part is not editable, only the 10 digits.
  Widget _buildPhoneField(bool isDark) {
    return _labelled(
      'MOBILE NUMBER',
      isDark,
      Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NP',
                      style: AppTheme.displayFont(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      )),
                  Text('+977',
                      style: AppTheme.displayFont(fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              indent: 10,
              endIndent: 10,
              color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
            ),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '98XXXXXXXX',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The 18+ declaration. Kathmandu liquor rules sit behind this, so it is
  /// recorded on the account and the API refuses sign-up without it.
  Widget _buildAgeGate(bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _ageConfirmed = !_ageConfirmed),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: _ageConfirmed
              ? AppTheme.successGreen.withOpacity(isDark ? 0.16 : 0.10)
              : (isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _ageConfirmed,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppTheme.navyBrand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTheme.bodyFont(
                    fontSize: 11,
                    height: 1.45,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: '18+ Age Verification: ',
                      style: AppTheme.displayFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const TextSpan(
                      text:
                          'I confirm I am 18 years or older as required by Kathmandu liquor '
                          'regulations for alcoholic deliveries.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelled(String label, bool isDark, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.displayFont(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
