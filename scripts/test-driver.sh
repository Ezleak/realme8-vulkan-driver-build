#!/bin/bash
# ==========================================================
# test-driver.sh - Проверка работоспособности драйвера
# ==========================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}===== Тестирование драйвера Panfrost =====${NC}"
echo ""

# Проверка наличия драйвера
if [ ! -d "$PREFIX/panfrost/lib" ]; then
    echo -e "${RED}❌ Драйвер не найден! Сначала запустите build_and_test.sh${NC}"
    exit 1
fi

# Установка переменных
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=$PREFIX/panfrost/lib/dri
export GALLIUM_DRIVER=panfrost

echo -e "${YELLOW}[1/4] Информация о драйвере:${NC}"
glxinfo -B 2>/dev/null | head -20 || echo "Ошибка: glxinfo не найден"

echo ""
echo -e "${YELLOW}[2/4] Тест OpenGL (glxgears):${NC}"
timeout 10s glxgears -info 2>/dev/null &
sleep 3
pkill glxgears || true

echo ""
echo -e "${YELLOW}[3/4] Тест производительности (glmark2):${NC}"
timeout 20s glmark2 --run-forever 2>/dev/null || echo "Тест завершен"

echo ""
echo -e "${YELLOW}[4/4] Проверка Vulkan:${NC}"
vulkaninfo --summary 2>/dev/null | head -10 || echo "Vulkan не найден"

echo -e "${GREEN}✅ Тестирование завершено!${NC}"
