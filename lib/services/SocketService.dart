import 'package:classifieds/services/api_endpoint_urls.dart';
import 'package:classifieds/utils/AppLogger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket connect(String userId) {
    if (_socket == null) {
      _socket = IO.io(APIEndpointUrls.socket_url, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'query': {
          'userId': userId, // 👈 passed here
        },
      });

      _socket!.connect();

      _socket!
        ..onConnect((_) => AppLogger.info('Socket connected as $userId'))
        ..onDisconnect((_) => AppLogger.info('Socket disconnected'))
        ..onError((err) => AppLogger.info('Socket error: $err'));
    }
    return _socket!;
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  static void off(String event) {
    _socket?.off(event);
  }

}
