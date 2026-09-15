@echo off
setlocal EnableExtensions

title OnoKasir Local Control Center

set "ROOT=D:\OnokasirLocal"
set "SCRIPT=%ROOT%\tools\control-center.ps1"

if not exist "%SCRIPT%" (
    echo.
    echo ============================================
    echo  ERROR
    echo ============================================
    echo Script tidak ditemukan:
    echo %SCRIPT%
    echo.
    pause
    exit /b 1
)

:: =========================================================
:: CHECK ADMINISTRATOR
:: =========================================================

net session >nul 2>&1

if errorlevel 1 (
    echo.
    echo Meminta hak Administrator...
    echo.

    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"

    exit /b 0
)

:: =========================================================
:: RUN CONTROL CENTER
:: =========================================================

echo.
echo ============================================
echo  ONOKASIR LOCAL CONTROL CENTER
echo ============================================
echo.
echo [OK] Administrator
echo [OK] Script: %SCRIPT%
echo.
echo Menjalankan Control Center...
echo.

powershell.exe ^
    -NoLogo ^
    -NoProfile ^
    -ExecutionPolicy Bypass ^
    -File "%SCRIPT%"

set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
    echo.
    echo ============================================
    echo  CONTROL CENTER ERROR
    echo ============================================
    echo.
    echo Exit Code: %EXITCODE%
    echo.
    pause
)

endlocal
exit /b 0