@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Service -Name 'OnokasirMySQL','OnokasirApache' | Select-Object Name,Status,StartType | Format-Table -AutoSize"
pause
