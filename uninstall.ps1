$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$targetDir    = Join-Path $env:APPDATA "MPC-BE\Shaders"
$manifestPath = Join-Path $targetDir "ProfessionalLighting_InstallManifest.json"

# ─────────────────────────────────────────────────────────────
#  ЯЗЫК / LANGUAGE
# ─────────────────────────────────────────────────────────────
$Lang = if ((Get-WinSystemLocale).TwoLetterISOLanguageName -eq 'ru') { 'ru' } else { 'en' }

$T = if ($Lang -eq 'ru') { @{
    BannerTitle   = "M P C - B E   $([char]0x00B7)   У Д А Л Е Н И Е   Ш Е Й Д Е Р О В"
    BannerDesc    = "  $([char]0x00B7)  Удаляет шейдеры амбиент-подсветки из MPC-BE"
    FileListTitle = "  Будет удалено из:"
    NotInstalled  = "  (не установлен)"
    Warning       = "!  Шейдеры будут удалены из MPC-BE  !"
    BtnDelete     = "  [У] Удалить  "
    BtnCancel     = "  [О] Отмена  "
    HotkeyDelete  = 'у'
    HotkeyCancel  = 'о'
    NavHint       = "$([char]0x2190)$([char]0x2192) выбор   $([char]0x00B7)   Enter подтвердить   $([char]0x00B7)   У / О хоткей"
    RemoveTitle   = "У Д А Л Е Н И Е . . ."
    Removed       = "  +  {0}  — удалён"
    Skipped       = "  -  {0}  (не найден, пропущен)"
    DoneCount     = "Удалено файлов: {0}. Шейдеры деинсталлированы."
    NothingDone   = "Файлы шейдеров не найдены. Ничего не удалено."
    Reinstall     = "  Для повторной установки запустите:"
    ReinstallCmd  = "    install.cmd   или   .\install.ps1"
    Cancelled     = "Отмена. Шейдеры не тронуты."
    NoFolder      = "Папка шейдеров MPC-BE не найдена: $targetDir"
    WaitMsg       = "Закроется через {0} сек  ·  любая клавиша — выйти сейчас"
}} else { @{
    BannerTitle   = "M P C - B E   $([char]0x00B7)   S H A D E R   R E M O V A L"
    BannerDesc    = "  $([char]0x00B7)  Removes ambient lighting shaders from MPC-BE"
    FileListTitle = "  Will be removed from:"
    NotInstalled  = "  (not installed)"
    Warning       = "!  Shaders will be removed from MPC-BE  !"
    BtnDelete     = "  [D] Delete  "
    BtnCancel     = "  [C] Cancel  "
    HotkeyDelete  = 'd'
    HotkeyCancel  = 'c'
    NavHint       = "$([char]0x2190)$([char]0x2192) select   $([char]0x00B7)   Enter confirm   $([char]0x00B7)   D / C hotkey"
    RemoveTitle   = "R E M O V I N G . . ."
    Removed       = "  +  {0}  — removed"
    Skipped       = "  -  {0}  (not found, skipped)"
    DoneCount     = "Removed: {0} file(s). Shaders uninstalled."
    NothingDone   = "No shader files found. Nothing removed."
    Reinstall     = "  To reinstall, run:"
    ReinstallCmd  = "    install.cmd   or   .\install.ps1"
    Cancelled     = "Cancelled. Shaders untouched."
    NoFolder      = "MPC-BE shaders folder not found: $targetDir"
    WaitMsg       = "Closing in {0} sec  ·  any key to exit now"
}}

# ─────────────────────────────────────────────────────────────
#  СИМВОЛЫ РАМОК
# ─────────────────────────────────────────────────────────────
$cTL  = [char]0x2554  # ╔
$cTR  = [char]0x2557  # ╗
$cBL  = [char]0x255A  # ╚
$cBR  = [char]0x255D  # ╝
$cH   = [char]0x2550  # ═
$cV   = [char]0x2551  # ║
$cML  = [char]0x2560  # ╠
$cMR  = [char]0x2563  # ╣
$cTLs = [char]0x250C  # ┌
$cTRs = [char]0x2510  # ┐
$cBLs = [char]0x2514  # └
$cBRs = [char]0x2518  # ┘
$cHs  = [char]0x2500  # ─
$cVs  = [char]0x2502  # │

$W = 62

# ─────────────────────────────────────────────────────────────
#  ХЕЛПЕРЫ
# ─────────────────────────────────────────────────────────────
function Wait-KeyOrTimeout {
    param([int]$Seconds = 8)
    try { [Console]::CursorVisible = $true } catch {}
    for ($i = $Seconds; $i -gt 0; $i--) {
        Write-Host ("`r  " + ($T.WaitMsg -f $i) + "  ") -NoNewline -ForegroundColor DarkGray
        for ($ms = 0; $ms -lt 10; $ms++) {
            if ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null; Write-Host ""; return }
            Start-Sleep -Milliseconds 100
        }
    }
    Write-Host ""
}

function Pad-Center {
    param([string]$s, [int]$w)
    $pad = $w - $s.Length
    if ($pad -le 0) { return $s }
    return (' ' * [math]::Floor($pad / 2)) + $s + (' ' * ($pad - [math]::Floor($pad / 2)))
}

function Write-BoxLine {
    param(
        [string]$inner = "",
        [ConsoleColor]$fc = [ConsoleColor]::DarkRed,
        [ConsoleColor]$tc = [ConsoleColor]::Gray
    )
    Write-Host $cV -ForegroundColor $fc -NoNewline
    Write-Host $inner.PadRight($W) -ForegroundColor $tc -NoNewline
    Write-Host $cV -ForegroundColor $fc
}

function Write-BoxTop    { Write-Host ($cTL + ([string]$cH * $W) + $cTR) -ForegroundColor DarkRed }
function Write-BoxDiv    { Write-Host ($cML + ([string]$cH * $W) + $cMR) -ForegroundColor DarkRed }
function Write-BoxBottom { Write-Host ($cBL + ([string]$cH * $W) + $cBR) -ForegroundColor DarkRed }
function Write-BoxEmpty  { Write-BoxLine }

# ─────────────────────────────────────────────────────────────
#  СПИСОК ФАЙЛОВ
# ─────────────────────────────────────────────────────────────
function Get-FileList {
    $defaults = @(
        "ProfessionalLighting_SM3.hlsl",
        "ProfessionalLighting_SM3_Ready.hlsl",
        "ProfessionalLighting_InstallManifest.json"
    )
    if (Test-Path $manifestPath) {
        try {
            $m = Get-Content -Raw $manifestPath | ConvertFrom-Json
            if ($m.files) { return @($m.files) + @("ProfessionalLighting_InstallManifest.json") }
        } catch {}
    }
    return $defaults
}

# ─────────────────────────────────────────────────────────────
#  БАННЕР
# ─────────────────────────────────────────────────────────────
function Show-Banner {
    Write-BoxTop
    Write-BoxEmpty
    Write-BoxLine (Pad-Center $T.BannerTitle $W) DarkRed Yellow
    Write-BoxEmpty
    Write-BoxLine $T.BannerDesc DarkRed DarkGray
    Write-BoxEmpty
}

# ─────────────────────────────────────────────────────────────
#  ПАНЕЛЬ ФАЙЛОВ
# ─────────────────────────────────────────────────────────────
function Show-FileList {
    param([string[]]$files)
    Write-BoxDiv
    Write-BoxEmpty
    Write-BoxLine $T.FileListTitle DarkRed White
    Write-BoxLine "  $env:APPDATA\MPC-BE\Shaders\" DarkRed DarkGray
    Write-BoxEmpty
    foreach ($f in ($files | Select-Object -Unique)) {
        if (Test-Path (Join-Path $targetDir $f)) {
            Write-BoxLine "  $([char]0x00B7)  $f" DarkRed Gray
        } else {
            Write-BoxLine "  $([char]0x00B7)  $f $($T.NotInstalled)" DarkRed DarkGray
        }
    }
    Write-BoxEmpty
    Write-BoxDiv
    Write-BoxEmpty
    Write-BoxLine (Pad-Center $T.Warning $W) DarkRed Red
    Write-BoxEmpty
}

# ─────────────────────────────────────────────────────────────
#  КНОПКИ
#  sel: 0 = Удалить/Delete   1 = Отмена/Cancel  (по умолчанию — Отмена)
# ─────────────────────────────────────────────────────────────
function Show-Buttons {
    param([int]$sel)

    $b0 = $T.BtnDelete
    $b1 = $T.BtnCancel
    $sp = "     "

    Write-BoxDiv
    Write-BoxEmpty

    $top = $sp + $cTLs + ([string]$cHs * $b0.Length) + $cTRs + $sp + $sp + $cTLs + ([string]$cHs * $b1.Length) + $cTRs
    Write-BoxLine $top DarkRed DarkGray

    $f0 = if ($sel -eq 0) { 'Black'  } else { 'DarkGray' }
    $g0 = if ($sel -eq 0) { 'Red'    } else { 'Black'    }
    $f1 = if ($sel -eq 1) { 'Black'  } else { 'DarkGray' }
    $g1 = if ($sel -eq 1) { 'Yellow' } else { 'Black'    }

    $tail = ' ' * ($W - $sp.Length*3 - $b0.Length - $b1.Length - 4)

    Write-Host $cV -ForegroundColor DarkRed -NoNewline
    Write-Host ($sp + $cVs) -ForegroundColor DarkGray -NoNewline
    Write-Host $b0 -ForegroundColor $f0 -BackgroundColor $g0 -NoNewline
    Write-Host ($cVs + $sp + $sp + $cVs) -ForegroundColor DarkGray -NoNewline
    Write-Host $b1 -ForegroundColor $f1 -BackgroundColor $g1 -NoNewline
    Write-Host ($cVs + $tail) -ForegroundColor DarkGray -NoNewline
    Write-Host $cV -ForegroundColor DarkRed

    $bot = $sp + $cBLs + ([string]$cHs * $b0.Length) + $cBRs + $sp + $sp + $cBLs + ([string]$cHs * $b1.Length) + $cBRs
    Write-BoxLine $bot DarkRed DarkGray

    Write-BoxEmpty
    Write-BoxLine (Pad-Center $T.NavHint $W) DarkRed DarkGray
    Write-BoxBottom
}

# ─────────────────────────────────────────────────────────────
#  ЦИКЛ ВВОДА
# ─────────────────────────────────────────────────────────────
function Invoke-MenuSelect {
    $sel = 1   # по умолчанию — Отмена (безопаснее)
    $startRow = try { [Console]::CursorTop } catch { 0 }
    Show-Buttons $sel

    while ($true) {
        $key = try { [Console]::ReadKey($true) } catch { return 'cancel' }
        $new = $sel
        $ok  = $false

        switch ($key.Key) {
            'LeftArrow'  { $new = 0 }
            'RightArrow' { $new = 1 }
            'UpArrow'    { $new = 0 }
            'DownArrow'  { $new = 1 }
            'Enter'      { $ok  = $true }
            'Escape'     { return 'cancel' }
        }

        $ch = [char]::ToLower($key.KeyChar)
        if ($ch -eq $T.HotkeyDelete) { $new = 0; $ok = $true }
        if ($ch -eq $T.HotkeyCancel) { $new = 1; $ok = $true }
        # latin fallback для русской раскладки
        switch ($ch) {
            'u' { if ($Lang -eq 'ru') { $new = 0; $ok = $true } }
            'o' { if ($Lang -eq 'ru') { $new = 1; $ok = $true } }
            'd' { if ($Lang -eq 'en') { $new = 0; $ok = $true } }
            'c' { if ($Lang -eq 'en') { $new = 1; $ok = $true } }
        }

        if ($ok) {
            return $(if ($new -eq 0) { 'remove' } else { 'cancel' })
        }

        if ($new -ne $sel) {
            $sel = $new
            try { [Console]::SetCursorPosition(0, $startRow) } catch {}
            Show-Buttons $sel
        }
    }
}

# ─────────────────────────────────────────────────────────────
#  УДАЛЕНИЕ
# ─────────────────────────────────────────────────────────────
function Do-Remove {
    param([string[]]$files)

    Write-Host ""
    Write-BoxTop
    Write-BoxLine (Pad-Center $T.RemoveTitle $W) DarkRed Red
    Write-BoxDiv
    Write-BoxEmpty

    $removed = 0
    foreach ($name in ($files | Select-Object -Unique)) {
        $path = Join-Path $targetDir $name
        if (Test-Path $path) {
            Remove-Item $path -Force
            Write-BoxLine ($T.Removed -f $name) DarkRed DarkGray
            $removed++
        } else {
            Write-BoxLine ($T.Skipped -f $name) DarkRed DarkGray
        }
    }

    Write-BoxEmpty
    Write-BoxDiv
    Write-BoxEmpty

    if ($removed -gt 0) {
        Write-BoxLine (Pad-Center ($T.DoneCount -f $removed) $W) DarkRed Green
    } else {
        Write-BoxLine (Pad-Center $T.NothingDone $W) DarkRed Yellow
    }

    Write-BoxEmpty
    Write-BoxLine $T.Reinstall    DarkRed White
    Write-BoxLine $T.ReinstallCmd DarkRed Gray
    Write-BoxEmpty
    Write-BoxBottom
    Write-Host ""
    Wait-KeyOrTimeout
}

# ─────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────
try { [Console]::CursorVisible = $false } catch {}

if (-not (Test-Path $targetDir)) {
    Write-Host $T.NoFolder -ForegroundColor Yellow
    exit 0
}

Clear-Host

$fileList = Get-FileList

Show-Banner
Show-FileList $fileList

$choice = Invoke-MenuSelect

try { [Console]::CursorVisible = $true } catch {}

if ($choice -eq 'remove') {
    Do-Remove $fileList
} else {
    Write-Host ""
    Write-BoxTop
    Write-BoxLine (Pad-Center $T.Cancelled $W) DarkRed Yellow
    Write-BoxBottom
    Write-Host ""
}



