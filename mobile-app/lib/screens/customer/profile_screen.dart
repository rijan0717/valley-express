import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../providers/chat_unread_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../widgets/avatar_upload_sheet.dart';
import '../../widgets/unread_badge.dart';
import '../../widgets/valley_snackbar.dart';
import 'my_orders_screen.dart';
import 'chat_screen.dart';
import 'chat_inbox_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'map_address_picker_screen.dart';
import '../auth/welcome_screen.dart';
import '../common/raise_issue_screen.dart';
import 'valley_coins_screen.dart';
import 'vouchers_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _api = ApiClient();

  // Counts for the three shortcut cards. They were hardcoded before, so the
  // card could claim a balance the account did not have.
  int _coinBalance = 0;
  int _voucherCount = 0;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
      Provider.of<ChatUnreadProvider>(context, listen: false).start();
    });
    _fetchShortcutCounts();
  }

  /// Each card reads its own figure; a failure just leaves that card at zero
  /// rather than taking the whole profile down.
  Future<void> _fetchShortcutCounts() async {
    try {
      final coins = await _api.dio.get('/coins/me');
      if (mounted && coins.data['success'] == true) {
        setState(() => _coinBalance = (coins.data['balance'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {}

    try {
      final offers = await _api.dio.get('/offers');
      if (mounted && offers.data['success'] == true) {
        setState(() => _voucherCount = (offers.data['count'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {}

    try {
      final saved = await _api.dio.get('/wishlist');
      if (mounted && saved.data['success'] == true) {
        setState(() => _savedCount = (saved.data['count'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {}
  }

  /// Opens a shortcut page and refreshes the counts on the way back, so a
  /// coin spent or a drink unsaved is reflected on the card straight away.
  Future<void> _openAndRefresh(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _fetchShortcutCounts();
  }

  /// Lets the customer attach their own photo.
  ///
  /// The curated stock avatars and the "paste an image URL" field are gone: a
  /// URL pointed the account at somebody else's server, which can change or
  /// disappear underneath us. The picture is uploaded, downscaled and stored
  /// on the account instead.
  void _showAvatarPicker() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = (auth.user?.avatarUrl ?? '').isNotEmpty;

    Future<void> save(BuildContext ctx, String dataUrl, String done) async {
      final res = await auth.updateAvatar(dataUrl);
      if (ctx.mounted) Navigator.of(ctx).pop();
      if (!mounted) return;
      res.success
          ? ValleySnack.success(context, done)
          : ValleySnack.error(context, res.message);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarUploadSheet(
        isDark: isDark,
        onPicked: (dataUrl) => save(ctx, dataUrl, 'Profile photo updated'),
        onRemoved: hasPhoto ? () => save(ctx, '', 'Profile photo removed') : null,
      ),
    );
  }

  // REDESIGNED CONFIRMATION BOX (MATCHING EXACT HTML PROTOTYPE LOGOUT MODAL)
  Future<void> _showLogoutModal() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.alertRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: AppTheme.alertRed, size: 26),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sign out?',
              textAlign: TextAlign.center,
              style: AppTheme.displayFont(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You will need your password or an SMS code to sign back in. Your basket and order history stay on your account.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyFont(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.alertRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Sign Out',
                style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                backgroundColor: isDark ? AppTheme.darkBgDevice : Colors.white,
                side: BorderSide(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Stay',
                style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      await auth.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final prefs = Provider.of<PreferencesProvider>(context);
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = user?.name.isNotEmpty == true ? user!.name : 'Prajina Maharjan';
    final userPhone = user?.phone.isNotEmpty == true ? '+977 ${user!.phone}' : 'No mobile number added';
    final initials = userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTheme.displayFont(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PROFILE HERO CARD WITH AVATAR IMAGE & PICKER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryOrange, AppTheme.primaryDeep],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGlow,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: hasAvatar
                              ? ClipOval(
                                  child: AvatarImage(
                                    url: user.avatarUrl!,
                                    size: 68,
                                    fallback: Center(
                                      child: Text(
                                        initials,
                                        style: AppTheme.displayFont(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initials.isNotEmpty ? initials : 'PM',
                                    style: AppTheme.displayFont(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTheme.displayFont(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userPhone,
                          style: AppTheme.bodyFont(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, size: 12, color: AppTheme.successGreen),
                              const SizedBox(width: 4),
                              Text(
                                '18+ Verified Account',
                                style: AppTheme.bodyFont(
                                  color: AppTheme.successGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
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

            // 2. NIGHT OWL VIP MEMBERSHIP CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryOrange.withOpacity(0.12),
                    AppTheme.navyBrand.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryOrange, AppTheme.primaryDeep],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGlow,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.star_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Night Owl Club',
                              style: AppTheme.displayFont(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'GOLD TIER',
                                style: AppTheme.displayFont(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Free night delivery & priority 20-min rider dispatch',
                          style: AppTheme.bodyFont(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryOrange, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. THREE VALUE SHORTCUT CARDS: COINS, VOUCHERS, SAVED DRINKS
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Valley Coin',
                    value: '$_coinBalance',
                    icon: Icons.monetization_on_outlined,
                    iconColor: AppTheme.primaryOrange,
                    isDark: isDark,
                    onTap: () => _openAndRefresh(const ValleyCoinsScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'My Vouchers',
                    value: _voucherCount == 1 ? '1 Active' : '$_voucherCount Active',
                    icon: Icons.local_offer_outlined,
                    iconColor: AppTheme.successGreen,
                    isDark: isDark,
                    onTap: () => _openAndRefresh(const VouchersScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Saved Drinks',
                    value: _savedCount == 1 ? '1 Item' : '$_savedCount Items',
                    icon: Icons.favorite_border_rounded,
                    iconColor: const Color(0xFFEC4899),
                    isDark: isDark,
                    onTap: () => _openAndRefresh(const WishlistScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 4. ACCOUNT SECTION
            _buildGroupHeader('Account', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                ),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.badge_outlined,
                    iconColor: AppTheme.navyBrand,
                    title: 'Personal Details',
                    subtitle: 'Name, email and account information',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                  _buildMenuItem(
                    icon: Icons.password_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Change Password',
                    subtitle: 'Update the password used to sign in',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 5. PREFERENCES & THEME (WITH DARK MODE TOGGLE)
            _buildGroupHeader('Preferences & Theme', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                ),
              ),
              child: Column(
                children: [
                  // THEME SWITCHER
                  _buildSwitchRow(
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFFD97706),
                    title: 'Dark / Midnight Mode',
                    subtitle: prefs.isDarkMode
                        ? 'Currently Midnight Dark Mode'
                        : 'Currently Clean Modern Light Mode',
                    value: prefs.isDarkMode,
                    onChanged: (val) {
                      prefs.setDarkMode(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Switched to Midnight Dark Theme' : 'Switched to Light Theme'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppTheme.primaryOrange,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),

                  // LOCATION SHARING
                  _buildSwitchRow(
                    icon: Icons.my_location_rounded,
                    iconColor: AppTheme.navyBrand,
                    title: 'Location Sharing',
                    subtitle: prefs.locationSharing
                        ? 'Drop-off pin centres on your live position'
                        : 'Off — choose address manually',
                    value: prefs.locationSharing,
                    onChanged: (val) => prefs.setLocationSharing(val),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),

                  // ORDER NOTIFICATIONS
                  _buildSwitchRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppTheme.warningYellow,
                    title: 'Order Notifications',
                    subtitle: prefs.orderNotifications
                        ? 'Live alerts on every delivery status update'
                        : 'Off — view status inside tracking',
                    value: prefs.orderNotifications,
                    onChanged: (val) => prefs.setOrderNotifications(val),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),

                  // NEPALI PRODUCT NAMES
                  _buildSwitchRow(
                    icon: Icons.translate_rounded,
                    iconColor: AppTheme.successGreen,
                    title: 'Show Nepali Product Names',
                    subtitle: prefs.showNepaliNames
                        ? 'Display Nepali names under each item'
                        : 'Off — show English names only',
                    value: prefs.showNepaliNames,
                    onChanged: (val) => prefs.setShowNepaliNames(val),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 6. ORDERS & SUPPORT SECTION
            _buildGroupHeader('Orders & Support', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                ),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    iconColor: AppTheme.primaryOrange,
                    title: 'Saved Delivery Addresses',
                    subtitle: 'Pick and manage Kathmandu drop-off spots',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MapAddressPickerScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    iconColor: const Color(0xFFF97316),
                    title: 'My Orders',
                    subtitle: 'Track active deliveries & order history',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: AppTheme.chilledIce,
                    title: 'Messages & Order Chats',
                    subtitle: 'Messenger inbox with riders & 24/7 support',
                    trailing: Consumer<ChatUnreadProvider>(
                      builder: (_, unread, __) => UnreadBadge(count: unread.total),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                  _buildMenuItem(
                    icon: Icons.report_problem_outlined,
                    iconColor: AppTheme.primaryOrange,
                    title: 'Raise an Issue / Help Ticket',
                    subtitle: 'Submit problem with order, delivery, or payment',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RaiseIssueScreen(userRole: 'customer')),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: AppTheme.alertRed,
                    title: 'Log Out',
                    subtitle: 'Sign out of your delivery account',
                    isDestructive: true,
                    onTap: _showLogoutModal, // EXACT PROTOTYPE MODAL
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTheme.displayFont(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.displayFont(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTheme.bodyFont(
                fontSize: 11,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.displayFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? AppTheme.alertRed
                          : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTheme.bodyFont(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDestructive ? AppTheme.alertRed : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.displayFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppTheme.bodyFont(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppTheme.primaryOrange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
