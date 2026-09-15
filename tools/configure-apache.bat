@echo off
setlocal EnableExtensions

title OnoKasir - Configure Apache

set "ROOT=D:\OnokasirLocal"
set "APACHE=%ROOT%\apache"
set "HTTPD=%APACHE%\bin\httpd.exe"
set "CONF=%APACHE%\conf\httpd.conf"
set "VHOSTDIR=%APACHE%\conf\vhosts"
set "VHOST=%VHOSTDIR%\onokasir.local.conf"

echo.
echo ============================================
echo  ONOKASIR LOCAL - CONFIGURE APACHE
echo ============================================
echo.

net session >nul 2>&1
if errorlevel 1 (
    echo [INFO] Meminta hak Administrator...
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b 0
)

if not exist "%HTTPD%" (
    echo [ERROR] Apache tidak ditemukan:
    echo         %HTTPD%
    echo.
    pause
    exit /b 1
)

if not exist "%CONF%" (
    echo [ERROR] httpd.conf tidak ditemukan:
    echo         %CONF%
    echo.
    pause
    exit /b 1
)

if not exist "%VHOSTDIR%" (
    echo [INFO] Membuat folder vhosts...
    mkdir "%VHOSTDIR%" >nul 2>&1
)

if not exist "%VHOST%" (
    echo [INFO] Membuat VirtualHost OnoKasir...

    (
        echo ^<VirtualHost *:80^>
        echo     ServerName onokasir.local
        echo     ServerAlias www.onokasir.local
        echo     DocumentRoot "D:/OnokasirLocal/public_html"
        echo.
        echo     ^<Directory "D:/OnokasirLocal/public_html"^>
        echo         Options Indexes FollowSymLinks
        echo         AllowOverride All
        echo         Require all granted
        echo     ^</Directory^>
        echo.
        echo     DirectoryIndex index.php index.html
        echo     ErrorLog "D:/OnokasirLocal/logs/onokasir-local-error.log"
        echo     CustomLog "D:/OnokasirLocal/logs/onokasir-local-access.log" combined
        echo ^</VirtualHost^>
    ) > "%VHOST%"

    echo [OK] VirtualHost dibuat:
    echo      %VHOST%
) else (
    echo [OK] VirtualHost sudah ada:
    echo      %VHOST%
)

echo.
echo [INFO] Memastikan Include VirtualHost di httpd.conf...

findstr /C:"Include conf/vhosts/onokasir.local.conf" "%CONF%" >nul 2>&1

if errorlevel 1 (
    >>"%CONF%" echo.
    >>"%CONF%" echo Include conf/vhosts/onokasir.local.conf
    echo [OK] Include VirtualHost ditambahkan.
) else (
    echo [OK] Include VirtualHost sudah tersedia.
)

echo.
echo [INFO] Apache config test...
echo.

"%HTTPD%" -t

if errorlevel 1 (
    echo.
    echo [ERROR] Apache configuration tidak valid.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo  APACHE CONFIGURATION OK
echo ============================================
echo.
echo Host: onokasir.local
echo DocumentRoot: D:\OnokasirLocal\public_html
echo.
pause

exit /b 0