import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../models/order.dart';
import 'order_tracking_screen.dart';
import 'chat_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final allOrders = orderProv.orders;
    final ongoing = allOrders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();
    final history = allOrders.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: Text(
          'My Orders',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              labelStyle: AppTheme.displayFont(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Ongoing (${ongoing.length})'),
                Tab(text: 'History (${history.length})'),
              ],
            ),
          ),
        ),
      ),
      body: orderProv.isLoading
          ? const ValleyLoaderScreen(label: "Fetching your orders...")
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(ongoing, isOngoing: true, isDark: isDark),
                _buildOrderList(history, isOngoing: false, isDark: isDark),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<OrderModel> list, {required bool isOngoing, required bool isDark}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOngoing ? Icons.delivery_dining_outlined : Icons.receipt_long_outlined,
                  size: 48,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isOngoing ? 'No Ongoing Orders' : 'No Order History Yet',
                style: AppTheme.displayFont(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isOngoing
                    ? 'Place an order from Kathmandu catalog to see real-time tracking.'
                    : 'Your completed or delivered orders will appear here.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyFont(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final order = list[idx];
        return _buildOrderCard(order, isOngoing: isOngoing, isDark: isDark);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isOngoing, required bool isDark}) {
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNo,
                      style: AppTheme.displayFont(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} item(s) • Rs. ${order.total}',
                      style: AppTheme.displayFont(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status == 'delivered'
                      ? AppTheme.successGreen.withOpacity(0.15)
                      : order.status == 'cancelled'
                          ? AppTheme.alertRed.withOpacity(0.15)
                          : AppTheme.primaryOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  order.status.replaceAll('_', ' ').toUpperCase(),
                  style: AppTheme.displayFont(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: order.status == 'delivered'
                        ? AppTheme.successGreen
                        : order.status == 'cancelled'
                            ? AppTheme.alertRed
                            : AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyFont(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.addressText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyFont(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (isOngoing) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      orderProv.setCurrentOrder(order);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Live Tracking', style: AppTheme.displayFont(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    side: BorderSide(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Chat Dispatch', style: AppTheme.displayFont(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
