@echo off
setlocal EnableExtensions DisableDelayedExpansion
title performance-app-backend DEV stop (improved)
cd /d "%~dp0"

set "LOG=[DEV]"
echo %LOG% stopping app and infra...

REM Try to close the bootRun window by title
for /f "tokens=2 delims=," %%P in ('tasklist /v /fo csv ^| findstr /i "perf-app bootRun"') do (
  echo %LOG% killing PID %%~P (bootRun window)
  taskkill /PID %%~P /T /F >nul 2>&1
)

REM Also stop any Gradle daemons
if exist gradlew.bat (
  call gradlew.bat --stop >nul 2>&1
)

REM Bring down docker compose
docker compose down -v

echo %LOG% done.
exit /b 0
