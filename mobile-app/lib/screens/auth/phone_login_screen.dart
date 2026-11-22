import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import 'register_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/valley_brand.dart';
import '../customer/customer_home_screen.dart';
import '../rider/rider_home_screen.dart';
import 'login_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  final int initialTab;
  const PhoneLoginScreen({super.key, this.initialTab = 0});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _submitting = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedPhone();
  }

  Future<void> _loadRememberedPhone() async {
    try {
      final remember = await _storage.read(key: 'valley_remember_phone_check');
      if (remember == 'true') {
        final savedPhone = await _storage.read(key: 'valley_remember_phone');
        if (mounted && savedPhone != null && savedPhone.isNotEmpty) {
          setState(() {
            _rememberMe = true;
            _phoneController.text = savedPhone;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showToast('Enter a valid 10-digit mobile number.');
      return;
    }

    setState(() => _submitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.sendOtp(phone);
    setState(() => _submitting = false);

    _showToast('Verification code sent to +977 $phone');
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (phone.isEmpty || otp.isEmpty) {
      _showToast('Please enter your mobile number and 6-digit OTP code.');
      return;
    }

    setState(() => _submitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Try customer OTP first, then rider if failed
    bool success = await auth.verifyOtp(phone, otp, role: 'customer');
    if (!success) {
      success = await auth.verifyOtp(phone, otp, role: 'rider');
    }

    setState(() => _submitting = false);
    if (!mounted) return;

    if (success) {
      if (_rememberMe) {
        await _storage.write(key: 'valley_remember_phone_check', value: 'true');
        await _storage.write(key: 'valley_remember_phone', value: phone);
      } else {
        await _storage.delete(key: 'valley_remember_phone_check');
        await _storage.delete(key: 'valley_remember_phone');
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
      _showToast('That code is invalid or has expired. Request a new one.');
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
          'SMS OTP Sign In',
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

              // LOGO — the official animated lockup, from the brand export.
              const Center(child: ValleyWordmark(width: 220)),
              const SizedBox(height: 28),

              // OTP CARD
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
                      'SMS OTP Sign In',
                      style: AppTheme.displayFont(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter your mobile number to receive a 6-digit code',
                      style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // MOBILE NUMBER INPUT
                    Text(
                      'MOBILE NUMBER',
                      style: AppTheme.displayFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '🇳🇵 +977',
                            style: AppTheme.displayFont(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          VerticalDivider(
                            indent: 10,
                            endIndent: 10,
                            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: AppTheme.bodyFont(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '98XXXXXXXX',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6-DIGIT OTP CODE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '6-DIGIT VERIFICATION CODE',
                          style: AppTheme.displayFont(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: _submitting ? null : _handleSendOtp,
                          child: Text(
                            'Send OTP',
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
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pin_outlined, color: AppTheme.primaryOrange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              style: AppTheme.displayFont(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter 6-digit code',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
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

                    // VERIFY & SIGN IN BUTTON
                    ElevatedButton(
                      onPressed: _submitting ? null : _handleVerifyOtp,
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
                              'Verify & Sign In',
                              style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // BACK TO PASSWORD LOGIN
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.navyBrand),
                  label: Text(
                    'Back to Password Sign In',
                    style: AppTheme.displayFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navyBrand,
                    ),
                  ),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
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
                        decoration: TextDecoration.underline,
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
