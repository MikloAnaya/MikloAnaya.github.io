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

echo === Make Money Doctor ===

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

    call :docker_health -Action engine-ready -DockerCommand "%DOCKER_CMD%" -TimeoutSec 5 >nul 2>nul
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

call :print_status "WSL2 available" "%WSL_OK%"
call :print_status "Docker CLI found" "%DOCKER_CLI%"
call :print_status "Docker service running" "%SVC_OK%"
call :print_status "Docker Desktop process running" "%DESKTOP_OK%"
call :print_status "Docker engine ready" "%ENGINE_OK%"
call :print_status "SEO compose running" "%SEO_COMPOSE_OK%"
call :print_status "Pain miner compose running" "%PM_COMPOSE_OK%"
call :print_status "SEO API health endpoint" "%SEO_HTTP_OK%"
call :print_status "Pain miner health endpoint" "%PM_HTTP_OK%"
echo.

if "%DOCKER_CLI%"=="0" (
    echo Diagnosis: Docker CLI missing.
    echo Next command: install Docker Desktop, then rerun mm.bat doctor
    exit /b 1
)
if "%WSL_OK%"=="0" (
    echo Diagnosis: WSL2 is missing.
    echo Next command: install-wsl-admin.bat
    exit /b 1
)
if "%SVC_OK%"=="0" (
    echo Diagnosis: Docker service is not running.
    echo Next command: mm.bat repair
    exit /b 1
)
if "%DESKTOP_OK%"=="0" (
    echo Diagnosis: Docker Desktop is not running.
    echo Next command: mm.bat repair
    exit /b 1
)
if "%ENGINE_OK%"=="0" (
    echo Diagnosis: Docker engine is not ready.
    echo Next command: mm.bat repair
    exit /b 1
)
if "%SEO_HTTP_OK%"=="0" (
    echo Diagnosis: SEO API is not healthy.
    echo Next command: mm.bat logs
    exit /b 1
)
if "%PM_HTTP_OK%"=="0" (
    echo Diagnosis: Pain Miner API is not healthy.
    echo Next command: mm.bat logs
    exit /b 1
)

echo Diagnosis: stack is healthy.
echo Next command: mm.bat open
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
    echo [OK] %LABEL%
) else (
    echo [FAIL] %LABEL%
)
exit /b 0

:docker_health
if not exist "%DOCKER_HEALTH_PS%" exit /b 1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DOCKER_HEALTH_PS%" %*
exit /b %errorlevel%
