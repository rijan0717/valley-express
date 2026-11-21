import 'package:socket_io_client/socket_io_client.dart' as io;
import 'constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  bool isConnected = false;
  String? currentUserId;
  final Set<String> _joinedOrders = {};

  void connect() {
    if (socket != null && socket!.connected) {
      if (currentUserId != null) {
        socket?.emit('join:user', currentUserId);
      }
      return;
    }

    socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket!.onConnect((_) {
      isConnected = true;
      if (currentUserId != null) {
        socket?.emit('join:user', currentUserId);
      }
      for (final orderId in _joinedOrders) {
        socket?.emit('join:order', orderId);
      }
    });

    socket!.onDisconnect((_) {
      isConnected = false;
    });
  }

  void joinUser(String userId) {
    currentUserId = userId;
    socket?.emit('join:user', userId);
  }

  void joinOrder(String orderId) {
    _joinedOrders.add(orderId);
    socket?.emit('join:order', orderId);
  }

  void joinRider(String riderId) {
    socket?.emit('join:rider', riderId);
  }

  void disconnect() {
    socket?.disconnect();
    isConnected = false;
    _joinedOrders.clear();
  }
}
