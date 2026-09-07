# 🎮 Realme 8 Vulkan Driver Build Guide
## PanVK/Panfork для Mali-G76 (Bifrost)

> **Цель проекта**: Собрать и интегрировать open-source Vulkan-драйвер PanVK для вашего Realme 8 (Mali-G76 MC4) и запустить эмулятор shadPS4 с полноценной графикой.

---

## 📱 Спецификация устройства

| Параметр | Значение |
|----------|----------|
| **Устройство** | Realme 8 |
| **Чипсет** | MediaTek Helio G95 |
| **GPU** | ARM Mali-G76 MC4 |
| **Архитектура GPU** | Bifrost (v7) |
| **Android** | 11/12 (Stock) |
| **Доступ** | Без root |

---

## 🧬 Почему это сложно?

### Проблема
1. **Проприетарный драйвер ARM**: Стоковый Mali-драйвер не предоставляет полную поддержку Vulkan 1.3
2. **Блокировка `/dev/dri`**: Android запрещает приложениям на��рямую обращаться к GPU без специальных разрешений
3. **Отсутствие модуля ядра**: На стоковой прошивке нет open-source модуля `panfrost.ko`
4. **Архитектурные ограничения**: Bifrost — это старая архитектура (2018), и поддержка open-source может быть нестабильной

### Решение
Используем комбинацию:
- **Panfork** — open-source драйвер от сообщества (начальный тест)
- **PanVK** — Vulkan-фронтенд для Panfrost (финальная цель)
- **Termux** — окружение для сборки и тестирования
- **Специальные обходные пути** — заглушки от проекта `PanVK-Mali-Android-Stubs` для обхода системных блокировок

---

## 📚 Ключевые репозитории

| Проект | Назначение | Статус |
|--------|-----------|--------|
| [`PanVK-Mali-Android-Stubs`](https://github.com/PanVK-Mali-Android-Stubs) | Экспериментальные сборки с обходными путями | ⚠️ Для Valhall, адаптируем для Bifrost |
| [`tokokudo/panfork`](https://github.com/tokokudo/panfork) | Готовый пакет Panfork для Termux | ✅ Базовое тестирование |
| [`Saikatsaha1996/mesa-Panfrost-G610`](https://github.com/Saikatsaha1996/mesa-Panfrost-G610) | Исходники Panfork с G610 | ✅ Основа для сборки |
| [`coffincolors/mesa-Panfork-android`](https://github.com/coffincolors/mesa-Panfork-android) | Инструкции по сборке | ✅ Шаблон конфигурации |

---

## 🛠️ План проекта

### Этап 1: Подготовка окружения (Шаг 1-3)
- [ ] Установка Termux и Termux-X11
- [ ] Настройка Android NDK
- [ ] Подготовка инструментов сборки (Meson, Ninja)

### Этап 2: Тестирование OpenGL (Шаг 4-5)
- [ ] Сборка Panfork (OpenGL-драйвер)
- [ ] Тестирование с `glxgears` и `glxinfo`
- [ ] Диагностика ошибок на Bifrost

### Этап 3: Переход на Vulkan (Шаг 6-7)
- [ ] Сборка PanVK с поддержкой Bifrost
- [ ] Тестирование на простых Vulkan-демках
- [ ] Интеграция с shadPS4

### Этап 4: Оптимизация (Шаг 8+)
- [ ] Profiling производительности
- [ ] Отладка ошибок `syncobj wait timeout`
- [ ] Конфигурация для игр

---

## ⚠️ Известные ограничения Bifrost

| Ограничение | Описание | Влияние |
|-------------|---------|--------|
| **Низкая производительность** | ~1 FPS на сложных сценах | Игры будут медленными, но работать должны |
| **Syncobj timeout** | Job Manager не всегда корректно синхронизирует задания | Может привести к зависаниям, нужна отладка |
| **KRAID не поддерживает Bifrost** | Новый компилятор только для Valhall | Используем старый Bifrost-компилятор |
| **Старая архитектура** | Bifrost — 2018 год, мало активной разработки | Меньше оптимизаций, больше проблем |

**Несмотря на это, проект осуществим!** Просто нужна терпеливая отладка.

---

## 🚀 Быстрый старт

### Для нетерпеливых (5 минут)
```bash
# На Realme 8 в Termux:
pkg install git termux-x11
git clone https://github.com/kamnevdima1220006-tech/realme8-vulkan-driver-build
cd realme8-vulkan-driver-build
bash scripts/setup-termux.sh
bash scripts/build.sh
```

### Подробный путь (1-2 часа)
1. Прочитайте `docs/termux-setup.md`
2. Установите зависимости вручную
3. Следуйте инструкциям в `scripts/build.sh` пошагово
4. Диагностируйте ошибки с помощью `docs/troubleshooting.md`

---

## 📁 Структура репозитория

```
realme8-vulkan-driver-build/
├── README.md                    # Этот файл
├── scripts/
│   ├── setup-termux.sh         # Установка зависимостей
│   ├── build.sh                # Основной скрипт сборки Panfork
│   ├── build-vulkan.sh         # Сборка PanVK (после OpenGL)
│   └── test-driver.sh          # Тестирование драйвера
├── docs/
│   ├── termux-setup.md         # Подробная настройка Termux
│   ├── architecture.md         # Архитектура PanVK/Panfork
│   ├── troubleshooting.md      # Решение типичных ошибок
│   ├── shadps4-integration.md  # Интеграция с эмулятором
│   └── bifrost-specifics.md    # Особенности Bifrost
├── patches/
│   └── bifrost-fixes.patch     # Патчи для совместимости
└── config/
    └── meson-cross-file.ini    # Кросс-компиляция ARM64
```

---

## 🔍 Диагностика перед началом

Выполните эту команду на Realme 8 в Termux, чтобы проверить базовую совместимость:

```bash
# Информация о GPU (требует root или специальных разрешений)
getprop ro.board.platform
getprop ro.hardware.keystore
cat /proc/device-tree/soc/gpu@* 2>/dev/null || echo "GPU info not accessible"

# Проверка Vulkan
vulkan-info 2>/dev/null || echo "Vulkan tools not installed"
```

---

## 📞 Контакты и поддержка

- **Проект**: https://github.com/kamnevdima1220006-tech/realme8-vulkan-driver-build
- **Issues**: Сообщайте о проблемах в разделе Issues
- **Обсуждение**: Используйте Discussions для вопросов
- **Исходные источники**:
  - Mesa Panfrost: https://gitlab.freedesktop.org/mesa/mesa
  - PanVK: https://gitlab.freedesktop.org/panfrost/mesa/-/tree/panvk-staging
  - ARM Mali Bifrost: https://developer.arm.com/products/graphics-and-multimedia/mali-gpus

---

## 📜 Лицензия

Проект использует код из Mesa (MIT/X11), Panfrost (MIT) и других open-source проектов.
Подробнее см. LICENSE файл.

---

**Готовы начать? Переходите к `docs/termux-setup.md` для пошагового руководства!**
