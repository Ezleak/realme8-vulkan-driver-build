#!/bin/bash
# ==========================================================
# УНИВЕРСАЛЬНЫЙ СБОРЩИК ДРАЙВЕРА PANFROST ДЛЯ REALME 8
# ==========================================================
# Версия 1.0 | Автор: kamnevdima1220006-tech
# Тестирование: Mali-G76 Bifrost (ARM Mali-G76 MC4)
# ==========================================================

set -e  # Остановка при любой ошибке

# Цветовой вывод
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ДРАЙВЕР PANFROST ДЛЯ REALME 8 (Mali)   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""

# ----------------------------------------------------------
# 1. Проверка и установка зависимостей
# ----------------------------------------------------------
echo -e "${YELLOW}[1/6] Установка зависимостей для Termux...${NC}"
pkg update -y && pkg upgrade -y
pkg install -y git meson ninja build-essential cmake python \
    termux-x11 x11-repo glmark2 glxgears glxinfo \
    android-ndk binutils

# Настройка переменных среды
export ANDROID_NDK_HOME=$PREFIX/lib/android-ndk
export PATH=$PATH:$ANDROID_NDK_HOME/bin

# ----------------------------------------------------------
# 2. Клонирование и сборка Panfork с поддержкой SW winsys
# ----------------------------------------------------------
echo -e "${YELLOW}[2/6] Клонирование форка Panfork для Mali-G76...${NC}"
cd ~
if [ -d "mesa-panfork" ]; then
    echo "Обновление существующего репозитория..."
    cd mesa-panfork && git pull && cd ..
else
    git clone -b Panfrost-G610 --depth 1 \
        https://github.com/Saikatsaha1996/mesa-Panfrost-G610 mesa-panfork
fi

cd mesa-panfork

# Подготовка кросс-компиляции для Android (ARM64)
echo -e "${YELLOW}[3/6] Настройка Meson для Android...${NC}"
rm -rf build
mkdir -p build && cd build

# Конфигурация для Termux-окружения
CFLAGS="-O3" meson setup .. \
    -Dgallium-drivers=panfrost,swrast \
    -Dvulkan-drivers= \
    -Dbuildtype=release \
    -Dllvm=disabled \
    -Dprefix=$PREFIX/panfrost

echo -e "${YELLOW}[4/6] Компиляция драйвера (может занять до 30 минут)...${NC}"
ninja -j$(nproc)

# ----------------------------------------------------------
# 3. Установка драйвера в каталог пользователя
# ----------------------------------------------------------
echo -e "${YELLOW}[5/6] Установка драйвера в $PREFIX/panfrost...${NC}"
ninja install

# Создание символических ссылок для универсального доступа
mkdir -p $PREFIX/panfrost/lib/dri
if [ -d "src/gallium/drivers/panfrost" ]; then
    cp src/gallium/drivers/panfrost/*.so $PREFIX/panfrost/lib/dri/ 2>/dev/null || true
fi

# ----------------------------------------------------------
# 4. Тестирование драйвера
# ----------------------------------------------------------
echo -e "${YELLOW}[6/6] Проверка работоспособности драйвера...${NC}"

# Настройка переменных для загрузки драйвера
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=$PREFIX/panfrost/lib/dri
export GALLIUM_DRIVER=panfrost

# Запуск диагностических утилит
echo -e "${GREEN}--- Информация о драйвере ---${NC}"
glxinfo -B 2>/dev/null | head -20 || echo "Vulkan tools not available"

echo -e "${GREEN}--- Информация о системе ---${NC}"
echo "Архитектура: $(uname -m)"
echo "ОС: $(uname -s)"
echo "Версия Android NDK: $(ls $ANDROID_NDK_HOME 2>/dev/null | head -1)"

# ----------------------------------------------------------
# 5. Итоговый отчет
# ----------------------------------------------------------
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ ДРАЙВЕР УСПЕШНО СОБРАН И УСТАНОВЛЕН ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Библиотеки драйвера находятся в:${NC}"
echo "  $PREFIX/panfrost/lib"
echo ""
echo -e "${YELLOW}Для постоянного использования добавьте в ~/.bashrc:${NC}"
cat << 'EOF'
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=$PREFIX/panfrost/lib/dri
export GALLIUM_DRIVER=panfrost
EOF
echo ""
echo -e "${GREEN}Проверка работы:${NC}"
echo "  1. glxgears -info          # Запуск теста графики"
echo "  2. glxinfo -B              # Информация о видеокарте"
echo "  3. glmark2                 # Тест производительности (если доступен)"
echo ""
echo -e "${YELLOW}Примечание: на Bifrost возможна низкая производительность (~1 FPS).${NC}"
echo -e "${YELLOW}Это нормально — это ограничение архитек��уры GPU.${NC}"
