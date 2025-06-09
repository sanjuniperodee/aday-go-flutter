# WebSocket Architecture для Taxi Service

## Обзор

Данная архитектура разделяет WebSocket подключения для клиентов и водителей, обеспечивая правильную маршрутизацию событий и уведомлений.

## Архитектура клиента (Flutter)

### WebSocketService

Централизованный сервис для управления WebSocket подключениями:

```dart
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
  orderUpdated,
  orderCancelled,
  orderDeleted,
  eventAck,
}
```

### Разделение подключений

1. **Клиентское подключение** (`SocketConnectionType.client`):
   - Параметры подключения: `userId`, `userType: 'client'`, `sessionId`
   - События: получение обновлений о статусе заказа, позиции водителя
   - Автоматическое переподключение при разрыве соединения

2. **Подключение водителя** (`SocketConnectionType.driver`):
   - Параметры подключения: `driverId`, `userType: 'driver'`, `sessionId`, `lat`, `lng`
   - События: получение новых заказов, обновлений заказов
   - Ручное управление подключением (онлайн/оффлайн)

## Архитектура сервера (Рекомендации)

### Структура подключений

```javascript
// Хранение подключений по типам
const clientConnections = new Map(); // userId -> socket
const driverConnections = new Map(); // driverId -> socket

// При подключении
io.on('connection', (socket) => {
  const { userType, userId, driverId, sessionId } = socket.handshake.query;
  
  if (userType === 'client') {
    clientConnections.set(userId, socket);
    socket.join(`client_${userId}`);
  } else if (userType === 'driver') {
    driverConnections.set(driverId, socket);
    socket.join(`driver_${driverId}`);
    socket.join('all_drivers'); // Для рассылки новых заказов
  }
});
```

### События для клиентов

```javascript
// Отправка событий конкретному клиенту
function notifyClient(userId, event, data) {
  io.to(`client_${userId}`).emit(event, data);
}

// События клиента:
// - orderRejected: заказ отклонен водителем
// - orderStarted: водитель начал движение к клиенту
// - driverArrived: водитель прибыл
// - rideStarted: поездка началась
// - rideEnded: поездка завершена
// - orderAccepted: заказ принят водителем
// - driverLocation: обновление позиции водителя
```

### События для водителей

```javascript
// Отправка новых заказов всем онлайн водителям
function broadcastNewOrder(orderData) {
  io.to('all_drivers').emit('newOrder', orderData);
}

// Отправка событий конкретному водителю
function notifyDriver(driverId, event, data) {
  io.to(`driver_${driverId}`).emit(event, data);
}

// События водителя:
// - newOrder: новый заказ доступен
// - orderTaken: заказ принят другим водителем
// - orderUpdated: заказ обновлен
// - orderCancelled: заказ отменен клиентом
// - orderDeleted: заказ удален
// - eventAck: подтверждение получения события
```

### Управление состоянием водителей

```javascript
// Отслеживание онлайн водителей
const onlineDrivers = new Set();

socket.on('driverOnline', (data) => {
  onlineDrivers.add(socket.driverId);
  socket.join('online_drivers');
});

socket.on('driverOffline', (data) => {
  onlineDrivers.delete(socket.driverId);
  socket.leave('online_drivers');
});

socket.on('driverLocationUpdate', (data) => {
  // Обновление позиции водителя в базе данных
  // Отправка позиции клиенту если есть активный заказ
  const activeOrder = getActiveOrderForDriver(socket.driverId);
  if (activeOrder) {
    notifyClient(activeOrder.clientId, 'driverLocation', data);
  }
});
```

### Логика обработки заказов

```javascript
// Создание нового заказа
function createOrder(orderData) {
  // Сохранение в базу данных
  const order = saveOrderToDatabase(orderData);
  
  // Отправка всем онлайн водителям
  io.to('online_drivers').emit('newOrder', {
    id: order.id,
    from: order.from,
    to: order.to,
    price: order.price,
    clientId: order.clientId
  });
}

// Принятие заказа водителем
function acceptOrder(driverId, orderId) {
  const order = getOrderById(orderId);
  
  if (order && order.status === 'pending') {
    // Обновляем статус заказа
    updateOrderStatus(orderId, 'accepted', driverId);
    
    // Уведомляем клиента
    notifyClient(order.clientId, 'orderAccepted', {
      orderId: orderId,
      driverId: driverId,
      driverInfo: getDriverInfo(driverId)
    });
    
    // Уведомляем других водителей что заказ занят
    io.to('online_drivers').emit('orderTaken', {
      orderId: orderId,
      takenBy: driverId
    });
  }
}

// Отмена заказа клиентом
function cancelOrder(clientId, orderId) {
  const order = getOrderById(orderId);
  
  if (order) {
    updateOrderStatus(orderId, 'cancelled');
    
    // Уведомляем водителя если заказ был принят
    if (order.driverId) {
      notifyDriver(order.driverId, 'orderCancelled', {
        orderId: orderId,
        reason: 'cancelled_by_client'
      });
    }
    
    // Уведомляем всех водителей об удалении заказа
    io.to('online_drivers').emit('orderDeleted', {
      orderId: orderId
    });
  }
}
```

## Преимущества новой архитектуры

1. **Разделение ответственности**: Клиенты и водители получают только релевантные им события
2. **Масштабируемость**: Легко добавлять новые типы пользователей и события
3. **Безопасность**: Каждый тип пользователя имеет доступ только к своим данным
4. **Производительность**: Уменьшение нагрузки за счет таргетированной отправки событий
5. **Надежность**: Централизованное управление подключениями и переподключениями

## Миграция

1. Обновить Flutter приложение для использования `WebSocketService`
2. Обновить серверную часть для поддержки разделенных подключений
3. Протестировать все сценарии взаимодействия
4. Постепенно мигрировать пользователей на новую версию

## Мониторинг

Рекомендуется добавить метрики для отслеживания:
- Количество подключенных клиентов/водителей
- Частота событий по типам
- Время отклика на события
- Количество переподключений 