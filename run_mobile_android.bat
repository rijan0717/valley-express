@echo off
title Valley Express - Android APK Installer
echo ========================================================
echo   Valley Express - Android Native APK Installation
echo ========================================================
echo.
set "ANDROID_CLI=%USERPROFILE%\AppData\AndroidCLI\android.exe"
set "ADB=C:\valley express\tools\android-sdk\platform-tools\adb.exe"
set "APK=C:\valley express\mobile-app\build\app\outputs\flutter-apk\app-debug.apk"

if not exist "%APK%" (
    echo [ERROR] APK not found at %APK%
    pause
    exit /b 1
)

echo Checking for connected Android devices or emulators...
"%ADB%" devices
echo.

if exist "%ANDROID_CLI%" (
    echo Deploying with Google Android CLI (fast delta deployment)...
    "%ANDROID_CLI%" run "%APK%"
    if %errorlevel% equ 0 (
        echo.
        echo [SUCCESS] App deployed and launched via Android CLI!
        pause
        exit /b 0
    )
    echo Falling back to ADB direct installer...
)

echo Installing APK (%APK%) with ADB...
"%ADB%" install -r "%APK%"
if %errorlevel% neq 0 (
    echo.
    echo If installation failed, make sure:
    echo  1. USB Debugging is turned on in your Android Phone Developer Options.
    echo  2. Or an Android Studio Emulator is currently running.
) else (
    echo.
    echo [SUCCESS] Valley Express installed successfully on device!
    echo Launching app...
    "%ADB%" shell monkey -p com.valleyexpress.app -c android.intent.category.LAUNCHER 1
)
echo.
pause
