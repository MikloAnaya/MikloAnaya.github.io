@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

:menu
cls
echo ============================================================
echo Make Money Dev Control Center
echo ============================================================
echo.
echo 1. Start everything
echo 2. Check status
echo 3. Watch logs (live)
echo 4. Run pain miner daily job now
echo 5. Open apps in browser
echo 6. Stop everything
echo 7. Doctor (diagnose stack)
echo 8. Repair Docker runtime
echo 0. Exit
echo.
set /p choice=Choose an option: 

if "%choice%"=="1" goto start_all
if "%choice%"=="2" goto check_status
if "%choice%"=="3" goto watch_logs
if "%choice%"=="4" goto run_daily
if "%choice%"=="5" goto open_apps
if "%choice%"=="6" goto stop_all
if "%choice%"=="7" goto doctor
if "%choice%"=="8" goto repair
if "%choice%"=="0" goto done

echo.
echo Invalid choice.
pause
goto menu

:start_all
call "%ROOT%\mm.bat" start
echo.
pause
goto menu

:check_status
call "%ROOT%\mm.bat" status
echo.
pause
goto menu

:watch_logs
call "%ROOT%\mm.bat" logs
goto menu

:run_daily
call "%ROOT%\mm.bat" daily
echo.
pause
goto menu

:open_apps
call "%ROOT%\mm.bat" open
echo.
pause
goto menu

:stop_all
call "%ROOT%\mm.bat" stop
echo.
pause
goto menu

:doctor
call "%ROOT%\mm.bat" doctor
echo.
pause
goto menu

:repair
call "%ROOT%\mm.bat" repair
echo.
pause
goto menu

:done
exit /b 0
