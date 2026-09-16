@echo off
setlocal EnableExtensions

title OnoKasir Local - Run All

set "APACHE_SERVICE=OnokasirApache"
set "MARIADB_SERVICE=OnokasirMariaDB"

echo.
echo ============================================
echo  ONOKASIR LOCAL - RUN ALL
echo ============================================
echo.
echo MariaDB : %MARIADB_SERVICE%
echo Apache  : %APACHE_SERVICE%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Service -Name '%MARIADB_SERVICE%' -ErrorAction Stop; Start-Service -Name '%APACHE_SERVICE%' -ErrorAction Stop"

if errorlevel 1 (
    echo.
    echo RUN ALL GAGAL.
    echo.
    pause
    exit /b 1
)

echo.
echo RUN ALL SELESAI.
echo.
pause

endlocal
exit /b 0
