<div align="center">
  <img src="logo/Gemini_Generated_Image_7b7rav7b7rav7b7r-topaz-lighting-upscale-2x-text-sharpen-denoise.png" width="460" alt="MPC-BE Ambient Glow — Software Ambilight for MPC-BE" />

  <br><br>

  [![](https://img.shields.io/badge/v1.2.4-0099CC?style=flat-square)](https://github.com/elementalmasterpotap/mpc-be-ambient-shaders/releases)
  [![](https://img.shields.io/badge/Windows-0078D6?style=flat-square&logo=windows&logoColor=white)](https://github.com/Aleksoid1978/MPC-BE)
  [![](https://img.shields.io/badge/DirectX%209%20·%20SM%203.0-FF7B00?style=flat-square)](#requirements)
  [![](https://img.shields.io/badge/license-MIT-22AA44?style=flat-square)](LICENSE)
  [![](https://img.shields.io/badge/Telegram-channel-26A5E4?style=flat-square&logo=telegram&logoColor=white)](https://t.me/potap_attic)

  <br>

  **[⬇ MPC-BE.Ambient.Lighting.v1.2.4.zip](https://github.com/elementalmasterpotap/mpc-be-ambient-shaders/releases/download/v1.2.4/MPC-BE.Ambient.Lighting.v1.2.4.zip)**

  <br>

  <details>
  <summary>🇬🇧 English</summary>

  **Software Ambilight for MPC-BE — fills black bars with color glow from the frame edges.**

  Not just a blur. Full post-processing pipeline: vivid colors, cinematic tone mapping, film glow, vignette, chromatic aberration. The detector finds black bars automatically — no manual setup needed.

  ## Installation

  Run **`AmbientGlow_Setup.exe`** — dark window, click Install, done.

  Or via console:

  ```cmd
  install.cmd
  ```

  ```powershell
  .\install.ps1            # with menu
  .\install.ps1 -NoPrompt  # silent mode
  ```

  Shaders install to `%APPDATA%\MPC-BE\Shaders\`.

  ## Enabling in MPC-BE

  ```
  View → Shader → Post-Processing
  ```

  Select `AmbientGlow_SM3_Ready.hlsl`, click OK. Effect applies instantly, no restart needed.

  > **[Nightly build of MPC-BE](https://github.com/Aleksoid1978/MPC-BE/wiki/Nightly-builds) recommended** — stable releases sometimes have shader bugs.

  ## What the shader does

  | Effect | What you see |
  |---|---|
  | Ambilight fill | Frame edge colors spread across black bars |
  | Vibrance | Vivid saturated colors — not grey, not washed out |
  | ACES tone mapping | Cinematic brightness compression: no blown highlights |
  | Warm glow | Film halo at the border between video and bars |
  | Vignette | Subtle corner darkening |
  | Chromatic aberration | Slight R/B shift toward corners — like a real lens |
  | Vertical gradient | Top of bars slightly darker, bottom warmer — depth |
  | Lens dirt | Procedural texture: barely visible, adds grain |

  **Dark scene** — glow suppressed automatically, bars stay black.
  **No bars** — no effect. The detector doesn't guess.

  ## Customization

  Want warmer, cooler, brighter, softer — see **[VIBE.md](VIBE.md)**. It maps "I want..." to which constants to change. Describe what you want to an AI assistant, it edits the shader, you deploy and check.

  ## Requirements

  - Windows
  - MPC-BE 1.5.6+ (nightly build recommended)
  - DirectX 9.0c+
  - GPU Shader Model 3.0+

  ## Uninstall

  Via `AmbientGlow_Setup.exe` → Uninstall button, or:

  ```powershell
  .\uninstall.ps1
  ```

  ## Rollback

  ```powershell
  # To previous deploy (saved automatically on each install):
  cp docs/ProfessionalLighting_SM3.prev.hlsl shaders/ProfessionalLighting_SM3.hlsl
  .\install.ps1 -NoPrompt

  # To stable baseline:
  cp docs/ProfessionalLighting_SM3.backup.hlsl shaders/ProfessionalLighting_SM3.hlsl
  .\install.ps1 -NoPrompt
  ```

  ## Development

  - [`docs/DEVELOPMENT_RULES.md`](docs/DEVELOPMENT_RULES.md) — architecture decisions
  - [`docs/PATCHNOTES.md`](docs/PATCHNOTES.md) — changelog
  - [`tasks/lessons.md`](tasks/lessons.md) — all breakages, rollbacks and lessons

  </details>

  <details open>
  <summary>🇷🇺 Русский</summary>

  **Программный Ambilight для MPC-BE — заполняет чёрные полосы цветным свечением с краёв кадра.**

  Не просто размытие. Полноценная постобработка: живые цвета, кино-компрессия яркости, плёночный ореол, виньетка, хроматическая аберрация. Детектор сам видит где полосы — ничего настраивать вручную не нужно.

  ## Установка

  Запустить **`AmbientGlow_Setup.exe`** — тёмное окно, кнопка «Установить», готово.

  Или через консоль:

  ```cmd
  install.cmd
  ```

  ```powershell
  .\install.ps1            # с меню
  .\install.ps1 -NoPrompt  # тихий режим, для скриптов
  ```

  Шейдеры устанавливаются в `%APPDATA%\MPC-BE\Shaders\`.

  ## Включение в MPC-BE

  ```
  View → Shader → Post-Processing
  ```

  Выбрать `AmbientGlow_SM3_Ready.hlsl`, нажать OK. Эффект применяется сразу, без перезапуска.

  > **Рекомендуется [ночной билд MPC-BE](https://github.com/Aleksoid1978/MPC-BE/wiki/Nightly-builds)** — в стабильных релизах иногда баги с шейдерами постобработки.

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

  ## Кастомизация

  Хочешь теплее, холоднее, ярче, мягче — смотри **[VIBE.md](VIBE.md)**. Там маппинг «хочу...» → какие константы менять. Описываешь желаемое AI-ассистенту, он правит шейдер, ты деплоишь и смотришь.

  ## Требования

  - Windows
  - MPC-BE 1.5.6+ (рекомендуется ночной билд)
  - DirectX 9.0c+
  - GPU Shader Model 3.0+

  ## Удаление

  Через `AmbientGlow_Setup.exe` кнопка «Удалить», или:

  ```powershell
  .\uninstall.ps1
  ```

  ## Откат

  ```powershell
  # К предыдущему деплою (автоматически сохраняется при каждой установке):
  cp docs/ProfessionalLighting_SM3.prev.hlsl shaders/ProfessionalLighting_SM3.hlsl
  .\install.ps1 -NoPrompt

  # К эталонной стабильной версии:
  cp docs/ProfessionalLighting_SM3.backup.hlsl shaders/ProfessionalLighting_SM3.hlsl
  .\install.ps1 -NoPrompt
  ```

  ## Разработка

  - [`docs/DEVELOPMENT_RULES.md`](docs/DEVELOPMENT_RULES.md) — архитектурные решения, почему именно так
  - [`docs/PATCHNOTES.md`](docs/PATCHNOTES.md) — история изменений
  - [`tasks/lessons.md`](tasks/lessons.md) — все поломки, откаты и выводы из них

  </details>

</div>
