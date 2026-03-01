param(
    [switch]$NoPrompt,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ─────────────────────────────────────────────────────────────
#  ПУТИ / PATHS
# ─────────────────────────────────────────────────────────────
$projectRoot    = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceSm3      = Join-Path $projectRoot "shaders\ProfessionalLighting_SM3.hlsl"
$targetDir      = Join-Path $env:APPDATA "MPC-BE\Shaders"
$targetSm3      = Join-Path $targetDir "ProfessionalLighting_SM3.hlsl"
$targetReadySm3 = Join-Path $targetDir "AmbientGlow_SM3_Ready.hlsl"
$manifest       = Join-Path $targetDir "AmbientGlow_InstallManifest.json"

# ─────────────────────────────────────────────────────────────
#  ЯЗЫК / LANGUAGE
# ─────────────────────────────────────────────────────────────
$Lang = if ((Get-WinSystemLocale).TwoLetterISOLanguageName -eq 'ru') { 'ru' } else { 'en' }

$T = if ($Lang -eq 'ru') { @{
    BannerTitle    = "M P C - B E   $([char]0x00B7)   А М Б И Е Н Т   П О Д С В Е Т К А"
    BannerLine1    = "  $([char]0x00B7)  Заполняет чёрные полосы цветом с краёв видео (Ambilight)"
    BannerLine2    = "  $([char]0x00B7)  Живые насыщенные цвета $([char]0x00B7)  Кино-компрессия яркости (ACES)"
    BannerLine3    = "  $([char]0x00B7)  Плёночное свечение $([char]0x00B7)  Виньетка $([char]0x00B7)  Хроматическая аберрация"
    InfoProfile    = "  Профиль  :  SM3  (максимальное качество)"
    InfoDest       = "  Куда     :  $env:APPDATA\MPC-BE\Shaders\"
    InfoFiles      = "  Файлов   :  1 шейдер + манифест установки"
    InfoSm3        = "  SM3  $([char]0x00B7)  Shader Model 3.0  $([char]0x00B7)  максимальное качество"
    Btn0           = "  [У] Установить  "
    Btn1           = "  [И] С инструкцией  "
    Btn2           = "  [О] Отмена  "
    BtnHotkey0     = 'у'
    BtnHotkey1     = 'и'
    BtnHotkey2     = 'о'
    NavHint        = "$([char]0x2190)$([char]0x2192) выбор   $([char]0x00B7)   Enter подтвердить   $([char]0x00B7)   У / И / О хоткей"
    ProgressTitle  = "У С Т А Н О В К А . . ."
    ProgressDone   = "У С Т А Н О В К А   З А В Е Р Ш Е Н А"
    FolderReady    = "  +  Папка назначения готова"
    GuideTitle     = "  Как включить в MPC-BE:"
    GuideStep1     = "  1. Откройте MPC-BE"
    GuideStep3     = "  3. Выберите шейдер из списка:"
    GuideStep4     = "  4. Нажмите OK — эффект применится сразу"
    GuideNote      = "  Примечание: рекомендуется ночной билд MPC-BE"
    GuideNoteUrl   = "  github.com/Aleksoid1978/MPC-BE/wiki/Nightly-builds"
    Cancelled      = "Установка отменена."
    NoPromptMode   = "Режим: МАКСИМАЛЬНОЕ КАЧЕСТВО (SM3)"
    NoPromptDest   = "Установка в: $targetDir"
    NoPromptDone   = "Готово. SM3 установлен."
    NoPromptHint   = "MPC-BE -> Вид -> Шейдер -> Постобработка"
    NoPromptShader = "Выбрать: AmbientGlow_SM3_Ready.hlsl"
    ErrNotFound    = "Файл SM3 не найден: $sourceSm3"
    WaitMsg        = "Закроется через {0} сек  ·  любая клавиша — выйти сейчас"
}} else { @{
    BannerTitle    = "M P C - B E   $([char]0x00B7)   A M B I E N T   L I G H T I N G"
    BannerLine1    = "  $([char]0x00B7)  Fills black bars with colors from video edges (Ambilight)"
    BannerLine2    = "  $([char]0x00B7)  Vivid saturated colors $([char]0x00B7)  Cinematic tone mapping (ACES)"
    BannerLine3    = "  $([char]0x00B7)  Film halation $([char]0x00B7)  Vignette $([char]0x00B7)  Chromatic aberration"
    InfoProfile    = "  Profile  :  SM3  (maximum quality)"
    InfoDest       = "  Target   :  $env:APPDATA\MPC-BE\Shaders\"
    InfoFiles      = "  Files    :  1 shader + install manifest"
    InfoSm3        = "  SM3  $([char]0x00B7)  Shader Model 3.0  $([char]0x00B7)  maximum quality"
    Btn0           = "  [I] Install  "
    Btn1           = "  [G] With guide  "
    Btn2           = "  [C] Cancel  "
    BtnHotkey0     = 'i'
    BtnHotkey1     = 'g'
    BtnHotkey2     = 'c'
    NavHint        = "$([char]0x2190)$([char]0x2192) select   $([char]0x00B7)   Enter confirm   $([char]0x00B7)   I / G / C hotkey"
    ProgressTitle  = "I N S T A L L I N G . . ."
    ProgressDone   = "I N S T A L L A T I O N   C O M P L E T E"
    FolderReady    = "  +  Target folder ready"
    GuideTitle     = "  How to enable in MPC-BE:"
    GuideStep1     = "  1. Open MPC-BE"
    GuideStep3     = "  3. Select shader from the list:"
    GuideStep4     = "  4. Click OK — effect applies immediately"
    GuideNote      = "  Note: nightly build of MPC-BE is recommended"
    GuideNoteUrl   = "  github.com/Aleksoid1978/MPC-BE/wiki/Nightly-builds"
    Cancelled      = "Installation cancelled."
    NoPromptMode   = "Mode: MAXIMUM QUALITY (SM3)"
    NoPromptDest   = "Installing to: $targetDir"
    NoPromptDone   = "Done. SM3 installed."
    NoPromptHint   = "MPC-BE -> View -> Shader -> Post-Processing"
    NoPromptShader = "Select: AmbientGlow_SM3_Ready.hlsl"
    ErrNotFound    = "SM3 file not found: $sourceSm3"
    WaitMsg        = "Closing in {0} sec  ·  any key to exit now"
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
$cArr = [char]0x2192  # →

$W = 68  # ширина внутри рамки

# ─────────────────────────────────────────────────────────────
#  ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ─────────────────────────────────────────────────────────────
function Write-Ui {
    param([string]$Text = "", [ConsoleColor]$Color = [ConsoleColor]::Gray)
    if (-not $Quiet) { Write-Host $Text -ForegroundColor $Color }
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
        [ConsoleColor]$fc = [ConsoleColor]::DarkCyan,
        [ConsoleColor]$tc = [ConsoleColor]::Gray
    )
    Write-Host $cV -ForegroundColor $fc -NoNewline
    Write-Host $inner.PadRight($W) -ForegroundColor $tc -NoNewline
    Write-Host $cV -ForegroundColor $fc
}

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

function Write-BoxTop    { Write-Host ($cTL + ([string]$cH * $W) + $cTR) -ForegroundColor DarkCyan }
function Write-BoxDiv    { Write-Host ($cML + ([string]$cH * $W) + $cMR) -ForegroundColor DarkCyan }
function Write-BoxBottom { Write-Host ($cBL + ([string]$cH * $W) + $cBR) -ForegroundColor DarkCyan }
function Write-BoxEmpty  { Write-BoxLine }

# ─────────────────────────────────────────────────────────────
#  ЯДРО УСТАНОВКИ
# ─────────────────────────────────────────────────────────────
function Run-Install {
    if (-not (Test-Path $sourceSm3)) { throw $T.ErrNotFound }
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $prevBackup = Join-Path $projectRoot "docs\ProfessionalLighting_SM3.prev.hlsl"
    Copy-Item $sourceSm3 -Destination $prevBackup -Force
    Copy-Item $sourceSm3 -Destination $targetSm3 -Force
    $h3 = "// AUTO-GENERATED FOR INSTANT USE`r`n// Profile: Ultra Quality SM3`r`n// Source: ProfessionalLighting_SM3.hlsl`r`n`r`n"
    Set-Content -Path $targetReadySm3 -Value ($h3 + (Get-Content -Raw $sourceSm3)) -Encoding UTF8
    $data = [ordered]@{
        installedAt = (Get-Date).ToString("s")
        profile     = "UltraQuality_SM3"
        files       = @("ProfessionalLighting_SM3.hlsl", "AmbientGlow_SM3_Ready.hlsl")
    }
    $data | ConvertTo-Json -Depth 3 | Set-Content -Path $manifest -Encoding UTF8
}

# ─────────────────────────────────────────────────────────────
#  ТИХИЙ РЕЖИМ  (-NoPrompt)
# ─────────────────────────────────────────────────────────────
if ($NoPrompt) {
    Write-Ui "=========================================================" Cyan
    Write-Ui "      MPC-BE ULTRA QUALITY SHADER INSTALLER" Cyan
    Write-Ui "=========================================================" Cyan
    Write-Ui $T.NoPromptMode Yellow
    Write-Ui ""
    Write-Ui $T.NoPromptDest Gray
    Run-Install
    Write-Ui ""
    Write-Ui $T.NoPromptDone Green
    Write-Ui $T.NoPromptHint Gray
    Write-Ui $T.NoPromptShader Green
    exit 0
}

# ─────────────────────────────────────────────────────────────
#  БАННЕР
# ─────────────────────────────────────────────────────────────
function Show-Banner {
    Write-BoxTop
    Write-BoxEmpty
    Write-BoxLine (Pad-Center $T.BannerTitle $W) DarkCyan Yellow
    Write-BoxEmpty
    Write-BoxLine $T.BannerLine1 DarkCyan DarkGray
    Write-BoxLine $T.BannerLine2 DarkCyan DarkGray
    Write-BoxLine $T.BannerLine3 DarkCyan DarkGray
    Write-BoxEmpty
}

# ─────────────────────────────────────────────────────────────
#  ИНФОРМАЦИОННАЯ ПАНЕЛЬ
# ─────────────────────────────────────────────────────────────
function Show-Info {
    Write-BoxDiv
    Write-BoxEmpty
    Write-BoxLine $T.InfoProfile DarkCyan White
    Write-BoxLine $T.InfoDest    DarkCyan Gray
    Write-BoxLine $T.InfoFiles   DarkCyan Gray
    Write-BoxEmpty
    Write-BoxLine $T.InfoSm3 DarkCyan Cyan
    Write-BoxEmpty
}

# ─────────────────────────────────────────────────────────────
#  КНОПКИ ГЛАВНОГО МЕНЮ
#  sel: 0 = Установить/Install  1 = С инструкцией/Guide  2 = Отмена/Cancel
# ─────────────────────────────────────────────────────────────
function Show-MainButtons {
    param([int]$sel)

    $b0 = $T.Btn0
    $b1 = $T.Btn1
    $b2 = $T.Btn2
    $sp = "  "

    Write-BoxDiv
    Write-BoxEmpty

    $top = $sp + $cTLs + ([string]$cHs * $b0.Length) + $cTRs + $sp + $cTLs + ([string]$cHs * $b1.Length) + $cTRs + $sp + $cTLs + ([string]$cHs * $b2.Length) + $cTRs
    Write-BoxLine $top DarkCyan DarkGray

    $f0 = if ($sel -eq 0) { 'Black'   } else { 'DarkGray' }
    $g0 = if ($sel -eq 0) { 'Cyan'    } else { 'Black'    }
    $f1 = if ($sel -eq 1) { 'Black'   } else { 'DarkGray' }
    $g1 = if ($sel -eq 1) { 'Green'   } else { 'Black'    }
    $f2 = if ($sel -eq 2) { 'Black'   } else { 'DarkGray' }
    $g2 = if ($sel -eq 2) { 'Yellow'  } else { 'Black'    }

    $tail = ' ' * ($W - $sp.Length*3 - $b0.Length - $b1.Length - $b2.Length - 6)

    Write-Host $cV -ForegroundColor DarkCyan -NoNewline
    Write-Host ($sp + $cVs) -ForegroundColor DarkGray -NoNewline
    Write-Host $b0 -ForegroundColor $f0 -BackgroundColor $g0 -NoNewline
    Write-Host ($cVs + $sp + $cVs) -ForegroundColor DarkGray -NoNewline
    Write-Host $b1 -ForegroundColor $f1 -BackgroundColor $g1 -NoNewline
    Write-Host ($cVs + $sp + $cVs) -ForegroundColor DarkGray -NoNewline
    Write-Host $b2 -ForegroundColor $f2 -BackgroundColor $g2 -NoNewline
    Write-Host ($cVs + $tail) -ForegroundColor DarkGray -NoNewline
    Write-Host $cV -ForegroundColor DarkCyan

    $bot = $sp + $cBLs + ([string]$cHs * $b0.Length) + $cBRs + $sp + $cBLs + ([string]$cHs * $b1.Length) + $cBRs + $sp + $cBLs + ([string]$cHs * $b2.Length) + $cBRs
    Write-BoxLine $bot DarkCyan DarkGray

    Write-BoxEmpty
    Write-BoxLine (Pad-Center $T.NavHint $W) DarkCyan DarkGray
    Write-BoxBottom
}

# ─────────────────────────────────────────────────────────────
#  ЦИКЛ ВВОДА ГЛАВНОГО МЕНЮ
# ─────────────────────────────────────────────────────────────
function Invoke-MainMenu {
    $sel = 0
    $startRow = try { [Console]::CursorTop } catch { 0 }
    Show-MainButtons $sel

    while ($true) {
        $key = try { [Console]::ReadKey($true) } catch { return 'cancel' }
        $new = $sel
        $ok  = $false

        switch ($key.Key) {
            'LeftArrow'  { $new = if ($sel -gt 0) { $sel - 1 } else { 2 } }
            'RightArrow' { $new = if ($sel -lt 2) { $sel + 1 } else { 0 } }
            'Enter'      { $ok  = $true }
            'Escape'     { return 'cancel' }
        }

        $ch = [char]::ToLower($key.KeyChar)
        if ($ch -eq $T.BtnHotkey0) { $new = 0; $ok = $true }
        if ($ch -eq $T.BtnHotkey1) { $new = 1; $ok = $true }
        if ($ch -eq $T.BtnHotkey2) { $new = 2; $ok = $true }
        # latin fallback для русской раскладки
        switch ($ch) {
            'u' { if ($Lang -eq 'ru') { $new = 0; $ok = $true } }
            'i' { if ($Lang -eq 'ru') { $new = 1; $ok = $true } }
            'o' { if ($Lang -eq 'ru') { $new = 2; $ok = $true } }
        }

        if ($ok) {
            switch ($new) {
                0 { return 'silent'  }
                1 { return 'guide'   }
                2 { return 'cancel'  }
            }
        }

        if ($new -ne $sel) {
            $sel = $new
            try { [Console]::SetCursorPosition(0, $startRow) } catch {}
            Show-MainButtons $sel
        }
    }
}

# ─────────────────────────────────────────────────────────────
#  ЭКРАН ПРОГРЕССА
# ─────────────────────────────────────────────────────────────
function Show-Progress {
    param([bool]$showGuide = $false)

    Write-Host ""
    Write-BoxTop
    Write-BoxLine (Pad-Center $T.ProgressTitle $W) DarkCyan Cyan
    Write-BoxDiv
    Write-BoxEmpty

    Run-Install

    Write-BoxLine $T.FolderReady DarkCyan DarkGreen
    Write-BoxLine "  +  ProfessionalLighting_SM3.hlsl" DarkCyan Gray
    Write-BoxLine "  +  AmbientGlow_SM3_Ready.hlsl" DarkCyan Cyan
    Write-BoxLine "  +  AmbientGlow_InstallManifest.json" DarkCyan DarkGray
    Write-BoxEmpty
    Write-BoxDiv
    Write-BoxEmpty
    Write-BoxLine (Pad-Center $T.ProgressDone $W) DarkCyan Green
    Write-BoxEmpty

    if ($showGuide) {
        Write-BoxLine $T.GuideTitle DarkCyan White
        Write-BoxEmpty
        Write-BoxLine $T.GuideStep1 DarkCyan Gray
        Write-BoxLine "  2. View  $cArr  Shader  $cArr  Post-Processing" DarkCyan Gray
        Write-BoxLine $T.GuideStep3 DarkCyan Gray
        Write-BoxEmpty
        Write-BoxLine "     AmbientGlow_SM3_Ready.hlsl" DarkCyan Cyan
        Write-BoxLine "     $([char]0x00B7)  SM3, maximum quality" DarkCyan DarkCyan
        Write-BoxEmpty
        Write-BoxLine $T.GuideStep4 DarkCyan Gray
        Write-BoxEmpty
        Write-BoxLine $T.GuideNote    DarkCyan DarkGray
        Write-BoxLine $T.GuideNoteUrl DarkCyan DarkGray
        Write-BoxEmpty
    }

    Write-BoxBottom
    Write-Host ""
    Wait-KeyOrTimeout
}

# ─────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────
try { [Console]::CursorVisible = $false } catch {}
Clear-Host

Show-Banner
Show-Info

$choice = Invoke-MainMenu

try { [Console]::CursorVisible = $true } catch {}

switch ($choice) {
    'silent' {
        Show-Progress $false
    }
    'guide' {
        Show-Progress $true
    }
    default {
        Write-Host ""
        Write-BoxTop
        Write-BoxLine (Pad-Center $T.Cancelled $W) DarkCyan Yellow
        Write-BoxBottom
        Write-Host ""
    }
}



