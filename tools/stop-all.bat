@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Stop-Service -Name 'OnokasirApache' -Force; Stop-Service -Name 'OnokasirMySQL' -Force"
