import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/socket_service.dart';

/// Tracks how many messages the store admin has sent that the customer has not
/// opened yet. Backed by `GET /api/chat/unread`; cleared per thread by
/// `POST /api/chat/<threadId>/read`.
class ChatUnreadProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final SocketService _socket = SocketService();

  int _total = 0;
  Map<String, int> _threads = {};
  bool _listening = false;
  String? _lastMessageNotice;

  int get total => _total;
  bool get hasUnread => _total > 0;
  Map<String, int> get threads => _threads;
  String? get lastMessageNotice => _lastMessageNotice;

  int countForThread(String? threadId) =>
      threadId == null ? 0 : (_threads[threadId] ?? 0);

  void clearNotice() {
    _lastMessageNotice = null;
    notifyListeners();
  }

  /// Starts listening for live message events. Safe to call more than once.
  void start([String? userId]) {
    refresh();
    if (userId != null) {
      _socket.joinUser(userId);
    }
    if (_listening) return;
    _socket.connect();
    if (userId != null) {
      _socket.joinUser(userId);
    }
    _socket.socket?.on('chat:message', (data) {
      refresh();
      if (data is Map) {
        final text = (data['text'] ?? '').toString();
        final senderRole = (data['senderRole'] ?? '').toString();
        if (senderRole != 'customer' && text.isNotEmpty) {
          final senderName = data['sender'] is Map ? (data['sender']['name'] ?? 'Support Admin') : 'Support Admin';
          _lastMessageNotice = '$senderName: $text';
          notifyListeners();
        }
      }
    });
    _socket.socket?.on('chat:read', (_) => refresh());
    _listening = true;
  }

  Future<void> refresh() async {
    try {
      final res = await _api.dio.get('/chat/unread');
      if (res.data['success'] == true) {
        _total = res.data['total'] ?? 0;
        _threads = Map<String, int>.from(
          (res.data['threads'] ?? {}).map(
            (key, value) => MapEntry(key.toString(), value as int),
          ),
        );
        notifyListeners();
      }
    } catch (_) {
      // The badge is non-critical; keep the last known count on failure
    }
  }

  Future<void> markThreadRead(String threadId) async {
    try {
      await _api.dio.post('/chat/$threadId/read');
    } catch (_) {
      // Ignore; the refresh below keeps the badge honest either way
    }
    await refresh();
  }
}
