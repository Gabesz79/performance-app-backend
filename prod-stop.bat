@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prod-stop.ps1" %*
