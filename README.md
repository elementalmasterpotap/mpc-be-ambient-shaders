<div align="center">
  <img src="logo/Gemini_Generated_Image_7b7rav7b7rav7b7r-topaz-lighting-upscale-2x-text-sharpen-denoise.png" width="460" alt="MPC-BE Ambient Glow — Забудь про чёрные полосы" />

  <br><br>

  **Программный Ambilight для MPC-BE**<br>
  Живые цвета · ACES tone mapping · Плёночный ореол · Без лишнего железа

  <br>

  [![](https://img.shields.io/badge/v1.2.4-0099CC?style=flat-square)](https://github.com/elementalmasterpotap/mpc-be-ambient-shaders/releases)
  [![](https://img.shields.io/badge/Windows-0078D6?style=flat-square&logo=windows&logoColor=white)](https://github.com/Aleksoid1978/MPC-BE)
  [![](https://img.shields.io/badge/DirectX%209%20·%20SM%203.0-FF7B00?style=flat-square)](#требования)
  [![](https://img.shields.io/badge/лицензия-MIT-22AA44?style=flat-square)](LICENSE)

  <br>

  **[⬇ MPC-BE.Ambient.Lighting.v1.2.4.zip](https://github.com/elementalmasterpotap/mpc-be-ambient-shaders/releases/download/v1.2.4/MPC-BE.Ambient.Lighting.v1.2.4.zip)** — шейдер, GUI-установщик, консольные скрипты
</div>

---

Заполняет чёрные полосы вокруг 4:3 и 21:9 видео цветным свечением с краёв кадра — в реальном времени, на GPU, без дополнительного железа.

Не просто размытие полосы. Полноценная постобработка: живые цвета, кино-компрессия яркости, плёночный ореол, виньетка, хроматическая аберрация. Детектор сам видит где полосы — ничего не нужно настраивать вручную.

---

## Установка

Проще всего — запустить **`AmbientGlow_Setup.exe`**. Тёмное окно, кнопка «Установить», готово.

Или через консоль:

```cmd
install.cmd
```

```powershell
.\install.ps1            # с меню
.\install.ps1 -NoPrompt  # тихий режим, для скриптов
```

Шейдеры устанавливаются в `%APPDATA%\MPC-BE\Shaders\`.

---

## Включение в MPC-BE

```
View  →  Shader  →  Post-Processing
```

Выбрать `AmbientGlow_SM3_Ready.hlsl`, нажать OK. Эффект применяется сразу, без перезапуска.

> **Рекомендуется [ночной билд MPC-BE](https://github.com/Aleksoid1978/MPC-BE/wiki/Nightly-builds)** — в стабильных релизах иногда баги с шейдерами постобработки.

---

## Что делает шейдер

| Эффект | Что видишь |
|---|---|
| Ambilight-заливка | Цвет с краёв кадра растекается по чёрным полосам |
| Vibrance | Живые насыщенные цвета — не серые, не выцветшие |
| ACES tone mapping | Кино-компрессия яркости: нет пересветов, нет серой каши |
| Тёплое свечение | Плёночный ореол у шва между видео и полосой |
| Виньетка | Лёгкое затемнение углов |
| Хроматическая аберрация | Лёгкое R/B расхождение к углам — как настоящая линза |
| Вертикальный градиент | Верх полос чуть темнее, низ теплее — глубина |
| Lens dirt | Процедурное пятнение: почти невидимо, но добавляет фактуру |

**Тёмная сцена** — свечение подавляется автоматически, полосы остаются чёрными.
**Нет полос** — нет эффекта. Детектор не гадает.

---

## Кастомизация

Хочешь теплее, холоднее, ярче, мягче — смотри **[VIBE.md](VIBE.md)**. Там маппинг «хочу...» → какие константы менять. Описываешь желаемое AI-ассистенту, он правит шейдер, ты деплоишь и смотришь.

---

## Требования

- Windows
- MPC-BE 1.5.6+ (рекомендуется ночной билд)
- DirectX 9.0c+
- GPU Shader Model 3.0+

---

## Удаление

Через `AmbientGlow_Setup.exe` кнопка «Удалить», или:

```powershell
.\uninstall.ps1
```

---

## Откат

```powershell
# К предыдущему деплою (автоматически сохраняется при каждой установке):
cp docs/ProfessionalLighting_SM3.prev.hlsl shaders/ProfessionalLighting_SM3.hlsl
.\install.ps1 -NoPrompt

# К эталонной стабильной версии:
cp docs/ProfessionalLighting_SM3.backup.hlsl shaders/ProfessionalLighting_SM3.hlsl
.\install.ps1 -NoPrompt
```

---

## Разработка

- [`docs/DEVELOPMENT_RULES.md`](docs/DEVELOPMENT_RULES.md) — архитектурные решения, почему именно так
- [`docs/PATCHNOTES.md`](docs/PATCHNOTES.md) — история изменений
- [`tasks/lessons.md`](tasks/lessons.md) — все поломки, откаты и выводы из них
