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

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Orders'),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: AppTheme.background,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Poppins'),
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
                _buildOrderList(ongoing, isOngoing: true),
                _buildOrderList(history, isOngoing: false),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<OrderModel> list, {required bool isOngoing}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.inputBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOngoing ? Icons.delivery_dining_outlined : Icons.receipt_long_outlined,
                  size: 48,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isOngoing ? 'No Ongoing Orders' : 'No Order History Yet',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textMain),
              ),
              const SizedBox(height: 6),
              Text(
                isOngoing
                    ? 'Place an order from Kathmandu catalog to see real-time tracking.'
                    : 'Your completed or delivered orders will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
        return _buildOrderCard(order, isOngoing: isOngoing);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isOngoing}) {
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
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
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fastfood_rounded, color: AppTheme.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNo,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} item(s) • Rs. ${order.total}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.accent),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status == 'delivered'
                      ? AppTheme.success.withAlpha(25)
                      : order.status == 'cancelled'
                          ? AppTheme.danger.withAlpha(25)
                          : AppTheme.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: order.status == 'delivered'
                        ? AppTheme.success
                        : order.status == 'cancelled'
                            ? AppTheme.danger
                            : AppTheme.accent,
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
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.addressText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                      backgroundColor: AppTheme.accent,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Track Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(orderId: order.id, orderNo: order.orderNo),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Chat Support', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Re-ordering items into basket...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Re-Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you! Rating submitted.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
