@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "SEO_DIR=%ROOT%\seo-rank-tracker"
set "PM_DIR=%ROOT%\pain-miner-service"
set "DOCKER_HEALTH_PS=%ROOT%\internal\docker-health.ps1"
set "DOCKER_CMD=docker"
set "DOCKER_CLI=0"
set "ENGINE_READY=0"

echo Stopping local app processes...
taskkill /FI "WINDOWTITLE eq MM-PM-API*" /T /F >nul 2>nul
taskkill /FI "WINDOWTITLE eq MM-PM-WORKER*" /T /F >nul 2>nul
taskkill /FI "WINDOWTITLE eq MM-PM-BEAT*" /T /F >nul 2>nul
taskkill /FI "WINDOWTITLE eq MM-SEO-API*" /T /F >nul 2>nul
taskkill /FI "WINDOWTITLE eq MM-SEO-WORKER*" /T /F >nul 2>nul

for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":8000 .*LISTENING"') do taskkill /PID %%p /F >nul 2>nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":8100 .*LISTENING"') do taskkill /PID %%p /F >nul 2>nul

powershell -NoProfile -NonInteractive -Command ^
  "$procs = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'python.exe' -and ($_.ExecutablePath -like '*\seo-rank-tracker\*' -or $_.ExecutablePath -like '*\pain-miner-service\*' -or $_.CommandLine -like '*seo-rank-tracker*' -or $_.CommandLine -like '*pain-miner-service*') };" ^
  "foreach($p in $procs){ try { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue } catch {} }" >nul 2>nul

where docker >nul 2>nul
if errorlevel 1 (
    if exist "C:\Program Files\Docker\Docker\resources\bin\docker.exe" (
        set "DOCKER_CMD=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
        set "DOCKER_CLI=1"
    )
) else (
    set "DOCKER_CLI=1"
)

if "%DOCKER_CLI%"=="1" (
    call :docker_health -Action engine-ready -DockerCommand "%DOCKER_CMD%" -TimeoutSec 3 >nul 2>nul
    if not errorlevel 1 set "ENGINE_READY=1"
)

if "%ENGINE_READY%"=="1" (
    echo Stopping Docker compose infra...
    if exist "%SEO_DIR%\docker-compose.yml" (
        pushd "%SEO_DIR%" >nul
        "%DOCKER_CMD%" compose down >nul 2>nul
        popd >nul
    )
    if exist "%PM_DIR%\docker-compose.yml" (
        pushd "%PM_DIR%" >nul
        "%DOCKER_CMD%" compose down >nul 2>nul
        popd >nul
    )
) else (
    echo Docker engine unavailable; skipped compose shutdown.
)

echo Done.
exit /b 0

:docker_health
if not exist "%DOCKER_HEALTH_PS%" exit /b 1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DOCKER_HEALTH_PS%" %*
exit /b %errorlevel%
