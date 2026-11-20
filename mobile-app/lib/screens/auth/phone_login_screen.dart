import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../customer/customer_home_screen.dart';
import '../rider/rider_home_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController(text: '9841234567');
  final _otpController = TextEditingController(text: '123456');
  final _passwordController = TextEditingController(text: 'Rider@123');
  bool _obscurePassword = true;
  String _selectedRole = 'customer'; // 'customer' or 'rider'

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (_selectedRole == 'rider') {
      success = await auth.riderPasswordLogin(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      success = await auth.verifyOtp(
        _phoneController.text.trim(),
        _otpController.text.trim(),
        role: _selectedRole,
      );
    }

    if (!mounted) return;

    if (success) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accent,
          content: Text(_selectedRole == 'rider'
              ? 'Rider login failed. Check Phone & Password set by Admin.'
              : 'Invalid OTP or login failed. Try test OTP: 123456'),
        ),
      );
    }
  }

  void _autofillDemo(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'customer') {
        _phoneController.text = '9841234567';
        _otpController.text = '123456';
      } else {
        _phoneController.text = '9811111111';
        _passwordController.text = 'Rider@123';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Navy Curved Top Banner (matching Figma reference)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 36, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: AppTheme.darkNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.background.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: AppTheme.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'VALLEY EXPRESS',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Log In',
                    style: TextStyle(
                      color: AppTheme.background,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please sign in to your Kathmandu delivery account',
                    style: TextStyle(
                      color: AppTheme.textSubtle,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role Switcher Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _autofillDemo('customer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'customer' ? AppTheme.background : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                border: _selectedRole == 'customer'
                                    ? Border.all(color: AppTheme.border)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Customer App',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedRole == 'customer' ? AppTheme.accent : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _autofillDemo('rider'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'rider' ? AppTheme.background : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                border: _selectedRole == 'rider'
                                    ? Border.all(color: AppTheme.border)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Rider Partner',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedRole == 'rider' ? AppTheme.accent : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone Input
                  const Text(
                    'MOBILE PHONE NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '98XXXXXXXX',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: 14, right: 8, top: 14),
                        child: Text(
                          '+977',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMain,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_selectedRole == 'rider') ...[
                    const Text(
                      'RIDER ACCESS PASSWORD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'SMS VERIFICATION OTP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter 6-digit OTP (Test: 123456)',
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Quick Demo Helpers
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Customer (9841234567)', style: TextStyle(fontSize: 11)),
                        backgroundColor: AppTheme.inputBg,
                        side: BorderSide.none,
                        onPressed: () => _autofillDemo('customer'),
                      ),
                      ActionChip(
                        label: const Text('Rider (9811111111)', style: TextStyle(fontSize: 11)),
                        backgroundColor: AppTheme.inputBg,
                        side: BorderSide.none,
                        onPressed: () => _autofillDemo('rider'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Login Button
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: AppTheme.background, strokeWidth: 2),
                          )
                        : Text(
                            _selectedRole == 'rider' ? 'LOG IN AS RIDER' : 'VERIFY & LOG IN',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'Fast 30-min beverage & snack delivery in Kathmandu, Lalitpur & Bhaktapur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted.withAlpha(200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
