@echo off
setlocal EnableExtensions

net session >nul 2>nul
if not "%errorlevel%"=="0" (
    echo ERROR: This script must be run as Administrator.
    echo Right-click install-wsl-admin.bat and choose "Run as administrator".
    exit /b 1
)

echo Enabling Windows Subsystem for Linux...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
if errorlevel 1 goto :fail

echo Enabling Virtual Machine Platform...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
if errorlevel 1 goto :fail

echo Installing WSL components...
wsl --install --no-distribution

echo.
echo WSL setup commands completed.
echo Reboot Windows now, then run start-dev.bat again.
exit /b 0

:fail
echo.
echo Failed to enable required Windows features.
exit /b 1
