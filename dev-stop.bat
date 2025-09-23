@echo off
setlocal EnableExtensions
title performance-app-backend - DEV STOP
cd /d "%~dp0"

echo [1/3] Gradle daemon leallitasa...
call .\gradlew --stop >nul 2>&1

echo [2/3] Spring Boot (8080) leallitasa...
set "FOUND="
for /f "tokens=5" %%P in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do (
  set "FOUND=1"
  echo   - PID %%P talalva a 8080-as porton, leallitom...
  taskkill /PID %%P /T /F >nul 2>&1
)

if not defined FOUND (
  echo   - Nem talaltam LISTENING folyamatot a 8080-as porton.
)

echo [3/3] Docker Compose szolgaltatasok leallitasa (db)...
docker compose stop db >nul 2>&1

rem Ha teljes takaritas kell (halo + network torles is), vedd ki a REM-et:
rem echo Teljes docker compose down...
rem docker compose down

echo Kesz.
pause
endlocal
