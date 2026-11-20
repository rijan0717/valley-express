@echo off
title Valley Express - Mobile Web Runner
echo ========================================================
echo   Starting Valley Express Mobile Application (Flutter)
echo ========================================================
echo.
echo Launching local server on http://localhost:8080...
echo.
start http://localhost:8080
node "%~dp0tools\serve_mobile.js"
pause
