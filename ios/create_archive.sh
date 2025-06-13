#!/bin/bash

# Скрипт для создания iOS архива для App Store
# Использование: ./create_archive.sh [version_suffix]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Создание iOS архива для App Store...${NC}"

# Переходим в корневую директорию проекта
cd "$(dirname "$0")/.."

# Автоматически увеличиваем Build Number
echo -e "${YELLOW}🔢 Проверяем и обновляем Build Number...${NC}"
ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"

# Находим максимальный Build Number из существующих архивов
MAX_BUILD=0
if [ -d "$ARCHIVE_DIR" ]; then
    for archive in $(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d); do
        if [ -f "$archive/Info.plist" ]; then
            BUILD_NUM=$(plutil -extract ApplicationProperties.CFBundleVersion raw "$archive/Info.plist" 2>/dev/null || echo "0")
            if [[ "$BUILD_NUM" =~ ^[0-9]+$ ]] && [ "$BUILD_NUM" -gt "$MAX_BUILD" ]; then
                MAX_BUILD=$BUILD_NUM
            fi
        fi
    done
fi

# Увеличиваем Build Number на 1
NEW_BUILD=$((MAX_BUILD + 1))
echo -e "${BLUE}📊 Найден максимальный Build Number: $MAX_BUILD${NC}"
echo -e "${BLUE}🆕 Новый Build Number: $NEW_BUILD${NC}"

# Обновляем Info.plist
INFO_PLIST="ios/Runner/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    # Создаем резервную копию
    cp "$INFO_PLIST" "$INFO_PLIST.backup"
    
    # Обновляем CFBundleVersion
    plutil -replace CFBundleVersion -string "$NEW_BUILD" "$INFO_PLIST"
    echo -e "${GREEN}✅ Build Number обновлен до $NEW_BUILD${NC}"
else
    echo -e "${RED}❌ Не найден файл $INFO_PLIST${NC}"
    exit 1
fi

# Очищаем предыдущие сборки
echo -e "${YELLOW}🧹 Очищаем предыдущие сборки...${NC}"
flutter clean
flutter pub get

# Создаем архив через Flutter
echo -e "${YELLOW}📦 Создаем архив через Flutter...${NC}"
flutter build ipa --release

# Проверяем что архив создался
if [ ! -d "build/ios/archive/Runner.xcarchive" ]; then
    echo -e "${RED}❌ Ошибка: Архив не создался!${NC}"
    # Восстанавливаем Info.plist
    mv "$INFO_PLIST.backup" "$INFO_PLIST"
    exit 1
fi

# Создаем директорию для архивов по дате
ARCHIVE_DATE=$(date +%Y-%m-%d)
ARCHIVE_TIME=$(date +%H-%M-%S)
ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives/$ARCHIVE_DATE"
mkdir -p "$ARCHIVE_DIR"

# Получаем версию из Info.plist
VERSION=$(plutil -extract CFBundleShortVersionString raw build/ios/archive/Runner.xcarchive/Info.plist)
BUILD=$(plutil -extract ApplicationProperties.CFBundleVersion raw build/ios/archive/Runner.xcarchive/Info.plist)

# Создаем имя архива
SUFFIX=$1
if [ -n "$SUFFIX" ]; then
    ARCHIVE_NAME="Runner-v${VERSION}-${BUILD}-${SUFFIX}.xcarchive"
else
    ARCHIVE_NAME="Runner-v${VERSION}-${BUILD}-${ARCHIVE_TIME}.xcarchive"
fi

# Копируем архив в Xcode Organizer
echo -e "${YELLOW}📋 Копируем архив в Xcode Organizer...${NC}"
cp -R "build/ios/archive/Runner.xcarchive" "$ARCHIVE_DIR/$ARCHIVE_NAME"

# Выводим информацию о созданном архиве
echo -e "${GREEN}✅ Архив успешно создан!${NC}"
echo -e "${BLUE}📍 Расположение архива:${NC} $ARCHIVE_DIR/$ARCHIVE_NAME"
echo -e "${BLUE}📱 Версия:${NC} $VERSION ($BUILD)"
echo -e "${BLUE}📦 Размер IPA:${NC} $(du -h build/ios/ipa/*.ipa | cut -f1)"

# Выводим информацию о подписи
SIGNING_IDENTITY=$(plutil -extract ApplicationProperties.SigningIdentity raw build/ios/archive/Runner.xcarchive/Info.plist)
TEAM=$(plutil -extract ApplicationProperties.Team raw build/ios/archive/Runner.xcarchive/Info.plist)
echo -e "${BLUE}🔐 Подпись:${NC} $SIGNING_IDENTITY"
echo -e "${BLUE}👥 Команда:${NC} $TEAM"

echo ""
echo -e "${GREEN}🎉 Готово! Теперь вы можете:${NC}"
echo -e "${YELLOW}1.${NC} Открыть Xcode Organizer (Window → Organizer)"
echo -e "${YELLOW}2.${NC} Выбрать архив $ARCHIVE_NAME"
echo -e "${YELLOW}3.${NC} Нажать 'Distribute App' для загрузки в App Store Connect"
echo ""
echo -e "${BLUE}💡 Альтернативно, можете загрузить IPA напрямую через Transporter:${NC}"
echo -e "   Путь к IPA: $(pwd)/build/ios/ipa/Aday GO.ipa"

# Удаляем резервную копию
rm -f "$INFO_PLIST.backup"

# Опционально открыть Xcode
read -p "Открыть Xcode Organizer? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Перезапускаем Xcode для обновления списка архивов
    killall Xcode 2>/dev/null || true
    sleep 2
    open -a Xcode
    sleep 3
    osascript -e 'tell application "Xcode" to activate'
    osascript -e 'tell application "System Events" to tell process "Xcode" to keystroke "9" using {shift down, command down}'
fi

echo -e "${GREEN}🔥 Процесс завершен!${NC}" 