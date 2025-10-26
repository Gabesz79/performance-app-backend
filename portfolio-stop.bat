@echo off
setlocal EnableExtensions

set "PORT=8084"
cd /d "%~dp0"

echo [PORTFOLIO] stopping app and deps

call :find_pid_on_port %PORT%
if defined PID_ON_PORT (
  echo [PORTFOLIO] killing PID %PID_ON_PORT% on port %PORT%
  taskkill /PID %PID_ON_PORT% /F 1>nul 2>&1
) else (
  echo [PORTFOLIO] no process listening on port %PORT%
)

call :find_compose
if defined COMPOSE_FILE (
  echo [PORTFOLIO] compose file found: %COMPOSE_FILE%
  echo [PORTFOLIO] docker compose down -v
  docker compose -p portfolio -f "%COMPOSE_FILE%" down -v 1>nul 2>&1
) else (
  echo [PORTFOLIO] compose file not found. skipping docker down.
)

echo [PORTFOLIO] stopped
exit /b 0

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

:find_pid_on_port
set "PID_ON_PORT="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%1 .*LISTENING"') do set "PID_ON_PORT=%%p"
exit /b 0
