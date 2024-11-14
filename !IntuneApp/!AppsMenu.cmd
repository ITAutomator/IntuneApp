@echo off
::: suppress interaction  (Ex: batchfile.cmd -quiet)
set quiet=true
IF /I "%1" EQU "-quiet" set quiet=true
::: set name and path
set ps1path=%~dp0
set ps1name=%~n0.ps1
:: skip the opening !
set ps1name=%ps1name:~1%
:: set ps1file
set ps1file=%ps1path%%ps1name%
set ps1file_double=%ps1file:'=''%
echo -------------------------------------------------
echo - %~nx0            Computer:%computername% User:%username%%
echo - 
echo - Runs the powershell script with the same base name.
echo - 
echo - Same as dbl-clicking a .ps1, except with .cmd files you can also
echo - right click and 'run as admin'
echo - 
echo -        ps1file: %ps1file%
echo - 
echo -------------------------------------------------
if not exist "%ps1file%"  echo ERR: Couldn't find '%ps1file%' & pause & goto :eof
:: check admin
::net session >nul 2>&1
::if %errorLevel% == 0 (echo [Admin confirmed]) else (echo ERR: Admin denied. Right-click and run as administrator. & pause & goto :EOF)
:: check admin
if /I "%quiet%" EQU "false" (pause) else (echo [-quiet: 2 seconds...] & ping -n 2 127.0.0.1>nul)

set params=
if /I "%quiet%" EQU "true" set params=-quiet
@echo on
cls
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "write-host [Starting PS1 called from CMD]; Set-Variable -Name PSCommandPath -value '%ps1file_double%';cls;& '%ps1file_double%' %params%"
@echo off

echo ----- Done.