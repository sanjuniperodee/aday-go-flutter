#!/bin/bash

# 🚀 Aday GO - iOS Deployment Script
# Версия: 1.0.18+38
# Выполнять на macOS с установленным Xcode

echo "🚀 Starting Aday GO iOS deployment..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

# Mapbox downloads token (for SPM binary targets like Mapbox)
# Set the public Mapbox token for iOS builds (this token works for SDK downloads)
export MAPBOX_DOWNLOADS_TOKEN='pk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY203MG04dzlpMDJ1NTJxcXd0NTlkeDdsdyJ9.x57YdgO8r_TCCQBTOvzHFw'

# Prefer env var if already set; otherwise try to read from ~/.netrc
if [ -z "${MAPBOX_DOWNLOADS_TOKEN}" ]; then
    if [ -f "$HOME/.netrc" ]; then
        NETRC_TOKEN=$(awk '/machine api.mapbox.com/{found=1} found&&/password /{print $2; exit}' "$HOME/.netrc")
        NETRC_LOGIN=$(awk '/machine api.mapbox.com/{found=1} found&&/login /{print $2; exit}' "$HOME/.netrc")
        if [ -n "$NETRC_TOKEN" ] && [ "$NETRC_LOGIN" = "mapbox" ]; then
            export MAPBOX_DOWNLOADS_TOKEN="$NETRC_TOKEN"
            print_status "Mapbox token loaded from ~/.netrc"
        fi
    fi
fi

# Validate that the token works to avoid SPM 401 errors during build
if [ -n "${MAPBOX_DOWNLOADS_TOKEN}" ]; then
    if command -v curl >/dev/null 2>&1; then
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${MAPBOX_DOWNLOADS_TOKEN}" "https://api.mapbox.com/downloads/v2/mapbox-common/releases/ios/packages/24.12.0/MapboxCommon.zip") || HTTP_STATUS="000"
        if [ "$HTTP_STATUS" != "200" ]; then
            print_warning "Mapbox token seems invalid (HTTP $HTTP_STATUS). SPM may fail to resolve Mapbox packages."
        else
            print_status "Mapbox token verified"
        fi
    fi
else
    print_warning "MAPBOX_DOWNLOADS_TOKEN is not set and not found in ~/.netrc. Mapbox SPM dependencies may fail with 401."
    print_warning "Set env var MAPBOX_DOWNLOADS_TOKEN or add to ~/.netrc: 'machine api.mapbox.com login mapbox password <token>'"
fi

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

# Создание архива
echo ""
echo "📦 Creating iOS archive for App Store..."

# Переход в папку iOS
cd ios

# Создание архива с правильными настройками
ARCHIVE_PATH="build/Runner-$(date +%Y%m%d-%H%M%S).xcarchive"

# Извлечение версии и номера сборки из pubspec.yaml
BUILD_NAME=$(echo $VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)

print_info "Creating archive at: $ARCHIVE_PATH"
print_info "Build name: $BUILD_NAME, Build number: $BUILD_NUMBER"

xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    ENABLE_USER_SCRIPT_SANDBOXING=NO \
    FLUTTER_BUILD_NAME="$BUILD_NAME" \
    FLUTTER_BUILD_NUMBER="$BUILD_NUMBER" \
    -allowProvisioningUpdates

if [ $? -eq 0 ]; then
    print_status "Archive created successfully!"
    
    # Копирование архива в стандартную папку Xcode
    XCODE_ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives"
    DATE_DIR=$(date +%Y-%m-%d)
    FINAL_ARCHIVE_DIR="$XCODE_ARCHIVES_DIR/$DATE_DIR"
    
    mkdir -p "$FINAL_ARCHIVE_DIR"
    cp -R "$ARCHIVE_PATH" "$FINAL_ARCHIVE_DIR/"
    
    print_status "Archive copied to Xcode Organizer: $FINAL_ARCHIVE_DIR"
    
    # Получение имени архива для отображения
    ARCHIVE_NAME=$(basename "$ARCHIVE_PATH")
    print_info "Archive name: $ARCHIVE_NAME"
    
else
    print_error "Archive creation failed!"
    cd ..
    exit 1
fi

# Возврат в корневую папку
cd ..

# Открытие Xcode Organizer
echo ""
echo "📱 Opening Xcode Organizer..."
open -a Xcode --args -showOrganizer

print_status "Xcode Organizer opened"

echo ""
echo "📋 Next steps in Xcode Organizer:"
echo "1. Find your archive in the Archives tab"
echo "2. Select the archive and click 'Distribute App'"
echo "3. Choose 'App Store Connect'"
echo "4. Follow the distribution wizard"
echo "5. Upload to App Store Connect"

echo ""
echo "🎯 After upload to App Store Connect:"
echo "1. Go to App Store Connect (https://appstoreconnect.apple.com)"
echo "2. Navigate to your app → TestFlight"
echo "3. Wait for build processing (10-30 minutes)"
echo "4. Add test information and internal testers"
echo "5. Submit for external testing (if needed)"

echo ""
print_status "Deployment script completed! 🚀"

# Информация о созданном архиве
echo ""
echo "📦 Archive Information:"
echo "• Version: $VERSION"
echo "• Archive Path: ios/$ARCHIVE_PATH"
echo "• Xcode Organizer Path: $FINAL_ARCHIVE_DIR"

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