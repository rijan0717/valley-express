import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../core/socket_service.dart';

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
        _fetchOrders();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  void _showNavigationDialog(String address, double lat, double lon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation_rounded, color: AppTheme.brandBlue, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Turn-by-Turn Navigation',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.brandBlue),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            const SizedBox(height: 12),
            Text('Destination: $address', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('GPS Coordinates: ${lat.toStringAsFixed(4)}N, ${lon.toStringAsFixed(4)}E', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open in Google Maps Directions'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandBlue, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Google Maps route to (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})'),
                    backgroundColor: AppTheme.brandBlue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog(String phone, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: AppTheme.accent),
            SizedBox(width: 8),
            Text('Call Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: $name', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Phone Number: $phone', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.brandBlue)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $phone...')),
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rider Dispatch Partner', style: TextStyle(fontSize: 11, color: AppTheme.textMain)),
            Text(user?.name ?? 'Rider', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.brandBlue)),
          ],
        ),
        actions: [
          Switch(
            value: user?.isOnline ?? false,
            activeColor: AppTheme.accent,
            onChanged: (_) => auth.toggleRiderOnline(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textMain),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _loading
          ? const ValleyLoaderScreen(label: "Loading your deliveries...")
          : ValleyRefresh(
              onRefresh: _fetchOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Rider Status Banner (No gradients)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      border: Border.all(
                        color: (user?.isOnline ?? false) ? AppTheme.brandBlue : AppTheme.border,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.two_wheeler,
                          color: (user?.isOnline ?? false) ? AppTheme.brandBlue : AppTheme.border,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (user?.isOnline ?? false) ? 'STATUS: ONLINE (ON DUTY)' : 'STATUS: OFFLINE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: (user?.isOnline ?? false) ? AppTheme.brandBlue : AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (user?.isOnline ?? false)
                                    ? 'Receiving delivery dispatches in Kathmandu'
                                    : 'Flip switch above to start receiving orders',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMain),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Assigned Delivery Jobs',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.brandBlue),
                  ),
                  const SizedBox(height: 12),

                  if (_assignedOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No active delivery assignments in queue.',
                          style: TextStyle(color: AppTheme.textMain, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._assignedOrders.map((o) {
                      final addr = o['deliveryAddress']?['addressText'] ?? o['address']?['addressText'] ?? 'Kathmandu';
                      final landmark = o['deliveryAddress']?['landmark'] ?? o['address']?['landmark'] ?? '';
                      final phone = o['deliveryAddress']?['contactPhone'] ?? o['customer']?['phone'] ?? '9841234567';
                      final customerName = o['customer']?['name'] ?? 'Customer';
                      final containsAlcohol = o['containsAlcohol'] == true;
                      final paymentMethod = o['paymentMethod'] ?? 'cash_on_delivery';
                      final paymentStatus = o['paymentStatus'] ?? 'pending';
                      final isPaid = paymentStatus == 'paid';

                      // Extract dropoff coordinates
                      double lat = 27.7280;
                      double lon = 85.3300;
                      final coords = o['deliveryAddress']?['location']?['coordinates'] ?? o['address']?['location']?['coordinates'];
                      if (coords is List && coords.length >= 2) {
                        lon = (coords[0] as num).toDouble();
                        lat = (coords[1] as num).toDouble();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  o['orderNo'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.brandBlue),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.brandBlue),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (o['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(color: AppTheme.brandBlue, fontWeight: FontWeight.w700, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Drop-off: $addr',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                            ),
                            if (landmark.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Landmark: $landmark',
                                style: const TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 8),

                            // Payment Status Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPaid ? AppTheme.success.withAlpha(20) : AppTheme.accent.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isPaid ? AppTheme.success : AppTheme.accent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPaid ? Icons.check_circle_rounded : Icons.payments_outlined,
                                    size: 16,
                                    color: isPaid ? AppTheme.success : AppTheme.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isPaid
                                          ? 'PREPAID (${paymentMethod.toUpperCase()}) — DO NOT COLLECT CASH'
                                          : 'CASH TO COLLECT: Rs. ${o['total']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: isPaid ? AppTheme.success : AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (containsAlcohol) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Mandatory: Inspect customer 18+ physical national identity card before handover.',
                                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Quick Navigation & Call Actions Row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.navigation_rounded, size: 16, color: AppTheme.brandBlue),
                                    label: const Text('Navigate (GPS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brandBlue)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.brandBlue),
                                      minimumSize: const Size(0, 42),
                                    ),
                                    onPressed: () => _showNavigationDialog(addr, lat, lon),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.phone, size: 16, color: AppTheme.accent),
                                    label: const Text('Call Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.accent),
                                      minimumSize: const Size(0, 42),
                                    ),
                                    onPressed: () => _showCallDialog(phone, customerName),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Touch-friendly Status Progression buttons (height >= 56px for rider gloves)
                            Row(
                              children: [
                                if (o['status'] != 'on_the_way' && o['status'] != 'delivered')
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 56),
                                      ),
                                      onPressed: () => _updateOrderStatus(o['_id'], 'on_the_way'),
                                      child: const Text('Picked Up -> On The Way'),
                                    ),
                                  ),
                                if (o['status'] == 'on_the_way')
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.brandBlue,
                                        minimumSize: const Size(double.infinity, 56),
                                      ),
                                      onPressed: () => _updateOrderStatus(o['_id'], 'delivered'),
                                      child: Text(isPaid ? 'Delivered (Prepaid Confirmed)' : 'Delivered & Cash Collected'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
