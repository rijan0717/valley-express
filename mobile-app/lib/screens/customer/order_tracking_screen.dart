import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme.dart';
import '../../widgets/avatar_upload_sheet.dart';
import '../../widgets/valley_loader.dart';
import '../../core/socket_service.dart';
import 'chat_screen.dart';
import 'chat_inbox_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;

  const OrderTrackingScreen({super.key, this.orderId});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      body: orderProv.isLoading
          ? const ValleyLoaderScreen(label: "Loading live GPS tracking...")
          : order == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining_outlined, size: 64, color: AppTheme.primaryOrange),
                        const SizedBox(height: 14),
                        Text(
                          'No Active Order Found',
                          style: AppTheme.displayFont(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your live deliveries will appear here with real-time rider tracking.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            minimumSize: const Size(160, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Back to Menu', style: AppTheme.displayFont(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // TOP HALF: MAP VIEWPORT
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
                                    color: isDark ? const Color(0xFF0B0E17) : const Color(0xFFE2E8F0),
                                    child: Center(
                                      child: Icon(Icons.map_rounded, size: 48, color: isDark ? Colors.grey[700] : Colors.grey[400]),
                                    ),
                                  ),
                                ),
                              ),

                              // Back Button (Top Left)
                              Positioned(
                                top: 40,
                                left: 16,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      size: 20,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ),

                              // Central Hub Badge (Top Right)
                              Positioned(
                                top: 40,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.navyBrand,
                                    borderRadius: BorderRadius.circular(99),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Hub: Valley Naxal',
                                    style: AppTheme.displayFont(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              // Center Rider Marker (Matching Redesign Prototype)
                              Center(
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGlow,
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(flex: 5, child: SizedBox()),
                      ],
                    ),

                    // BOTTOM HALF: BOTTOM SHEET CARD (MATCHING REDESIGN)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ORDER NO & STATUS ROW
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order ${order.orderNo}',
                                      style: AppTheme.displayFont(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Rider: ${order.riderName ?? "Suresh S."} • ETA: 16 mins',
                                      style: AppTheme.bodyFont(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    order.status.replaceAll('_', ' ').toUpperCase(),
                                    style: AppTheme.displayFont(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // STEP PROGRESSION TIMELINE
                            _buildStepRow(
                              title: 'Order Verified & Dispatched',
                              isDone: true,
                              isCurrent: false,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStepRow(
                              title: 'Rider navigating Baluwatar corridor',
                              isDone: true,
                              isCurrent: true,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStepRow(
                              title: 'Doorstep delivery & Fonepay verification',
                              isDone: order.status == 'delivered',
                              isCurrent: false,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),

                            // Order Financial & Delivery Charge Breakdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkBgApp : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Delivery Charge',
                                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rs. ${order.deliveryFee}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.navyBrand),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 26, color: Colors.grey.withOpacity(0.3)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Items Subtotal',
                                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rs. ${order.subtotal}',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 26, color: Colors.grey.withOpacity(0.3)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Total Paid/Due',
                                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rs. ${order.total}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryOrange),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Two separate conversations: operations is always
                            // reachable, the rider only once they are
                            // carrying the order. The server enforces the
                            // same rule, so this is the visible half of it.
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      orderId: order.id,
                                      orderNo: order.orderNo,
                                      channel: ChatChannel.support,
                                      title: 'Valley Dispatch Hub',
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Chat with Support',
                                    style: AppTheme.displayFont(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Builder(builder: (_) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              const openFrom = ['rider_assigned', 'picked_up', 'on_the_way', 'delivered'];
                              final riderReady = openFrom.contains(order.status) &&
                                  (order.riderName != null && order.riderName!.trim().isNotEmpty);
                              final riderLabel = (order.riderName ?? '').isNotEmpty
                                  ? order.riderName!
                                  : 'Assigned Rider';
                              final activeColor = isDark ? Colors.white : AppTheme.navyBrand;

                              return OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: riderReady ? activeColor : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                  backgroundColor: riderReady
                                      ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FA))
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: riderReady
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              orderId: order.id,
                                              orderNo: order.orderNo,
                                              channel: ChatChannel.delivery,
                                              title: riderLabel,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // The riders own photo when they have set one.
                                    if ((order.riderAvatarUrl ?? '').isNotEmpty)
                                      ClipOval(
                                        child: AvatarImage(
                                          url: order.riderAvatarUrl!,
                                          size: 22,
                                          fallback: Icon(
                                            Icons.pedal_bike_rounded,
                                            size: 18,
                                            color: riderReady ? activeColor : Colors.grey,
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.pedal_bike_rounded,
                                        size: 18,
                                        color: riderReady ? activeColor : Colors.grey,
                                      ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        riderReady
                                            ? 'Chat with $riderLabel'
                                            : 'Chat opens once rider is assigned',
                                        textAlign: TextAlign.center,
                                        style: AppTheme.displayFont(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: riderReady ? activeColor : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
                                  );
                                },
                                icon: const Icon(Icons.forum_outlined, size: 15, color: AppTheme.primaryOrange),
                                label: const Text(
                                  'View All Messages & Chats ➔',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStepRow({
    required String title,
    required bool isDone,
    required bool isCurrent,
    required bool isDark,
  }) {
    Color iconColor;
    Widget iconWidget;

    if (isCurrent) {
      iconColor = AppTheme.primaryOrange;
      iconWidget = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppTheme.primaryOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withOpacity(0.6),
              blurRadius: 6,
            ),
          ],
        ),
      );
    } else if (isDone) {
      iconColor = AppTheme.successGreen;
      iconWidget = const Icon(Icons.check_rounded, color: AppTheme.successGreen, size: 14);
    } else {
      iconColor = Colors.grey;
      iconWidget = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 1.5),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          child: iconWidget,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTheme.bodyFont(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                  : (isDone ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary) : Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
