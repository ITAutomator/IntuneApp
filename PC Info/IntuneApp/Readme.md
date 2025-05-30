# PC Info Setup.ps1

Use this to install the PC Info Program for all users of a machine.

There are two steps to the install.  It's hard to surface a .ps1 to all users (as a Start Menu icon)
  
Step 1: The machine is set up with a program files folder  
C:\Program Files\PC Info  
PC Info Setup.ps1  
PC Info.lnk  
PC Info.ps1  

Also, this registry key is added so that users (on logon) will run the install_user portion  
HKLM:\Software\Microsoft\Active Setup\Installed Components\PC Info  
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -file "C:\Program Files\PC Info\PC Info Setup.ps1" -mode install_user  

Step 2: On users first logon  
PC Info Setup.ps1 -mode install_user  
This copies the .lnk file into the Start Menu of the user.  

Done  
