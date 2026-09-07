#!/bin/bash
# ==========================================================
# setup-termux.sh - Полная настройка Termux для Realme 8
# ==========================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}===== Настройка Termux для Realme 8 =====${NC}"
echo ""

# Обновление пакетов
echo -e "${YELLOW}[1/5] Обновление пакетов...${NC}"
pkg update -y && pkg upgrade -y

# Установка базовых инструментов
echo -e "${YELLOW}[2/5] Установка инструментов разработки...${NC}"
pkg install -y git meson ninja build-essential cmake python \
    termux-x11 x11-repo glmark2 glxgears glxinfo \
    android-ndk binutils wget curl

# Настройка переменных окружения
echo -e "${YELLOW}[3/5] Настройка переменных окружения...${NC}"
cat >> ~/.bashrc << 'EOF'

# Android NDK
export ANDROID_NDK_HOME=$PREFIX/lib/android-ndk
export PATH=$PATH:$ANDROID_NDK_HOME/bin

# Panfrost driver
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=$PREFIX/panfrost/lib/dri
export GALLIUM_DRIVER=panfrost

# Termux-X11
export DISPLAY=:0
EOF

# Применение переменных
source ~/.bashrc

# Проверка Android NDK
echo -e "${YELLOW}[4/5] Проверка Android NDK...${NC}"
if [ -d "$ANDROID_NDK_HOME" ]; then
    echo -e "${GREEN}✅ NDK установлен: $ANDROID_NDK_HOME${NC}"
else
    echo -e "${RED}❌ NDK не найден! Переустановите: pkg install android-ndk${NC}"
    exit 1
fi

# Настройка Termux-X11
echo -e "${YELLOW}[5/5] Настройка Termux-X11...${NC}"
mkdir -p ~/.termux
cat > ~/.termux/termux.properties << 'EOF'
extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]
use-black-ui = true
bell-character = ignore
EOF

echo -e "${GREEN}✅ Настройка завершена!${NC}"
echo ""
echo -e "${YELLOW}Для применения изменений выполните:${NC}"
echo "  source ~/.bashrc"
echo ""
echo -e "${YELLOW}Для запуска X-сервера:${NC}"
echo "  termux-x11 &"
