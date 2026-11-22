@echo off
setlocal
title Valley Express - Mobile Web Runner
set "ROOT=%~dp0"
if exist "%ROOT%tools\flutter\bin\flutter.bat" set "PATH=%ROOT%tools\flutter\bin;%PATH%"
echo ========================================================
echo   Starting Valley Express Mobile Application (Flutter)
echo ========================================================
echo.

REM Verify Backend is responding on port 5000
netstat -ano | findstr /r /c:"LISTENING.*:5000 " >nul 2>&1
if errorlevel 1 (
    echo [INFO] Backend is not running on port 5000. Launching start_dev.bat...
    start "Valley Express Services" cmd /c "cd /d "%ROOT%" && call start_dev.bat"
    echo Waiting for backend to initialize...
    timeout /t 5 /nobreak >nul
) else (
    echo [OK] Backend is already running on http://localhost:5000
)

echo.
echo Target: Chrome. Backend on http://localhost:5000
echo.
cd /d "%ROOT%mobile-app" || exit /b 1
call flutter pub get
call flutter run -d chrome
pause
