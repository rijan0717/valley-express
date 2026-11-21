import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'order_tracking_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedFilter = 0; // 0: All, 1: Orders, 2: Offers

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'offer',
      'title': '15% Off Your Late-Night Order',
      'body': 'Use code VALLEYFIRST at checkout for 15% discount on chilled beers, food and snacks.',
      'time': '10 mins ago',
      'icon': Icons.local_offer_rounded,
      'color': AppTheme.primaryOrange,
      'isRead': false,
    },
    {
      'id': '2',
      'type': 'order',
      'title': 'Rider Dispatched for Order #VX-74423',
      'body': 'Rider Suresh S. has picked up your cold beverages with ice bags. ETA: ~16 mins.',
      'time': '25 mins ago',
      'icon': Icons.two_wheeler_rounded,
      'color': AppTheme.navyBrand,
      'isRead': false,
    },
    {
      'id': '3',
      'type': 'order',
      'title': 'Kathmandu Night Hub is Active',
      'body': 'Naxal Central Chilling Hub is open tonight until 4:00 AM. 20-30 min delivery valley-wide.',
      'time': '1 hour ago',
      'icon': Icons.access_time_rounded,
      'color': AppTheme.successGreen,
      'isRead': true,
    },
    {
      'id': '4',
      'type': 'offer',
      'title': 'Free 2kg Tube Ice Bag Tonight',
      'body': 'Automatic free 2kg tube ice bag included with any spirits or beer orders above Rs. 2,000.',
      'time': '3 hours ago',
      'icon': Icons.ac_unit_rounded,
      'color': AppTheme.chilledIce,
      'isRead': true,
    },
    {
      'id': '5',
      'type': 'order',
      'title': '18+ ID Compliance Reminder',
      'body': 'Please have your physical government ID or citizenship card ready for alcohol handovers.',
      'time': 'Yesterday',
      'icon': Icons.verified_user_rounded,
      'color': AppTheme.warningYellow,
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _notifications.where((n) {
      if (_selectedFilter == 1) return n['type'] == 'order';
      if (_selectedFilter == 2) return n['type'] == 'offer';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: Text(
          'Notifications',
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
            onTap: () => Navigator.of(context).pop(),
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
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppTheme.navyBrand,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Mark all read',
              style: AppTheme.bodyFont(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (All, Orders, Offers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All (${_notifications.length})', 0, isDark),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Orders (${_notifications.where((n) => n['type'] == 'order').length})',
                  1,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Offers (${_notifications.where((n) => n['type'] == 'offer').length})',
                  2,
                  isDark,
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 52, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications in this tab',
                          style: AppTheme.displayFont(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      final isRead = item['isRead'] == true;
                      final Color iconColor = item['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          setState(() => item['isRead'] = true);
                          if (item['type'] == 'order') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? (isRead ? AppTheme.darkSurfaceCard : AppTheme.darkSurfaceHover)
                                : (isRead ? Colors.white : const Color(0xFFFFF9F5)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? (isRead ? AppTheme.darkBorderCard : AppTheme.primaryOrange.withOpacity(0.3))
                                  : (isRead ? AppTheme.lightBorderCard : AppTheme.primaryOrange.withOpacity(0.3)),
                              width: isRead ? 1.0 : 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item['icon'] as IconData, color: iconColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: AppTheme.displayFont(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 7,
                                            height: 7,
                                            margin: const EdgeInsets.only(left: 6),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryOrange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['body'] as String,
                                      style: AppTheme.bodyFont(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['time'] as String,
                                      style: AppTheme.bodyFont(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange
              : (isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.displayFont(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
