@echo off
::: suppress interaction  (Ex: batchfile.cmd -quiet)
set quiet=true
IF /I "%1" EQU "-quiet" set quiet=true
::: suppress interaction
set ps1file=%~dp0%~n0.ps1

echo -------------------------------------------------
echo - %~n0
echo - 
echo - Runs the powershell script with the same base name.
echo - 


if exist "%ps1file%" goto :FOUNDPS1
set ps1file=%~dp0IntuneApp\%~n0.ps1

if not exist "%ps1file%"  echo ERR: Couldn't find '%~dp0%~n0.ps1' or '%ps1file%' & pause & goto :eof

:FOUNDPS1
echo - ps1file: %ps1file%
echo - 
echo -------------------------------------------------
set ps1file_double=%ps1file:'=''%
if /I "%quiet%" EQU "false" (pause) else (echo [-quiet: 2 seconds...] & ping -n 3 127.0.0.1>nul)

set params=
if /I "%quiet%" EQU "true" set params=-quiet
@echo on
cls
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "write-host [Starting PS1 called from CMD]; Set-Variable -Name PSCommandPath -value '%ps1file_double%';& '%ps1file_double%' %params%"
@echo off

echo ----- Done.
if /I "%quiet%" EQU "false" (pause) else (echo [-quiet: 2 seconds...] & ping -n 3 127.0.0.1>nul)