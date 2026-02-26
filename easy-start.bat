@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "SEO_PY=%ROOT%\seo-rank-tracker\.venv\Scripts\python.exe"
set "PM_PY=%ROOT%\pain-miner-service\.venv\Scripts\python.exe"
set "SEO_ENV=%ROOT%\seo-rank-tracker\.env"
set "PM_ENV=%ROOT%\pain-miner-service\.env"
set "NEEDS_SETUP=0"

if not exist "%SEO_PY%" set "NEEDS_SETUP=1"
if not exist "%PM_PY%" set "NEEDS_SETUP=1"
if not exist "%SEO_ENV%" set "NEEDS_SETUP=1"
if not exist "%PM_ENV%" set "NEEDS_SETUP=1"

echo ============================================================
echo Beginner Mode: Make Money Stack
echo ============================================================
echo.
echo What each part does:
echo - Docker Postgres/Redis: database + queue backbone
echo - SEO API (port 8000): your web app
echo - Pain Miner API (port 8100): internal opportunity engine
echo - Workers: background jobs for rank checks and mining
echo.

if "%NEEDS_SETUP%"=="1" (
    echo First-time or incomplete setup detected. Running setup-dev.bat...
    echo This may take a few minutes the first time.
    echo.
    call "%ROOT%\setup-dev.bat"
    if errorlevel 1 (
        echo.
        echo Setup failed. Run setup-dev.bat directly and review the error output.
        exit /b 1
    )
    echo.
    echo Setup complete.
    echo.
)

echo Starting everything now...
echo.

call "%ROOT%\start-dev.bat"
if errorlevel 1 (
    echo.
    echo Start failed. Run watch-dev-logs.bat to view errors.
    exit /b 1
)

echo.
echo Waiting 6 seconds for services to warm up...
powershell -NoProfile -NonInteractive -Command "Start-Sleep -Seconds 6" >nul 2>nul

echo.
call "%ROOT%\status-dev.bat"

set "SEO_OK=0"
set "PM_OK=0"
curl -fsS "http://localhost:8000/openapi.json" >nul 2>nul && set "SEO_OK=1"
curl -fsS "http://localhost:8100/healthz" >nul 2>nul && set "PM_OK=1"

echo.
if "%SEO_OK%"=="1" if "%PM_OK%"=="1" (
    echo Startup check: READY
    echo Apps are ready:
    echo 1. Pain Miner Dashboard: http://localhost:8100/dashboard
    echo 2. SEO app:              http://localhost:8000
    echo 3. Internal Insights:    http://localhost:8000/internal/pain-insights
    echo.
    echo Opening app pages in your browser...
    start "" "http://localhost:8100/dashboard"
    start "" "http://localhost:8000"
    exit /b 0
)

echo Startup check: PARTIAL
echo Some services are still booting or failed.
echo Run watch-dev-logs.bat and check for ERROR lines.
echo Then run status-dev.bat again.
echo.
exit /b 1
