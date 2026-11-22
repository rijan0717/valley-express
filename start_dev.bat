@echo off
setlocal
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

echo =========================================================
echo    Valley Express - Kathmandu Valley On-Demand Delivery
echo =========================================================
echo.
echo Repo root: %ROOT%
echo Starting MongoDB, Backend API and Admin Web Dashboard...
echo.

REM Locate mongod.exe - prefer PATH, then the standard install locations
set "MONGOD="
for %%V in (8.3 8.2 8.1 8.0 7.0) do (
    if not defined MONGOD if exist "C:\Program Files\MongoDB\Server\%%V\bin\mongod.exe" set "MONGOD=C:\Program Files\MongoDB\Server\%%V\bin\mongod.exe"
)
if not defined MONGOD for %%I in (mongod.exe) do if not "%%~$PATH:I"=="" set "MONGOD=%%~$PATH:I"
if not defined MONGOD (
    echo [ERROR] mongod.exe not found. Install MongoDB Server or add it to PATH.
    pause
    exit /b 1
)

if exist "%ROOT%\data\db" (
    set "DB_PATH=%ROOT%\data\db"
) else (
    set "DB_PATH=%ROOT%\backend\data\db"
    if not exist "%ROOT%\backend\data\db" mkdir "%ROOT%\backend\data\db"
)

REM Start mongod if port 27017 is not already serving
netstat -ano | findstr /r /c:"LISTENING.*:27017 " >nul 2>&1
if errorlevel 1 (
    start "MongoDB Daemon" "%MONGOD%" --dbpath "%DB_PATH%" --port 27017
    timeout /t 3 /nobreak >nul
) else (
    echo MongoDB already listening on 27017 - reusing it.
)

REM Start Backend API Server
start "Valley Express Backend (Port 5000)" cmd /k "cd /d "%ROOT%\backend" && npm run dev"

timeout /t 2 /nobreak >nul

REM Start Admin Web Dashboard
start "Valley Express Admin Web (Port 5173)" cmd /k "cd /d "%ROOT%\admin-web" && npm run dev"

echo.
echo =========================================================
echo  Valley Express Services Launched
echo.
echo  Admin Web Dashboard: http://localhost:5173
echo  Backend REST ^& Socket.io: http://localhost:5000
echo  Mobile App Preview: http://localhost:5173/mobile-preview
echo  Admin Credentials: admin@gmail.com / Password@123
echo.
echo  First run only: cd backend ^&^& npm run seed
echo =========================================================
echo.
pause
