@echo off
echo Cleaning Flutter project...
cd /d "D:\AndroidStudioProjects\last_final"
call flutter clean

echo.
echo Building APK...
call flutter build apk --release

echo.
echo Build complete!
pause
