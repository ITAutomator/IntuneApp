@echo off
set exe=C:\Program Files\ShareX\ShareX.exe
:::::::::::::::::::::::::::::
"%exe%" -imageeditor %1
echo ShareX Image Editor
echo --------------------
echo Filename: %~nx1
echo   Folder: %~dp1
echo      Exe: %exe%
timeout /t 5 /nobreak >nul