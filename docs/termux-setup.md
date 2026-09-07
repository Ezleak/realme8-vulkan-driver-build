# Настройка Termux для сборки драйвера

## 1. Установка Termux

Скачайте **Termux** и **Termux-X11** из официальных репозиториев:
- Termux: https://f-droid.org/packages/com.termux/
- Termux-X11: https://f-droid.org/packages/com.termux.x11/

## 2. Базовые разрешения

Запустите Termux и дайте все запрашиваемые разрешения (особенно доступ к хранилищу).

## 3. Запуск скрипта настройки

```bash
cd ~/realme8-vulkan-driver-build
chmod +x scripts/setup-termux.sh
./scripts/setup-termux.sh
```

## 4. Применение изменений

```bash
source ~/.bashrc
```

## 5. Проверка окружения

```bash
echo $ANDROID_NDK_HOME   # Должен показать путь к NDK
```

## 6. Запуск X-сервера (для графики)

В отдельном терминале:
```bash
termux-x11 &
```

## 7. Установка дополнительных пакетов (если нужно)

```bash
pkg install xfce4-terminal  # Терминал с GUI
pkg install firefox         # Браузер для проверки WebGL
```

## 8. Запуск сборки драйвера

После завершения настройки:

```bash
cd ~/realme8-vulkan-driver-build
chmod +x build_and_test.sh
./build_and_test.sh
```

Сборка займет около 20-30 минут в зависимости от производительности вашего устройства.
