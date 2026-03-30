@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0psTaskStatus.ps1"
timeout /t 5 /nobreak >nul