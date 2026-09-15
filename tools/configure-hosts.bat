@echo off
setlocal EnableExtensions

title OnoKasir - Configure Hosts

set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
set "DOMAIN=onokasir.local"
set "IP=127.0.0.1"

echo.
echo ============================================
echo  ONOKASIR LOCAL - CONFIGURE HOSTS
echo ============================================
echo.
echo Hosts : %HOSTS%
echo Domain: %DOMAIN%
echo IP    : %IP%
echo.

net session >nul 2>&1
if errorlevel 1 (
    echo [INFO] Meminta hak Administrator...
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b 0
)

findstr /R /C:"^[ ]*%IP%[ ]\+%DOMAIN%[ ]*$" "%HOSTS%" >nul 2>&1

if not errorlevel 1 (
    echo [OK] Host sudah terdaftar:
    echo      %IP%    %DOMAIN%
    echo.
    pause
    exit /b 0
)

echo.
echo [INFO] Menambahkan host...

>>"%HOSTS%" echo %IP%    %DOMAIN%

if errorlevel 1 (
    echo [ERROR] Gagal menulis hosts.
    echo.
    pause
    exit /b 1
)

echo [OK] Host berhasil ditambahkan.
echo.

ipconfig /flushdns >nul 2>&1

echo [OK] DNS cache berhasil di-refresh.
echo.
echo ============================================
echo  SELESAI
echo ============================================
echo.

pause
exit /b 0