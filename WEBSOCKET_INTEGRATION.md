# Интеграция новой WebSocket архитектуры для Taxi Service

## ✅ ПОЛНЫЙ АНАЛИЗ ПОКРЫТЫХ КЕЙСОВ

### Статусы заказов в системе:
1. **CREATED** - заказ создан, ищем водителя
2. **STARTED** - водитель принял заказ, едет к клиенту  
3. **WAITING** - водитель прибыл на место (на месте)
4. **ONGOING** - поездка началась
5. **COMPLETED** - поездка завершена
6. **REJECTED** - заказ отклонен (общий статус)
7. **REJECTED_BY_CLIENT** - заказ отменен клиентом
8. **REJECTED_BY_DRIVER** - заказ отменен водителем

### ✅ ВСЕ ПОКРЫТЫЕ КЕЙСЫ:

#### 1. **Создание и распределение заказов**
- ✅ Клиент создает заказ через API
- ✅ Система находит ближайших водителей нужной категории
- ✅ WebSocket уведомления отправляются ТОЛЬКО онлайн водителям
- ✅ Push уведомления отправляются всем подходящим водителям
- ✅ Заказ НЕ отправляется клиенту, если он сам водитель

#### 2. **Принятие заказа водителем**
- ✅ Водитель принимает заказ через API
- ✅ Клиент получает `orderAccepted` с информацией о водителе и машине
- ✅ Другие водители получают `orderTaken` (заказ больше недоступен)
- ✅ Статус заказа меняется на `STARTED`

#### 3. **Прибытие водителя (на месте)**
- ✅ Водитель нажимает "Я на месте" в приложении
- ✅ Клиент получает `driverArrived` с уведомлением
- ✅ Статус заказа меняется на `WAITING`
- ✅ Push уведомление с информацией о машине

#### 4. **Начало поездки**
- ✅ Водитель нажимает "Начать поездку"
- ✅ Клиент получает `rideStarted`
- ✅ Статус заказа меняется на `ONGOING`

#### 5. **Завершение поездки**
- ✅ Водитель нажимает "Завершить поездку"
- ✅ Клиент получает `rideEnded`
- ✅ Статус заказа меняется на `COMPLETED`
- ✅ Предложение оценить поездку

#### 6. **Отмена заказа КЛИЕНТОМ**
- ✅ Клиент может отменить заказ на любом этапе
- ✅ Если водитель уже принял - он получает `orderCancelledByClient`
- ✅ Все водители получают `orderDeleted` (убрать из списка)
- ✅ Статус заказа меняется на `REJECTED_BY_CLIENT`

#### 7. **Отмена заказа ВОДИТЕЛЕМ**
- ✅ Водитель может отклонить заказ (не принимать) - заказ остается доступным
- ✅ Водитель может отменить уже принятый заказ
- ✅ Клиент получает `orderCancelledByDriver` 
- ✅ Заказ становится снова доступным для других водителей
- ✅ Статус заказа меняется на `REJECTED_BY_DRIVER`

#### 8. **Постоянное отслеживание позиции**
- ✅ Водитель ВСЕГДА отправляет позицию (независимо от наличия заказа)
- ✅ Позиция сохраняется в кеше для поиска ближайших водителей
- ✅ Клиент получает `driverLocation` ТОЛЬКО если у водителя активный заказ
- ✅ Позиция передается с информацией о заказе и его статусе

#### 9. **Управление онлайн статусом**
- ✅ Водитель может перейти в онлайн (`driverOnline`)
- ✅ Водитель может уйти в оффлайн (`driverOffline`)
- ✅ Новые заказы отправляются ТОЛЬКО онлайн водителям
- ✅ Позиция обновляется независимо от онлайн статуса

## Новые методы Gateway

### Методы для всех статусов заказов:
```typescript
handleOrderCreated()        // Создание заказа
handleOrderAccepted()       // Принятие заказа
handleDriverArrived()       // Водитель прибыл (на месте) 
handleRideStarted()         // Начало поездки
handleRideEnded()           // Завершение поездки
handleOrderRejected()       // Отклонение заказа
handleOrderCancelledByClient()   // Отмена клиентом
handleOrderCancelledByDriver()   // Отмена водителем
```

### Методы для уведомлений:
```typescript
notifyClient()              // Уведомление конкретного клиента
notifyDriver()              // Уведомление конкретного водителя  
broadcastToOnlineDrivers()  // Рассылка онлайн водителям
```

## События для клиентов

| Событие | Когда происходит | Данные |
|---------|------------------|--------|
| `orderAccepted` | Водитель принял заказ | driver, order, timestamp |
| `driverArrived` | Водитель прибыл на место | message: "Водитель прибыл и ждет вас" |
| `rideStarted` | Поездка началась | message: "Поездка началась" |
| `rideEnded` | Поездка завершена | message: "Поездка завершена" |
| `orderCancelledByDriver` | Водитель отменил заказ | reason, message |
| `driverLocation` | Обновление позиции водителя | lat, lng, orderId, orderStatus |

## События для водителей

| Событие | Когда происходит | Данные |
|---------|------------------|--------|
| `newOrder` | Новый заказ доступен | order details, clientId, coordinates |
| `orderTaken` | Заказ принят другим водителем | orderId, takenBy |
| `orderDeleted` | Заказ удален/отменен клиентом | orderId, reason |
| `orderCancelledByClient` | Клиент отменил заказ | orderId, reason, message |

## Отправляемые события от клиентов

### От водителей:
- `driverOnline` - выход в онлайн для получения заказов
- `driverOffline` - уход в оффлайн  
- `driverLocationUpdate` - обновление координат (постоянно)

### От клиентов:
- Пока нет специальных событий, только через REST API

## Архитектура подключений

### Параметры подключения клиента:
```dart
{
  'userType': 'client',
  'userId': userId,
  'sessionId': sessionId,
}
```

### Параметры подключения водителя:
```dart
{
  'userType': 'driver', 
  'driverId': driverId,
  'sessionId': sessionId,
  'lat': latitude,        // опционально при подключении
  'lng': longitude,       // опционально при подключении
}
```

## Комнаты WebSocket

- `client_${userId}` - для каждого клиента
- `driver_${driverId}` - для каждого водителя
- `all_drivers` - все водители (онлайн и оффлайн)
- `online_drivers` - только онлайн водители

## Преимущества новой архитектуры

1. **Полное покрытие всех кейсов** - каждый статус заказа имеет соответствующее уведомление
2. **Точечная доставка** - события отправляются только нужным пользователям
3. **Постоянное отслеживание** - позиция водителя обновляется независимо от наличия заказа
4. **Правильные отмены** - отдельная логика для отмены клиентом и водителем
5. **Онлайн статус** - заказы отправляются только активным водителям
6. **Масштабируемость** - легко добавлять новые статусы и события

## Следующие шаги

1. ✅ Исправить ошибки TypeScript в бэкенде
2. ✅ Протестировать все статусы заказов
3. ✅ Проверить отмену заказов клиентом и водителем  
4. ✅ Протестировать постоянное отслеживание позиции
5. ⏳ Добавить heartbeat для проверки соединения
6. ⏳ Реализовать автоматическое переподключение при сбоях
7. ⏳ Добавить метрики и мониторинг

## Отладка

### Логи сервера:
- `🔌 Новое подключение: userType=driver, driverId=123`
- `📦 Создан новый заказ 789, найдено водителей: 5`
- `✅ Заказ 789 принят водителем 123`
- `🚗 Водитель 123 прибыл к клиенту 456 для заказа 789`
- `🚀 Поездка началась: заказ 789, водитель 123`
- `🏁 Поездка завершена: заказ 789, водитель 123`
- `🚫 Заказ 789 отменен клиентом`
- `🚫 Заказ 789 отменен водителем 123`

### Логи Flutter:
Включите логи WebSocketService для отслеживания событий в режиме отладки. 