---
paths:
  - "shaders/**/*.hlsl"
---

# HLSL — детали шейдеров

## Архитектура
main() → IsDarkColumn/IsDarkRow → BuildSideFillSM3() или BuildTopFillSM3()
BuildFill: BlurAniso13/9 → EdgePaletteSide → CleanEdgeColor → GradeAmbientSM3 → WarmHalation → ArtifactGuardSM3

## USER TWEAKABLES (~строки 12–65)
| Константа | Знач. | Эффект ↑ |
|---|---|---|
| `GRADE_VIBRANCE_NEAR` | 1.42 | насыщеннее у края видео |
| `GRADE_VIBRANCE_FAR` | 1.20 | насыщеннее у края экрана |
| `GRADE_GAIN_NEAR` | 1.52 | ярче у края видео |
| `GRADE_GAIN_FAR` | 1.22 | ярче у края экрана |
| `GRADE_SAT_LIMIT_NEAR` | 0.74 | сдерживает neon-blowout у края |
| `GRADE_SAT_LIMIT_FAR` | 0.56 | нейтральнее у края экрана |
| `GRADE_FINAL_BRIGHT_NEAR` | 1.02 | итоговая яркость near |
| `GRADE_FINAL_BRIGHT_FAR` | 0.74 | итоговая яркость far |
| `FADE_DECAY_RATE` | 2.8 | быстрее затухание к краю |
| `FADE_FLOOR_LIGHT` | 0.18 | мин. яркость в светлой сцене |
| `FADE_FLOOR_DARK` | 0.10 | мин. яркость в тёмной сцене |
| `HALATION_AMOUNT_BASE` | 0.045 | warm-glow у яркого края |
| `HALATION_AMOUNT_FAR` | 0.035 | свечение дальше от края |
| `HALATION_DARK_SUPPRESS` | 0.45 | подавление halation в тёмном |
| `VIGNETTE_BLEND` | 0.40 | затемнение углов |
| `VERT_GRAD_AMOUNT` | 0.38 | верх темнее низа |
| `CHROMA_ABERR_AMOUNT` | 0.10 | R/B split в углах |
| `LENS_DIRT_AMOUNT` | 0.016 | шум/пятна (0.010–0.022) |
| `ENABLE_VIGNETTE` | 1 | вкл/выкл виньетку |
| `ENABLE_VERT_GRADIENT` | 1 | вкл/выкл вертикальный градиент |
| `ENABLE_CHROMA_ABERR` | 1 | вкл/выкл хроматику |
| `ENABLE_LENS_DIRT` | 1 | вкл/выкл lens dirt |
| `ENABLE_WARM_HALATION` | 1 | вкл/выкл warm glow |
| `ENABLE_TPDF_DITHER` | 1 | вкл/выкл dithering |

## ps_3_0 лимиты
Детектор + блюр ≈ 9–12 tex2D. ALU — безопасно в любом количестве. Новый tex2D → по одному, проверить детектор.
Признак поломки: полосы не заполняются.

## Что можно свободно
GradeAmbientSM3 · ArtifactGuardSM3 · WarmHalation · VibranceBoost · BlurAniso9/13 веса
EdgePaletteSide/Top · CleanEdgeColor · SatGuard · SaturationLimit · MidContrast
fade/spreadAmt/seam/grain · ALU-эффекты: Vignette/ChromaticAberration/VerticalGradient/LensDirt

## Осторожно
centerLum: порог >0.02, max из 5 точек · Seam: smoothstep(0.002, 0.065, n) · hardBandSide/TBuild

## Переменные BuildFill
n: 0=край видео/1=край экрана · edgeLum: яркость края · darkScene: 0=светлая/1=тёмная
streakRisk: риск полос · darkSuppress: подавление нас. в тёмном · fadeFloor: мин. яркость у края

## Вайбкодинг: запрос → константа
| Запрос | Константа | ↑↓ |
|---|---|---|
| "теплее" | blue в warm tint + `HALATION_AMOUNT_BASE` | blue↓ halation↑ |
| "холоднее" | blue в warm tint + `HALATION_AMOUNT_BASE` | blue↑ halation↓ |
| "насыщеннее" | `GRADE_VIBRANCE_NEAR/FAR` | ↑ |
| "ярче у края видео" | `GRADE_GAIN_NEAR`, `GRADE_FINAL_BRIGHT_NEAR` | ↑ |
| "ярче у края экрана" | `GRADE_GAIN_FAR`, `GRADE_FINAL_BRIGHT_FAR` | ↑ |
| "слабее весь эффект" | `GRADE_GAIN_NEAR/FAR`, `GRADE_FINAL_BRIGHT_NEAR/FAR` | ↓ |
| "мягче затухание" | `FADE_DECAY_RATE` | ↓ |
| "меньше в тёмном" | `HALATION_DARK_SUPPRESS` | ↑ |
| "убрать виньетку" | `ENABLE_VIGNETTE` | 0 |
| "убрать хроматику" | `ENABLE_CHROMA_ABERR` | 0 |
| "убрать градиент" | `ENABLE_VERT_GRADIENT` | 0 |
| "убрать grain" | `ENABLE_LENS_DIRT` | 0 |
| "убрать halation" | `ENABLE_WARM_HALATION` | 0 |
| "меньше затемнения сверху" | `VERT_GRAD_AMOUNT` | ↓ |
| "меньше R/B разброса" | `CHROMA_ABERR_AMOUNT` | ↓ |

## Антипаттерны (→ tasks/lessons.md)
| # | Антипаттерн | Симптом | L# |
|---|---|---|---|
| A1 | 2+ функции с tex2D за раз | детектор ломается | L1 |
| A2 | Меняешь кол-во/координаты точек IsDarkColumn/IsDarkRow | детектор ломается | L2 |
| A3 | Меняешь веса в IsDarkColumn/IsDarkRow | детектор ломается | L3 |
| A4 | `if (lum > threshold)` в шейдере | branch penalty | L11 |
| A5 | `length(d)` для лимита насыщенности | неравномерный лимит | L7 |
| A6 | SoftClip + Filmic вместе | двойное пережатие | L10 |
| A7 | lumVib ДО десатурации | неправильный пивот vibrance | L9 |
| A8 | FADE_FLOOR_LIGHT>0.22 или DARK>0.12 | серый ореол | L5 |
| A9 | Меняешь IsDarkColumn/Row вместо xBorder/yBorder | детектор ломается | L3 |

## Верификация (грейдинг/эффекты)
1. `.\install.ps1 -NoPrompt`  2. 4:3 → бока светятся  3. нет серого/neon blowout  4. тёмная → не светятся

## Верификация детектора (ЭКСТРЕННО)
1. 4:3 в 16:9 → бока  2. 21:9 в 16:9 → верх/низ  3. тёмный кадр → не светятся
