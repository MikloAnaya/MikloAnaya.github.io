@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "CMD=%~1"
if "%CMD%"=="" goto help

if /I "%CMD%"=="start" goto start
if /I "%CMD%"=="status" goto status
if /I "%CMD%"=="doctor" goto doctor
if /I "%CMD%"=="logs" goto logs
if /I "%CMD%"=="daily" goto daily
if /I "%CMD%"=="open" goto open
if /I "%CMD%"=="stop" goto stop
if /I "%CMD%"=="repair" goto repair
if /I "%CMD%"=="menu" goto menu
if /I "%CMD%"=="autopilot" goto autopilot
if /I "%CMD%"=="profit" goto profit
if /I "%CMD%"=="help" goto help
if /I "%CMD%"=="-h" goto help
if /I "%CMD%"=="--help" goto help

echo Unknown command: %CMD%
echo.
goto help

:start
call "%ROOT%\run-app.bat"
exit /b %errorlevel%

:status
call "%ROOT%\status-dev.bat"
exit /b %errorlevel%

:doctor
call "%ROOT%\doctor-dev.bat"
exit /b %errorlevel%

:logs
call "%ROOT%\watch-dev-logs.bat"
exit /b %errorlevel%

:daily
call "%ROOT%\run-daily-now.bat"
exit /b %errorlevel%

:open
start "" "http://localhost:8100/dashboard"
start "" "http://localhost:8000"
start "" "http://localhost:8100/healthz"
start "" "http://localhost:8000/internal/pain-insights"
start "" "http://localhost:8000/internal/autopilot-console"
echo Opened app pages.
exit /b 0

:stop
call "%ROOT%\stop-dev.bat"
exit /b %errorlevel%

:repair
call "%ROOT%\repair-docker.bat"
exit /b %errorlevel%

:menu
call "%ROOT%\dev-control.bat"
exit /b %errorlevel%

:autopilot
shift
call "%ROOT%\run-money-autopilot.bat" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b %errorlevel%

:profit
shift
call "%ROOT%\run-free-profit-day.bat" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b %errorlevel%

:help
echo Make Money command runner
echo.
echo Usage:
echo   mm.bat start
echo   mm.bat status
echo   mm.bat doctor
echo   mm.bat logs
echo   mm.bat daily
echo   mm.bat open
echo   mm.bat stop
echo   mm.bat repair
echo   mm.bat menu
echo   mm.bat autopilot [args]
echo   mm.bat profit [args]
echo.
echo Examples:
echo   mm.bat start
echo   mm.bat doctor
echo   mm.bat autopilot -Date 2026-02-27 -Fast
echo   mm.bat profit -Date 2026-02-27 -DailyTouches 20
exit /b 0
