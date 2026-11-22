import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/socket_service.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_unread_provider.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  final String? initialFilter; // 'all' | 'riders' | 'support'

  const ChatInboxScreen({
    super.key,
    this.initialFilter = 'all',
  });

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ApiClient _api = ApiClient();
  final SocketService _socket = SocketService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _conversations = [];
  bool _loading = true;
  String _activeFilter = 'all'; // 'all' | 'riders' | 'support'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'all';
    _socket.connect();
    final auth = context.read<AuthProvider>();
    if (auth.user?.id != null) {
      _socket.joinUser(auth.user!.id);
    }

    _fetchConversations();

    // Listen to incoming messages in real-time to update inbox snippets
    _socket.socket?.on('chat:message', (_) {
      if (mounted) {
        _fetchConversations(silent: true);
        context.read<ChatUnreadProvider>().refresh();
      }
    });

    _socket.socket?.on('chat:read', (_) {
      if (mounted) {
        _fetchConversations(silent: true);
        context.read<ChatUnreadProvider>().refresh();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversations({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final res = await _api.dio.get('/chat/conversations');
      if (mounted && res.data['success'] == true) {
        setState(() {
          _conversations = res.data['conversations'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return '';
    DateTime dt;
    if (raw is DateTime) {
      dt = raw;
    } else {
      dt = DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  List<dynamic> get _filteredConversations {
    return _conversations.where((c) {
      final type = c['type']?.toString().toLowerCase() ?? '';
      final channel = c['channel']?.toString().toLowerCase() ?? '';

      // Tab filter
      if (_activeFilter == 'riders') {
        if (type != 'rider' && channel != 'delivery') return false;
      } else if (_activeFilter == 'support') {
        if (type != 'support' && channel != 'support' && channel != 'fleet') return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (c['title'] ?? '').toString().toLowerCase();
        final orderNo = (c['orderNo'] ?? '').toString().toLowerCase();
        final subtitle = (c['subtitle'] ?? '').toString().toLowerCase();
        final lastMsg = (c['lastMessage'] ?? '').toString().toLowerCase();

        return title.contains(q) || orderNo.contains(q) || subtitle.contains(q) || lastMsg.contains(q);
      }

      return true;
    }).toList();
  }

  int get _totalUnreadCount {
    int total = 0;
    for (final c in _conversations) {
      final unread = (c['unreadCount'] ?? 0) as num;
      total += unread.toInt();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalUnread = _totalUnreadCount;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBgApp : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : AppTheme.navyBrand,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Messages & Chats',
                  style: AppTheme.displayFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.navyBrand,
                  ),
                ),
                if (totalUnread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalUnread new',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              'Order deliveries, riders & 24/7 dispatch support',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh conversations',
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : AppTheme.navyBrand,
            ),
            onPressed: () => _fetchConversations(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search TextField
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                      hintText: 'Search rider, order #, or messages...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Tabs (Messenger style)
                Row(
                  children: [
                    _buildFilterChip('all', 'All Chats', Icons.chat_bubble_outline_rounded, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('riders', 'Riders', Icons.two_wheeler_rounded, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('support', 'Dispatch & Support', Icons.headset_mic_outlined, isDark),
                  ],
                ),
              ],
            ),
          ),

          // Conversation List
          Expanded(
            child: _loading
                ? const Center(
                    child: ValleyLoader(
                      variant: 'beer',
                      text: 'Loading Messenger conversations...',
                    ),
                  )
                : _filteredConversations.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: () => _fetchConversations(),
                        color: AppTheme.primaryOrange,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredConversations.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 76,
                            endIndent: 16,
                            color: isDark ? AppTheme.darkBorderCard : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, idx) {
                            final conv = _filteredConversations[idx];
                            return _buildConversationTile(conv, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon, bool isDark) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primaryOrange : AppTheme.navyBrand)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.primaryOrange : AppTheme.navyBrand)
                : (isDark ? AppTheme.darkBorderCard : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(dynamic conv, bool isDark) {
    final type = conv['type']?.toString().toLowerCase() ?? 'support';
    final isRider = type == 'rider';
    final isCustomer = type == 'customer';
    final title = conv['title'] ?? (isRider ? 'Rider' : 'Support');
    final orderNo = conv['orderNo'];
    final lastMsg = conv['lastMessage'] ?? 'Tap to start conversation';
    final timeStr = _formatTimeAgo(conv['lastMessageTime']);
    final unread = (conv['unreadCount'] ?? 0) as num;
    final hasUnread = unread > 0;
    final orderStatus = conv['orderStatus']?.toString().toLowerCase() ?? '';

    Color avatarBg;
    IconData avatarIcon;
    if (isRider) {
      avatarBg = const Color(0xFFFF6B1A);
      avatarIcon = Icons.two_wheeler_rounded;
    } else if (isCustomer) {
      avatarBg = const Color(0xFF003893);
      avatarIcon = Icons.person_rounded;
    } else {
      avatarBg = const Color(0xFF0284C7);
      avatarIcon = Icons.headset_mic_rounded;
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              orderId: conv['orderId']?.toString(),
              orderNo: conv['orderNo']?.toString(),
              channel: conv['channel'] ?? ChatChannel.support,
              title: title,
            ),
          ),
        );
        // Refresh unread counts upon returning from conversation
        if (mounted) {
          _fetchConversations(silent: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: hasUnread
            ? (isDark ? AppTheme.primaryOrange.withOpacity(0.08) : const Color(0xFFFFF7ED))
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with Online / Order Badge
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: avatarBg.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(avatarIcon, color: Colors.white, size: 22),
                  ),
                ),
                // Green status indicator dot
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppTheme.darkBgApp : Colors.white,
                        width: 2.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Conversation Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (orderNo != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark ? AppTheme.darkBorderCard : const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Text(
                                  '#$orderNo',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF003893),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                          color: hasUnread
                              ? AppTheme.primaryOrange
                              : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Order Status Pill if available
                  if (orderStatus.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: orderStatus == 'delivered'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            orderStatus.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: orderStatus == 'delivered'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Snippet & Unread badge Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                            color: hasUnread
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: Color(0xFF003893),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No conversations matching "$_searchQuery"'
                  : 'No Messages Yet',
              style: AppTheme.displayFont(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.navyBrand,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching by a different name, order ID, or keyword.'
                  : 'Your order delivery threads with riders and operations support will appear here once an order is placed.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
