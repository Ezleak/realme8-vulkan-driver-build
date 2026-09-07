# Интеграция драйвера с shadPS4

## 1. Сборка PanVK (Vulkan)

По умолчанию `build_and_test.sh` собирает только OpenGL (Panfrost). Для интеграции с shadPS4 нужно собрать Vulkan-версию.

### Способ 1: Модификация скрипта

Отредактируйте `build_and_test.sh` и найдите строку:
```meson
-Dvulkan-drivers=
```

Измените на:
```meson
-Dvulkan-drivers=panfrost
```

Затем пересоберите:
```bash
./build_and_test.sh
```

### Способ 2: Ручная сборка

```bash
cd ~/mesa-panfork/build
meson configure -Dvulkan-drivers=panfrost
ninja -j$(nproc)
ninja install
```

## 2. Создание ICD-файла для Vulkan

Vulkan требует специального конфигурационного файла (ICD — Installable Client Driver). Создайте его:

```bash
cat > ~/panfrost.icd << 'EOF'
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "$PREFIX/panfrost/lib/libvulkan_panfrost.so",
        "api_version": "1.0.0"
    }
}
EOF
```

## 3. Запуск shadPS4 с драйвером

### Способ 1: Через VK_ICD_FILENAMES (рекомендуется)

```bash
export VK_ICD_FILENAMES=~/panfrost.icd
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH
export GALLIUM_DRIVER=panfrost

# Запуск shadPS4
./shadPS4
```

### Способ 2: Через LD_PRELOAD

```bash
export LD_PRELOAD=$PREFIX/panfrost/lib/libvulkan_panfrost.so
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH

./shadPS4
```

### Способ 3: Скрипт-обертка

Создайте скрипт `run_shadps4.sh`:

```bash
#!/bin/bash

export VK_ICD_FILENAMES=~/panfrost.icd
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH
export GALLIUM_DRIVER=panfrost

cd /path/to/shadPS4
./shadPS4
```

Затем:
```bash
chmod +x run_shadps4.sh
./run_shadps4.sh
```

## 4. Проверка работы Vulkan

```bash
export VK_ICD_FILENAMES=~/panfrost.icd
export LD_LIBRARY_PATH=$PREFIX/panfrost/lib:$LD_LIBRARY_PATH

vulkaninfo --summary
```

Ожидаемый вывод:
```
Vulkan Instance Version: 1.0.0
Instance Extensions: ... panfrost ...
```

## 5. Ожидаемые результаты

### Успех
- shadPS4 запускается с видео
- Может быть медленно, но работает
- Звук воспроизводится

### Частичный успех
- shadPS4 запускается, но черный экран (как на MediaTek Helio G99)
- Возможен звук без видео
- Это означает, что Vulkan работает, но есть проблемы с расширениями

### Неудача
- Ошибки Vulkan при запуске
- Эмулятор не запускается
- Нужна дополнительная отладка

## 6. Отладка проблем

### Если черный экран

1. Проверьте, собран ли PanVK:
```bash
ls -la $PREFIX/panfrost/lib/ | grep -i vulkan
```

2. Проверьте логи:
```bash
export VK_LOADER_DEBUG=all
./shadPS4
```

3. Попробуйте режим отладки:
```bash
export PANVK_DEBUG=all
./shadPS4
```

### Если segmentation fault

Возможно, на вашем GPU недостаточно памяти. Попробуйте:
```bash
export PANVK_ALLOW_UNSAFE=1
./shadPS4
```

## 7. Известные ограничения

| Ограничение | Причина | Решение |
|-------------|---------|----------|
| **Низкая производительность** | Bifrost архитектура (2018) | Ожидайте 1-10 FPS на сложных сценах |
| **Стабильность** | Неполная поддержка Vulkan на Mali | Может быть хорошие результаты на простых играх |
| **Частые вылеты** | Ошибки в реализации JM-бэкенда | Используйте последние версии Mesa |
| **Нет расширений** | Mali не поддерживает все Vulkan 1.3 расширения | Используйте Turnip для Adreno GPU |

## 8. Дополнительные ресурсы

- [shadPS4 GitHub](https://github.com/shadps4-emu/shadPS4)
- [PanVK Mali Android Stubs](https://github.com/martuniykmisha012-rgb/PanVK-Mali-Android-Stubs)
- [Mesa Panfork](https://github.com/tokokudo/panfork)
- [Vulkan Specification](https://www.khronos.org/vulkan/)
- [ARM Mali Developer Site](https://developer.arm.com/products/graphics-and-multimedia/mali-gpus)
