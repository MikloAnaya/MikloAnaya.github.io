@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "DOCKER_HEALTH_PS=%ROOT%\internal\docker-health.ps1"
set "DOCKER_DESKTOP_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"
set "DOCKER_CMD=docker"

where docker >nul 2>nul
if errorlevel 1 (
    if exist "C:\Program Files\Docker\Docker\resources\bin\docker.exe" (
        set "DOCKER_CMD=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
    ) else (
        echo ERROR: Docker CLI was not found.
        echo Next step: install Docker Desktop, then run mm.bat doctor.
        exit /b 1
    )
)

if not exist "%DOCKER_HEALTH_PS%" (
    echo ERROR: Missing %DOCKER_HEALTH_PS%.
    echo Next step: restore launcher scripts and run mm.bat repair again.
    exit /b 1
)

echo Repairing Docker runtime...
wsl --shutdown >nul 2>nul
taskkill /FI "IMAGENAME eq Docker Desktop.exe" /T /F >nul 2>nul
taskkill /FI "IMAGENAME eq com.docker.backend.exe" /T /F >nul 2>nul
taskkill /FI "IMAGENAME eq vpnkit.exe" /T /F >nul 2>nul
call :sleep_seconds 2

call :docker_health -Action service-start >nul 2>nul
set "SVC_RC=%errorlevel%"
if "%SVC_RC%"=="11" (
    echo Administrator approval required to start Docker service.
    call :docker_health -Action service-start-elevated >nul 2>nul
    set "SVC_RC=%errorlevel%"
)
if not "%SVC_RC%"=="0" (
    echo ERROR: Docker service could not be started.
    echo Next step: run mm.bat repair from an Administrator shell.
    exit /b 1
)

call :docker_health -Action desktop-start -DockerDesktopExe "%DOCKER_DESKTOP_EXE%" >nul 2>nul
if errorlevel 1 (
    echo ERROR: Docker Desktop failed to launch.
    echo Next step: open Docker Desktop manually, then run mm.bat doctor.
    exit /b 1
)

call :docker_health -Action engine-wait -DockerCommand "%DOCKER_CMD%" -TimeoutSec 150 -IntervalSec 3 >nul 2>nul
if errorlevel 1 (
    echo ERROR: Docker engine did not recover in time.
    echo Next step: open Docker Desktop and wait for Engine running, then run mm.bat doctor.
    exit /b 1
)

echo Docker runtime is healthy.
echo Next step: run mm.bat start.
exit /b 0

:docker_health
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DOCKER_HEALTH_PS%" %*
exit /b %errorlevel%

:sleep_seconds
powershell -NoProfile -NonInteractive -Command "Start-Sleep -Seconds %~1" >nul 2>nul
exit /b 0
