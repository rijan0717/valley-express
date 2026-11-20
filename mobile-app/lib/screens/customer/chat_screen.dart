import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/socket_service.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../providers/chat_unread_provider.dart';

class ChatScreen extends StatefulWidget {
  final String? orderId;
  final String? orderNo;

  const ChatScreen({super.key, this.orderId, this.orderNo});

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

  @override
  void initState() {
    super.initState();
    _socket.connect();
    if (widget.orderId != null) {
      _socket.joinOrder(widget.orderId!);
    }
    _fetchMessages();
    _markRead();

    _socket.socket?.on('chat:message', (data) {
      if (!mounted) return;
      final msgOrderId = data['order'] is Map ? data['order']['_id'] : data['order'];
      if (widget.orderId == null || msgOrderId == widget.orderId) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
        // The thread is on screen, so it counts as read straight away
        if (data['senderRole'] == 'admin') _markRead();
      }
    });
  }

  void _markRead() {
    if (!mounted) return;
    context.read<ChatUnreadProvider>().markThreadRead(_resolvedThreadId);
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
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await _api.dio.get('/chat/$_resolvedThreadId');
      if (mounted) {
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
      final res = await _api.dio.post('/chat/$_resolvedThreadId', data: {
        'text': text,
        'senderRole': 'customer',
      });
      if (res.data['success'] == true) {
        setState(() {
          _messages.add(res.data['message']);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
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
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECE0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.support_agent_rounded, color: AppTheme.accent, size: 22),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operations & Dispatch',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                ),
                Text(
                  widget.orderNo != null ? 'Order: ${widget.orderNo} • Live' : 'Store Admin • Online',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? const ValleyLoaderScreen(label: "Opening your chat...")
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
                                  decoration: const BoxDecoration(
                                    color: AppTheme.inputBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppTheme.accent),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Direct Support Messenger',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textMain),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ask questions about stock, delivery times, or special requests directly to store admins.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, idx) {
                            final msg = _messages[idx];
                            final role = msg['senderRole'] ?? msg['sender']?['role'];
                            final isMe = role == 'customer';

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? AppTheme.accent : AppTheme.background,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  border: isMe ? null : Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? AppTheme.background : AppTheme.textMain,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMe ? 'You' : 'Store Admin / Operations',
                                      style: TextStyle(
                                        color: isMe ? const Color(0xFFFFECE0) : AppTheme.textSubtle,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Modern Input Bar (matching Figma reference)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.inputBg,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Message store admin...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: AppTheme.background, size: 20),
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
