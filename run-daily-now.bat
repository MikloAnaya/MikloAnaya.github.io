@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "ENV_FILE=%ROOT%\pain-miner-service\.env"
set "TOKEN=change-me"

if exist "%ENV_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        if /I "%%A"=="PM_INTERNAL_TOKEN" (
            set "TOKEN=%%B"
        )
    )
)

if "%TOKEN%"=="" set "TOKEN=change-me"

echo Triggering daily pain-miner pipeline...
powershell -NoProfile -Command ^
  "$headers=@{'x-internal-token'='%TOKEN%'};" ^
  "try {" ^
  "  $resp = Invoke-RestMethod -Method Post -Uri 'http://localhost:8100/v1/jobs/run-daily' -Headers $headers -TimeoutSec 20;" ^
  "  Write-Output 'SUCCESS:';" ^
  "  $resp | ConvertTo-Json -Depth 6;" ^
  "} catch {" ^
  "  Write-Output ('FAILED: ' + $_.Exception.Message);" ^
  "  exit 1;" ^
  "}"
if errorlevel 1 (
    echo.
    echo If this says unauthorized, check PM_INTERNAL_TOKEN in pain-miner-service\.env
    exit /b 1
)

echo.
echo Job queued. Watch progress in logs\pm-worker.log and logs\pm-beat.log
exit /b 0
