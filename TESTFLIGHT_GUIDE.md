# 📱 TestFlight Deployment Guide - Aday GO

## 📋 Информация о приложении
- **Название:** Aday GO  
- **Bundle ID:** `kz.aday.go`
- **Версия:** 1.0.7 (23)
- **Платформы:** iOS 12.0+

## 🔧 Предварительные требования

### 1. Apple Developer Account
- Нужен активный Apple Developer Program ($99/год)
- Доступ к [App Store Connect](https://appstoreconnect.apple.com)

### 2. macOS с Xcode
- macOS 11+ 
- Xcode 13.0+
- Command Line Tools установлены

### 3. Подписание приложения
Необходимы сертификаты:
- **iOS Distribution Certificate** 
- **Provisioning Profile** для App Store

## 🚀 Пошаговая инструкция

### Шаг 1: Настройка на macOS

```bash
# 1. Склонируйте проект на macOS
git clone [your-repo-url]
cd aktau_go

# 2. Установите зависимости
flutter pub get
cd ios && pod install && cd ..

# 3. Проверьте flutter doctor
flutter doctor
```

### Шаг 2: Настройка App Store Connect

1. Войдите в [App Store Connect](https://appstoreconnect.apple.com)
2. Создайте новое приложение:
   - **Имя:** Aday GO
   - **Bundle ID:** kz.aday.go
   - **SKU:** kz.aday.go.2025
   - **Язык:** Русский

### Шаг 3: Подписание в Xcode

```bash
# Откройте проект в Xcode
open ios/Runner.xcworkspace
```

В Xcode:
1. Выберите проект **Runner**
2. Во вкладке **Signing & Capabilities**:
   - Team: Выберите ваш Developer Team
   - Bundle Identifier: `kz.aday.go`
   - Provisioning Profile: Automatic

### Шаг 4: Сборка для App Store

```bash
# 1. Очистите предыдущие сборки
flutter clean
flutter pub get

# 2. Соберите iOS release
flutter build ios --release --no-codesign

# 3. Архивируйте в Xcode
# Откройте проект и выберите:
# Product → Archive
```

### Шаг 5: Загрузка в App Store Connect

В Xcode Organizer:
1. Выберите созданный архив
2. Нажмите **Distribute App**
3. Выберите **App Store Connect**
4. Выберите **Upload**
5. Следуйте инструкциям мастера

### Шаг 6: Настройка TestFlight

В App Store Connect:
1. Перейдите в **TestFlight**
2. Дождитесь обработки сборки (10-30 минут)
3. Добавьте информацию о тестировании
4. Добавьте внутренних тестировщиков
5. Отправьте на внешнее тестирование (если нужно)

## 📝 Метаданные приложения

### Описание (рус)
```
Aday GO - современное приложение для заказа такси в Актау. 

Основные возможности:
🚗 Быстрый заказ такси
🍕 Доставка еды
📦 Курьерские услуги
🌆 Межгородские поездки

Удобный интерфейс, быстрая подача, надежные водители.
```

### Описание (англ)
```
Aday GO - modern taxi booking app for Aktau city.

Key features:
🚗 Quick taxi booking
🍕 Food delivery
📦 Courier services  
🌆 Intercity trips

User-friendly interface, fast pickup, reliable drivers.
```

### Ключевые слова
```
такси, taxi, актау, aktau, доставка, delivery, курьер, aday
```

## 🖼️ Скриншоты для App Store

Необходимо добавить скриншоты для:
- iPhone 6.7" (обязательно)
- iPhone 6.5" (обязательно) 
- iPhone 5.5" (опционально)
- iPad Pro 12.9" (если поддерживается)

Размеры:
- 6.7": 1290 x 2796 пикселей
- 6.5": 1242 x 2688 пикселей

## 🔒 Разрешения

Убедитесь что добавлены описания для:
- ✅ Location (уже добавлено)
- ✅ Push Notifications (уже добавлено)

## 📧 Контактная информация

- **Support URL:** https://taxi.aktau-go.kz/support
- **Marketing URL:** https://taxi.aktau-go.kz
- **Privacy Policy:** https://taxi.aktau-go.kz/privacy

## ⚠️ Важные замечания

1. **Mapbox Token**: Убедитесь что токен валиден для продакшена
2. **API Endpoints**: Проверьте что используются продакшен URL
3. **Push Notifications**: Настройте APNs ключи
4. **App Review**: Подготовьте тестовый аккаунт для Apple Review

## 🧪 Тестирование

После загрузки в TestFlight:
1. Протестируйте все основные функции
2. Проверьте геолокацию 
3. Протестируйте заказ такси
4. Убедитесь что карты работают
5. Проверьте push уведомления

## 🎯 Следующие шаги

1. ✅ Проект подготовлен (версия 1.0.7+23)
2. ⏳ Требуется macOS для сборки
3. ⏳ Настройка Apple Developer Account
4. ⏳ Создание приложения в App Store Connect
5. ⏳ Сборка и загрузка архива
6. ⏳ Настройка TestFlight

---

💡 **Совет**: Рекомендую сначала протестировать на iOS симуляторе на macOS, а затем переходить к TestFlight. 