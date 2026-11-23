import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/socket_service.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_snackbar.dart';

class RiderNotificationsScreen extends StatefulWidget {
  const RiderNotificationsScreen({super.key});

  @override
  State<RiderNotificationsScreen> createState() => _RiderNotificationsScreenState();
}

class _RiderNotificationsScreenState extends State<RiderNotificationsScreen> {
  final ApiClient _api = ApiClient();
  final SocketService _socket = SocketService();

  List<dynamic> _notifications = [];
  bool _loading = true;
  String _selectedFilter = 'all'; // all | unpicked | new | assigned | cancelled

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    _socket.socket?.on('rider_notification', (data) {
      if (data != null && data['notification'] != null) {
        if (mounted) {
          setState(() {
            _notifications.insert(0, data['notification']);
          });
        }
      }
    });

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
    _socket.socket?.off('rider_notification');
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

  List<dynamic> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    if (_selectedFilter == 'unpicked') {
      return _notifications.where((n) => n['type'] == 'order_not_picked').toList();
    }
    if (_selectedFilter == 'new') {
      return _notifications.where((n) => n['type'] == 'new_order').toList();
    }
    if (_selectedFilter == 'assigned') {
      return _notifications.where((n) => n['type'] == 'order_assigned').toList();
    }
    if (_selectedFilter == 'cancelled') {
      return _notifications.where((n) => n['type'] == 'order_cancelled').toList();
    }
    return _notifications;
  }

  String _formatTimeAgo(String? isoString) {
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
          'Fleet Alerts & Orders',
          style: AppTheme.displayFont(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all_rounded, size: 16, color: AppTheme.primaryOrange),
            label: const Text('Mark all read', style: TextStyle(color: AppTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.w700)),
            onPressed: _notifications.isEmpty ? null : _markAllRead,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${_notifications.length})', null, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('unpicked', 'Pickup Reminders', Icons.warning_amber_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('new', 'New Orders', Icons.inventory_2_outlined, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('assigned', 'Assigned', Icons.two_wheeler_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('cancelled', 'Cancelled', Icons.cancel_outlined, isDark),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Notification List
          Expanded(
            child: _loading
                ? const Center(child: ValleyLoader(size: 64, label: 'Loading fleet notifications...'))
                : _filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'No Notifications in This Category',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order updates, pickup warnings, and assignments will appear here.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ValleyRefresh(
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (ctx, idx) {
                            final notif = _filteredNotifications[idx];
                            return _buildNotificationCard(notif, idx, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData? icon, bool isDark) {
    final selected = _selectedFilter == id;
    return ChoiceChip(
      // The avatar already carries the state; a tick on top of it just
      // crowds the chip.
      showCheckmark: false,
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : (isDark ? Colors.white70 : AppTheme.primaryOrange),
            )
          : null,
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryOrange,
      backgroundColor: isDark ? AppTheme.darkBgDevice : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
      ),
      onSelected: (_) => setState(() => _selectedFilter = id),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, int index, bool isDark) {
    final type = notif['type'] ?? 'system';
    final title = notif['title'] ?? 'Fleet Alert';
    final body = notif['body'] ?? '';
    final isRead = notif['isRead'] == true;
    final id = notif['_id'] ?? '';
    final createdAt = notif['createdAt'];

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (type) {
      case 'order_not_picked':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFEF3C7);
        break;
      case 'order_assigned':
        icon = Icons.two_wheeler_rounded;
        iconColor = const Color(0xFF003893);
        iconBg = const Color(0xFFDBEAFE);
        break;
      case 'order_cancelled':
        icon = Icons.cancel_outlined;
        iconColor = const Color(0xFFDC2626);
        iconBg = const Color(0xFFFEE2E2);
        break;
      case 'new_order':
        icon = Icons.local_mall_rounded;
        iconColor = AppTheme.primaryOrange;
        iconBg = const Color(0xFFFFEDD5);
        break;
      case 'issue_update':
        icon = Icons.assignment_late_rounded;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFEDE9FE);
        break;
      default:
        icon = Icons.notifications_active_rounded;
        iconColor = const Color(0xFF059669);
        iconBg = const Color(0xFFD1FAE5);
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
                ? AppTheme.primaryOrange.withOpacity(0.4)
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
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                            fontSize: 14,
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
                  const SizedBox(height: 6),
                  Text(
                    _formatTimeAgo(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
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
