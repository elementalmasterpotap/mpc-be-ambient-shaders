$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$out = Join-Path $PSScriptRoot "AmbientGlow_Setup.exe"
$src = Join-Path $PSScriptRoot "src\Setup.cs"

Write-Host "Building AmbientGlow_Setup.exe..." -ForegroundColor Cyan

& $csc `
    /target:winexe `
    /out:"$out" `
    /reference:System.Windows.Forms.dll `
    /reference:System.Drawing.dll `
    /reference:System.dll `
    /optimize+ `
    "$src"

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK  -->  AmbientGlow_Setup.exe" -ForegroundColor Green
} else {
    Write-Host "Build failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}
