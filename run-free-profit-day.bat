@echo off
setlocal EnableDelayedExpansion

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "ENV_FILE=%ROOT%\trajectory-revenue-ops\.env"

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
    echo Copy .env.example to .env and set links/credentials.
)

echo Running free-profit distribution day workflow...
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ROOT%\trajectory-revenue-ops\scripts\run-free-distribution-day.ps1" %*

if errorlevel 1 (
    echo Free-profit distribution workflow failed.
    exit /b 1
)

echo.
echo ==============================================
echo   Free-profit distribution workflow complete.
echo   Check trajectory-revenue-ops\tracking\
echo ==============================================
exit /b 0
