# MPC-BE Ambient Shaders
# Sync: ~/.claude/CLAUDE.md → .claude/universal-rules.md | ~/.claude/memory/MEMORY.md → .claude/universal-memory.md

## Проект
HLSL шейдеры постобработки для MPC-BE. Ambilight: letterbox/pillarbox полосы = свечение с краёв кадра.

## Активный шейдер
`shaders/ProfessionalLighting_SM3.hlsl`

## Детектор — ТОЛЬКО ЧЕРЕЗ xBorder/yBorder
`IsDarkColumn`/`IsDarkRow` (топология/координаты/веса/пороги `sideDark>0.54`/`topDark>0.54`) — заморожены. Трижды сломано.
Не работает → только `xBorder`/`yBorder` (~строки 795–825).
Откат к предыдущей: `cp docs/ProfessionalLighting_SM3.prev.hlsl shaders/ProfessionalLighting_SM3.hlsl && .\install.ps1 -NoPrompt`
Откат к эталону: `cp docs/ProfessionalLighting_SM3.backup.hlsl shaders/ProfessionalLighting_SM3.hlsl && .\install.ps1 -NoPrompt`
`prev.hlsl` — авто-обновляется при каждом install.ps1.

## Перед началом работы
`tasks/lessons.md` · `VIBE.md` (маппинг запросов→константы)

## Правила
`.claude/rules/hlsl.md` — ps_3_0, антипаттерны, чеклисты (при работе с shaders/)
`.claude/rules/workflow.md` — деплой, патчноты
`.claude/rules/preferences.md` — цвета, структура
Правила правил → `~/.claude/CLAUDE.md` + `~/.claude/memory/MEMORY.md`

## Метафоры (этот проект)
CLAUDE.md=гримуар · баг=мини-босс/финальный босс · деплой=спелл · рефакторинг=левел-ап
откат=phoenix down · ps_3_0=мана-кап · ALU-эффект=пассивный скилл · детектор сломался=TPK
