import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import '../domains/user/user_domain.dart';
import '../utils/utils.dart';

enum SocketConnectionType { client, driver }

enum SocketEventType {
  // Client events
  orderRejected,
  orderCancelledByClient,
  orderCancelledByDriver,
  orderStarted,
  driverArrived,
  rideStarted,
  rideEnded,
  orderAccepted,
  driverLocation,
  orderSync, // Синхронизация активного заказа
  driverInfo, // Информация о водителе
  
  // Driver events
  newOrder,
  orderTaken,
  orderCancelledByClientForDriver, // Для водителя - когда клиент отменил заказ
  orderDeleted,
  eventAck,
  clientInfo, // Информация о клиенте
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
  
  // Connection in progress flags to prevent duplicate connections
  bool _clientConnecting = false;
  bool _driverConnecting = false;
  
  // Reconnection timers
  Timer? _clientReconnectTimer;
  Timer? _driverReconnectTimer;
  
  // Heartbeat timers for connection health check
  Timer? _clientHeartbeatTimer;
  Timer? _driverHeartbeatTimer;
  
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
    required UserDomain user,
    Position? position,
  }) async {
    try {
      final sessionId = inject<SharedPreferences>().getString('access_token');
      
      if (sessionId == null || sessionId.isEmpty) {
        _logger.e('❌ Access token отсутствует, невозможно подключить сокет');
        return;
      }
      
      if (user.id.isEmpty) {
        _logger.e('❌ ID пользователя отсутствует');
        return;
      }
      
      // Проверяем, не подключен ли уже сокет этого типа или не происходит ли подключение
      switch (type) {
        case SocketConnectionType.client:
          if (_isClientConnected) {
            _logger.i('✅ Клиентский сокет уже подключен, пропускаем инициализацию');
            return;
          }
          if (_clientConnecting) {
            _logger.i('⏳ Клиентский сокет уже подключается, пропускаем дублирующий запрос');
            return;
          }
          await _initializeClientSocket(user, sessionId);
          break;
        case SocketConnectionType.driver:
          if (_isDriverConnected) {
            _logger.i('✅ Сокет водителя уже подключен, пропускаем инициализацию');
            return;
          }
          if (_driverConnecting) {
            _logger.i('⏳ Сокет водителя уже подключается, пропускаем дублирующий запрос');
            return;
          }
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
  Future<void> _initializeClientSocket(UserDomain user, String sessionId) async {
    _clientConnecting = true;
    _clientReconnectTimer?.cancel(); // Отменяем любые активные таймеры переподключения
    
    try {
      await _disconnectClientSocket();
      
      _logger.i('🚀 Инициализация клиентского сокета...');
      
      _clientSocket = IO.io(
        'https://taxi.aktau-go.kz',
        <String, dynamic>{
          'transports': ['websocket', 'polling'],
          'autoConnect': false,
          'forceNew': true,
          'timeout': 10000, // Уменьшаем таймаут до 10 секунд
          'reconnection': false, // Отключаем автоматическое переподключение socket.io
          'reconnectionAttempts': 0,
          'upgrade': true, // Разрешаем апгрейд с polling на websocket
          'rememberUpgrade': true, // Запоминаем предпочтение websocket
          'query': {
            'sessionId': sessionId,
            'userId': user.id,
            'userType': 'client',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        },
      );
      
      _setupClientEventHandlers();
      _clientSocket!.connect();
      
      _logger.i('🔌 Клиентский сокет создан и подключается...');
    } catch (e) {
      _logger.e('❌ Ошибка при создании клиентского сокета: $e');
      _clientConnecting = false;
    }
  }
  
  // Initialize driver socket
  Future<void> _initializeDriverSocket(UserDomain user, String sessionId, Position position) async {
    _driverConnecting = true;
    _driverReconnectTimer?.cancel(); // Отменяем любые активные таймеры переподключения
    
    try {
      await _disconnectDriverSocket();
      
      _logger.i('🚀 Инициализация сокета водителя...');
      
      _driverSocket = IO.io(
        'https://taxi.aktau-go.kz',
        <String, dynamic>{
          'transports': ['websocket', 'polling'],
          'autoConnect': false,
          'forceNew': true,
          'timeout': 10000, // Уменьшаем таймаут до 10 секунд
          'reconnection': false, // Отключаем автоматическое переподключение socket.io
          'reconnectionAttempts': 0,
          'upgrade': true, // Разрешаем апгрейд с polling на websocket
          'rememberUpgrade': true, // Запоминаем предпочтение websocket
          'query': {
            'sessionId': sessionId,
            'driverId': user.id,
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
    } catch (e) {
      _logger.e('❌ Ошибка при создании сокета водителя: $e');
      _driverConnecting = false;
    }
  }
  
  // Setup client event handlers
  void _setupClientEventHandlers() {
    if (_clientSocket == null) return;
    
    _clientSocket!.clearListeners();
    
    // Connection events
    _clientSocket!.onConnect((_) {
      _logger.i('✅ Клиентский сокет подключен');
      _isClientConnected = true;
      _clientConnecting = false;
      _clientReconnectTimer?.cancel();
      _startClientHeartbeat();
      _notifyClientConnectionCallbacks(true);
    });
    
    _clientSocket!.onDisconnect((reason) {
      _logger.w('🔌 Клиентский сокет отключен: $reason');
      _isClientConnected = false;
      _clientConnecting = false;
      _stopClientHeartbeat();
      _notifyClientConnectionCallbacks(false);
      
      // Контролируемое переподключение только для неожиданных отключений
      if (reason != 'io client disconnect' && reason != 'transport close' && reason != 'client namespace disconnect') {
        _logger.i('🔄 Планируется переподключение клиентского сокета через 3 секунды...');
        _clientReconnectTimer?.cancel();
        _clientReconnectTimer = Timer(Duration(seconds: 3), () {
          if (!_isClientConnected && !_clientConnecting) {
            _logger.i('🔄 Выполняется переподключение клиентского сокета...');
            // Полностью пересоздаем сокет для надежности
            _clientSocket?.dispose();
            _clientSocket = null;
            // Переподключение будет выполнено через полную переинициализацию
            _logger.i('🔄 Требуется полная переинициализация клиентского сокета');
          }
        });
      }
    });
    
    _clientSocket!.onConnectError((error) {
      _logger.e('❌ Ошибка подключения клиентского сокета: $error');
      _isClientConnected = false;
      _clientConnecting = false;
      _notifyClientConnectionCallbacks(false);
    });
    
    // Client-specific events
    _clientSocket!.on('orderRejected', (data) {
      _logger.i('📦 Client: orderRejected');
      _notifyEventCallbacks(SocketEventType.orderRejected, data);
    });
    
    _clientSocket!.on('orderCancelledByClient', (data) {
      _logger.i('📦 Client: orderCancelledByClient');
      _notifyEventCallbacks(SocketEventType.orderCancelledByClient, data);
    });
    
    _clientSocket!.on('orderCancelledByDriver', (data) {
      _logger.i('📦 Client: orderCancelledByDriver');
      _notifyEventCallbacks(SocketEventType.orderCancelledByDriver, data);
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
    
    _clientSocket!.on('pong', (data) {
      _logger.d('💓 Client: pong received');
    });
    
    _clientSocket!.on('orderSync', (data) {
      _logger.i('📦 Client: orderSync');
      _notifyEventCallbacks(SocketEventType.orderSync, data);
    });
    
    _clientSocket!.on('driverInfo', (data) {
      _logger.i('📦 Client: driverInfo');
      _notifyEventCallbacks(SocketEventType.driverInfo, data);
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
      _driverConnecting = false;
      _driverReconnectTimer?.cancel();
      _startDriverHeartbeat();
      _notifyDriverConnectionCallbacks(true);
    });
    
    _driverSocket!.onDisconnect((reason) {
      _logger.w('🔌 Сокет водителя отключен: $reason');
      _isDriverConnected = false;
      _driverConnecting = false;
      _stopDriverHeartbeat();
      _notifyDriverConnectionCallbacks(false);
      
      // Контролируемое переподключение для водителей только при неожиданных отключениях
      if (reason != 'io client disconnect' && reason != 'transport close' && reason != 'client namespace disconnect') {
        _logger.i('🔄 Планируется переподключение сокета водителя через 5 секунд...');
        _driverReconnectTimer?.cancel();
        _driverReconnectTimer = Timer(Duration(seconds: 5), () {
          if (!_isDriverConnected && !_driverConnecting) {
            _logger.i('🔄 Выполняется переподключение сокета водителя...');
            // Полностью пересоздаем сокет для надежности
            _driverSocket?.dispose();
            _driverSocket = null;
            // Переподключение будет выполнено через полную переинициализацию
            _logger.i('🔄 Требуется полная переинициализация сокета водителя');
          }
        });
      }
    });
    
    _driverSocket!.onConnectError((error) {
      _logger.e('❌ Ошибка подключения сокета водителя: $error');
      _isDriverConnected = false;
      _driverConnecting = false;
      _notifyDriverConnectionCallbacks(false);
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
    
    
    _driverSocket!.on('orderCancelledByClient', (data) {
      _logger.i('📦 Driver: orderCancelledByClient');
      _notifyEventCallbacks(SocketEventType.orderCancelledByClientForDriver, data);
    });
    
    _driverSocket!.on('orderDeleted', (data) {
      _logger.i('📦 Driver: orderDeleted');
      _notifyEventCallbacks(SocketEventType.orderDeleted, data);
    });
    
    _driverSocket!.on('eventAck', (data) {
      _logger.i('📦 Driver: eventAck');
      _notifyEventCallbacks(SocketEventType.eventAck, data);
    });
    
    _driverSocket!.on('pong', (data) {
      _logger.d('💓 Driver: pong received');
    });
    
    _driverSocket!.on('orderSync', (data) {
      _logger.i('📦 Driver: orderSync');
      _notifyEventCallbacks(SocketEventType.orderSync, data);
    });
    
    _driverSocket!.on('clientInfo', (data) {
      _logger.i('📦 Driver: clientInfo');
      _notifyEventCallbacks(SocketEventType.clientInfo, data);
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
    _clientReconnectTimer?.cancel();
    _clientReconnectTimer = null;
    _clientConnecting = false;
    
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
    _driverReconnectTimer?.cancel();
    _driverReconnectTimer = null;
    _driverConnecting = false;
    
    if (_driverSocket != null) {
      _logger.i('🔌 Отключение сокета водителя');
      
      // Больше не нужно отправлять driverOffline - backend автоматически убирает из онлайн при отключении
      
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
    // Проверяем, что есть активные обработчики для этого события
    final callbacks = _eventCallbacks[eventType];
    if (callbacks == null || callbacks.isEmpty) {
      _logger.w('⚠️ Нет активных обработчиков для события $eventType');
      print('⚠️ WebSocket: Нет активных обработчиков для события $eventType');
      return;
    }
    
    _logger.i('📡 Уведомляем ${callbacks.length} обработчиков о событии $eventType');
    print('📡 WebSocket: Уведомляем ${callbacks.length} обработчиков о событии $eventType');
    print('📡 WebSocket: Данные события: $data');
    
    callbacks.forEach((callback) {
      try {
        print('🔄 WebSocket: Выполняем callback для $eventType');
        callback(data);
        print('✅ WebSocket: Callback для $eventType выполнен успешно');
      } catch (e) {
        _logger.e('❌ Ошибка в callback для события $eventType: $e');
        print('❌ WebSocket: Ошибка в callback для события $eventType: $e');
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
  
  // Heartbeat methods
  void _startClientHeartbeat() {
    _stopClientHeartbeat();
    _clientHeartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isClientConnected && _clientSocket != null) {
        _clientSocket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
        _logger.d('💓 Client heartbeat sent');
      } else {
        _stopClientHeartbeat();
      }
    });
  }
  
  void _stopClientHeartbeat() {
    _clientHeartbeatTimer?.cancel();
    _clientHeartbeatTimer = null;
  }
  
  void _startDriverHeartbeat() {
    _stopDriverHeartbeat();
    _driverHeartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isDriverConnected && _driverSocket != null) {
        _driverSocket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
        _logger.d('💓 Driver heartbeat sent');
      } else {
        _stopDriverHeartbeat();
      }
    });
  }
  
  void _stopDriverHeartbeat() {
    _driverHeartbeatTimer?.cancel();
    _driverHeartbeatTimer = null;
  }

  // Cleanup
  void dispose() {
    _clientReconnectTimer?.cancel();
    _driverReconnectTimer?.cancel();
    _stopClientHeartbeat();
    _stopDriverHeartbeat();
    disconnectAll();
    _eventCallbacks.clear();
    _clientConnectionCallbacks.clear();
    _driverConnectionCallbacks.clear();
  }
} 