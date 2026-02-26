@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "SEO_DIR=%ROOT%\seo-rank-tracker"
set "PM_DIR=%ROOT%\pain-miner-service"

call :resolve_python
if errorlevel 1 goto :fail

echo.
echo [1/6] Validating project folders...
if not exist "%SEO_DIR%\pyproject.toml" (
    echo ERROR: Missing %SEO_DIR%\pyproject.toml
    goto :fail
)
if not exist "%PM_DIR%\pyproject.toml" (
    echo ERROR: Missing %PM_DIR%\pyproject.toml
    goto :fail
)

echo.
echo [2/6] Creating .env files if missing...
if not exist "%SEO_DIR%\.env" (
    copy /Y "%SEO_DIR%\.env.example" "%SEO_DIR%\.env" >nul
    echo - Created seo-rank-tracker\.env
)
if not exist "%PM_DIR%\.env" (
    copy /Y "%PM_DIR%\.env.example" "%PM_DIR%\.env" >nul
    echo - Created pain-miner-service\.env
)

echo.
echo [3/6] Creating virtualenv for seo-rank-tracker...
if not exist "%SEO_DIR%\.venv\Scripts\python.exe" (
    pushd "%SEO_DIR%"
    %PY_CMD% -m venv .venv
    if errorlevel 1 (
        popd
        echo ERROR: Failed to create venv for seo-rank-tracker.
        goto :fail
    )
    popd
)

echo.
echo [4/6] Creating virtualenv for pain-miner-service...
if not exist "%PM_DIR%\.venv\Scripts\python.exe" (
    pushd "%PM_DIR%"
    %PY_CMD% -m venv .venv
    if errorlevel 1 (
        popd
        echo ERROR: Failed to create venv for pain-miner-service.
        goto :fail
    )
    popd
)

echo.
echo [5/6] Installing dependencies for seo-rank-tracker...
pushd "%SEO_DIR%"
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
if errorlevel 1 (
    popd
    echo ERROR: pip upgrade failed for seo-rank-tracker.
    goto :fail
)
python -m pip install -e ".[dev]"
if errorlevel 1 (
    echo First attempt failed. Retrying in 3 seconds...
    powershell -NoProfile -NonInteractive -Command "Start-Sleep -Seconds 3" >nul 2>nul
    python -m pip install -e ".[dev]"
    if errorlevel 1 (
        popd
        echo ERROR: Dependency install failed for seo-rank-tracker.
        goto :fail
    )
)
popd

echo.
echo [6/6] Installing dependencies for pain-miner-service...
pushd "%PM_DIR%"
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
if errorlevel 1 (
    popd
    echo ERROR: pip upgrade failed for pain-miner-service.
    goto :fail
)
python -m pip install -e ".[dev]"
if errorlevel 1 (
    echo First attempt failed. Retrying in 3 seconds...
    powershell -NoProfile -NonInteractive -Command "Start-Sleep -Seconds 3" >nul 2>nul
    python -m pip install -e ".[dev]"
    if errorlevel 1 (
        popd
        echo ERROR: Dependency install failed for pain-miner-service.
        goto :fail
    )
)
popd

echo.
echo Setup complete.
echo Next:
echo   1) Edit seo-rank-tracker\.env and set INTERNAL_ADMIN_EMAILS to your email.
echo   2) Edit pain-miner-service\.env with Reddit credentials and PM_INTERNAL_TOKEN.
echo   3) Set the same token in seo-rank-tracker\.env as PAIN_MINER_INTERNAL_TOKEN.
echo   4) Run start-dev.bat
exit /b 0

:resolve_python
where py >nul 2>nul
if not errorlevel 1 (
    set "PY_CMD=py -3"
    exit /b 0
)
where python >nul 2>nul
if not errorlevel 1 (
    set "PY_CMD=python"
    exit /b 0
)
echo ERROR: Could not find Python on PATH.
exit /b 1

:fail
echo.
echo Setup failed.
exit /b 1
