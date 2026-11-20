import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme.dart';
import '../../core/socket_service.dart';
import 'chat_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final SocketService _socket = SocketService();

  @override
  void initState() {
    super.initState();
    _socket.connect();
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    orderProv.fetchMyOrders();

    _socket.socket?.on('order:status', (data) {
      if (mounted) {
        orderProv.updateOrderStatus(data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final order = orderProv.currentOrder;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Track Order'),
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
      body: orderProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : order == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining_outlined, size: 56, color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active Order Found',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textMain),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your live deliveries will appear here with real-time status updates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            minimumSize: const Size(160, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back to Home'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Top Half: Interactive OpenStreetMap Tile Viewer
                    Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  'https://tile.openstreetmap.org/15/${((order.longitude ?? 85.33) + 180.0) ~/ 360.0 * 32768}/${(1.0 - log(tan((order.latitude ?? 27.728) * pi / 180.0) + 1.0 / cos((order.latitude ?? 27.728) * pi / 180.0)) / pi) ~/ 2.0 * 32768}.png',
                                  fit: BoxFit.cover,
                                  headers: const {'User-Agent': 'ValleyExpressTracking/1.0'},
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.inputBg,
                                    child: const Center(
                                      child: Icon(Icons.map_rounded, size: 48, color: AppTheme.textSubtle),
                                    ),
                                  ),
                                ),
                              ),

                              // Map Drop-off Pin Marker
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkNavy,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(50),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        order.addressText.split(',')[0],
                                        style: const TextStyle(
                                          color: AppTheme.background,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Icon(Icons.location_on_rounded, color: AppTheme.accent, size: 36),
                                  ],
                                ),
                              ),

                              // Hub Pin Marker (Kathmandu Dispatch)
                              Positioned(
                                top: 20,
                                left: 24,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.storefront_rounded, size: 14, color: AppTheme.brandBlue),
                                      SizedBox(width: 4),
                                      Text(
                                        'Valley Central Hub',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.brandBlue),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Spacer for bottom card
                        const Expanded(flex: 6, child: SizedBox()),
                      ],
                    ),

                    // Bottom Floating Bottom Sheet Card (matching Figma reference)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.52,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppTheme.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Hub and Order Header Row
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputBg,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.delivery_dining_rounded, color: AppTheme.accent, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.orderNo,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textMain),
                                        ),
                                        Text(
                                          '${order.items.length} item(s) • Rs. ${order.total}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: order.status == 'delivered'
                                          ? AppTheme.success.withAlpha(20)
                                          : AppTheme.accent.withAlpha(20),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      order.status.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        color: order.status == 'delivered' ? AppTheme.success : AppTheme.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Delivery Progression Timeline
                              const Text(
                                'DELIVERY PROGRESSION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildProgressStep(
                                title: 'Order Received & Verified',
                                desc: 'Transmitted to Kathmandu kitchen hub',
                                isDone: true,
                              ),
                              _buildProgressStep(
                                title: 'Kitchen Preparing & Chilling',
                                desc: 'Beverages safely packed with chilled seal',
                                isDone: ['preparing', 'rider_assigned', 'picked_up', 'on_the_way', 'delivered'].contains(order.status),
                              ),
                              _buildProgressStep(
                                title: 'Rider Dispatched',
                                desc: order.riderName != null ? '${order.riderName} en route' : 'Dispatched to your drop-off',
                                isDone: ['picked_up', 'on_the_way', 'delivered'].contains(order.status),
                              ),
                              _buildProgressStep(
                                title: 'Delivered & Completed',
                                desc: 'Cash cleared and handed over',
                                isDone: order.status == 'delivered',
                                isLast: true,
                              ),

                              const SizedBox(height: 20),

                              // Chat with Dispatch / Rider Button (matching Figma)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(orderId: order.id, orderNo: order.orderNo),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                label: const Text('Direct Chat with Dispatch / Rider'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProgressStep({
    required String title,
    required String desc,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.accent : AppTheme.background,
                border: Border.all(
                  color: isDone ? AppTheme.accent : AppTheme.border,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Center(child: Icon(Icons.check, size: 10, color: AppTheme.background))
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? AppTheme.accent : AppTheme.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDone ? AppTheme.textMain : AppTheme.textSubtle,
                ),
              ),
              Text(desc, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}
