@echo off
setlocal EnableExtensions DisableDelayedExpansion
title performance-app-backend DEV start (improved)

REM Resolve script dir and go there
cd /d "%~dp0"

set "LOG=[DEV]"
call :log "%LOG% starting..."

REM ---------- 0) JDK lookup (prefers JDK 21) ----------
set "JAVA_HOME="
set "GRADLE_JAVA_HOME="

for %%A in (
"C:\Program Files\Java\jdk-21"
"C:\Program Files\Eclipse Adoptium\jdk-21"
"C:\Program Files\Zulu\zulu-21"
"C:\Program Files (x86)\Java\jdk-21"
) do (
  if exist "%%~A\bin\javac.exe" (
    set "JAVA_HOME=%%~A"
    goto :jdk_found
  )
)

REM fallback – try current PATH
where javac >nul 2>&1
if %ERRORLEVEL%==0 (
  for /f "usebackq tokens=*" %%P in (`where javac`) do (
    set "_javac=%%~dpP.."
  )
  if exist "!_javac!\bin\javac.exe" set "JAVA_HOME=!_javac!"
)

:jdk_found
if not defined JAVA_HOME (
  call :err "%LOG% [ERROR] JDK 21 not found. Please install JDK 21."
  exit /b 2
)

set "GRADLE_JAVA_HOME=%JAVA_HOME%"
set "PATH=%JAVA_HOME%\bin;%PATH%"
call :log "%LOG% JAVA_HOME=%JAVA_HOME%"
java -version 2>&1

REM Prefer IPv4 (temporary for this shell)
set "JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true"

REM ---------- 1) Docker Desktop check & start ----------
docker version >nul 2>&1
if not %ERRORLEVEL%==0 (
  call :warn "%LOG% Docker CLI not available. Trying to start Docker Desktop..."
  if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
  ) else (
    call :err "%LOG% [ERROR] Docker Desktop not found."
    exit /b 3
  )
)

REM wait for docker engine (max ~90s)
set /a _tries=0
:wait_docker
docker info >nul 2>&1
if %ERRORLEVEL%==0 goto :docker_ready
set /a _tries+=1
if %_tries% gtr 30 (
  call :err "%LOG% [ERROR] Docker engine did not become ready in time."
  exit /b 4
)
call :log "%LOG% waiting for Docker... (%_tries%)"
timeout /t 3 >nul
goto :wait_docker
:docker_ready
call :log "%LOG% Docker is ready."

REM ---------- 2) Compose up (db etc.) ----------
if exist "docker-compose.yml" (
  call :log "%LOG% docker compose up -d ..."
  docker compose up -d
  if not %ERRORLEVEL%==0 (
    call :err "%LOG% [ERROR] docker compose up failed."
    exit /b 5
  )
) else (
  call :warn "%LOG% docker-compose.yml not found in %cd% (skipping)"
)

REM ---------- 3) Start Spring Boot (new window) ----------
if exist "gradlew.bat" (
  call :log "%LOG% launching bootRun in a new window..."
  start "perf-app bootRun" cmd /c ".\gradlew.bat --no-daemon bootRun"
) else (
  call :err "%LOG% [ERROR] gradlew.bat not found."
  exit /b 6
)

REM ---------- 4) Health check with retries ----------
set "_healthUrl=http://localhost:8080/api/healthz"
set /a _hc=0
:health_loop
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r=Invoke-WebRequest '%_healthUrl%' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { Write-Output $r.Content; exit 0 } else { exit 1 } } catch { exit 1 }"
if %ERRORLEVEL%==0 (
  call :log "%LOG% health OK."
  goto :success
)
set /a _hc+=1
if %_hc% gtr 40 (
  call :warn "%LOG% health check timeout, but bootRun window may still be starting. Open http://localhost:8080/swagger-ui.html once ready."
  goto :success
)
call :log "%LOG% waiting app health... (%_hc%)"
timeout /t 3 >nul
goto :health_loop

:success
call :log "%LOG% done. You can now work in IntelliJ. Swagger UI: http://localhost:8080/swagger-ui.html"
exit /b 0

REM ---------- helpers ----------
:log
echo %~1
goto :eof

:warn
echo %~1
goto :eof

:err
echo %~1
goto :eof
