@echo off
set needsadmin=no
set verbose=no
::
set ps1file=%~dp0%~n0.ps1
set ps1file_double=%ps1file:'=''%
set params=%1 %2 %3 %4 %5 %6 %7 %8
echo -------------------------------------------------
echo - %~n0
echo - 
echo - Runs the powershell script with the same base name.
echo - 
echo - Same as dbl-clicking a .ps1, except with .cmd files you can also
echo - right click and 'run as admin'
echo - 
echo -    ps1file: %ps1file% %params%
echo - needsadmin: %needsadmin%
echo -    verbose: %verbose%
echo - 
echo -------------------------------------------------
if not exist "%ps1file%" echo ERR: Couldn't find '%ps1file%' & pause & goto :EOF

if /I "%needsadmin%" EQU "no" goto :DONE_ADMIN
net session >nul 2>&1
if %errorLevel% == 0 (echo [Admin confirmed]) else (echo ERR: Admin denied. Right-click and run as administrator. & pause & goto :EOF)
:DONE_ADMIN

if /I "%verbose%" EQU "yes" @echo on & echo powershell.exe %ps1file_double% %params% & pause
if /I "%verbose%" EQU "no" cls
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "write-host [Starting PS1 called from CMD]; Set-Variable -Name PSCommandPath -value '%ps1file_double%';& '%ps1file_double%' %params%"
@echo off

echo ----- Done.
if /I "%quiet%" EQU "false" (pause) else (echo [-quiet: 2 seconds...] & ping -n 3 127.0.0.1>nul)