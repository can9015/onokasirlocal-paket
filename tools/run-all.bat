@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Service -Name 'OnokasirMySQL'; Start-Service -Name 'OnokasirApache'"
