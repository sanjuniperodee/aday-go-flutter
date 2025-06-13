import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import '../models/user/user_model.dart';
import '../utils/utils.dart';

enum SocketConnectionType { client, driver }

enum SocketEventType {
  // Client events
  orderRejected,
  orderStarted,
  driverArrived,
  rideStarted,
  rideEnded,
  orderAccepted,
  driverLocation,
  
  // Driver events
  newOrder,
  orderTaken,
  orderAcceptedByMe,
  orderUpdated,
  orderCancelled,
  orderDeleted,
  eventAck,
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final Logger _logger = Logger();
  
  // Separate sockets for different user types
  IO.Socket? _clientSocket;
  IO.Socket? _driverSocket;
  
  // Connection states
  bool _isClientConnected = false;
  bool _isDriverConnected = false;
  
  // Event callbacks
  final Map<SocketEventType, List<Function(dynamic)>> _eventCallbacks = {};
  
  // Connection state callbacks
  final List<Function(bool)> _clientConnectionCallbacks = [];
  final List<Function(bool)> _driverConnectionCallbacks = [];
  
  // Singleton getters
  bool get isClientConnected => _isClientConnected;
  bool get isDriverConnected => _isDriverConnected;
  
  // Initialize socket connection based on user role
  Future<void> initializeConnection({
    required SocketConnectionType type,
    required UserModel user,
    Position? position,
  }) async {
    try {
      final sessionId = inject<SharedPreferences>().getString('sessionId');
      
      if (sessionId == null || sessionId.isEmpty) {
        _logger.e('❌ SessionId отсутствует, невозможно подключить сокет');
        return;
      }
      
      if (user.id == null) {
        _logger.e('❌ ID пользователя отсутствует');
        return;
      }
      
      switch (type) {
        case SocketConnectionType.client:
          await _initializeClientSocket(user, sessionId);
          break;
        case SocketConnectionType.driver:
          if (position == null) {
            _logger.e('❌ Позиция обязательна для водителя');
            return;
          }
          await _initializeDriverSocket(user, sessionId, position);
          break;
      }
    } catch (e) {
      _logger.e('❌ Ошибка при инициализации WebSocket: $e');
    }
  }
  
  // Initialize client socket
  Future<void> _initializeClientSocket(UserModel user, String sessionId) async {
    await _disconnectClientSocket();
    
    _logger.i('🚀 Инициализация клиентского сокета...');
    
    _clientSocket = IO.io(
      'https://taxi.aktau-go.kz',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
        'timeout': 30000,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 3000,
        'query': {
          'sessionId': sessionId,
          'userId': user.id.toString(),
          'userType': 'client',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      },
    );
    
    _setupClientEventHandlers();
    _clientSocket!.connect();
    
    _logger.i('🔌 Клиентский сокет создан и подключается...');
  }
  
  // Initialize driver socket
  Future<void> _initializeDriverSocket(UserModel user, String sessionId, Position position) async {
    await _disconnectDriverSocket();
    
    _logger.i('🚀 Инициализация сокета водителя...');
    
    _driverSocket = IO.io(
      'https://taxi.aktau-go.kz',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
        'timeout': 30000,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 3000,
        'query': {
          'sessionId': sessionId,
          'driverId': user.id.toString(),
          'userType': 'driver',
          'lat': position.latitude.toString(),
          'lng': position.longitude.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      },
    );
    
    _setupDriverEventHandlers();
    _driverSocket!.connect();
    
    _logger.i('🔌 Сокет водителя создан и подключается...');
  }
  
  // Setup client event handlers
  void _setupClientEventHandlers() {
    if (_clientSocket == null) return;
    
    _clientSocket!.clearListeners();
    
    // Connection events
    _clientSocket!.onConnect((_) {
      _logger.i('✅ Клиентский сокет подключен');
      _isClientConnected = true;
      _notifyClientConnectionCallbacks(true);
    });
    
    _clientSocket!.onDisconnect((reason) {
      _logger.w('🔌 Клиентский сокет отключен: $reason');
      _isClientConnected = false;
      _notifyClientConnectionCallbacks(false);
      
      // Auto-reconnect for clients
      if (reason != 'io client disconnect') {
        _logger.i('🔄 Автоматическое переподключение клиентского сокета...');
        Future.delayed(Duration(seconds: 3), () {
          if (!_isClientConnected) {
            _clientSocket?.connect();
          }
        });
      }
    });
    
    _clientSocket!.onConnectError((error) {
      _logger.e('❌ Ошибка подключения клиентского сокета: $error');
      _isClientConnected = false;
      _notifyClientConnectionCallbacks(false);
    });
    
    // Client-specific events
    _clientSocket!.on('orderRejected', (data) {
      _logger.i('📦 Client: orderRejected');
      _notifyEventCallbacks(SocketEventType.orderRejected, data);
    });
    
    _clientSocket!.on('orderStarted', (data) {
      _logger.i('📦 Client: orderStarted');
      _notifyEventCallbacks(SocketEventType.orderStarted, data);
    });
    
    _clientSocket!.on('driverArrived', (data) {
      _logger.i('📦 Client: driverArrived');
      _notifyEventCallbacks(SocketEventType.driverArrived, data);
    });
    
    _clientSocket!.on('rideStarted', (data) {
      _logger.i('📦 Client: rideStarted');
      _notifyEventCallbacks(SocketEventType.rideStarted, data);
    });
    
    _clientSocket!.on('rideEnded', (data) {
      _logger.i('📦 Client: rideEnded');
      _notifyEventCallbacks(SocketEventType.rideEnded, data);
    });
    
    _clientSocket!.on('orderAccepted', (data) {
      _logger.i('📦 Client: orderAccepted');
      _notifyEventCallbacks(SocketEventType.orderAccepted, data);
    });
    
    _clientSocket!.on('driverLocation', (data) {
      _logger.i('📦 Client: driverLocation');
      _notifyEventCallbacks(SocketEventType.driverLocation, data);
    });
  }
  
  // Setup driver event handlers
  void _setupDriverEventHandlers() {
    if (_driverSocket == null) return;
    
    _driverSocket!.clearListeners();
    
    // Connection events
    _driverSocket!.onConnect((_) {
      _logger.i('✅ Сокет водителя подключен');
      _isDriverConnected = true;
      _notifyDriverConnectionCallbacks(true);
      
      // Send driver online status
      _driverSocket!.emit('driverOnline', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
    
    _driverSocket!.onDisconnect((reason) {
      _logger.w('🔌 Сокет водителя отключен: $reason');
      _isDriverConnected = false;
      _notifyDriverConnectionCallbacks(false);
      
      // Don't auto-reconnect drivers - they need to manually go online
    });
    
    _driverSocket!.onConnectError((error) {
      _logger.e('❌ Ошибка подключения сокета водителя: $error');
      _isDriverConnected = false;
      _notifyDriverConnectionCallbacks(false);
    });
    
    _driverSocket!.onReconnect((attempt) {
      _logger.i('🔄 Сокет водителя переподключился (попытка $attempt)');
      _isDriverConnected = true;
      _notifyDriverConnectionCallbacks(true);
    });
    
    // Driver-specific events
    _driverSocket!.on('newOrder', (data) {
      _logger.i('📦 Driver: newOrder');
      _notifyEventCallbacks(SocketEventType.newOrder, data);
    });
    
    _driverSocket!.on('orderTaken', (data) {
      _logger.i('📦 Driver: orderTaken');
      _notifyEventCallbacks(SocketEventType.orderTaken, data);
    });
    
    _driverSocket!.on('orderAcceptedByMe', (data) {
      _logger.i('📦 Driver: orderAcceptedByMe');
      _notifyEventCallbacks(SocketEventType.orderAcceptedByMe, data);
    });
    
    _driverSocket!.on('orderUpdated', (data) {
      _logger.i('📦 Driver: orderUpdated');
      _notifyEventCallbacks(SocketEventType.orderUpdated, data);
    });
    
    _driverSocket!.on('orderCancelled', (data) {
      _logger.i('📦 Driver: orderCancelled');
      _notifyEventCallbacks(SocketEventType.orderCancelled, data);
    });
    
    _driverSocket!.on('orderDeleted', (data) {
      _logger.i('📦 Driver: orderDeleted');
      _notifyEventCallbacks(SocketEventType.orderDeleted, data);
    });
    
    _driverSocket!.on('eventAck', (data) {
      _logger.i('📦 Driver: eventAck');
      _notifyEventCallbacks(SocketEventType.eventAck, data);
    });
  }
  
  // Event subscription
  void addEventListener(SocketEventType eventType, Function(dynamic) callback) {
    if (!_eventCallbacks.containsKey(eventType)) {
      _eventCallbacks[eventType] = [];
    }
    _eventCallbacks[eventType]!.add(callback);
  }
  
  void removeEventListener(SocketEventType eventType, Function(dynamic) callback) {
    _eventCallbacks[eventType]?.remove(callback);
  }
  
  void clearEventListeners(SocketEventType eventType) {
    _eventCallbacks[eventType]?.clear();
  }
  
  // Connection state subscription
  void addClientConnectionListener(Function(bool) callback) {
    _clientConnectionCallbacks.add(callback);
  }
  
  void addDriverConnectionListener(Function(bool) callback) {
    _driverConnectionCallbacks.add(callback);
  }
  
  void removeClientConnectionListener(Function(bool) callback) {
    _clientConnectionCallbacks.remove(callback);
  }
  
  void removeDriverConnectionListener(Function(bool) callback) {
    _driverConnectionCallbacks.remove(callback);
  }
  
  // Emit events
  void emitDriverEvent(String event, Map<String, dynamic> data) {
    if (_driverSocket?.connected == true) {
      _driverSocket!.emit(event, data);
      _logger.i('📤 Driver emit: $event');
    } else {
      _logger.w('⚠️ Попытка отправить событие водителя без подключения: $event');
    }
  }
  
  void emitClientEvent(String event, Map<String, dynamic> data) {
    if (_clientSocket?.connected == true) {
      _clientSocket!.emit(event, data);
      _logger.i('📤 Client emit: $event');
    } else {
      _logger.w('⚠️ Попытка отправить событие клиента без подключения: $event');
    }
  }
  
  // Update driver location
  void updateDriverLocation(Position position) {
    emitDriverEvent('driverLocationUpdate', {
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  // Driver status management
  void setDriverOnline() {
    emitDriverEvent('driverOnline', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  void setDriverOffline() {
    emitDriverEvent('driverOffline', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  // Disconnect methods
  Future<void> _disconnectClientSocket() async {
    if (_clientSocket != null) {
      _logger.i('🔌 Отключение клиентского сокета');
      _clientSocket!.clearListeners();
      _clientSocket!.disconnect();
      _clientSocket!.dispose();
      _clientSocket = null;
      _isClientConnected = false;
    }
  }
  
  Future<void> _disconnectDriverSocket() async {
    if (_driverSocket != null) {
      _logger.i('🔌 Отключение сокета водителя');
      
      // Send offline status before disconnecting
      if (_driverSocket!.connected) {
        setDriverOffline();
        await Future.delayed(Duration(milliseconds: 500)); // Give time for the event to be sent
      }
      
      _driverSocket!.clearListeners();
      _driverSocket!.disconnect();
      _driverSocket!.dispose();
      _driverSocket = null;
      _isDriverConnected = false;
    }
  }
  
  // Public disconnect methods
  Future<void> disconnectClient() async {
    await _disconnectClientSocket();
    _notifyClientConnectionCallbacks(false);
  }
  
  Future<void> disconnectDriver() async {
    await _disconnectDriverSocket();
    _notifyDriverConnectionCallbacks(false);
  }
  
  Future<void> disconnectAll() async {
    await _disconnectClientSocket();
    await _disconnectDriverSocket();
    _notifyClientConnectionCallbacks(false);
    _notifyDriverConnectionCallbacks(false);
  }
  
  // Notification helpers
  void _notifyEventCallbacks(SocketEventType eventType, dynamic data) {
    _eventCallbacks[eventType]?.forEach((callback) {
      try {
        callback(data);
      } catch (e) {
        _logger.e('❌ Ошибка в callback для события $eventType: $e');
      }
    });
  }
  
  void _notifyClientConnectionCallbacks(bool isConnected) {
    _clientConnectionCallbacks.forEach((callback) {
      try {
        callback(isConnected);
      } catch (e) {
        _logger.e('❌ Ошибка в callback подключения клиента: $e');
      }
    });
  }
  
  void _notifyDriverConnectionCallbacks(bool isConnected) {
    _driverConnectionCallbacks.forEach((callback) {
      try {
        callback(isConnected);
      } catch (e) {
        _logger.e('❌ Ошибка в callback подключения водителя: $e');
      }
    });
  }
  
  // Cleanup
  void dispose() {
    disconnectAll();
    _eventCallbacks.clear();
    _clientConnectionCallbacks.clear();
    _driverConnectionCallbacks.clear();
  }
} 