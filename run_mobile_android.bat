@echo off
setlocal
title Valley Express - Android Build and Install
set "ROOT=%~dp0"
if exist "%ROOT%tools\flutter\bin\flutter.bat" set "PATH=%ROOT%tools\flutter\bin;%PATH%"
set "APK=%ROOT%mobile-app\build\app\outputs\flutter-apk\app-debug.apk"

REM Locate adb - prefer PATH, then the standard Android SDK location
set "ADB="
for %%I in (adb.exe) do if not "%%~$PATH:I"=="" set "ADB=%%~$PATH:I"
if not defined ADB if exist "%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" set "ADB=%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe"
if not defined ADB if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "ADB=%ANDROID_HOME%\platform-tools\adb.exe"

echo ========================================================
echo   Valley Express - Android Native APK Installation
echo ========================================================
echo.

cd /d "%ROOT%mobile-app" || exit /b 1

if not exist "%APK%" (
    echo APK not found - building it now...
    call flutter build apk --debug || exit /b 1
)

if not defined ADB (
    echo [WARN] adb.exe not found; falling back to "flutter install".
    call flutter install
    pause
    exit /b 0
)

echo Checking for connected Android devices or emulators...
"%ADB%" devices
echo.

echo Installing APK with ADB...
"%ADB%" install -r "%APK%"
if errorlevel 1 (
    echo.
    echo If installation failed, make sure:
    echo  1. USB Debugging is turned on in your Android phone's Developer Options.
    echo  2. Or an Android Studio emulator is currently running.
) else (
    echo.
    echo [SUCCESS] Valley Express installed on the device.
    echo Launching app...
    "%ADB%" shell monkey -p com.valleyexpress.app.valley_express_mobile -c android.intent.category.LAUNCHER 1
)
echo.
pause
