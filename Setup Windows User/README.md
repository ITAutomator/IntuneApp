# IntuneApp Setup Windows User

## Description  

Description of this App
-------------------------------
Setup Windows User
Basic settings for a Windows User - this app is run once 
This is a User level package.

User StartMenu Cleanup.ps1
- Pin / Unpin apps from start menu and taskbar (more difficult in Win 11)

User UserPrep.ps1 
- Setting screen saver lock (takes effect after logout / logon)
- Show hidden files, show extensions
- (Win 10) Disable 'Occasionally show suggestions in Start' in Windows 10
- (Win 10) Set cortana to be only an icon
- No longer adjusts the location of the Start icon to the left (leaves it as is)
- (Win 11) Turn off opening of Widgets on hover
- (Win 11) Set Search to Icon only
- Allows location services for store (for auto Timezone adjustment) User level

RemovePersonalTeams.ps1
- Removes the personal version of Teams (so the business version is left)

TimeZone.ps1
- Sets the timezone of the machine according to the public IP address

## IntuneApp Publishing System

This app was packaged for compatibility with the *IntuneApp* Publishing System. It can also be installed\:

- automatically by other package delivdery systems using  
  `Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File IntuneUtils\intune_install.ps1 -quiet`  
- manually by double-clicking `intune_command.cmd`  

Information about the *IntuneApp* Publishing System  

- See here for the *IntuneApp* readme: (readme.md) <https://github.com/ITAutomator/IntuneApp>  
- See here for the *IntuneApp* blog post (blog): <https://www.itautomator.com/intuneapp>  
- See here for the *IntuneApp* admin guide: (pdf) <https://github.com/ITAutomator/IntuneApp/blob/main/Readme%20IntuneApp.pdf>  
- Is this code used for [a business](https://github.com/ITAutomator/IntuneApp/blob/main/LICENSE)? Become a sponsor: https://github.com/sponsors/ITAutomator  
