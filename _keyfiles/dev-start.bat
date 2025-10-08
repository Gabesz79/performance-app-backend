@echo off
setlocal EnableExtensions DisableDelayedExpansion
title performance-app-backend DEV start
cd /d "%~dp0"

rem ============================ LOG helper =============================
set "LOGTAG=[DEV]"
call :log "%LOGTAG% Script indul..."

rem ============================ 0) JDK ================================
set "JAVA_HOME="
set "GRADLE_JAVA_HOME="

rem 0.1 Elsődleges fix útvonal (nálad létezik)
if exist "C:\Program Files\Java\jdk-21\bin\javac.exe" (
  set "JAVA_HOME=C:\Program Files\Java\jdk-21"
  call :log "%LOGTAG% JDK fix talalat: %JAVA_HOME%"
) else (
  call :log "%LOGTAG% Nincs fix jdk-21, keresek tipikus helyeken..."
  call :pick_jdk_root "C:\Program Files\Java" 21
  if not defined JAVA_HOME call :pick_jdk_root "C:\Program Files\Eclipse Adoptium" 21
  if not defined JAVA_HOME call :pick_jdk_root "C:\Program Files\Microsoft" 21
  if not defined JAVA_HOME call :pick_jdk_root "C:\Program Files\AdoptOpenJDK" 21

  if not defined JAVA_HOME (
    call :pick_jdk_root "C:\Program Files\Java" 17
    if not defined JAVA_HOME call :pick_jdk_root "C:\Program Files\Eclipse Adoptium" 17
    if not defined JAVA_HOME call :pick_jdk_root "C:\Program Files\Microsoft" 17
    if not defined JAVA_HOME call :pick_jdk_root "C:\Program Files\AdoptOpenJDK" 17
  )
)

if not defined JAVA_HOME (
  call :err  "%LOGTAG% [HIBA] Nem talaltam hasznalhato JDK-t (21/17). Telepitsd pl.: C:\Program Files\Java\jdk-21"
  goto fail
)

if not exist "%JAVA_HOME%\bin\javac.exe" (
  call :err  "%LOGTAG% [HIBA] A talalt JAVA_HOME nem JDK (hianyzik: javac.exe) -> %JAVA_HOME%"
  goto fail
)

set "GRADLE_JAVA_HOME=%JAVA_HOME%"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo [JDK] JAVA_HOME = %JAVA_HOME%
"%JAVA_HOME%\bin\java" -version 2>&1

rem IPv4 preferencia: ideiglenes + tartos (kovetkezo shell-ekre)
set "JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true"
setx JAVA_TOOL_OPTIONS "-Djava.net.preferIPv4Stack=true" >nul 2>&1

rem ======================== 1) Admin check ============================
net session >nul 2>&1
if errorlevel 1 (
  call :warn "%LOGTAG% [FIGYELEM] Nem rendszergazdakent fut. Folytatom, de egyes lepesek (szolgaltatasok leallitasa) sikertelenek lehetnek."
) else (
  call :log "%LOGTAG% Admin jog OK."
)

rem ===================== 2) Docker Desktop ============================
call :log "%LOGTAG% [1/8] Docker Desktop inditas/ellenorzes"
sc start "com.docker.service" >nul 2>&1

if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
  start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
) else if exist "%ProgramFiles(x86)%\Docker\Docker\Docker Desktop.exe" (
  start "" "%ProgramFiles(x86)%\Docker\Docker\Docker Desktop.exe"
) else if exist "%LocalAppData%\Docker\Docker\Docker Desktop.exe" (
  start "" "%LocalAppData%\Docker\Docker\Docker Desktop.exe"
)

set "TRIES=0"
:wait_docker
docker info >nul 2>&1
if not errorlevel 1 goto docker_ok
set /a TRIES=TRIES+1
if %TRIES% GEQ 120 (
  call :err "%LOGTAG% [HIBA] A Docker Engine nem erheto el 120 mp utan."
  goto fail
)
if %TRIES% EQU 5 (
  if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
)
timeout /t 1 >nul
goto wait_docker

:docker_ok
call :log "%LOGTAG%   - Docker OK."

rem ============= 3) Native Postgres stop + port info ==================
call :log "%LOGTAG% [2/8] Nativ PostgreSQL leallitasa/tiltasa (5432)"
for %%S in (
  postgresql-x64-16 postgresql-x64-15 postgresql-x64-14 postgresql-x64-13
  postgresql postgresql-16 postgresql-15 pgsql pgsql-x64-16
) do (
  sc query "%%S" >nul 2>&1 && (
    call :log "%LOGTAG%   - Szolgaltatas leallitasa: %%S"
    sc stop "%%S" >nul 2>&1
    sc config "%%S" start= disabled >nul 2>&1
  )
)
taskkill /F /IM postgres.exe /T >nul 2>&1

call :log "%LOGTAG% [3/8] 5432 port allapota (info)"
netstat -ano | findstr ":5432" >nul 2>&1
if errorlevel 1 (
  call :log "%LOGTAG%   - Nem hallgat senki a 5432 porton."
)

rem =================== 4) DB kontener + readiness =====================
call :log "%LOGTAG% [4/8] db kontener inditasa docker compose-szal"
docker compose up -d db
if errorlevel 1 (
  call :err "%LOGTAG% [HIBA] docker compose up -d db sikertelen."
  goto fail
)

call :log "%LOGTAG%   - Varakozas a Postgres ready allapotara..."
set "PGTRIES=0"
:wait_pg
docker compose exec -T db pg_isready -U perf_user -d performance_db -h localhost -p 5432 >nul 2>&1
if not errorlevel 1 goto pg_ok
set /a PGTRIES=PGTRIES+1
if %PGTRIES% GEQ 60 (
  call :err "%LOGTAG% [HIBA] A Postgres nem lett elerheto 60 mp alatt."
  goto show_db_logs
)
timeout /t 1 >nul
goto wait_pg

:pg_ok
call :log "%LOGTAG%   - Postgres kesz."

rem =============== 5) perf_user jelszo beallitasa =====================
call :log "%LOGTAG% [5/8] perf_user jelszo beallitasa (idempotens)"
docker compose exec -T db psql -U perf_user -d postgres -v "ON_ERROR_STOP=1" -c "ALTER ROLE perf_user WITH PASSWORD 'Perf_1234!';" >nul 2>&1

rem ==================== 6) DB gyorsteszt =============================
call :log "%LOGTAG% [6/8] DB kapcsolat gyorsteszt"
docker compose exec -T db psql -U perf_user -d performance_db -c "\conninfo"
if errorlevel 1 (
  call :err "%LOGTAG% [HIBA] A konteneren beluli psql teszt megbukott."
  goto show_db_logs
)

rem =================== 7) Gradle daemon stop =========================
call :log "%LOGTAG% [7/8] Regebbi Gradle daemon leallitasa"
call .\gradlew --stop >nul 2>&1

rem =================== 8) Spring Boot inditas ========================
call :log "%LOGTAG% [8/8] Spring Boot inditasa (IPv4 + JDK preferencia)"

set "GRADLE_USER_HOME=%CD%\.gradle-jdk"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%" >nul 2>&1

> "%GRADLE_USER_HOME%\gradle.properties" (
  echo org.gradle.warning.mode=summary
  echo org.gradle.java.home=%GRADLE_JAVA_HOME:\=/%
)

set "SPRING_PROFILES_ACTIVE=local"
set "SPRING_DATASOURCE_URL=jdbc:postgresql://127.0.0.1:5432/performance_db?sslmode=disable"
set "SPRING_DATASOURCE_USERNAME=perf_user"
set "SPRING_DATASOURCE_PASSWORD=Perf_1234!"
set "SPRING_FLYWAY_ENABLED=true"
set "SPRING_FLYWAY_URL=jdbc:postgresql://127.0.0.1:5432/performance_db?sslmode=disable"
set "SPRING_FLYWAY_USER=perf_user"
set "SPRING_FLYWAY_PASSWORD=Perf_1234!"

call .\gradlew --gradle-user-home="%GRADLE_USER_HOME%" bootRun
if errorlevel 1 (
  call :err "%LOGTAG% [HIBA] A bootRun hibaval leallt."
  goto fail
)

goto success

:show_db_logs
echo.
echo --- docker compose logs db (utolso 200 sor) ---
docker compose logs db --tail 200
goto fail

:fail
echo.
echo *** Inditas sikertelen. ***
pause
exit /b 1

:success
echo.
echo *** Kesz. A szolgaltatas fut (Gradle bootRun). ***
pause
exit /b 0

:: ====================== F U N K C I O K ===============================

:pick_jdk_root
rem Hasznalat: call :pick_jdk_root "GYOKER" MAJOR
set "___ROOT=%~1"
set "___MAJOR=%~2"
if not exist "%___ROOT%" goto :eof
for /d %%D in ("%___ROOT%\jdk-%___MAJOR%*") do (
  if exist "%%~fD\bin\javac.exe" (
    set "JAVA_HOME=%%~fD"
    call :log "%LOGTAG%   - JDK talalat: %%~fD"
    goto :eof
  )
)
goto :eof

:pick_jdk_from_path
for %%P in (javac.exe) do set "_JVC=%%~$PATH:P"
if defined _JVC (
  for %%Q in ("%_JVC%") do set "JAVA_HOME=%%~dpQ.."
)
set "_JVC="
goto :eof

:log
echo %~1
goto :eof

:warn
echo %~1
goto :eof

:err
echo %~1
goto :eof
