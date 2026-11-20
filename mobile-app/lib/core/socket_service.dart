import 'package:socket_io_client/socket_io_client.dart' as io;
import 'constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  bool isConnected = false;

  void connect() {
    if (socket != null && socket!.connected) return;

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
    });

    socket!.onDisconnect((_) {
      isConnected = false;
    });
  }

  void joinOrder(String orderId) {
    socket?.emit('join:order', orderId);
  }

  void joinRider(String riderId) {
    socket?.emit('join:rider', riderId);
  }

  void disconnect() {
    socket?.disconnect();
    isConnected = false;
  }
}
