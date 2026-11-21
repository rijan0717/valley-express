import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../core/socket_service.dart';
import '../customer/chat_screen.dart';
import '../auth/welcome_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final ApiClient _api = ApiClient();
  final SocketService _socket = SocketService();
  List<dynamic> _assignedOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _socket.connect();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await _api.dio.get('/orders/my');
      if (mounted) {
        setState(() {
          _assignedOrders = res.data['orders'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final res = await _api.dio.patch('/orders/$orderId/status', data: {'status': newStatus});
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'on_the_way'
                  ? 'Order picked! Route navigation started.'
                  : 'Order delivered successfully!',
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchOrders();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: AppTheme.primaryOrange),
      );
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
              icon: const Icon(Icons.map_rounded),
              label: const Text('Launch Google Maps Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBrand,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Google Maps navigation to $address'),
                    backgroundColor: AppTheme.navyBrand,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _callCustomer(String phone, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
              child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Call Customer', style: AppTheme.displayFont(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: $name', style: AppTheme.bodyFont(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Direct Phone: +977 $phone', style: AppTheme.displayFont(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryOrange)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling customer $name at $phone...'), backgroundColor: AppTheme.successGreen),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = user?.isOnline ?? true;

    final riderName = user?.name.isNotEmpty == true ? user!.name : 'Suresh Shrestha';
    final initials = riderName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: Text(
          'Rider Dispatch Fleet',
          style: AppTheme.displayFont(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.alertRed),
            tooltip: 'Log Out',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const ValleyLoaderScreen(label: "Connecting to dispatch queue...")
          : RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: _fetchOrders,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // 1. RIDER DUTY HEADER CARD (MATCHING PROTOTYPE SCREEN-RIDER)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.navyBrand,
                            border: Border.all(color: AppTheme.primaryOrange, width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              initials.isNotEmpty ? initials : 'SS',
                              style: AppTheme.displayFont(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                riderName,
                                style: AppTheme.displayFont(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isOnline ? AppTheme.successGreen : Colors.grey,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        if (isOnline)
                                          BoxShadow(
                                            color: AppTheme.successGreen.withOpacity(0.6),
                                            blurRadius: 4,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOnline ? 'ONLINE • Ready for Orders' : 'OFFLINE • Duty Paused',
                                    style: AppTheme.bodyFont(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isOnline ? AppTheme.successGreen : Colors.grey,
                                    ),
                                  ),
                                ],
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
                  const SizedBox(height: 18),

                  // 2. ACTIVE ORDERS / NEW PICKUP REQUESTS
                  Text(
                    'Active Pickup Requests',
                    style: AppTheme.displayFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_assignedOrders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.two_wheeler_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          Text(
                            'No active delivery jobs in queue',
                            style: AppTheme.displayFont(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep duty switch online to receive instant dispatches from Central Hub.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._assignedOrders.map((o) {
                      final orderId = o['_id'] ?? '';
                      final orderNo = o['orderNo'] ?? 'VX-74423';
                      final addr = o['deliveryAddress']?['addressText'] ?? o['address']?['addressText'] ?? 'Baluwatar, Near Russian Embassy';
                      final landmark = o['deliveryAddress']?['landmark'] ?? o['address']?['landmark'] ?? '';
                      final phone = o['deliveryAddress']?['contactPhone'] ?? o['customer']?['phone'] ?? '9841234567';
                      final customerName = o['customer']?['name'] ?? 'Prajina Maharjan';
                      final status = o['status'] ?? 'rider_assigned';
                      final total = o['total'] ?? 770;
                      final isPicked = status == 'on_the_way' || status == 'picked_up';

                      double lat = 27.7280;
                      double lon = 85.3300;
                      final coords = o['deliveryAddress']?['location']?['coordinates'] ?? o['address']?['location']?['coordinates'];
                      if (coords is List && coords.length >= 2) {
                        lon = (coords[0] as num).toDouble();
                        lat = (coords[1] as num).toDouble();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryOrange.withOpacity(0.08),
                              AppTheme.navyBrand.withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.primaryOrange.withOpacity(0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGlow,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    isPicked ? 'ON THE ROAD' : 'NEW PICKUP REQUEST',
                                    style: AppTheme.displayFont(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '1.8 km drop',
                                  style: AppTheme.displayFont(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Text(
                              'Order $orderNo (Rs. $total)',
                              style: AppTheme.displayFont(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Includes insulated beverages with ice packs',
                              style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),

                            // PICKUP & DROP DETAILS CARD
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryOrange),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'PICKUP: Central Hub — Naxal / Gairidhara',
                                          style: AppTheme.bodyFont(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 14),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.successGreen),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'DROP: $addr${landmark.isNotEmpty ? " ($landmark)" : ""}',
                                          style: AppTheme.bodyFont(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ACTION BUTTON: ACCEPT & PICK ORDER / DELIVERED
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPicked ? AppTheme.successGreen : AppTheme.primaryOrange,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                if (!isPicked) {
                                  _updateOrderStatus(orderId, 'on_the_way');
                                } else {
                                  _updateOrderStatus(orderId, 'delivered');
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isPicked ? Icons.check_circle_rounded : Icons.two_wheeler_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    isPicked
                                        ? 'Hand Over & Mark Delivered (Rs. $total)'
                                        : 'Accept & Pick Order ($orderNo)',
                                    style: AppTheme.displayFont(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // COMMUNICATION SHORTCUTS
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.call, size: 16),
                                    label: Text('Call $customerName', style: AppTheme.displayFont(fontSize: 11, fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _callCustomer(phone, customerName),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.navigation_rounded, size: 16, color: AppTheme.navyBrand),
                                    label: Text('Navigate', style: AppTheme.displayFont(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.navyBrand)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.navyBrand),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _showNavigationDialog(addr, lat, lon),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppTheme.primaryOrange),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(orderId: orderId, orderNo: orderNo),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 10),

                  // 3. MY TOTAL WORKS & EARNINGS 4-GRID (MATCHING REDESIGN PROTO)
                  Text(
                    'My Total Works & Earnings',
                    style: AppTheme.displayFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        title: "Today's Deliveries",
                        value: '8 Orders',
                        sub: '● All on time',
                        subColor: AppTheme.successGreen,
                        isDark: isDark,
                      ),
                      _buildMetricCard(
                        title: 'Lifetime Rides',
                        value: '142 Rides',
                        sub: 'Kathmandu Valley',
                        subColor: Colors.grey,
                        isDark: isDark,
                      ),
                      _buildMetricCard(
                        title: 'Cash Collected',
                        value: 'Rs. 6,840',
                        sub: 'Ready for settlement',
                        subColor: AppTheme.primaryOrange,
                        isDark: isDark,
                      ),
                      _buildMetricCard(
                        title: 'Rider Rating',
                        value: '★ 4.9',
                        sub: 'Gold Fleet Level',
                        subColor: AppTheme.warningYellow,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. VEHICLE & FLEET DETAILS
                  Text(
                    'Vehicle & Compliance Details',
                    style: AppTheme.displayFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.navyBrand.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, color: AppTheme.navyBrand, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Honda Activa 125cc (Ba 98 Pa 4321)',
                                    style: AppTheme.displayFont(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Insulated Ice-Delivery Carrier Mounted',
                                    style: AppTheme.bodyFont(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'VERIFIED',
                                style: AppTheme.displayFont(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
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
              fontSize: 18,
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
}
