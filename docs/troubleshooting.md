# Устранение неполадок при сборке драйвера

## Ошибка: `syncobj wait timeout`

**Описание**: Драйвер работает, но очень медленно (~1 FPS) с ошибками таймаута.

**Причина**: Известная проблема для архитектуры Bifrost на GPU Mali-G76. Связана с несовершенством Job Manager бэкенда в Panfrost.

**Решение**: 
1. Используйте патч `bifrost-v7-compat.patch` из папки `patches/`
2. Попробуйте собрать с флагом `-Dpanfrost-debug=1` для получения дополнительной информации
3. Ожидайте улучшений в следующих релизах Mesa

## Ошибка: `cannot find -lGL`

**Описание**: При сборке возникает ошибка линковки.

**Решение**:
```bash
pkg install libglvnd-dev
```

## Ошибка: `No rule to make target`

**Описание**: Meson не может найти файлы Android NDK.

**Решение**:
```bash
export ANDROID_NDK_HOME=$PREFIX/lib/android-ndk
export PATH=$PATH:$ANDROID_NDK_HOME/bin
```

## Ошибка: `vulkaninfo: command not found`

**Решение**:
```bash
pkg install vulkan-tools
```

## Ошибка: `Black screen in shadPS4`

**Причина**: Отсутствие совместимог�� Vulkan-драйвера. На Mali штатный Vulkan-драйвер не поддерживает нужные расширения.

**Решение**: 
1. Убедитесь, что собрали PanVK с `-Dvulkan-drivers=panfrost`
2. Подгрузите драйвер через `VK_ICD_FILENAMES`
3. Используйте режим `-Dvulkan-drivers=swrast` для отладки

## Проблема: `MediaTek Helio G95` не видит GPU

**Решение**: 
```bash
# Проверка доступных устройств
ls -la /dev/dri/
# Если /dev/dri/renderD128 отсутствует, используйте SW winsys
# Настройка в скрипте уже включает SW winsys
```

## Ошибка: `meson: command not found`

**Решение**:
```bash
pkg install meson
```

## Ошибка: `ninja: command not found`

**Решение**:
```bash
pkg install ninja
```

## Ошибка: `python: command not found`

**Решение**:
```bash
pkg install python
```

## Сборка очень медленная

**Причина**: Недостаточно памяти или процессор перегружен.

**Решение**:
- Закройте все лишние приложения
- Используйте ф��аг `-j2` вместо `-j$(nproc)` в скрипте
- Увеличьте пространство своп-памяти

## Ошибка при загрузке драйвера в shadPS4

**Проверка 1**: Убедитесь, что драйвер собран с Vulkan:
```bash
ls -la $PREFIX/panfrost/lib/ | grep vulkan
```

**Проверка 2**: Проверьте путь к ICD-файлу:
```bash
cat ~/panfrost.icd
```

**Проверка 3**: Проверьте переменные окружения:
```bash
echo $VK_ICD_FILENAMES
echo $LD_LIBRARY_PATH
```
