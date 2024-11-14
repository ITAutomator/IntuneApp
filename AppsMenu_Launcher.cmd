:: ---------------------------
:: v2024-05-01
:: Powershell Launcher.cmd   www.itautomator.com
:: Launches .ps1 file with the same base name
::
:: See Readme for details
:: 
:: Usage: 
:: Copy the .cmd to the same folder as your .ps1
:: Rename it to have the same base name as your .ps1
:: Add ' (as admin)' at the end to enforce elevation
:: Double-click it
:: ---------------------------
@echo off
:: suppress interaction  (Ex: batchfile.cmd -quiet)
set quiet=false
if /I "%1" == "-quiet" set quiet=true
::: set ps1 params here
set params=
:: Example1 set params=-mode auto -samplestrparam HelloWorld
:: Example1 set params=-samplestrparam 'This IsMyString'
:: Example2 if /I "%quiet%" == "true" set params=-quiet
::
:: check if (as admin) specified, strip it too
set ps1file=%~dp0%~n0.ps1
set ps1file_orig=%ps1file%
set ps1file=%ps1file: (as admin)=%
set ps1file=%ps1file:(as admin)=%
set checkadmin=true
if "%ps1file%" == "%ps1file_orig%" set checkadmin=false
:: double the quotes
set ps1file_double=%ps1file:'=''%
:: split the path into folder and name
For %%P in ("%ps1file%") do (
    Set pfolder=%%~dpP
    Set pname=%%~nxP
)
echo -------------------------------------------------
echo - %~nx0            Computer:%computername% User:%username%%
echo - 
echo - Runs the powershell script with the same base name, without '(as admin)' if that's at the end of the cmd.
echo - 
echo - Same as dbl-clicking a .ps1, except with .cmd files you can also
echo - right click and 'run as admin'
echo - 
echo -  ps1file: '%pname%' %params%
echo - as admin: %checkadmin%
echo - 
echo -------------------------------------------------
if not exist "%ps1file%"  echo ERR: Couldn't find '%ps1file%' & pause & goto :eof
:: check admin required?
if /I "%checkadmin%" == "false" goto :ADMIN_DONE
:: check admin
net session >nul 2>&1
if %errorLevel% == 0 (echo [Admin confirmed]) else (echo ERR: Admin denied. Right-click and run as administrator. & pause & goto :EOF)
if /I "%quiet%" == "false" (ping -n 3 127.0.0.1>nul) else (echo [-quiet: 2 seconds...] & ping -n 3 127.0.0.1>nul)
:ADMIN_DONE
:: powershell version
set exename="powershell.exe"
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set psh_menu=true
if [%psh_menu%]==[] goto :PSH_MENU_DONE
CHOICE /T 5 /C 57 /D 7 /N /M "Multiple PS versions detected. Select PowerShell Version [5] or [7 Default] 5 secs:"
if %ERRORLEVEL%==1 echo Powershell 5 & goto :PSH_MENU_DONE
if %ERRORLEVEL%==2 echo Powershell 7 & set exename="%ProgramFiles%\PowerShell\7\pwsh.exe" & goto :PSH_MENU_DONE
:PSH_MENU_DONE
ping -n 3 127.0.0.1>nul
cls
%exename% -NoProfile -ExecutionPolicy Bypass -Command "write-host [Starting PS1 called from CMD] -Foregroundcolor green;& '%ps1file_double%' %params%"
::%exename% -NoProfile -ExecutionPolicy Bypass -Command "write-host [Starting PS1 called from CMD] -Foregroundcolor green; Set-Variable -Name PSCommandPath -value '%ps1file_double%';& '%ps1file_double%' %params%"
@echo off
echo -- Done with Powershell Launcher.cmd
if /I "%quiet%" == "false" (ping -n 3 127.0.0.1>nul) else (echo [-quiet: 2 seconds...] & ping -n 3 127.0.0.1>nul)