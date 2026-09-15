@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-services.ps1"
if errorlevel 1 (
  echo.
  echo INSTALL SERVICE GAGAL.
  pause
  exit /b 1
)
echo.
echo Selesai. Tekan tombol apa saja untuk keluar.
pause >nul
endlocal
