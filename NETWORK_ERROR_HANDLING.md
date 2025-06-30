# Система обработки сетевых ошибок

Эта система предоставляет централизованную обработку ошибок интернет-соединения для всех кнопок и сетевых запросов в приложении.

## Основные компоненты

### 1. NetworkUtils
Основной класс для обработки сетевых ошибок и проверки интернет-соединения.

#### Основные методы:

```dart
// Проверка наличия интернета
bool hasInternet = await NetworkUtils.hasInternetConnection();

// Выполнение запроса с автоматической обработкой ошибок
final result = await NetworkUtils.executeWithErrorHandling<UserDomain>(
  () => model.getUserProfile(),
  customErrorMessage: 'Не удалось загрузить профиль пользователя',
  showErrorMessages: true, // по умолчанию true
);

if (result != null) {
  // Запрос выполнен успешно
  user.accept(result);
}
```

#### Автоматическая обработка ошибок:
- **Нет интернета**: "Нет подключения к интернету. Проверьте соединение и попробуйте снова."
- **Таймаут**: "Превышено время ожидания. Проверьте соединение и попробуйте снова."
- **Ошибка сервера**: "Ошибка сервера. Попробуйте позже."

### 2. NetworkStatusWidget
Виджет для отображения состояния интернет-соединения в реальном времени.

```dart
NetworkStatusWidget(
  child: Scaffold(
    // ваш контент
  ),
)
```

Показывает красный баннер при отсутствии интернета с кнопкой "Повторить".

### 3. NetworkAwareMixin
Миксин для автоматической проверки интернета в виджетах.

```dart
class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget> with NetworkAwareMixin {
  @override
  void onNoInternet() {
    // Переопределите для кастомной обработки
    super.onNoInternet(); // Показывает стандартное сообщение
  }

  void someAction() async {
    final result = await executeWithInternet(() async {
      return await someNetworkCall();
    });
    
    if (result != null) {
      // Обработка успешного результата
    }
  }
}
```

## Примеры использования

### 1. Обновление существующих методов

**Было:**
```dart
Future<void> fetchUserProfile() async {
  try {
    final response = await model.getUserProfile();
    me.accept(response);
  } catch (e) {
    logger.e(e);
    // Показать ошибку пользователю
  }
}
```

**Стало:**
```dart
Future<void> fetchUserProfile() async {
  final result = await NetworkUtils.executeWithErrorHandling<UserDomain>(
    () => model.getUserProfile(),
    showErrorMessages: false, // Для автоматических запросов
  );
  
  if (result != null) {
    me.accept(result);
  }
}
```

### 2. Обработка кнопок

```dart
ElevatedButton(
  onPressed: () async {
    final result = await NetworkUtils.executeWithErrorHandling<void>(
      () => createOrder(),
      customErrorMessage: 'Не удалось создать заказ',
    );
    
    if (result != null) {
      // Показать успешное сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заказ создан успешно!')),
      );
    }
  },
  child: Text('Создать заказ'),
)
```

### 3. Диалоги с проверкой интернета

```dart
// Показать диалог с проверкой интернета
final shouldRetry = await NetworkStatusDialog.showNoInternetDialog(context);
if (shouldRetry) {
  // Повторить действие
}

// Создать SnackBar с кнопкой повтора
ScaffoldMessenger.of(context).showSnackBar(
  NetworkUtils.createRetrySnackBar(
    message: 'Не удалось загрузить данные',
    onRetry: () => fetchData(),
  ),
);
```

## Интеграция в существующий код

### Шаг 1: Добавить зависимость
В `pubspec.yaml` уже добавлена зависимость `connectivity_plus: ^6.1.0`.

### Шаг 2: Обернуть главный экран
```dart
// main_screen.dart
return NetworkStatusWidget(
  child: Scaffold(
    // ваш контент
  ),
);
```

### Шаг 3: Обновить методы с сетевыми запросами
Заменить `try-catch` блоки на `NetworkUtils.executeWithErrorHandling`.

### Шаг 4: Обновить обработчики кнопок
Добавить проверку интернета перед выполнением сетевых операций.

## Преимущества новой системы

1. **Централизованная обработка**: Все ошибки обрабатываются в одном месте
2. **Автоматическая проверка интернета**: Проверка перед каждым запросом
3. **Понятные сообщения**: Пользователь видит понятные сообщения об ошибках
4. **Кнопки повтора**: Возможность легко повторить неудачные операции
5. **Визуальная индикация**: Баннер состояния интернета в реальном времени
6. **Простота использования**: Минимум кода для максимальной функциональности

## Настройка сообщений

Все сообщения об ошибках можно настроить в `NetworkUtils`:

```dart
// Кастомные сообщения
static void showCustomErrorMessage(String message) {
  final messageController = MaterialMessageController();
  messageController.showError(message);
}
```

## Тестирование

Для тестирования отключения интернета:
1. Отключите Wi-Fi и мобильные данные
2. Попробуйте выполнить любое действие в приложении
3. Убедитесь, что появляется соответствующее сообщение
4. Включите интернет и нажмите "Повторить" 