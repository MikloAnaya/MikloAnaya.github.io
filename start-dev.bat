@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "SEO_DIR=%ROOT%\seo-rank-tracker"
set "PM_DIR=%ROOT%\pain-miner-service"
set "LOG_DIR=%ROOT%\logs"
set "RUNNER_DIR=%ROOT%\internal"
set "DOCKER_HEALTH_PS=%ROOT%\internal\docker-health.ps1"
set "DOCKER_DESKTOP_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"

set "DOCKER_CMD=docker"
set /a "DOCKER_ENGINE_WAIT_SEC=120"
set /a "COMPOSE_TIMEOUT_SEC=120"
set /a "PORT_WAIT_SEC=%COMPOSE_TIMEOUT_SEC%"
set /a "PORT_WAIT_INTERVAL_SEC=1"
set /a "HTTP_WAIT_SEC=90"
set /a "HTTP_INTERVAL_SEC=2"

echo Starting local stack...
echo.

if not exist "%DOCKER_HEALTH_PS%" (
    echo ERROR: Missing %DOCKER_HEALTH_PS%.
    echo Next step: restore launcher scripts, then run mm.bat start again.
    exit /b 1
)
if not exist "%SEO_DIR%\docker-compose.yml" (
    echo ERROR: Missing %SEO_DIR%\docker-compose.yml.
    echo Next step: restore seo-rank-tracker files, then run mm.bat start.
    exit /b 1
)
if not exist "%PM_DIR%\docker-compose.yml" (
    echo ERROR: Missing %PM_DIR%\docker-compose.yml.
    echo Next step: restore pain-miner-service files, then run mm.bat start.
    exit /b 1
)
if not exist "%SEO_DIR%\.env" (
    echo ERROR: Missing seo-rank-tracker\.env.
    echo Next step: run setup-dev.bat, then run mm.bat start.
    exit /b 1
)
if not exist "%PM_DIR%\.env" (
    echo ERROR: Missing pain-miner-service\.env.
    echo Next step: run setup-dev.bat, then run mm.bat start.
    exit /b 1
)
if not exist "%SEO_DIR%\.venv\Scripts\python.exe" (
    echo ERROR: Missing seo-rank-tracker virtual environment.
    echo Next step: run setup-dev.bat, then run mm.bat start.
    exit /b 1
)
if not exist "%PM_DIR%\.venv\Scripts\python.exe" (
    echo ERROR: Missing pain-miner-service virtual environment.
    echo Next step: run setup-dev.bat, then run mm.bat start.
    exit /b 1
)
if not exist "%RUNNER_DIR%\run-seo-api.bat" (
    echo ERROR: Missing internal runner scripts in %RUNNER_DIR%.
    echo Next step: restore internal scripts, then run mm.bat start.
    exit /b 1
)
if not exist "%RUNNER_DIR%\run-pm-api.bat" (
    echo ERROR: Missing internal runner scripts in %RUNNER_DIR%.
    echo Next step: restore internal scripts, then run mm.bat start.
    exit /b 1
)
if not exist "%RUNNER_DIR%\run-seo-worker.bat" (
    echo ERROR: Missing internal runner scripts in %RUNNER_DIR%.
    echo Next step: restore internal scripts, then run mm.bat start.
    exit /b 1
)
if not exist "%RUNNER_DIR%\run-pm-worker.bat" (
    echo ERROR: Missing internal runner scripts in %RUNNER_DIR%.
    echo Next step: restore internal scripts, then run mm.bat start.
    exit /b 1
)
if not exist "%RUNNER_DIR%\run-pm-beat.bat" (
    echo ERROR: Missing internal runner scripts in %RUNNER_DIR%.
    echo Next step: restore internal scripts, then run mm.bat start.
    exit /b 1
)

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

wsl --status >nul 2>nul
if errorlevel 1 (
    echo ERROR: WSL2 is not available.
    echo Next step: run install-wsl-admin.bat, reboot, then run mm.bat start.
    exit /b 1
)

call :ensure_docker_service
if errorlevel 1 exit /b 1

call :docker_health -Action desktop-status >nul 2>nul
if errorlevel 1 (
    echo Starting Docker Desktop...
    call :docker_health -Action desktop-start -DockerDesktopExe "%DOCKER_DESKTOP_EXE%" >nul 2>nul
    if errorlevel 1 (
        echo ERROR: Docker Desktop could not be launched.
        echo Next step: open Docker Desktop manually, wait for Engine running, then run mm.bat start.
        exit /b 1
    )
)

call :docker_health -Action engine-wait -DockerCommand "%DOCKER_CMD%" -TimeoutSec %DOCKER_ENGINE_WAIT_SEC% -IntervalSec 2 >nul 2>nul
if errorlevel 1 (
    echo Docker engine not ready. Running one auto-repair attempt...
    call :auto_repair_docker
    if errorlevel 1 (
        echo ERROR: Docker engine did not become ready in %DOCKER_ENGINE_WAIT_SEC%s.
        echo Next step: run mm.bat repair.
        exit /b 1
    )
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul
if not exist "%LOG_DIR%" (
    echo ERROR: Could not create log directory at %LOG_DIR%.
    echo Next step: verify folder permissions, then run mm.bat start.
    exit /b 1
)

for /f %%t in ('powershell -NoProfile -NonInteractive -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "MM_SESSION_ID=%%t"
if not defined MM_SESSION_ID set "MM_SESSION_ID=manual-session"
call :append_log_markers

echo [1/4] Starting Docker infra...
call :compose_up "%SEO_DIR%" "seo-rank-tracker"
if errorlevel 1 exit /b 1
call :compose_up "%PM_DIR%" "pain-miner-service"
if errorlevel 1 exit /b 1

call :wait_for_port 5432 "SEO Postgres"
if errorlevel 1 exit /b 1
call :wait_for_port 6379 "SEO Redis"
if errorlevel 1 exit /b 1
call :wait_for_port 5433 "Pain Miner Postgres"
if errorlevel 1 exit /b 1
call :wait_for_port 6380 "Pain Miner Redis"
if errorlevel 1 exit /b 1

echo [2/4] Launching app processes...
start "MM-PM-API" /min "%ComSpec%" /c call "%RUNNER_DIR%\run-pm-api.bat"
start "MM-PM-WORKER" /min "%ComSpec%" /c call "%RUNNER_DIR%\run-pm-worker.bat"
start "MM-PM-BEAT" /min "%ComSpec%" /c call "%RUNNER_DIR%\run-pm-beat.bat"
start "MM-SEO-API" /min "%ComSpec%" /c call "%RUNNER_DIR%\run-seo-api.bat"
start "MM-SEO-WORKER" /min "%ComSpec%" /c call "%RUNNER_DIR%\run-seo-worker.bat"

echo [3/4] Verifying HTTP health...
call :wait_http "http://localhost:8000/openapi.json" "SEO API"
if errorlevel 1 exit /b 1
call :wait_http "http://localhost:8100/healthz" "Pain Miner API"
if errorlevel 1 exit /b 1

echo [4/4] Startup complete.
echo.
echo Apps:
echo - SEO app:         http://localhost:8000
echo - Pain dashboard:  http://localhost:8100/dashboard
echo - Pain miner API:  http://localhost:8100/healthz
echo.
echo Logs:
echo - %LOG_DIR%\seo-api.log
echo - %LOG_DIR%\seo-worker.log
echo - %LOG_DIR%\pm-api.log
echo - %LOG_DIR%\pm-worker.log
echo - %LOG_DIR%\pm-beat.log
echo.
echo Next: run mm.bat logs to watch live logs or mm.bat stop when done.
exit /b 0

:ensure_docker_service
call :docker_health -Action service-status >nul 2>nul
set "SVC_RC=%errorlevel%"
if "%SVC_RC%"=="0" exit /b 0

echo Starting Docker service...
call :docker_health -Action service-start >nul 2>nul
set "SVC_START_RC=%errorlevel%"
if "%SVC_START_RC%"=="0" exit /b 0

if "%SVC_START_RC%"=="11" (
    echo Requesting administrator approval for Docker service start...
    call :docker_health -Action service-start-elevated >nul 2>nul
    set "SVC_ELEV_RC=%errorlevel%"
    if "%SVC_ELEV_RC%"=="0" exit /b 0
    echo ERROR: Docker service start was denied or failed.
    echo Next step: approve the UAC prompt, or run mm.bat repair as Administrator.
    exit /b 1
)

echo ERROR: Docker service is not running.
echo Next step: run mm.bat repair.
exit /b 1

:compose_up
set "COMPOSE_DIR=%~1"
set "COMPOSE_NAME=%~2"
call :docker_health -Action compose-up -DockerCommand "%DOCKER_CMD%" -ComposeDir "%COMPOSE_DIR%" -TimeoutSec %COMPOSE_TIMEOUT_SEC% >nul 2>nul
if not errorlevel 1 (
    echo - %COMPOSE_NAME% infra is up.
    exit /b 0
)
echo ERROR: %COMPOSE_NAME% compose startup failed or timed out.
echo Next step: run mm.bat doctor, then mm.bat repair.
exit /b 1

:wait_http
set "TARGET_URL=%~1"
set "TARGET_NAME=%~2"
set /a "HTTP_ELAPSED=0"
echo - Waiting for %TARGET_NAME% HTTP health (up to %HTTP_WAIT_SEC%s)...
:wait_http_loop
call :docker_health -Action http-check -Url "%TARGET_URL%" -TimeoutSec 3 >nul 2>nul
if not errorlevel 1 (
    echo - %TARGET_NAME% is healthy.
    exit /b 0
)
if !HTTP_ELAPSED! geq %HTTP_WAIT_SEC% (
    echo ERROR: %TARGET_NAME% did not become healthy.
    echo Next step: run mm.bat logs.
    exit /b 1
)
call :sleep_seconds %HTTP_INTERVAL_SEC%
set /a "HTTP_ELAPSED+=%HTTP_INTERVAL_SEC%"
goto wait_http_loop

:wait_for_port
set "TARGET_PORT=%~1"
set "TARGET_NAME=%~2"
echo - Waiting for %TARGET_NAME% on port %TARGET_PORT% (up to %PORT_WAIT_SEC%s)...
powershell -NoProfile -NonInteractive -Command ^
  "$port=%TARGET_PORT%;" ^
  "$timeout=%PORT_WAIT_SEC%;" ^
  "$interval=%PORT_WAIT_INTERVAL_SEC%;" ^
  "$attempts=[Math]::Ceiling($timeout / [double][Math]::Max(1, $interval));" ^
  "for($i=0; $i -lt $attempts; $i++) {" ^
  "  try {" ^
  "    $client = New-Object System.Net.Sockets.TcpClient;" ^
  "    $async = $client.BeginConnect('127.0.0.1', $port, $null, $null);" ^
  "    $ok = $async.AsyncWaitHandle.WaitOne(1000, $false);" ^
  "    if ($ok -and $client.Connected) { $client.EndConnect($async); $client.Close(); exit 0 }" ^
  "    $client.Close();" ^
  "  } catch {}" ^
  "  Start-Sleep -Seconds ([Math]::Max(1, $interval));" ^
  "}" ^
  "exit 1" >nul 2>nul
if not errorlevel 1 (
    echo - %TARGET_NAME% port is reachable.
    exit /b 0
)
echo ERROR: Timed out waiting for %TARGET_NAME% on port %TARGET_PORT%.
echo Next step: run mm.bat doctor.
exit /b 1

:append_log_markers
for %%f in ("seo-api.log" "seo-worker.log" "pm-api.log" "pm-worker.log" "pm-beat.log") do (
    if not exist "%LOG_DIR%\%%~f" type nul > "%LOG_DIR%\%%~f"
    >> "%LOG_DIR%\%%~f" echo(
    >> "%LOG_DIR%\%%~f" echo ===== Session %MM_SESSION_ID% started %date% %time% =====
)
exit /b 0

:auto_repair_docker
wsl --shutdown >nul 2>nul
taskkill /FI "IMAGENAME eq Docker Desktop.exe" /T /F >nul 2>nul
taskkill /FI "IMAGENAME eq com.docker.backend.exe" /T /F >nul 2>nul
taskkill /FI "IMAGENAME eq vpnkit.exe" /T /F >nul 2>nul
call :sleep_seconds 2

call :docker_health -Action service-start >nul 2>nul
set "AUTO_SVC_RC=%errorlevel%"
if "%AUTO_SVC_RC%"=="11" (
    call :docker_health -Action service-start-elevated >nul 2>nul
    set "AUTO_SVC_RC=%errorlevel%"
)
if not "%AUTO_SVC_RC%"=="0" exit /b 1

call :docker_health -Action desktop-start -DockerDesktopExe "%DOCKER_DESKTOP_EXE%" >nul 2>nul
if errorlevel 1 exit /b 1

call :docker_health -Action engine-wait -DockerCommand "%DOCKER_CMD%" -TimeoutSec 90 -IntervalSec 3 >nul 2>nul
if errorlevel 1 exit /b 1
exit /b 0

:docker_health
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DOCKER_HEALTH_PS%" %*
exit /b %errorlevel%

:sleep_seconds
powershell -NoProfile -NonInteractive -Command "Start-Sleep -Seconds %~1" >nul 2>nul
exit /b 0
