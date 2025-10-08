@echo off
setlocal
REM ---- Opcionális kapcsolók:
REM   --with-deps     : függőségek listázása (lassabb)
REM   --interactive   : külön PS ablak nyílik, ami Transcripttel mindent logol
set PSARGS=
for %%A in (%*) do (
  if /I "%%~A"=="--with-deps" set PSARGS=%PSARGS% -WithDeps
  if /I "%%~A"=="--interactive" set PSARGS=%PSARGS% -Interactive
)

REM A PowerShell script futtatása (policy megkerülés, profilok nélkül)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0save_conversation_and_context.ps1" %PSARGS%
endlocal
