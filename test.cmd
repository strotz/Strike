@ECHO OFF
REM PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Scripts\Test.ps1"
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0Scripts\Test.ps1""' -Verb RunAs}"
PAUSE