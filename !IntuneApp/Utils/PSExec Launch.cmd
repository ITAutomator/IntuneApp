@echo off
:: don't use quotes around path
set ps1dir=%USERPROFILE%\Downloads\Winget Update\IntuneApp\IntuneUtils
set ps1fil=intune_command.ps1
::
set quiet=false
set ps1path="%ps1dir%\%ps1fil%"
set psexec=%~dp0psexec.exe
echo -------------------------------------------------
echo - %~nx0            Computer:%computername% User:%username%%
echo - 
echo - Runs the powershell script as local service.
echo - 
echo - Uses PSexec.exe
echo - 
echo -  psexec: %psexec%
echo - ps1path: %ps1path%
echo - 
echo -------------------------------------------------
if not exist %ps1path%  echo ERR: Couldn't find %ps1path% & pause & goto :eof
:: check admin
net session >nul 2>&1
if %errorLevel% == 0 (echo [Admin confirmed]) else (echo ERR: Admin denied. Right-click and run as administrator. & pause & goto :EOF)
:: check admin
if /I "%quiet%" EQU "false" (pause) else (echo [-quiet: 2 seconds...] & ping -n 3 127.0.0.1>nul)

set params=
if /I "%quiet%" EQU "true" set params=-quiet
@echo on
cls
"%psexec%" -i -s Powershell.exe -ExecutionPolicy Bypass -File %ps1path%
@echo off

echo ----- Done.
if /I "%quiet%" EQU "false" (pause) else (echo [-quiet: 2 seconds...] & ping -n 3 127.0.0.1>nul)
