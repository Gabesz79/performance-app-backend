@echo off
setlocal
title performance-app-backend - DEV STOP
echo Stopping Spring Boot app on port 8080 (if running)...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do (
  echo Found PID %%a on 8080, terminating...
  taskkill /PID %%a /T /F >NUL 2>&1
)
echo Bringing down Docker Compose services...
docker compose down
echo Done.
pause
endlocal
