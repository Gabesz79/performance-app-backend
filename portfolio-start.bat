@echo off
setlocal EnableExtensions

rem ===== Base config =====
set "PROFILE=portfolio"
set "PORT=8084"
set "DB_PORT=5433"
set "HEALTH1=http://localhost:%PORT%/api/healthz"
set "HEALTH2=http://localhost:%PORT%/actuator/health"
set "DOCS=http://localhost:%PORT%/v3/api-docs"
set "TAIL_EVERY_N_TICKS=15"  rem 1 tick = 2 mp -> 30 mp-enkent log tail

cd /d "%~dp0"

echo [PORTFOLIO] profile=%PROFILE%
echo [PORTFOLIO] app port=%PORT%
echo [PORTFOLIO] health primary=%HEALTH1%

rem ===== .run + log =====
if not exist ".run" mkdir ".run" 1>nul 2>&1
for /f "delims=" %%t in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd-HHmmss')"') do set "TS=%%t"
set "LOG=.run\portfolio-bootrun-%TS%.log"

rem ===== Gradle wrapper autodetect =====
set "GRADLEW="
if exist "gradlew.bat" set "GRADLEW=gradlew.bat"
if not defined GRADLEW if exist "gradlew" set "GRADLEW=gradlew"
if not defined GRADLEW (
  echo [PORTFOLIO] ERROR: gradle wrapper not found in repo root.
  exit /b 1
)

rem ===== docker compose autodetect + DB start =====
call :find_compose
if defined COMPOSE_FILE (
  echo [PORTFOLIO] compose file found: %COMPOSE_FILE%
  echo [PORTFOLIO] docker compose up -d
  docker compose -p portfolio -f "%COMPOSE_FILE%" up -d 1>nul 2>&1

  echo [PORTFOLIO] waiting for DB port %DB_PORT%
  call :wait_port %DB_PORT% 120
  if errorlevel 1 (
    echo [PORTFOLIO] WARN: DB port %DB_PORT% not listening yet. continue.
  ) else (
    echo [PORTFOLIO] DB port %DB_PORT% is listening.
  )
) else (
  echo [PORTFOLIO] compose file not found. skipping DB startup.
)

rem ===== free app port if needed =====
call :find_pid_on_port %PORT%
if defined PID_ON_PORT (
  echo [PORTFOLIO] port %PORT% in use by PID %PID_ON_PORT%. killing...
  taskkill /PID %PID_ON_PORT% /F 1>nul 2>&1
  timeout /t 1 >nul
) else (
  echo [PORTFOLIO] port %PORT% free.
)

rem ===== start bootRun WITHOUT extra window =====
echo [PORTFOLIO] starting bootRun (no extra window), logging to %LOG%
start "" /b cmd /c "set SPRING_PROFILES_ACTIVE=%PROFILE% && set SERVER_PORT=%PORT% && call %GRADLEW% bootRun 1>>%LOG% 2>&1"

rem ===== robust health check (healthz OR actuator/health OR v3/api-docs) =====
echo [PORTFOLIO] waiting for health: healthz OR actuator/health OR v3/api-docs
set /a _tries=300
set /a _tick=0

:health_loop
call :probe_health
if %errorlevel%==0 goto app_ok

set /a _tries-=1
if %_tries% LEQ 0 goto health_fail

set /a _tick+=1
if %_tick% GEQ %TAIL_EVERY_N_TICKS% (
  echo [PORTFOLIO] --- log tail ---
  powershell -NoProfile -Command "Get-Content -Tail 20 '%LOG%'"
  set /a _tick=0
)
timeout /t 2 >nul
goto health_loop

:app_ok
echo [PORTFOLIO] health OK
echo [PORTFOLIO] swagger: http://localhost:%PORT%/swagger-ui/index.html
exit /b 0

:health_fail
echo [PORTFOLIO] ERROR: health timeout. last 200 log lines:
powershell -NoProfile -Command "Get-Content -Tail 200 '%LOG%'"
exit /b 1

rem ==================== Subroutines ====================

:find_compose
for %%P in (
  "docker-compose.portfolio.yml"
  "docker\portfolio\docker-compose.yml"
  "docker\portfolio.yml"
  ".docker\portfolio\docker-compose.yml"
  ".docker\portfolio.yml"
  "compose\portfolio\docker-compose.yml"
  "compose\portfolio.yml"
  "infra\portfolio\docker-compose.yml"
  "infra\docker-compose.portfolio.yml"
  "infra\docker-compose.yml"
  "docker-compose.yml"
) do (
  if not defined COMPOSE_FILE if exist "%%~P" set "COMPOSE_FILE=%%~P"
)
exit /b 0

:wait_port
rem %1=port  %2=tries (2 sec per try)
set "WPORT=%1"
set /a WTRIES=%2
:wp_loop
set "WFOUND="
for /f "delims=" %%L in ('netstat -ano ^| findstr /R /C:":%WPORT% .*LISTENING"') do set "WFOUND=1"
if defined WFOUND exit /b 0
set /a WTRIES=WTRIES-1
if %WTRIES% LEQ 0 exit /b 1
timeout /t 2 >nul
goto wp_loop

:find_pid_on_port
rem %1=port -> sets PID_ON_PORT
set "PID_ON_PORT="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%1 .*LISTENING"') do set "PID_ON_PORT=%%p"
exit /b 0

:probe_health
rem ===== Curl-based health probe (no FOR/backticks, no %%{...}) =====
set "TMP=.run\_hc.tmp"
del /q "%TMP%" >nul 2>&1

rem 1) /api/healthz -> ok
"%SystemRoot%\System32\curl.exe" -s --max-time 2 "%HEALTH1%" > "%TMP%" 2>nul
if exist "%TMP%" (
  set "H="
  set /p H=<"%TMP%"
  if /I "%H%"=="ok" ( del /q "%TMP%" >nul 2>&1 & exit /b 0 )
)

rem 2) /actuator/health -> contains UP
"%SystemRoot%\System32\curl.exe" -s --max-time 2 "%HEALTH2%" > "%TMP%" 2>nul
if exist "%TMP%" (
  findstr /I "UP" "%TMP%" >nul 2>&1 && ( del /q "%TMP%" >nul 2>&1 & exit /b 0 )
)

rem 3) /v3/api-docs -> curl --fail succeeds (HTTP 2xx)
"%SystemRoot%\System32\curl.exe" -s --fail --max-time 2 -o NUL "%DOCS%"
if %errorlevel%==0 ( del /q "%TMP%" >nul 2>&1 & exit /b 0 )

del /q "%TMP%" >nul 2>&1
exit /b 1
