@echo off
setlocal EnableExtensions DisableDelayedExpansion
title performance-app-backend DEV start
cd /d "%~dp0"

rem ======= FIX JDK 21 HELY =======
set "JAVA_HOME=C:\Program Files\Java\jdk-21"
if not exist "%JAVA_HOME%\bin\java.exe" (
  echo(
  echo [HIBA] A beallitott JAVA_HOME nem talalhato: %JAVA_HOME%
  echo        Telepits JDK 21-et ide, vagy modositd a fajl tetejen a JAVA_HOME-ot.
  pause
  exit /b 1
)
set "PATH=%JAVA_HOME%\bin;%PATH%"

rem ======= Admin ellenorzes =======
net session >nul 2>&1 || (
  echo(
  echo [HIBA] Rendszergazdakent futtasd ezt a szkriptet!
  pause
  exit /b 1
)

:: ===== [1/8] Docker Desktop szolgaltatas inditasa =====
echo [1/8] Docker Desktop szolgaltatas inditasa

:: 1) Probald meg elinditani a szolgaltatast, ha letezik
set "DDS_STATE="
for /f "tokens=2 delims==" %%A in ('
  wmic service where "name='com.docker.service'" get State /value ^| find "="
') do set "DDS_STATE=%%A"

if /I "%DDS_STATE%"=="Running" (
  echo   - com.docker.service: RUNNING
) else if defined DDS_STATE (
  echo   - com.docker.service start...
  sc start "com.docker.service" >nul 2>&1
) else (
  echo   - Nincs com.docker.service szolgaltatas, Desktop app inditasa kell.
)

:: 2) Ha kell, inditsd a Desktop appot (GUI) tipikus helyekrol
call :start_docker_desktop_if_needed

:: 3) Varakozas a Docker Engine-re (max 120s)
set "DOCKER_OK="
set /a _tries=0
:wait_docker
docker info >nul 2>&1 && set "DOCKER_OK=1"
if not defined DOCKER_OK (
  set /a _tries+=1
  if %_tries% geq 120 (
    echo [HIBA] A Docker Engine nem erheto el 120 mp utan.
    goto fail
  )
  if %_tries% EQU 5 (
    :: Ha 5 mp utan sincs, meg egyszer megprobalkozunk a Desktop exe elinditasaval
    call :start_docker_desktop_if_needed
  )
  timeout /t 1 >nul
  goto wait_docker
)
echo   - Docker OK.
goto :after_docker_block

:start_docker_desktop_if_needed
  set "_DD_STARTED="
  for %%P in (
    "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    "%ProgramFiles(x86)%\Docker\Docker\Docker Desktop.exe"
    "%LocalAppData%\Docker\Docker\Docker Desktop.exe"
  ) do (
    if exist %%~P (
      echo   - Docker Desktop inditasa: %%~P
      start "" "%%~P"
      set "_DD_STARTED=1"
      goto :eof
    )
  )
  if not defined _DD_STARTED (
    echo   - [FIGYELEM] Nem talaltam a Docker Desktop alkalmazast ismert helyen.
    echo     Ellenorizd a telepites helyet, vagy inditsd el kezzel egyszer.
  )
  goto :eof

:after_docker_block

echo(
echo [2/8] Nativ PostgreSQL leallitasa es tiltasa (5432 felszabaditasa)
for %%S in (
  postgresql-x64-16 postgresql-x64-15 postgresql-x64-14 postgresql-x64-13
  postgresql postgresql-16 postgresql-15 pgsql-x64-16 pgsql
) do (
  sc query "%%S" >nul 2>&1 && (
    echo   - Szolgaltatas leallitasa: %%S
    sc stop "%%S" >nul 2>&1
    sc config "%%S" start= disabled >nul 2>&1
  )
)
tasklist /FI "IMAGENAME eq postgres.exe" | find /I "postgres.exe" >nul && (
  echo   - Futo postgres.exe folyamatok leallitasa...
  taskkill /F /IM postgres.exe /T >nul 2>&1
)

echo(
echo [3/8] 5432 port allapota (info)
netstat -ano | findstr ":5432" || echo   - Nem hallgat senki a 5432 porton.

echo(
echo [4/8] db kontener inditasa docker compose-szal
docker compose up -d db || ( echo [HIBA] docker compose up -d db sikertelen. & goto :fail )

echo   - Varakozas, amig a Postgres valaszol a kontenerben...
set /a _tries=0
:wait_pg
docker compose exec -T db pg_isready -U perf_user -d performance_db -h localhost -p 5432 >nul 2>&1 || (
  set /a _tries+=1
  if %_tries% geq 60 (
    echo [HIBA] A Postgres nem lett elerheto 60 mp alatt.
    goto :show_db_logs
  )
  timeout /t 1 >nul & goto :wait_pg
)
echo   - Postgres kesz.

echo(
echo [5/8] perf_user jelszo beallitasa a kontenerben (idempotens)
docker compose exec -T db psql -U perf_user -d postgres -v "ON_ERROR_STOP=1" -c "ALTER ROLE perf_user WITH PASSWORD 'Perf_1234!';" >nul 2>&1

echo(
echo [6/8] DB kapcsolat gyorsteszt a kontenerben
docker compose exec -T db psql -U perf_user -d performance_db -c "\conninfo" || (
  echo [HIBA] A konteneren beluli psql teszt megbukott.
  goto :show_db_logs
)

echo(
echo [7/8] Regebbi Gradle daemon leallitasa
call .\gradlew --stop >nul 2>&1

echo(
echo [8/8] Spring Boot inditasa (IPv4 + JDK21 kenyszer)
rem projektspecifikus Gradle user home + org.gradle.java.home
set "GRADLE_USER_HOME=%CD%\.gradle-j21"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%" >nul 2>&1
set "_JAVA_HOME_FS=%JAVA_HOME:\=/%"
> "%GRADLE_USER_HOME%\gradle.properties" (
  echo org.gradle.java.home=%_JAVA_HOME_FS%
  echo org.gradle.warning.mode=summary
)

rem Spring env
set "SPRING_PROFILES_ACTIVE=local"
set "SPRING_DATASOURCE_URL=jdbc:postgresql://127.0.0.1:5432/performance_db?sslmode=disable"
set "SPRING_DATASOURCE_USERNAME=perf_user"
set "SPRING_DATASOURCE_PASSWORD=Perf_1234!"
set "SPRING_FLYWAY_ENABLED=true"
set "SPRING_FLYWAY_URL=jdbc:postgresql://127.0.0.1:5432/performance_db?sslmode=disable"
set "SPRING_FLYWAY_USER=perf_user"
set "SPRING_FLYWAY_PASSWORD=Perf_1234!"

rem TELJES -D egy par idezojelen belul
call .\gradlew --gradle-user-home="%GRADLE_USER_HOME%" "-Dspring-boot.run.jvmArguments=-Djava.net.preferIPv4Stack=true" bootRun
set "_rc=%ERRORLEVEL%"
if not "%_rc%"=="0" (
  echo(
  echo [HIBA] A bootRun hibaval leallt. (RC=%_rc%)
  goto :fail
)

goto :success

:show_db_logs
echo(
echo --- docker compose logs db (utolso 200 sor) ---
docker compose logs db --tail 200
goto :fail

:fail
echo(
echo *** Inditas sikertelen. ***
pause
exit /b 1

:success
echo(
echo *** Kesz. A szolgaltatas fut (Gradle bootRun). ***
pause
exit /b 0