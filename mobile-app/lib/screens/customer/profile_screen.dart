import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'chat_screen.dart';
import 'map_address_picker_screen.dart';
import '../auth/phone_login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Kathmandu Customer';
    final userPhone = user?.phone.isNotEmpty == true ? '+977 ${user!.phone}' : '+977 9841234567';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.inputBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.textMain),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Info Header Card (matching Figma reference)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE0),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accent, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, size: 36, color: AppTheme.accent),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 10, color: AppTheme.background),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textMain),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userPhone,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: AppTheme.success),
                              SizedBox(width: 4),
                              Text(
                                '18+ Verified Account',
                                style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Navigation Menu Options List
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppTheme.brandBlue,
                    title: 'Saved Delivery Addresses',
                    subtitle: 'Pick and manage Kathmandu drop-off spots',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MapAddressPickerScreen(
                            initialLat: 27.7280,
                            initialLon: 85.3300,
                            initialAddress: 'Baluwatar, Kathmandu',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    iconBg: const Color(0xFFFFF7ED),
                    iconColor: AppTheme.accent,
                    title: 'My Orders',
                    subtitle: 'Track active deliveries & order history',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.shopping_bag_outlined,
                    iconBg: const Color(0xFFF0FDF4),
                    iconColor: AppTheme.success,
                    title: 'View Cart & Checkout',
                    subtitle: 'Manage items currently in your basket',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconBg: const Color(0xFFFFF7ED),
                    iconColor: AppTheme.accent,
                    title: 'Live Chat with Store Admin',
                    subtitle: 'Real-time inquiries, special requests & support',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: Colors.deepPurple,
                    title: 'Legal Compliance & Age Policy',
                    subtitle: 'Mandatory 18+ ID check for alcohol delivery',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Kathmandu Delivery Policy'),
                          content: const Text(
                            'Valley Express strictly complies with local alcohol regulations. Orders containing alcoholic beverages require physical 18+ ID verification upon delivery by our rider.',
                            style: TextStyle(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Understood'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: AppTheme.danger,
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    isDanger: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out from Valley Express?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await auth.logout();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDanger ? AppTheme.danger : AppTheme.textMain,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSubtle),
    );
  }
}
