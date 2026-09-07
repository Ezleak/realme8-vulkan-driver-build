# Архитектура PanVK и Panfrost для Mali-G76 Bifrost

## 1. Обзор архитектуры

### Стек графического конвейера

```
Приложение (shadPS4, OpenGL app)
    ↓
[Vulkan API] или [OpenGL API]
    ↓
┌─────────────────────────────────────┐
│     PanVK (Vulkan Frontend)         │ ← Конвертирует Vulkan в GPU команды
│  или                                 │
│  Gallium (OpenGL Frontend)          │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  Panfrost Compiler (JM Backend)     │ ← Генерирует Job Manager коды для Bifrost
│  (Job Manager для v7)                │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  Kernel Driver (panfrost.ko)        │ ← На стоке НЕТ, используем SW winsys
│  или SW winsys (наш случай)         │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  kbase (ARM Mali Kernel Module)     │ ← Стоковый драйвер, всегда есть
└─────────────────────────────────────┘
    ↓
[GPU Mali-G76 MC4]
```

## 2. Job Manager (JM) Backend для Bifrost

### Что такое Job Manager?

Job Manager — это архитектура командной очереди для GPU Bifrost (v7). Она описывает, как отправлять задания на GPU через драйвер.

### Структура Job Descriptor

```c
struct mali_job_descriptor_header {
    uint32_t job_type;        // Тип задания (COMPUTE, FRAGMENT, VERTEX и т.д.)
    uint32_t job_index;       // Индекс в очереди
    uint32_t fault_barrier;   // Флаг преграды при ошибке
    uint32_t job_dependency_mask;  // Зависимости от других заданий
};
```

### Типы заданий
- **COMPUTE**: Вычислительные шейдеры
- **FRAGMENT**: Фрагментные (пиксельные) шейдеры
- **VERTEX**: Вершинные шейдеры
- **TILER**: Подготовка тайлов (tile list creation)

## 3. SW Winsys (Software Windowing System)

### Проблема на стоке

На стоковой прошивке Realme 8:
- ✅ Есть проприетарный драйвер `kbase`
- ✅ Доступен `/dev/mali0` (или похожий)
- ❌ НЕТ open-source модуля `panfrost.ko`
- ❌ Прямой доступ к `/dev/dri/*` заблокирован для пользовательских приложений

### Решение: SW Winsys

SW Winsys — это программный backend, который:
1. Работает через `kbase` (проприетарный)
2. Не требует `/dev/dri/*` (используется `ioctl` на дру��ие устройства)
3. Позволяет создавать виртуальные "окна" в памяти (off-screen rendering)
4. Совместим со стоковыми прошивками

```bash
# Включение SW winsys в Meson
-Dgallium-winsys=surfaceless  # или kmsro для DRM
```

## 4. Bifrost vs Valhall

| Фактор | Bifrost (v7) | Valhall (v9+) |
|--------|-------------|---------------|
| **Год выпуска** | 2018 | 2020+ |
| **Бэкенд** | Job Manager (JM) | Command Stream Frontend (CSF) |
| **Поддержка в PanVK** | ✅ Полная | ✅ Полная (лучше) |
| **Производительность** | Низкая (~1 FPS) | Высокая (10+ FPS) |
| **Поддержка Vulkan** | 1.0 - 1.1 | 1.1 - 1.3 |
| **Примеры GPU** | Mali-G76, G72 | Mali-G610, G710, G715 |

**Ваша ситуация**: Mali-G76 → Bifrost → JM Backend

## 5. Panfrost компилятор

### Этапы компиляции

```
IR (промежуточный код из шейдера)
    ↓
[Panfrost NIR Pass] ← Оптимизация кода
    ↓
[JM Code Generator] ← Генерирует машинный код для Bifrost
    ↓
[Panfrost Binary] ← Готовые инструкции для GPU
```

### Компилятор vs KRAID

| Компонент | Назначение | Для какой архитектуры |
|-----------|-----------|---------------------|
| **Panfrost Compiler** | Старый компилятор | Bifrost, Midgard |
| **KRAID** | Новый оптимизирующий компилятор | Только Valhall v9+ |
| **LLVM** | Альтернативный бэкенд | Не используется |

**Важно**: На Bifrost используется старый Panfrost Compiler. KRAID не совместим.

## 6. Syncobj и Job Synchronization

### Проблема: `syncobj wait timeout`

Sync Objects (syncobj) — это механизм синхронизации между GPU и CPU.

```c
// Пример из кода Panfrost
struct panfrost_syncobj {
    uint64_t kbase_handle;  // Handle в ядре
    uint32_t seqno;         // Sequence number
};
```

Проблема на Bifrost:
- Job Manager не всегда корректно сигнализирует об окончании задания
- CPU ждет сигнала от GPU, но он не приходит
- Результат: таймаут и зависание

### Решение

```c
/* Увеличение таймаута для Bifrost */
if (pan_device_gpu_id(dev) == 0x7500) {  // Mali-G76
    ctx->syncobj_timeout = 1000000000ULL;  // 1 секунда вместо 10ms
}
```

## 7. GPU Memory Management

### Типы памяти

```
┌─────────────────────────────────────┐
│   Unified Memory (UVM)              │ ← CPU и GPU видят один адрес
│   Используется на современных ARM   │
└─────────────────────────────────────┘
         ↓
┌──────────────────┬──────────────────┐
│  CPU Portion     │  GPU Portion     │
│  (System RAM)    │  (VRAM на GPU)   │
└──────────────────┴──────────────────┘
```

### Управление памятью в Panfrost

```bash
# Структура BO (Buffer Object)
struct panfrost_bo {
    struct panfrost_device *dev;
    uint64_t gpu_va;        // GPU virtual address
    void *cpu;              // CPU mapping
    uint32_t size;
    uint32_t flags;
};
```

## 8. Расширения Vulkan на Mali-G76

### П��ддерживаемые расширения

```bash
# На Mali-G76 Bifrost доступны:
VK_KHR_surface
VK_KHR_swapchain
VK_KHR_synchronization2
VK_KHR_maintenance1
VK_EXT_debug_report
# И несколько других
```

### Отсутствующие расширения

shadPS4 может требовать:
```bash
VK_KHR_dynamic_rendering       # НЕТ на Bifrost
VK_EXT_extended_dynamic_state  # НЕТ на Bifrost
VK_KHR_ray_tracing            # НЕТ (требуется Valhall+)
```

Это может быть причиной проблем при запуске эмулятора.

## 9. Отладка на уровне ядра

### Если возникают проблемы, можно включить логирование:

```bash
# В compile-time
meson configure -Dpanfrost-debug=1

# Runtime
export PANFROST_DEBUG=all
export MESA_DEBUG=all
```

### Лог-файлы

```bash
# Логи будут выводиться в stderr
./build_and_test.sh 2> panfrost_debug.log
```

## 10. Дополнительные ресурсы

- [Panfrost Wiki](https://panfrost.freedesktop.org/)
- [Mesa Panfrost Code](https://gitlab.freedesktop.org/mesa/mesa/-/tree/main/src/panfrost)
- [ARM Mali Bifrost Specification](https://developer.arm.com/-/media/Files/pdf/graphics/mali-bifrost-gpu-architecture.pdf)
- [Khronos Vulkan Specification](https://www.khronos.org/vulkan/)
