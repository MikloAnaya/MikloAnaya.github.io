@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

echo ============================================================
echo One-Click Runner: Make Money Stack
echo ============================================================
echo.
echo This will:
echo - run setup automatically if needed
echo - start Docker infra and app services
echo - verify health and open app pages
echo.

call "%ROOT%\easy-start.bat"
if errorlevel 1 (
    echo.
    echo Startup failed.
    echo Use watch-dev-logs.bat and status-dev.bat to troubleshoot.
    exit /b 1
)

echo.
echo Stack is running.
echo When done, run stop-dev.bat
exit /b 0
