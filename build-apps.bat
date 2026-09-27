@echo off
echo ===================================================
echo           Looplyn V2 - Multi-Platform Build
echo ===================================================
echo.
echo [1] Build Web PWA (for workspace.looplyn.tech)
echo [2] Build Android APK (for sideload / Play Store)
echo [3] Build Windows Desktop (.exe)
echo [4] Build iOS Payload (for Sideloadly / AltStore .ipa)
echo ===================================================
set /p choice="Select target (1-4): "

cd /d "C:\Development\looplyn-v2\client_app"

if "%choice%"=="1" (
    echo Building Web PWA...
    flutter build web --pwa-strategy=offline-first --release
    echo.
    echo Output saved at: client_app\build\web
)

if "%choice%"=="2" (
    echo Building Android APK...
    flutter build apk --release
    echo.
    echo Output saved at: client_app\build\app\outputs\flutter-apk\app-release.apk
)

if "%choice%"=="3" (
    echo Building Windows Executable...
    flutter build windows --release
    echo.
    echo Output saved at: client_app\build\windows\x64\runner\Release
)

if "%choice%"=="4" (
    echo Building iOS Runner (Sideloadable IPA preparation)...
    flutter build ios --no-codesign --release
    echo.
    echo Output saved at: client_app\build\ios\iphoneos
    echo You can package Payload folder into .ipa for AltStore / Sideloadly.
)

pause
