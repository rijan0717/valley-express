@echo off
echo =========================================================
echo    Valley Express - Kathmandu Valley On-Demand Delivery
echo =========================================================
echo.
echo Starting MongoDB, Backend API and Admin Web Dashboard...
echo.

REM Start mongod if not running
start "MongoDB Daemon" "C:\Program Files\MongoDB\Server\8.3\bin\mongod.exe" --dbpath "C:\valley express\backend\data\db" --port 27017

timeout /t 2 /nobreak >nul

REM Start Backend API Server
start "Valley Express Backend (Port 5000)" cmd /k "cd /d C:\valley express\backend && npm run dev"

timeout /t 2 /nobreak >nul

REM Start Admin Web Dashboard
start "Valley Express Admin Web (Port 5173)" cmd /k "cd /d C:\valley express\admin-web && npm run dev"

echo.
echo =========================================================
echo  Valley Express Services Launched
echo.
echo  Admin Web Dashboard: http://localhost:5173
echo  Backend REST & Socket.io: http://localhost:5000
echo  Mobile App Preview: http://localhost:5173/mobile-preview
echo  Admin Credentials: admin@gmail.com / Password@123
echo =========================================================
echo.
pause
