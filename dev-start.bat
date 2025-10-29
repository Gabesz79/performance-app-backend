@echo off
setlocal
set "PG_PORT=5432"
for /f "tokens=*" %%A in ('powershell -NoProfile -Command "if ((Get-NetTCPConnection -LocalPort %PG_PORT% -State Listen -ErrorAction SilentlyContinue)) { 'BUSY' }"') do set "PORT_STATUS=%%A"
if "%PORT_STATUS%"=="BUSY" (
  echo [HIBA] A %PG_PORT% port foglalt. Zarj be mas Postgrest vagy valassz masik portot!
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dev-start.ps1" %*
exit /b %errorlevel%