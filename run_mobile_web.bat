@echo off
setlocal
title Valley Express - Mobile Web Runner
set "ROOT=%~dp0"
echo ========================================================
echo   Starting Valley Express Mobile Application (Flutter)
echo ========================================================
echo.
echo Target: Chrome. Backend must be running on http://localhost:5000
echo.
cd /d "%ROOT%mobile-app" || exit /b 1
call flutter pub get
call flutter run -d chrome
pause
