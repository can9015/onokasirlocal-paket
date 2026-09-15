@echo off
setlocal EnableExtensions

title OnoKasir - Local Health Check

set "ROOT=D:\OnokasirLocal"
set "DOMAIN=onokasir.local"

set "APACHE_SERVICE=OnokasirApache"
set "MARIADB_SERVICE=OnokasirMariaDB"

set "APACHE_PORT=80"
set "MARIADB_PORT=3306"

echo.
echo ============================================
echo  ONOKASIR LOCAL - HEALTH CHECK
echo ============================================
echo.
echo Root   : %ROOT%
echo Host   : %DOMAIN%
echo Apache : %APACHE_SERVICE% : %APACHE_PORT%
echo DB     : %MARIADB_SERVICE% : %MARIADB_PORT%
echo.

set "FAIL=0"

:: =========================================================
:: APACHE SERVICE
:: =========================================================

echo [1] Apache Service

sc.exe query "%APACHE_SERVICE%" | findstr /C:"RUNNING" >nul 2>&1

if errorlevel 1 (
    echo     [FAIL] Apache tidak RUNNING.
    set "FAIL=1"
) else (
    echo     [OK] Apache RUNNING.
)

echo.

:: =========================================================
:: MARIADB SERVICE
:: =========================================================

echo [2] MariaDB Service

sc.exe query "%MARIADB_SERVICE%" | findstr /C:"RUNNING" >nul 2>&1

if errorlevel 1 (
    echo     [FAIL] MariaDB tidak RUNNING.
    set "FAIL=1"
) else (
    echo     [OK] MariaDB RUNNING.
)

echo.

:: =========================================================
:: PORT 80
:: =========================================================

echo [3] Port 80

netstat -ano | findstr /R /C:":80 .*LISTENING" >nul 2>&1

if errorlevel 1 (
    echo     [FAIL] Port 80 tidak LISTENING.
    set "FAIL=1"
) else (
    echo     [OK] Port 80 LISTENING.
)

echo.

:: =========================================================
:: PORT 3306
:: =========================================================

echo [4] Port 3306

netstat -ano | findstr /R /C:":3306 .*LISTENING" >nul 2>&1

if errorlevel 1 (
    echo     [FAIL] Port 3306 tidak LISTENING.
    set "FAIL=1"
) else (
    echo     [OK] Port 3306 LISTENING.
)

echo.

:: =========================================================
:: LOCAL HOST
:: =========================================================

echo [5] Local Host

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$r=try { Invoke-WebRequest -Uri 'http://onokasir.local/' -UseBasicParsing -TimeoutSec 8 } catch { $null }; if ($null -ne $r -and $r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { exit 0 } else { exit 1 }"

if errorlevel 1 (
    echo     [FAIL] http://onokasir.local tidak dapat diakses.
    set "FAIL=1"
) else (
    echo     [OK] http://onokasir.local dapat diakses.
)

echo.

:: =========================================================
:: PHPMYADMIN
:: =========================================================

echo [6] phpMyAdmin

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$r=try { Invoke-WebRequest -Uri 'http://onokasir.local/phpmyadmin/' -UseBasicParsing -TimeoutSec 8 } catch { $null }; if ($null -ne $r -and $r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { exit 0 } else { exit 1 }"

if errorlevel 1 (
    echo     [FAIL] phpMyAdmin tidak dapat diakses.
    set "FAIL=1"
) else (
    echo     [OK] phpMyAdmin dapat diakses.
)

echo.

:: =========================================================
:: PHP
:: =========================================================

echo [7] PHP

if exist "%ROOT%\php\php.exe" (
    "%ROOT%\php\php.exe" -v >nul 2>&1

    if errorlevel 1 (
        echo     [FAIL] PHP ditemukan tetapi gagal dijalankan.
        set "FAIL=1"
    ) else (
        echo     [OK] PHP tersedia.
    )
) else (
    echo     [FAIL] php.exe tidak ditemukan.
    set "FAIL=1"
)

echo.

:: =========================================================
:: APACHE CONFIG
:: =========================================================

echo [8] Apache Configuration

if exist "%ROOT%\apache\bin\httpd.exe" (
    "%ROOT%\apache\bin\httpd.exe" -t >nul 2>&1

    if errorlevel 1 (
        echo     [FAIL] httpd.conf tidak valid.
        set "FAIL=1"
    ) else (
        echo     [OK] Apache configuration valid.
    )
) else (
    echo     [FAIL] httpd.exe tidak ditemukan.
    set "FAIL=1"
)

echo.
echo ============================================

if "%FAIL%"=="0" (
    echo  HEALTH CHECK: ALL READY
    echo ============================================
    echo.
    exit /b 0
) else (
    echo  HEALTH CHECK: WARNING / ERROR
    echo ============================================
    echo.
    echo Periksa hasil di atas dan gunakan
    echo Control Center untuk diagnostik.
    echo.
    exit /b 1
)