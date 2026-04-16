import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';
import 'package:classifieds/services/AuthService.dart';
import 'package:classifieds/utils/AppLogger.dart';

class SocketService {
  static WebSocketChannel? _channel;
  static final _listeners = <String, List<Function(dynamic)>>{};
  static bool _connected = false;
  static String? _currentUserId;
  static Timer? _reconnectTimer;
  static Timer? _heartbeatTimer;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  /// Stream controller for WebSocket errors from the backend (rate limit, validation, etc.)
  static final _errorController = StreamController<String>.broadcast();
  static Stream<String> get onError => _errorController.stream;

  /// Connect to AWS API Gateway WebSocket with JWT token
  static Future<void> connect(String userId) async {
    if (_connected && _currentUserId == userId) return;

    _currentUserId = userId;
    final token = await AuthService.getAccessToken();
    if (token == null || token.isEmpty) {
      AppLogger.error('WebSocket: No access token available');
      return;
    }

    final url = '${APIEndpointUrls.chatWebSocketUrl}?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _connected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();

      AppLogger.info('WebSocket connected as $userId');

      // Listen for incoming messages
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            final action = json['action'] as String?;
            if (action != null && _listeners.containsKey(action)) {
              for (final cb in _listeners[action]!) {
                cb(json['data'] ?? json);
              }
            }
          } catch (e) {
            AppLogger.error('WebSocket parse error: $e');
          }
        },
        onDone: () {
          AppLogger.info('WebSocket disconnected');
          _connected = false;
          _heartbeatTimer?.cancel();
          _scheduleReconnect();
        },
        onError: (err) {
          AppLogger.error('WebSocket error: $err');
          _connected = false;
          _heartbeatTimer?.cancel();
          _scheduleReconnect();
        },
      );

      // Register built-in error listener for backend error actions
      _listeners.remove('error'); // Clear stale listeners
      on('error', (data) {
        final message = data is Map ? (data['message'] ?? 'Unknown error') : data.toString();
        AppLogger.error('WebSocket server error: $message');
        _errorController.add(message.toString());
      });

      // Heartbeat every 5 minutes to keep connection alive
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        send('ping', {});
      });
    } catch (e) {
      AppLogger.error('WebSocket connect failed: $e');
      _connected = false;
      _scheduleReconnect();
    }
  }

  /// Send a message with an action
  static void send(String action, Map<String, dynamic> data) {
    if (_channel == null || !_connected) return;
    try {
      _channel!.sink.add(jsonEncode({'action': action, ...data}));
    } catch (e) {
      AppLogger.error('WebSocket send error: $e');
    }
  }

  /// Register a listener for a specific action
  static void on(String action, Function(dynamic) callback) {
    _listeners.putIfAbsent(action, () => []);
    _listeners[action]!.add(callback);
  }

  /// Remove a specific listener for an action, or all listeners if no callback given
  static void off(String action, [Function(dynamic)? callback]) {
    if (callback != null) {
      _listeners[action]?.remove(callback);
      if (_listeners[action]?.isEmpty == true) _listeners.remove(action);
    } else {
      _listeners.remove(action);
    }
  }

  /// Alias for backward compatibility (old Socket.IO code used emit)
  static void emit(String action, dynamic data) {
    if (data is Map<String, dynamic>) {
      send(action, data);
    }
  }

  /// Disconnect and clean up
  static void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _currentUserId = null;
    _reconnectAttempts = 0;
    _listeners.clear();
    AppLogger.info('WebSocket disconnected manually');
  }

  static bool get isConnected => _connected;

  /// Auto-reconnect with exponential backoff + jitter
  static void _scheduleReconnect() {
    if (_currentUserId == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.error('WebSocket: max reconnect attempts ($_maxReconnectAttempts) reached');
      return;
    }
    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s capped at 30s + random jitter
    final baseDelay = Duration(seconds: 1 << _reconnectAttempts.clamp(0, 5));
    final jitter = Duration(milliseconds: (DateTime.now().millisecondsSinceEpoch % 1000));
    final delay = baseDelay + jitter;
    final cappedDelay = delay > const Duration(seconds: 30) ? const Duration(seconds: 30) : delay;

    _reconnectAttempts++;
    _reconnectTimer = Timer(cappedDelay, () {
      if (!_connected && _currentUserId != null) {
        AppLogger.info('WebSocket reconnecting (attempt $_reconnectAttempts/$_maxReconnectAttempts)...');
        connect(_currentUserId!);
      }
    });
  }
}
