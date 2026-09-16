@echo off
setlocal EnableExtensions

title OnoKasir Local - Status

set "APACHE_SERVICE=OnokasirApache"
set "MARIADB_SERVICE=OnokasirMariaDB"

echo.
echo ============================================
echo  ONOKASIR LOCAL - SERVICE STATUS
echo ============================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-Service -Name '%MARIADB_SERVICE%','%APACHE_SERVICE%' -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize"

echo.
pause

endlocal
exit /b 0
