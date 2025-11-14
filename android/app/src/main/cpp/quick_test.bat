@echo off
REM Quick test build script for Strategy Pattern (Windows)
REM Run this to verify everything compiles

echo.
echo ================================================
echo   Strategy Pattern Test Build
echo ================================================
echo.

REM Check if g++ is available
where g++ >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] g++ not found. Please install MinGW or similar.
    echo.
    echo Download from: https://www.mingw-w64.org/
    pause
    exit /b 1
)

echo [OK] Compiler found
g++ --version | findstr /C:"g++"
echo.

REM Build test suite
echo [BUILD] Compiling test suite...
echo.

g++ -std=c++17 -Wall -o test_strategy.exe test_strategy_pattern.cpp core/EncryptionContext.cpp core/XOREncryptionStrategy.cpp core/NoEncryptionStrategy.cpp

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Build successful!
    echo.
    echo ================================================
    echo   Running Tests
    echo ================================================
    echo.
    
    test_strategy.exe
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ================================================
        echo   SUCCESS! All tests passed!
        echo ================================================
        echo.
        echo Next steps:
        echo   1. Review code in core/ directory
        echo   2. Read SUBMISSION_SUMMARY.md
        echo   3. Read QUICK_REFERENCE.md for presentation
        echo.
        echo Ready for course submission!
        echo.
    ) else (
        echo.
        echo [WARNING] Some tests failed.
        echo Please review the output above.
        echo.
    )
) else (
    echo.
    echo [ERROR] Build failed!
    echo Please check the error messages above.
    echo.
    pause
    exit /b 1
)

pause
