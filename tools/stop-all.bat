@echo off
setlocal EnableExtensions

title OnoKasir Local - Stop All

set "APACHE_SERVICE=OnokasirApache"
set "MARIADB_SERVICE=OnokasirMariaDB"

echo.
echo ============================================
echo  ONOKASIR LOCAL - STOP ALL
echo ============================================
echo.
echo Apache  : %APACHE_SERVICE%
echo MariaDB : %MARIADB_SERVICE%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Stop-Service -Name '%APACHE_SERVICE%' -Force -ErrorAction Stop; Stop-Service -Name '%MARIADB_SERVICE%' -Force -ErrorAction Stop"

if errorlevel 1 (
    echo.
    echo STOP ALL GAGAL.
    echo.
    pause
    exit /b 1
)

echo.
echo STOP ALL SELESAI.
echo.
pause

endlocal
exit /b 0
