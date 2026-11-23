import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/socket_service.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_snackbar.dart';
import 'order_tracking_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiClient _api = ApiClient();
  final SocketService _socket = SocketService();

  List<dynamic> _notifications = [];
  bool _loading = true;
  int _selectedFilter = 0; // 0: All, 1: Orders, 2: Offers, 3: Updates

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    _socket.socket?.on('new_notification', (notif) {
      if (notif != null && mounted) {
        setState(() {
          _notifications.insert(0, notif);
        });
      }
    });
  }

  @override
  void dispose() {
    _socket.socket?.off('new_notification');
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/notifications');
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _notifications = res.data['notifications'] ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    try {
      await _api.dio.patch('/notifications/$id/read');
      if (mounted) {
        setState(() {
          _notifications[index]['isRead'] = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.dio.patch('/notifications/read-all');
      if (mounted) {
        setState(() {
          for (var n in _notifications) {
            n['isRead'] = true;
          }
        });
        ValleySnackbar.success(context, 'All notifications marked as read');
      }
    } catch (_) {}
  }

  List<dynamic> get _filteredList {
    if (_selectedFilter == 1) {
      return _notifications.where((n) => n['type'] == 'order_update').toList();
    }
    if (_selectedFilter == 2) {
      return _notifications.where((n) => n['type'] == 'promo').toList();
    }
    if (_selectedFilter == 3) {
      return _notifications.where((n) => n['type'] == 'system' || n['type'] == 'issue_update').toList();
    }
    return _notifications;
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab(0, 'All (${_notifications.length})', null, isDark),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, 'Orders', Icons.inventory_2_outlined, isDark),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, 'Offers & Promos', Icons.local_offer_outlined, isDark),
                  const SizedBox(width: 8),
                  _buildFilterTab(3, 'Support & Updates', Icons.notifications_active_outlined, isDark),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Notification List
          Expanded(
            child: _loading
                ? const Center(child: ValleyLoader(size: 64, label: 'Loading notifications...'))
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'No Notifications in this Category',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order updates, driver pickups, and deals will appear here.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ValleyRefresh(
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          itemBuilder: (ctx, idx) {
                            final notif = _filteredList[idx];
                            return _buildNotificationCard(notif, idx, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String label, IconData? icon, bool isDark) {
    final isSelected = _selectedFilter == index;
    return ChoiceChip(
      // The avatar already carries the state; a tick on top of it just
      // crowds the chip.
      showCheckmark: false,
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.primaryOrange),
            )
          : null,
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryOrange,
      backgroundColor: isDark ? AppTheme.darkBgDevice : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
      ),
      onSelected: (_) => setState(() => _selectedFilter = index),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, int index, bool isDark) {
    final type = notif['type'] ?? 'system';
    final title = notif['title'] ?? 'Notification';
    final body = notif['body'] ?? '';
    final isRead = notif['isRead'] == true;
    final id = notif['_id'] ?? '';
    final createdAt = notif['createdAt'];
    final data = notif['data'] is Map ? notif['data'] : {};
    final orderId = data['orderId']?.toString();

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (type) {
      case 'order_update':
        icon = Icons.two_wheeler_rounded;
        iconColor = const Color(0xFF003893);
        iconBg = const Color(0xFFDBEAFE);
        break;
      case 'promo':
        icon = Icons.local_offer_rounded;
        iconColor = AppTheme.primaryOrange;
        iconBg = const Color(0xFFFFEDD5);
        break;
      case 'issue_update':
        icon = Icons.support_agent_rounded;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFEDE9FE);
        break;
      case 'system':
      default:
        icon = Icons.electric_bolt_rounded;
        iconColor = const Color(0xFF059669);
        iconBg = const Color(0xFFD1FAE5);
        break;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead && id.isNotEmpty) {
          _markAsRead(id, index);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? (isRead ? AppTheme.darkSurfaceCard : const Color(0xFF1E293B))
              : (isRead ? Colors.white : const Color(0xFFFFF7ED)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isRead
                ? AppTheme.primaryOrange.withOpacity(0.35)
                : (isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            width: !isRead ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      if (orderId != null && orderId.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderTrackingScreen(orderId: orderId),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003893).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Track Order →',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF003893),
                              ),
                            ),
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
    );
  }
}
