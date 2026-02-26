@echo off
setlocal EnableDelayedExpansion

REM Load environment variables from .env if it exists
set "ENV_FILE=%~dp0trajectory-revenue-ops\.env"
if exist "%ENV_FILE%" (
    echo Loading environment from %ENV_FILE%
    for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        set "LINE=%%A"
        if not "!LINE:~0,1!"=="#" (
            if not "%%A"=="" (
                set "%%A=%%B"
            )
        )
    )
) else (
    echo WARNING: No .env file found at %ENV_FILE%
    echo Copy .env.example to .env and configure SMTP and optional payment credentials.
    echo Running in dry-run mode...
)

REM Check Rank Matrix app health (optional)
if defined APP_URL (
    echo Checking Rank Matrix health at %APP_URL%/health ...
    set "HEALTH_CODE=000"
    curl -s -o nul -w "%%{http_code}" "%APP_URL%/health" > "%TEMP%\rankmatrixseo_health.txt" 2>nul
    if exist "%TEMP%\rankmatrixseo_health.txt" (
        set /p HEALTH_CODE=<"%TEMP%\rankmatrixseo_health.txt"
    )
    if not defined HEALTH_CODE set "HEALTH_CODE=000"
    if "!HEALTH_CODE!"=="200" (
        echo Rank Matrix is UP.
    ) else (
        echo WARNING: Rank Matrix health check returned !HEALTH_CODE! (or unreachable^).
        echo Outreach will still run, but prospects cannot see a live demo.
    )
)

REM Run the revenue autopilot
cd /d "%~dp0trajectory-revenue-ops"
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ".\scripts\run-revenue-autopilot.ps1" %*

if errorlevel 1 (
    echo Revenue autopilot run failed.
    exit /b 1
)

echo.
echo ==============================================
echo   Revenue autopilot run finished.
echo   Check tracking\ folder for today's artifacts.
echo ==============================================
exit /b 0
