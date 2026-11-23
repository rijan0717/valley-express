import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import '../../providers/auth_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_snackbar.dart';
import '../../widgets/avatar_upload_sheet.dart';
import '../../core/socket_service.dart';
import '../customer/chat_screen.dart';
import '../customer/edit_profile_screen.dart';
import '../customer/change_password_screen.dart';
import '../auth/welcome_screen.dart';
import '../common/raise_issue_screen.dart';
import '../common/support_screen.dart';
import '../common/support_screen.dart';
import 'rider_notifications_screen.dart';
import 'rider_order_details_screen.dart';
import '../customer/chat_inbox_screen.dart';
import '../../providers/chat_unread_provider.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  final SocketService _socket = SocketService();
  late TabController _tabController;

  List<dynamic> _assignedOrders = [];
  List<dynamic> _availableOrders = [];
  List<dynamic> _deliveredOrders = [];
  String _orderFilterMode = 'active'; // 'active' | 'delivered'
  String _orderSearchQuery = '';
  bool _loading = true;
  String? _claimingOrderId;

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _fleetSummary;
  DateTime? _lastBackPressTime;
  String _selectedStatsFilter = 'today';
  int _unreadNotifCount = 0;

  Future<void> _fetchUnreadNotifCount() async {
    try {
      final res = await _api.dio.get('/notifications/unread-count');
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _unreadNotifCount = (res.data['count'] ?? 0) as int;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _socket.connect();
    _setupSockets();
    _refreshAll();
    _fetchUnreadNotifCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final unread = Provider.of<ChatUnreadProvider>(context, listen: false);
      unread.start(auth.user?.id);
    });
  }

  static String formatOrderPlacedTime(dynamic rawDate) {
    if (rawDate == null) return '';
    DateTime? dt;
    if (rawDate is DateTime) {
      dt = rawDate;
    } else {
      dt = DateTime.tryParse(rawDate.toString());
    }
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.isNegative || diff.inSeconds < 45) {
      return 'Just now';
    }

    final minutes = diff.inMinutes;
    final hours = diff.inHours;
    final days = diff.inDays;

    if (days >= 1) {
      return days == 1 ? '1 day ago' : '$days days ago';
    }

    if (hours >= 1) {
      final remMinutes = minutes % 60;
      final hourPart = hours == 1 ? '1 hour' : '$hours hours';
      if (remMinutes == 0) {
        return '$hourPart ago';
      }
      final minPart = remMinutes == 1 ? '1 min' : '$remMinutes mins';
      return '$hourPart $minPart ago';
    }

    return minutes <= 1 ? '1 min ago' : '$minutes mins ago';
  }

  static String formatClockTime(dynamic rawDate) {
    if (rawDate == null) return '';
    DateTime? dt;
    if (rawDate is DateTime) {
      dt = rawDate;
    } else {
      dt = DateTime.tryParse(rawDate.toString());
    }
    if (dt == null) return '';
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _socket.socket?.off('order:claimed');
    _socket.socket?.off('order:available');
    _socket.socket?.off('order:new');
    _socket.socket?.off('order:assigned');
    _socket.socket?.off('order:status');
    _socket.socket?.off('rider_notification');
    _socket.socket?.off('new_notification');
    super.dispose();
  }

  void _setupSockets() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _socket.socket?.emit('join:rider', user.id);
      _socket.socket?.emit('join:riders-pool');
    }

    _socket.socket?.on('order:claimed', (data) {
      if (!mounted) return;
      final claimedId = data?['orderId']?.toString();
      if (claimedId != null) {
        setState(() {
          _availableOrders.removeWhere((o) => o['_id']?.toString() == claimedId);
        });
      }
      _fetchStats();
      _fetchFleetStats();
    });

    _socket.socket?.on('order:available', (_) {
      if (mounted) _fetchAvailableOrders();
    });

    _socket.socket?.on('order:new', (_) {
      if (mounted) _fetchAvailableOrders();
    });

    _socket.socket?.on('order:assigned', (_) {
      if (mounted) {
        _fetchOrders();
        _fetchAvailableOrders();
      }
    });

    _socket.socket?.on('order:status', (_) {
      if (mounted) {
        _fetchOrders();
        _fetchAvailableOrders();
      }
    });

    _socket.socket?.on('rider_notification', (_) {
      if (mounted) {
        setState(() => _unreadNotifCount++);
        _fetchOrders();
        _fetchAvailableOrders();
      }
    });

    _socket.socket?.on('new_notification', (_) {
      if (mounted) {
        setState(() => _unreadNotifCount++);
      }
    });
  }

  Future<void> _refreshAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _fetchOrders(),
      _fetchAvailableOrders(),
      _fetchStats(),
      _fetchFleetStats(),
      _fetchUnreadNotifCount(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await _api.dio.get('/orders/my');
      if (mounted) {
        final all = (res.data['orders'] ?? []) as List<dynamic>;
        setState(() {
          _assignedOrders = all.where((o) => o['status'] != 'delivered' && o['status'] != 'cancelled').toList();
          _deliveredOrders = all.where((o) => o['status'] == 'delivered').toList();
        });
      }
    } catch (_) {}
  }

  String _calculateEta(double destLat, double destLon) {
    // Current Valley Express Kathmandu Logistics Hub: 27.7172, 85.3240
    final dLat = (destLat - 27.7172).abs() * 111.0;
    final dLon = (destLon - 85.3240).abs() * 111.0 * 0.88;
    final kmSq = (dLat * dLat + dLon * dLon);
    final distanceKm = kmSq > 0 ? (kmSq < 1 ? 1.4 : kmSq * 1.25).clamp(1.1, 16.5) : 2.6;
    final minutes = (distanceKm * 3.8).round().clamp(9, 45);
    return '~${minutes} mins (${distanceKm.toStringAsFixed(1)} km away)';
  }

  Future<void> _fetchAvailableOrders() async {
    try {
      final res = await _api.dio.get('/orders/available');
      if (mounted) {
        setState(() {
          _availableOrders = res.data['orders'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchStats([String? filter]) async {
    final activeFilter = filter ?? _selectedStatsFilter;
    try {
      final res = await _api.dio.get('/rider/stats', queryParameters: {'filter': activeFilter});
      if (mounted && res.data['success'] == true) {
        setState(() {
          _selectedStatsFilter = activeFilter;
          _stats = Map<String, dynamic>.from(res.data['stats'] ?? {});
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchFleetStats() async {
    try {
      final res = await _api.dio.get('/rider/fleet-summary');
      if (mounted && res.data['success'] == true) {
        setState(() {
          _fleetSummary = {
            'totalRiders': res.data['totalRiders'] ?? 0,
            'onlineRiders': res.data['onlineRiders'] ?? 0,
            'activeOrders': res.data['activeOrders'] ?? 0,
          };
        });
      }
    } catch (_) {}
  }

  static String _rupees(num value) {
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return 'Rs. $buffer';
  }

  Future<void> _claimOrder(String orderId, String orderNo) async {
    setState(() => _claimingOrderId = orderId);
    try {
      final res = await _api.dio.patch('/orders/$orderId/claim');
      if (!mounted) return;
      setState(() => _claimingOrderId = null);

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $orderNo accepted! Added to your active delivery jobs.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _fetchOrders();
        await _fetchAvailableOrders();
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _claimingOrderId = null);

      String message = 'Could not accept order. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (e.response?.statusCode == 409 || data?['isAlreadyClaimed'] == true) {
          message = data?['message'] ?? 'This order has already been picked up by another rider.';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.info_rounded, color: AppTheme.primaryOrange, size: 24),
                  SizedBox(width: 8),
                  Text('Order Already Claimed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
              content: Text(
                message,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _fetchAvailableOrders();
                    _fetchOrders();
                  },
                  child: const Text('Refresh Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          setState(() {
            _availableOrders.removeWhere((o) => o['_id'] == orderId);
          });
          return;
        } else if (data?['message'] != null) {
          message = data['message'];
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchAvailableOrders();
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final res = await _api.dio.patch('/orders/$orderId/status', data: {'status': newStatus});
      if (res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'on_the_way'
                  ? 'Order picked! Route navigation started.'
                  : 'Order delivered successfully! Payment confirmed.',
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchOrders();
        _fetchStats();
      }
    } catch (e) {
      if (!mounted) return;
      ValleySnack.error(context, friendlyApiError(e, 'Could not update the order. Try again.'));
    }
  }

  Future<void> _launchGoogleMaps(double lat, double lon, String address) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    try {
      if (kIsWeb) {
        await launchUrl(uri, mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
      } else {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening Google Maps navigation to $address')),
        );
      }
    }
  }

  void _showNavigationDialog(String address, double lat, double lon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.navigation_rounded, color: AppTheme.primaryOrange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rider Navigation',
                    style: AppTheme.displayFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Destination: $address',
              style: AppTheme.displayFont(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GPS Coordinates: ${lat.toStringAsFixed(4)}° N, ${lon.toStringAsFixed(4)}° E',
              style: AppTheme.bodyFont(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.map_rounded, color: Colors.white),
              label: const Text('Open in Google Maps ↗', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003893),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _launchGoogleMaps(lat, lon, address);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callCustomer(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer phone ($cleanPhone) copied to clipboard'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer phone ($cleanPhone) copied to clipboard'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  Widget _buildInitialsAvatar(String initials, {double size = 32, double fontSize = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.navyBrand,
        border: Border.all(color: AppTheme.primaryOrange, width: 2),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'R',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: fontSize),
        ),
      ),
    );
  }

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
              'Sign out from Fleet?',
              textAlign: TextAlign.center,
              style: AppTheme.displayFont(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You will be marked offline on operations dispatch. You will need your rider phone and password to sign back in.',
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
                side: BorderSide(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
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
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = user?.isOnline ?? true;

    final riderName = user?.name.isNotEmpty == true ? user!.name : 'Fleet Rider';
    final initials = riderName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // If not on first tab (Active Orders), pressing back switches smoothly to tab 0
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
          return;
        }
        // Double-back to exit prevention
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Press back again to exit app'),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.navyBrand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
        appBar: AppBar(
          title: InkWell(
            onTap: () => _tabController.animateTo(3),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                        // AvatarImage, not Image.network: the photo is stored as a
                        // data URL, which Image.network cannot decode, so every
                        // uploaded picture fell through to the initials.
                        ? AvatarImage(
                            url: user.avatarUrl!,
                            size: 38,
                            fallback: _buildInitialsAvatar(initials, size: 38),
                          )
                        : _buildInitialsAvatar(initials, size: 38),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $riderName',
                          style: AppTheme.displayFont(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isOnline ? AppTheme.successGreen : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isOnline ? 'Kathmandu Fleet • Online on Duty' : 'Kathmandu Fleet • Duty Paused',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isOnline ? AppTheme.successGreen : Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          elevation: 1,
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppTheme.navyBrand),
                  tooltip: 'Fleet Alerts & Orders',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RiderNotificationsScreen(),
                      ),
                    ).then((_) => _fetchUnreadNotifCount());
                  },
                ),
                if (_unreadNotifCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryOrange),
              tooltip: 'Refresh Orders',
              onPressed: _refreshAll,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.alertRed),
              tooltip: 'Log Out',
              onPressed: _showLogoutModal,
            ),
          ],
        ),
        // FLOATING CHAT BUTTON (MATCHING USER VIEW - OPENS MESSAGES INBOX)
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryOrange,
          elevation: 4,
          shape: const CircleBorder(),
          tooltip: 'Messages & Order Chats',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChatInboxScreen(),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
              Consumer<ChatUnreadProvider>(
                builder: (_, unread, __) => unread.total == 0
                    ? const SizedBox.shrink()
                    : Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.alertRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            unread.total > 9 ? '9+' : '${unread.total}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        // BOTTOM NAVIGATION BAR (4 SECTIONS IN FOOTER LIKE USER VIEW)
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          // Clear the Android gesture/navigation bar, which otherwise
          // sits on top of the tab labels.
          padding: EdgeInsets.only(
            top: 8,
            bottom: 8 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.moped_rounded,
                label: 'Active',
                badgeCount: _assignedOrders.length,
                isSelected: _tabController.index == 0,
                onTap: () => _tabController.animateTo(0),
                isDark: isDark,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'Available',
                badgeCount: _availableOrders.length,
                isSelected: _tabController.index == 1,
                onTap: () => _tabController.animateTo(1),
                isDark: isDark,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.bar_chart_rounded,
                label: 'Fleet & Stats',
                isSelected: _tabController.index == 2,
                onTap: () => _tabController.animateTo(2),
                isDark: isDark,
              ),
              Consumer<ChatUnreadProvider>(
                builder: (_, unread, __) => _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  showDot: unread.total > 0,
                  isSelected: _tabController.index == 3,
                  onTap: () => _tabController.animateTo(3),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const ValleyLoaderScreen(label: "Connecting to dispatch queue...")
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveOrdersTab(isDark),
                  _buildAvailableOrdersTab(isDark),
                  _buildFleetStatsTab(isDark, isOnline, auth),
                  _buildRiderProfileTab(isDark, isOnline, auth),
                ],
              ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: ACTIVE ASSIGNED DELIVERIES & DELIVERED ORDERS
  // ----------------------------------------------------
  Widget _buildActiveOrdersTab(bool isDark) {
    // Filter active and delivered orders by search query
    final query = _orderSearchQuery.toLowerCase();
    final activeFiltered = _assignedOrders.where((o) {
      if (query.isEmpty) return true;
      final orderNo = (o['orderNo'] ?? '').toString().toLowerCase();
      final name = (o['customer']?['name'] ?? o['customerName'] ?? '').toString().toLowerCase();
      final addr = (o['deliveryAddress']?['addressText'] ?? o['address']?['addressText'] ?? '').toString().toLowerCase();
      return orderNo.contains(query) || name.contains(query) || addr.contains(query);
    }).toList();

    final deliveredFiltered = _deliveredOrders.where((o) {
      if (query.isEmpty) return true;
      final orderNo = (o['orderNo'] ?? '').toString().toLowerCase();
      final name = (o['customer']?['name'] ?? o['customerName'] ?? '').toString().toLowerCase();
      final addr = (o['deliveryAddress']?['addressText'] ?? o['address']?['addressText'] ?? '').toString().toLowerCase();
      return orderNo.contains(query) || name.contains(query) || addr.contains(query);
    }).toList();

    final displayList = _orderFilterMode == 'active' ? activeFiltered : deliveredFiltered;

    return Column(
      children: [
        // 1. TOP HEADER BAR: Delivery Hub Location & Real-Time Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              // Delivery Hub Banner
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: AppTheme.primaryOrange, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Kathmandu Central Hub • Naxal / Gairidhara Base',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DISPATCH ACTIVE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.successGreen),
                    ),
                  ),
                ],
              ),
              // Pickup Alert Reminder if any assigned orders are not yet picked up
              Builder(builder: (_) {
                final unpicked = _assignedOrders.where((o) => o['status'] == 'rider_assigned').toList();
                if (unpicked.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${unpicked.length} delivery awaiting store pickup! Head to hub.',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),

              // Search Bar
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBgApp : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppTheme.darkBorderCard : const Color(0xFFCBD5E1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 17, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _orderSearchQuery = val.trim()),
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Search order #, customer, or address...',
                          hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_orderSearchQuery.isNotEmpty)
                      InkWell(
                        onTap: () => setState(() => _orderSearchQuery = ''),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Filter Pills: Active vs Delivered Orders
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: isDark ? AppTheme.darkBgApp : const Color(0xFFF8FAFC),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _orderFilterMode = 'active'),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _orderFilterMode == 'active'
                          ? AppTheme.primaryOrange
                          : (isDark ? AppTheme.darkSurfaceCard : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _orderFilterMode == 'active'
                            ? AppTheme.primaryOrange
                            : (isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
                      ),
                      boxShadow: _orderFilterMode == 'active'
                          ? [BoxShadow(color: AppTheme.primaryOrange.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Active Deliveries (${_assignedOrders.length})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _orderFilterMode == 'active' ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _orderFilterMode = 'delivered'),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _orderFilterMode == 'delivered'
                          ? AppTheme.successGreen
                          : (isDark ? AppTheme.darkSurfaceCard : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _orderFilterMode == 'delivered'
                            ? AppTheme.successGreen
                            : (isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
                      ),
                      boxShadow: _orderFilterMode == 'delivered'
                          ? [BoxShadow(color: AppTheme.successGreen.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Delivered History (${_deliveredOrders.length})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _orderFilterMode == 'delivered' ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Orders List View
        Expanded(
          child: ValleyRefreshIndicator(
            onRefresh: _fetchOrders,
            child: displayList.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      const SizedBox(height: 30),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _orderFilterMode == 'active' ? Icons.two_wheeler_rounded : Icons.check_circle_outline_rounded,
                                size: 50,
                                color: (_orderFilterMode == 'active' ? AppTheme.navyBrand : AppTheme.successGreen).withOpacity(0.4),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _orderFilterMode == 'active' ? 'No Active Deliveries' : 'No Delivered Orders Yet',
                                style: AppTheme.displayFont(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _orderFilterMode == 'active'
                                    ? 'Check the "Available" tab to pick up newly placed customer orders in Kathmandu Valley.'
                                    : 'Completed delivery jobs will appear here with collected cash and route details.',
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                              ),
                              if (_orderFilterMode == 'active') ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryOrange,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _tabController.animateTo(1),
                                  child: const Text('View Available Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayList.length,
                    itemBuilder: (context, idx) {
                      final o = displayList[idx];
                      if (_orderFilterMode == 'delivered') {
                        return _buildDeliveredOrderCard(o, isDark);
                      }
                      return _buildOrderCard(o, isDark, isAvailable: false);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 2: AVAILABLE ORDERS (CONCURRENCY LOCK READY)
  // ----------------------------------------------------
  Widget _buildAvailableOrdersTab(bool isDark) {
    if (_availableOrders.isEmpty) {
      return ValleyRefreshIndicator(
        onRefresh: _fetchAvailableOrders,
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 54, color: AppTheme.primaryOrange.withOpacity(0.4)),
                    const SizedBox(height: 14),
                    Text(
                      'All Orders Claimed',
                      style: AppTheme.displayFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'There are currently no pending orders waiting for pickup in Kathmandu Valley. Pull down to refresh.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ValleyRefreshIndicator(
      onRefresh: _fetchAvailableOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableOrders.length,
        itemBuilder: (context, idx) {
          final o = _availableOrders[idx];
          return _buildOrderCard(o, isDark, isAvailable: true);
        },
      ),
    );
  }

  // ----------------------------------------------------
  // DELIVERED ORDER CARD COMPONENT (SLEEK & ATTRACTIVE)
  // ----------------------------------------------------
  Widget _buildDeliveredOrderCard(dynamic o, bool isDark) {
    final orderNo = o['orderNo'] ?? 'VX-Order';
    final addr = o['deliveryAddress']?['addressText'] ?? o['address']?['addressText'] ?? 'Kathmandu Valley';
    final landmark = o['deliveryAddress']?['landmark'] ?? o['address']?['landmark'] ?? '';
    final customerName = o['customer']?['name'] ?? o['customerName'] ?? 'Customer';
    final total = (o['total'] ?? 0) as num;
    final deliveryFee = (o['deliveryFee'] ?? o['deliveryCharge'] ?? 50) as num;
    final isCOD = o['paymentMethod'] == 'cash_on_delivery';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RiderOrderDetailsScreen(
                  order: o,
                  isAvailable: false,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'DELIVERED',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#$orderNo',
                          style: AppTheme.displayFont(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.navyBrand,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _rupees(total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Customer and Location in 1 clean line
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.successGreen),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '$addr${landmark.isNotEmpty ? " (Near $landmark)" : ""}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Footer row: Delivery charge & Tap to View CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery: ${_rupees(deliveryFee)} • ${isCOD ? "Cash Reconciled" : "Prepaid"}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF003893),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF003893)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ORDER CARD COMPONENT (SLEEK, ATTRACTIVE, UNCONGESTED)
  // ----------------------------------------------------
  Widget _buildOrderCard(dynamic o, bool isDark, {required bool isAvailable}) {
    final orderNo = o['orderNo'] ?? 'VX-Order';
    final addr = o['deliveryAddress']?['addressText'] ?? o['address']?['addressText'] ?? 'Kathmandu Valley';
    final landmark = o['deliveryAddress']?['landmark'] ?? o['address']?['landmark'] ?? '';
    final customerName = o['customer']?['name'] ?? 'Customer';
    final status = o['status'] ?? 'placed';
    final total = (o['total'] ?? 0) as num;
    final deliveryFee = (o['deliveryFee'] ?? o['deliveryCharge'] ?? 50) as num;
    final paymentMethod = o['paymentMethod'] ?? 'cash_on_delivery';
    final isCOD = paymentMethod == 'cash_on_delivery';
    final isEnRoute = status == 'on_the_way' || status == 'picked_up';
    final itemsCount = (o['items'] as List?)?.length ?? 0;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (isAvailable) {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF1D4ED8);
      badgeLabel = 'OPEN REQUEST';
    } else if (isEnRoute) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF16A34A);
      badgeLabel = 'ON THE WAY';
    } else {
      badgeBg = const Color(0xFFFFF7ED);
      badgeText = const Color(0xFFEA580C);
      badgeLabel = 'ASSIGNED TO YOU';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF003893).withOpacity(0.25)
              : (isEnRoute
                  ? AppTheme.successGreen.withOpacity(0.35)
                  : AppTheme.primaryOrange.withOpacity(0.35)),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RiderOrderDetailsScreen(
                  order: o,
                  isAvailable: isAvailable,
                  onStatusChanged: _updateOrderStatus,
                  onClaimOrder: _claimOrder,
                ),
              ),
            ).then((_) {
              if (mounted) {
                _fetchOrders();
                _fetchAvailableOrders();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Status badge, Order #, Price & Payment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeText,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #$orderNo',
                          style: AppTheme.displayFont(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.navyBrand,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _rupees(total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 2. Relative time placed
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.primaryOrange),
                    const SizedBox(width: 4),
                    Text(
                      'Placed ${formatOrderPlacedTime(o['createdAt'])}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    if (o['createdAt'] != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${formatClockTime(o['createdAt'])}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCOD ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isCOD ? 'COD' : 'Prepaid',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isCOD ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Customer & Delivery Location
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.successGreen),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '$addr${landmark.isNotEmpty ? " (Near $landmark)" : ""}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. Financial snippet & "Tap to View & Track" CTA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$itemsCount item${itemsCount == 1 ? '' : 's'} • Delivery: ${_rupees(deliveryFee)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAvailable ? 'View & Claim ➔' : 'View Details & Track ➔',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isAvailable ? const Color(0xFF003893) : AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 3: FLEET & STATS (TOTAL RIDERS + EARNINGS)
  // ----------------------------------------------------
  Widget _buildFleetStatsTab(bool isDark, bool isOnline, AuthProvider auth) {
    return ValleyRefreshIndicator(
      onRefresh: () async {
        await _fetchStats();
        await _fetchFleetStats();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Rider Duty Switch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isOnline ? AppTheme.successGreen : Colors.grey).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline ? Icons.two_wheeler_rounded : Icons.power_settings_new_rounded,
                    color: isOnline ? AppTheme.successGreen : Colors.grey,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Duty Active • Receiving Orders' : 'Duty Paused • Offline',
                        style: AppTheme.displayFont(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? 'You appear on live operations radar' : 'Toggle on to receive dispatch requests',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isOnline,
                  activeColor: AppTheme.successGreen,
                  onChanged: (_) => auth.toggleRiderOnline(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Total Fleet Radar Card (Rider View requirement)
          Text(
            'Kathmandu Valley Fleet Network',
            style: AppTheme.displayFont(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFleetStatItem(
                  icon: Icons.groups_rounded,
                  label: 'Total Fleet',
                  value: '${_fleetSummary?['totalRiders'] ?? '—'} Riders',
                  color: const Color(0xFF003893),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                _buildFleetStatItem(
                  icon: Icons.motorcycle_rounded,
                  label: 'Active on Duty',
                  value: '${_fleetSummary?['onlineRiders'] ?? '—'} Online',
                  color: AppTheme.successGreen,
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                _buildFleetStatItem(
                  icon: Icons.local_shipping_rounded,
                  label: 'Live Deliveries',
                  value: '${_fleetSummary?['activeOrders'] ?? '—'} Orders',
                  color: AppTheme.primaryOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Works & Earnings Header with Date Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Works & Earnings',
                style: AppTheme.displayFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedStatsFilter == 'today'
                      ? 'Today'
                      : (_selectedStatsFilter == '3days'
                          ? 'Last 3 Days'
                          : (_selectedStatsFilter == '1month' ? 'Last 30 Days' : 'All Time')),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Interactive Filter Chips: Today, 3 Days, 1 Month, All Time
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatsFilterChip('Today', 'today', isDark),
                const SizedBox(width: 8),
                _buildStatsFilterChip('3 Days', '3days', isDark),
                const SizedBox(width: 8),
                _buildStatsFilterChip('1 Month', '1month', isDark),
                const SizedBox(width: 8),
                _buildStatsFilterChip('All Time', 'all', isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                title: _selectedStatsFilter == 'today'
                    ? "Today's Deliveries"
                    : (_selectedStatsFilter == '3days'
                        ? "3-Day Deliveries"
                        : (_selectedStatsFilter == '1month' ? "Monthly Deliveries" : "Lifetime Deliveries")),
                value: _stats == null
                    ? '—'
                    : '${_stats!['filteredDeliveries'] ?? _stats!['todayDeliveries'] ?? 0} Orders',
                sub: _selectedStatsFilter == 'today'
                    ? 'Completed today'
                    : (_selectedStatsFilter == '3days'
                        ? 'Last 3 days'
                        : (_selectedStatsFilter == '1month' ? 'Last 30 days' : 'All delivered')),
                subColor: AppTheme.successGreen,
                isDark: isDark,
              ),
              _buildMetricCard(
                title: 'Lifetime Rides',
                value: _stats == null ? '—' : '${_stats!['lifetimeRides'] ?? 0} Rides',
                sub: 'Kathmandu Valley',
                subColor: Colors.grey,
                isDark: isDark,
              ),
              _buildMetricCard(
                title: _selectedStatsFilter == 'today'
                    ? 'Cash Collected (COD)'
                    : (_selectedStatsFilter == '3days'
                        ? 'COD (3 Days)'
                        : (_selectedStatsFilter == '1month' ? 'COD (30 Days)' : 'Total COD Collected')),
                value: _stats == null
                    ? '—'
                    : _rupees((_stats!['cashCollected'] ?? _stats!['cashCollectedToday'] ?? 0) as num),
                sub: 'Ready for reconcile',
                subColor: AppTheme.primaryOrange,
                isDark: isDark,
              ),
              _buildMetricCard(
                title: 'Active Now',
                value: '${_assignedOrders.length} Orders',
                sub: 'Assigned to you',
                subColor: AppTheme.warningYellow,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Operations Dispatch Message Action
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.navyBrand, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChatScreen(
                    channel: ChatChannel.fleet,
                    title: 'Operations Dispatch',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.support_agent_rounded, color: AppTheme.navyBrand),
            label: const Text(
              'Chat with Operations Dispatch',
              style: TextStyle(color: AppTheme.navyBrand, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsFilterChip(String label, String key, bool isDark) {
    final isSelected = _selectedStatsFilter == key;
    return InkWell(
      onTap: () {
        if (_selectedStatsFilter != key) {
          _fetchStats(key);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange
              : (isDark ? AppTheme.darkSurfaceCard : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange
                : (isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 4: RIDER PROFILE & OPERATIONS ACCOUNT
  // ----------------------------------------------------
  Widget _buildRiderProfileTab(bool isDark, bool isOnline, AuthProvider auth) {
    final user = auth.user;
    final prefs = Provider.of<PreferencesProvider>(context);
    final riderName = user?.name.isNotEmpty == true ? user!.name : 'Fleet Rider';
    final initials = riderName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final phone = user?.phone ?? '';
    final email = user?.email.isNotEmpty == true ? user!.email : 'Official Courier';
    final vehiclePlate = user?.vehicleNumber?.isNotEmpty == true ? user!.vehicleNumber! : 'BA 99 PA 4521';

    return ValleyRefreshIndicator(
      onRefresh: () async {
        await _fetchStats();
        await _fetchFleetStats();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(44),
                      child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                          ? AvatarImage(
                              url: user.avatarUrl!,
                              size: 80,
                              fallback: _buildInitialsAvatar(initials, size: 80, fontSize: 28),
                            )
                          : _buildInitialsAvatar(initials, size: 80, fontSize: 28),
                    ),
                    InkWell(
                      onTap: _showAvatarPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  riderName,
                  style: AppTheme.displayFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1D4ED8)),
                      SizedBox(width: 4),
                      Text(
                        'OFFICIAL FLEET RIDER • KATHMANDU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phone.isNotEmpty ? phone : email,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Duty Status Switch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isOnline ? AppTheme.successGreen : Colors.grey).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline ? Icons.two_wheeler_rounded : Icons.pause_circle_filled_rounded,
                    color: isOnline ? AppTheme.successGreen : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online on Duty' : 'Duty Paused',
                        style: AppTheme.displayFont(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? 'Receiving active valley dispatch jobs' : 'Taking break • Standby mode',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isOnline,
                  activeColor: AppTheme.successGreen,
                  onChanged: (_) => auth.toggleRiderOnline(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Vehicle & Equipment Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, size: 18, color: AppTheme.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Vehicle & Equipment Details',
                      style: AppTheme.displayFont(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProfileDetailRow('Vehicle Plate', vehiclePlate, isDark),
                const Divider(height: 16),
                _buildProfileDetailRow('Vehicle Type', 'Motorbike / Scooter (Valley Fleet)', isDark),
                const Divider(height: 16),
                _buildProfileDetailRow('Operating Zone', 'Kathmandu • Lalitpur • Bhaktapur', isDark),
                const Divider(height: 16),
                _buildProfileDetailRow('Thermal Insulated Bag', 'Verified & Equipped', isDark, isHighlight: true),
                const Divider(height: 16),
                _buildProfileDetailRow('Courier Rating', '4.9 ★ (Valley Elite Driver)', isDark, isHighlight: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Account Settings & Preferences
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile Information',
                  subtitle: 'Update your name or contact email',
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                Divider(height: 1, color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                _buildActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your secure rider account password',
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
                Divider(height: 1, color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.navyBrand.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppTheme.navyBrand,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'App Theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isDark ? 'Dark Mode (Night Express)' : 'Light Mode',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeColor: AppTheme.primaryOrange,
                    onChanged: (val) {
                      prefs.setDarkMode(val);
                    },
                  ),
                ),
                Divider(height: 1, color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.navyBrand.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppTheme.navyBrand,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Location Sharing',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    prefs.locationSharing
                        ? 'Dispatch and customers see your live position'
                        : 'Off — your position is not broadcast'
                    ,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Switch.adaptive(
                    value: prefs.locationSharing,
                    activeColor: AppTheme.primaryOrange,
                    onChanged: (val) => prefs.setLocationSharing(val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Operations Dispatch & Support
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Messages & Order Chats',
                  subtitle: 'Dispatch line and customer delivery messages',
                  isDark: isDark,
                  iconColor: const Color(0xFF003893),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChatInboxScreen(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                _buildActionTile(
                  icon: Icons.report_problem_rounded,
                  title: 'Raise an Issue / Incident Report',
                  subtitle: 'Report problems with delivery, customer, or app',
                  isDark: isDark,
                  iconColor: AppTheme.primaryOrange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RaiseIssueScreen(userRole: 'rider'),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                _buildActionTile(
                  icon: Icons.phone_in_talk_rounded,
                  title: 'Emergency Dispatch Hotline',
                  subtitle: 'Call Kathmandu Valley Operations Hub',
                  isDark: isDark,
                  iconColor: AppTheme.successGreen,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SupportScreen(isRider: true)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 6. Sign Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.alertRed.withOpacity(0.08),
                foregroundColor: AppTheme.alertRed,
                elevation: 0,
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Log Out from Fleet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              onPressed: _showLogoutModal,
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isHighlight
                ? AppTheme.primaryOrange
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.navyBrand).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.navyBrand, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildFleetStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required Color subColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTheme.bodyFont(fontSize: 11, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.displayFont(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTheme.bodyFont(fontSize: 10, fontWeight: FontWeight.w700, color: subColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    int badgeCount = 0,
    bool showDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? AppTheme.primaryOrange
                    : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
              else if (showDot)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.alertRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.displayFont(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppTheme.primaryOrange
                  : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
            ),
          ),
        ],
      ),
    );
  }
}
