import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../providers/chat_unread_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../widgets/unread_badge.dart';
import '../../widgets/valley_dialog.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'chat_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'map_address_picker_screen.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Keeps the order counters on this screen current
      Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
      Provider.of<ChatUnreadProvider>(context, listen: false).start();
    });
  }

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
            const SizedBox(height: 14),

            // Order activity at a glance
            Consumer<OrderProvider>(
              builder: (_, orderProv, __) {
                final orders = orderProv.orders;
                final active = orders
                    .where((o) => o.status != 'delivered' && o.status != 'cancelled')
                    .length;
                final delivered =
                    orders.where((o) => o.status == 'delivered').length;
                final spent = orders
                    .where((o) => o.status == 'delivered')
                    .fold<num>(0, (sum, o) => sum + o.total);

                return Row(
                  children: [
                    _statCard('Active', '$active', Icons.local_shipping_outlined,
                        AppTheme.accent),
                    const SizedBox(width: 10),
                    _statCard('Delivered', '$delivered',
                        Icons.check_circle_outline_rounded, AppTheme.success),
                    const SizedBox(width: 10),
                    _statCard('Spent', 'Rs. ${spent.toStringAsFixed(0)}',
                        Icons.account_balance_wallet_outlined, AppTheme.brandBlue),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Account section
            _sectionLabel('Account'),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.badge_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppTheme.brandBlue,
                    title: 'Personal Details',
                    subtitle: 'Name, email and account information',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.password_rounded,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: Colors.deepPurple,
                    title: 'Change Password',
                    subtitle: 'Update the password used to sign in',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preferences section
            _sectionLabel('Preferences'),
            Consumer<PreferencesProvider>(
              builder: (_, prefs, __) => Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildSwitchItem(
                      icon: Icons.my_location_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: AppTheme.brandBlue,
                      title: 'Location Sharing',
                      subtitle: prefs.locationSharing
                          ? 'Drop-off pin centres on your live position'
                          : 'Off — you will pick drop-off points manually',
                      value: prefs.locationSharing,
                      onChanged: (v) {
                        prefs.setLocationSharing(v);
                        _toast(
                          v
                              ? 'Location sharing turned on'
                              : 'Location sharing turned off',
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 64, color: AppTheme.border),
                    _buildSwitchItem(
                      icon: Icons.notifications_active_outlined,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: AppTheme.accent,
                      title: 'Order Notifications',
                      subtitle: prefs.orderNotifications
                          ? 'Alerts on every delivery status change'
                          : 'Off — check the tracking screen for updates',
                      value: prefs.orderNotifications,
                      onChanged: (v) {
                        prefs.setOrderNotifications(v);
                        _toast(
                          v
                              ? 'Order notifications turned on'
                              : 'Order notifications turned off',
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 64, color: AppTheme.border),
                    _buildSwitchItem(
                      icon: Icons.translate_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: AppTheme.success,
                      title: 'Show Nepali Product Names',
                      subtitle: prefs.showNepaliNames
                          ? 'Nepali names shown under each product'
                          : 'English product names only',
                      value: prefs.showNepaliNames,
                      onChanged: (v) {
                        prefs.setShowNepaliNames(v);
                        _toast(
                          v
                              ? 'Nepali product names shown'
                              : 'Nepali product names hidden',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Navigation Menu Options List
            _sectionLabel('Orders & Support'),
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
                  Consumer<ChatUnreadProvider>(
                    builder: (_, unread, __) => _buildMenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: AppTheme.accent,
                      title: 'Live Chat with Store Admin',
                      subtitle: unread.total > 0
                          ? '${unread.total} unread repl${unread.total == 1 ? 'y' : 'ies'} from dispatch'
                          : 'Real-time inquiries, special requests & support',
                      badgeCount: unread.total,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: Colors.deepPurple,
                    title: 'Legal Compliance & Age Policy',
                    subtitle: 'Mandatory 18+ ID check for alcohol delivery',
                    onTap: () => ValleyDialog.info(
                      context,
                      icon: Icons.shield_outlined,
                      accent: Colors.deepPurple,
                      title: 'Kathmandu Delivery Policy',
                      message:
                          'Valley Express complies with local alcohol regulations. Orders containing alcoholic beverages require physical 18+ ID verification at the door before the rider hands them over.',
                      buttonLabel: 'Understood',
                    ),
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.border),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: AppTheme.danger,
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    isDanger: true,
                    onTap: () async {
                      final confirmed = await ValleyDialog.confirm(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Sign out?',
                        message:
                            'You will need your password or an SMS code to sign back in. Your basket and order history stay on your account.',
                        confirmLabel: 'Sign Out',
                        cancelLabel: 'Stay',
                        isDestructive: true,
                      );
                      if (!confirmed) return;

                      await auth.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        (route) => false,
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

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.darkNavy,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 7),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.accent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textMain,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
    int badgeCount = 0,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount > 0) ...[
            UnreadBadge(count: badgeCount),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSubtle),
        ],
      ),
    );
  }
}
