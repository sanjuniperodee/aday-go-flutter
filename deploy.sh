#!/bin/bash

# 🚀 Aday GO - iOS Deployment Script
# Версия: 1.0.7+23
# Выполнять на macOS с установленным Xcode

echo "🚀 Starting Aday GO iOS deployment..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода статуса
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка окружения
echo "🔍 Checking environment..."

# Проверка Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter не найден. Установите Flutter SDK."
    exit 1
fi

print_status "Flutter найден: $(flutter --version | head -n 1)"

# Проверка Xcode
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode не найден. Установите Xcode из App Store."
    exit 1
fi

print_status "Xcode найден: $(xcodebuild -version | head -n 1)"

# Проверка iOS устройств/симуляторов
if ! flutter devices | grep -q ios; then
    print_warning "iOS устройства не найдены. Откройте симулятор или подключите iPhone."
fi

# Очистка и получение зависимостей
echo ""
echo "🧹 Cleaning and getting dependencies..."
flutter clean
flutter pub get

print_status "Dependencies updated"

# Установка iOS зависимостей
echo ""
echo "📦 Installing iOS pods..."
cd ios
pod install --repo-update
cd ..

print_status "iOS pods installed"

# Проверка конфигурации
echo ""
echo "🔧 Checking configuration..."

# Проверка Bundle ID
if grep -q "kz.aday.go" ios/Runner.xcodeproj/project.pbxproj; then
    print_status "Bundle ID: kz.aday.go ✓"
else
    print_warning "Bundle ID может быть неправильным"
fi

# Проверка версии
VERSION=$(grep "version:" pubspec.yaml | awk '{print $2}')
print_status "App version: $VERSION"

# Сборка iOS release
echo ""
echo "🔨 Building iOS release..."
flutter build ios --release --no-codesign

if [ $? -eq 0 ]; then
    print_status "iOS build completed successfully"
else
    print_error "iOS build failed"
    exit 1
fi

# Открытие проекта в Xcode
echo ""
echo "🍎 Opening project in Xcode..."
open ios/Runner.xcworkspace

print_status "Project opened in Xcode"

echo ""
echo "📋 Next steps in Xcode:"
echo "1. Select 'Any iOS Device' as target"
echo "2. Product → Archive"
echo "3. Distribute App → App Store Connect"
echo "4. Upload to App Store Connect"

echo ""
echo "🎯 After upload:"
echo "1. Go to App Store Connect"
echo "2. Navigate to TestFlight"
echo "3. Wait for build processing (10-30 minutes)"
echo "4. Add test information and internal testers"

echo ""
print_status "Deployment script completed! 🚀"

# Открытие полезных ссылков
echo ""
echo "🔗 Useful links:"
echo "• App Store Connect: https://appstoreconnect.apple.com"
echo "• TestFlight Guide: ./TESTFLIGHT_GUIDE.md"
echo "• Deployment Checklist: ./DEPLOYMENT_CHECKLIST.md"

# Опционально открыть App Store Connect
read -p "Open App Store Connect in browser? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "https://appstoreconnect.apple.com"
fi

echo ""
echo "🎉 Happy deploying!" 