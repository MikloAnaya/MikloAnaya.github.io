@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "SEO_DIR=%ROOT%\seo-rank-tracker"
set "PM_DIR=%ROOT%\pain-miner-service"
set "DOCKER_HEALTH_PS=%ROOT%\internal\docker-health.ps1"

set "DOCKER_CMD=docker"
set "DOCKER_CLI=0"
set "WSL_OK=0"
set "SVC_OK=0"
set "DESKTOP_OK=0"
set "ENGINE_OK=0"
set "SEO_COMPOSE_OK=0"
set "PM_COMPOSE_OK=0"
set "SEO_HTTP_OK=0"
set "PM_HTTP_OK=0"

where docker >nul 2>nul
if errorlevel 1 (
    if exist "C:\Program Files\Docker\Docker\resources\bin\docker.exe" (
        set "DOCKER_CMD=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
        set "DOCKER_CLI=1"
    )
) else (
    set "DOCKER_CLI=1"
)

wsl --status >nul 2>nul
if not errorlevel 1 set "WSL_OK=1"

if "%DOCKER_CLI%"=="1" (
    call :docker_health -Action service-status >nul 2>nul
    if not errorlevel 1 set "SVC_OK=1"

    call :docker_health -Action desktop-status >nul 2>nul
    if not errorlevel 1 set "DESKTOP_OK=1"

    call :docker_health -Action engine-ready -DockerCommand "%DOCKER_CMD%" -TimeoutSec 3 >nul 2>nul
    if not errorlevel 1 set "ENGINE_OK=1"
)

if "%ENGINE_OK%"=="1" (
    call :compose_has_running "%SEO_DIR%"
    if not errorlevel 1 set "SEO_COMPOSE_OK=1"
    call :compose_has_running "%PM_DIR%"
    if not errorlevel 1 set "PM_COMPOSE_OK=1"
)

call :docker_health -Action http-check -Url "http://localhost:8000/openapi.json" -TimeoutSec 2 >nul 2>nul
if not errorlevel 1 set "SEO_HTTP_OK=1"
call :docker_health -Action http-check -Url "http://localhost:8100/healthz" -TimeoutSec 2 >nul 2>nul
if not errorlevel 1 set "PM_HTTP_OK=1"

echo === Runtime Matrix ===
call :print_status "WSL2" "%WSL_OK%"
call :print_status "Docker CLI" "%DOCKER_CLI%"
call :print_status "Docker Service" "%SVC_OK%"
call :print_status "Docker Desktop Process" "%DESKTOP_OK%"
call :print_status "Docker Engine" "%ENGINE_OK%"
call :print_status "SEO Compose Running" "%SEO_COMPOSE_OK%"
call :print_status "Pain Miner Compose Running" "%PM_COMPOSE_OK%"
call :print_status "SEO API HTTP 8000" "%SEO_HTTP_OK%"
call :print_status "Pain Miner API HTTP 8100" "%PM_HTTP_OK%"
echo.

if "%DOCKER_CLI%"=="0" (
    echo Next step: install/start Docker Desktop, then run mm.bat doctor.
    exit /b 1
)
if "%WSL_OK%"=="0" (
    echo Next step: run install-wsl-admin.bat, reboot, then run mm.bat start.
    exit /b 1
)
if "%ENGINE_OK%"=="0" (
    echo Next step: run mm.bat repair.
    exit /b 1
)
if "%SEO_HTTP_OK%"=="0" (
    echo Next step: run mm.bat logs and inspect logs\seo-api.log.
    exit /b 1
)
if "%PM_HTTP_OK%"=="0" (
    echo Next step: run mm.bat logs and inspect logs\pm-api.log.
    exit /b 1
)

echo Next step: run mm.bat open.
exit /b 0

:compose_has_running
setlocal EnableDelayedExpansion
set "COMPOSE_DIR=%~1"
if not exist "%COMPOSE_DIR%\docker-compose.yml" (
    endlocal & exit /b 1
)
pushd "%COMPOSE_DIR%" >nul
set "HAS_RUNNING=0"
for /f "delims=" %%s in ('"%DOCKER_CMD%" compose ps --status running --services 2^>nul') do (
    set "HAS_RUNNING=1"
)
popd >nul
if "!HAS_RUNNING!"=="1" (
    endlocal & exit /b 0
)
endlocal & exit /b 1

:print_status
set "LABEL=%~1"
set "STATE=%~2"
if "%STATE%"=="1" (
    echo %LABEL%: OK
) else (
    echo %LABEL%: FAIL
)
exit /b 0

:docker_health
if not exist "%DOCKER_HEALTH_PS%" exit /b 1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DOCKER_HEALTH_PS%" %*
exit /b %errorlevel%
