PSExec Readme.txt

In some cases, IntuneApp logs show unexpected results due to the way Intune executes code. The code executor is the service (services.msc) called Microsoft Intune Management Extension. This service runs as System. In logs the Username shows up as COMPUTERNAME$.

To simulate running as system (the way the service does) use the utility psexec from SysInternals.
The command "psexec -i -s" does this.
https://learn.microsoft.com/en-us/sysinternals/downloads/psexec

Steps to test running as system 
---------------------------------
Copy your package to Downloads [or any local folder]
%USERPROFILE%\Downloads

Option 1: Test manually from a Powershell prompt (as admin)
Open prompt as admin
CD to your work area
CD %USERPROFILE%\Downloads
Copy psexec.exe to this folder
Sample command:
psexec -i -s Powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\Downloads\MyPackage\IntuneApp\IntuneCommand.ps1"

Option 2: Test using cmd
Open PSExec Launch.cmd
Edit the ps1path variables at the top of the file to point to your package intune_command.ps1 file.
Save.
Right click the .cmd and run as admin
