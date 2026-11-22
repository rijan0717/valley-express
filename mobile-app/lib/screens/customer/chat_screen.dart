import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/socket_service.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_snackbar.dart';
import '../../providers/chat_unread_provider.dart';
import '../../providers/auth_provider.dart';

/// The conversations an order can carry. Each is a separate thread: the
/// customer's line to operations, the customer's line to the rider carrying
/// the order, and the rider's line to dispatch.
class ChatChannel {
  static const support = 'support';
  static const delivery = 'delivery';
  static const fleet = 'fleet';
}

class ChatScreen extends StatefulWidget {
  final String? orderId;
  final String? orderNo;

  /// Which conversation to open. The server keeps these apart, so a customer
  /// never sees the rider's dispatch traffic and vice versa.
  final String channel;

  /// Shown in the app bar; defaults to the channel's usual counterpart.
  final String? title;

  const ChatScreen({
    super.key,
    this.orderId,
    this.orderNo,
    this.channel = ChatChannel.support,
    this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiClient _api = ApiClient();
  final SocketService _socket = SocketService();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _messages = [];
  bool _loading = true;

  String get _resolvedThreadId => widget.orderId ?? 'general';

  /// Who the caller is talking to when no explicit title is supplied.
  String get _defaultTitle {
    switch (widget.channel) {
      case ChatChannel.delivery:
        return 'Your Rider';
      case ChatChannel.fleet:
        return 'Dispatch Control';
      default:
        return 'Valley Dispatch Hub';
    }
  }

  String get _channelLabel {
    switch (widget.channel) {
      case ChatChannel.delivery:
        return 'Delivery Chat';
      case ChatChannel.fleet:
        return 'Fleet Line';
      default:
        return 'Live Order Support';
    }
  }

  @override
  void initState() {
    super.initState();
    _socket.connect();
    final auth = context.read<AuthProvider>();
    if (auth.user?.id != null) {
      _socket.joinUser(auth.user!.id);
    }
    if (widget.orderId != null) {
      _socket.joinOrder(widget.orderId!);
    }
    _fetchMessages();
    _markRead();

    _socket.socket?.on('chat:message', (data) {
      if (!mounted) return;
      final msgOrderId = data['order'] is Map ? data['order']['_id'] : data['order'];
      final msgCustomerId = data['customer'] is Map ? data['customer']['_id'] : data['customer'];

      final isOrderThread = widget.orderId != null;
      final bool belongsToThisThread = isOrderThread
          ? (msgOrderId == widget.orderId)
          : (msgOrderId == null && (auth.user?.id == null || msgCustomerId == auth.user!.id));

      if (belongsToThisThread) {
        final msgId = data['_id'];
        final exists = _messages.any((m) => m is Map && m['_id'] == msgId);
        if (!exists) {
          setState(() {
            _messages.add(data);
          });
          _scrollToBottom();
          _markRead();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markRead() async {
    try {
      await _api.dio.post('/chat/$_resolvedThreadId/read', data: {'channel': widget.channel});
      if (mounted) {
        context.read<ChatUnreadProvider>().refresh();
      }
    } catch (_) {}
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await _api.dio.get(
        '/chat/$_resolvedThreadId',
        queryParameters: {'channel': widget.channel},
      );
      if (mounted && res.data['success'] == true) {
        setState(() {
          _messages.clear();
          _messages.addAll(res.data['messages'] ?? []);
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      // senderRole is no longer sent: the API takes it from the session, so
      // a client cannot label its own messages as coming from operations.
      final res = await _api.dio.post('/chat/$_resolvedThreadId', data: {
        'text': text,
        'channel': widget.channel,
      });
      if (res.data['success'] == true) {
        final newMsg = res.data['message'];
        setState(() {
          final exists = _messages.any((m) => m is Map && m['_id'] == newMsg['_id']);
          if (!exists) {
            _messages.add(newMsg);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      _messageController.text = text;
      ValleySnack.error(context, friendlyApiError(e, 'Message not sent. Tap send to retry.'));
    }
  }

  String _formatMessageTimestamp(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatDateHeader(dynamic rawDate) {
    if (rawDate == null) return 'Today';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
        return 'Yesterday';
      }
      return DateFormat('EEE, d MMM').format(dt);
    } catch (_) {
      return 'Today';
    }
  }

  bool _isSameCalendarDay(dynamic a, dynamic b) {
    if (a == null || b == null) return false;
    try {
      final dtA = DateTime.parse(a.toString()).toLocal();
      final dtB = DateTime.parse(b.toString()).toLocal();
      return dtA.year == dtB.year && dtA.month == dtB.month && dtA.day == dtB.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
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
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.support_agent_rounded, color: AppTheme.primaryOrange, size: 22),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? _defaultTitle,
                  style: AppTheme.displayFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  widget.orderNo != null
                      ? 'Order: ${widget.orderNo} • $_channelLabel'
                      : '● Online • $_channelLabel',
                  style: AppTheme.bodyFont(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? const ValleyLoaderScreen(label: "Connecting to dispatch hub...")
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppTheme.primaryOrange),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Valley Dispatch Messenger',
                                  style: AppTheme.displayFont(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Connect directly with Central Operations or your assigned delivery rider.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodyFont(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, idx) {
                            final msg = _messages[idx];
                            final role = msg['senderRole'] ?? msg['sender']?['role'];
                            final isMe = role == 'customer';
                            final showDateHeader = idx == 0 ||
                                !_isSameCalendarDay(_messages[idx - 1]['createdAt'], msg['createdAt']);
                            final formattedTime = _formatMessageTimestamp(msg['createdAt']);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateHeader)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                                          ),
                                        ),
                                        child: Text(
                                          _formatDateHeader(msg['createdAt']),
                                          style: AppTheme.bodyFont(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.80,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppTheme.primaryOrange
                                          : (isDark ? AppTheme.darkSurfaceCard : Colors.white),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 16),
                                      ),
                                      border: isMe
                                          ? null
                                          : Border.all(
                                              color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                                            ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg['text'] ?? '',
                                          style: AppTheme.bodyFont(
                                            color: isMe
                                                ? Colors.white
                                                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              isMe ? 'You' : 'Dispatch',
                                              style: AppTheme.displayFont(
                                                color: isMe ? Colors.white70 : Colors.grey,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const Text(
                                              ' • ',
                                              style: TextStyle(color: Colors.grey, fontSize: 9),
                                            ),
                                            Text(
                                              formattedTime,
                                              style: AppTheme.bodyFont(
                                                color: isMe ? Colors.white70 : Colors.grey,
                                                fontSize: 9,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                msg['isRead'] == true
                                                    ? Icons.done_all_rounded
                                                    : Icons.done_rounded,
                                                size: 13,
                                                color: Colors.white70,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                // INPUT BAR (MATCHING PROTOTYPE SCREEN 6)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                              ),
                            ),
                            child: TextField(
                              controller: _messageController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              style: AppTheme.bodyFont(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Message dispatch or rider...',
                                hintStyle: AppTheme.bodyFont(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryOrange.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
