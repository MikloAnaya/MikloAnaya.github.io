@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "LOG_DIR=%ROOT%\logs"

if not exist "%LOG_DIR%" (
    echo No logs directory found yet. Run start-dev.bat first.
    exit /b 1
)

powershell -NoProfile -NonInteractive -Command ^
  "$files=@('%LOG_DIR%\seo-api.log','%LOG_DIR%\seo-worker.log','%LOG_DIR%\pm-api.log','%LOG_DIR%\pm-worker.log','%LOG_DIR%\pm-beat.log');" ^
  "foreach($f in $files){ if(-not (Test-Path $f)){ New-Item -ItemType File -Path $f | Out-Null } };" ^
  "Write-Host 'Watching logs... Ctrl+C to stop.' -ForegroundColor Cyan;" ^
  "Get-Content -Path $files -Wait -Tail 30"
