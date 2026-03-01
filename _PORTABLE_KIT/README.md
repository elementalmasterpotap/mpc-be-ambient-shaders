# _PORTABLE_KIT — Портативный стартер для новых проектов

Всё что нужно чтобы начать новый проект с тем же воркфлоу, стилем, душой и вайбом.
Выкачан из MPC-BE Ambient Shaders — первого проекта где это всё было обкатано.

---

## Структура

```
_PORTABLE_KIT/
├── README.md                    ← ты здесь
│
├── CLAUDE_BASE.md               ← базовый CLAUDE.md для нового проекта
│                                   скопируй в корень нового проекта как CLAUDE.md
│                                   и допиши специфику
│
├── rules/
│   ├── communication.md         ← стиль общения — копируй без изменений
│   ├── workflow_universal.md    ← цикл патч→деплой→патчнот→коммит
│   ├── github_ops.md            ← GitHub без gh CLI (чистый API)
│   └── vibe_coding.md           ← концепция вайбкодинга (адаптируй под домен)
│
├── memory/
│   ├── MEMORY_TEMPLATE.md       ← шаблон MEMORY.md для нового проекта
│   └── lessons_universal.md     ← уроки не привязанные к HLSL
│
└── templates/
    ├── PATCHNOTES_template.md   ← формат патчнота
    ├── VIBE_template.md         ← шаблон VIBE.md
    └── TELEGRAM_POST_template.md ← шаблон поста в Telegram
```

---

## Как использовать

### 1. Новый проект — минимальный старт
```
cp _PORTABLE_KIT/CLAUDE_BASE.md     CLAUDE.md
cp _PORTABLE_KIT/rules/             .claude/rules/
cp _PORTABLE_KIT/memory/MEMORY_TEMPLATE.md  ~/.claude/memory/MEMORY.md
```
Открываешь `CLAUDE.md`, дописываешь секцию `## Проект` и `## Активный файл` под специфику.

### 2. GitHub — новый репо
Смотри `rules/github_ops.md` — там весь процесс от `git init` до релиза с ассетами.

### 3. Патчнот
Смотри `templates/PATCHNOTES_template.md`.

### 4. Telegram пост
Смотри `templates/TELEGRAM_POST_template.md`.

---

## Что НУЖНО адаптировать под новый проект
- `CLAUDE.md` → секция `## Проект`, `## Активный файл`, метафоры
- `VIBE_template.md` → маппинг желания → что трогает AI (домен-специфично)
- `MEMORY_TEMPLATE.md` → архитектура, ключевые файлы, критические правила

## Что копируется БЕЗ изменений
- `rules/communication.md` — стиль и тон всегда одинаковый
- `rules/github_ops.md` — GitHub API одинаков для всех проектов
- `templates/PATCHNOTES_template.md` — формат универсальный
