# IntuneApp Setup Windows Remove AzureAD Admins  

## Description   

Removes all AzureAD users from the local administrators group.  
The primary purpose would be to remove the initial joining user – who is automatically made a local administrator.  
For non-AzureAD users, local admins are displayed (not removed) and noted if they have vulnerable names (like ‘admin’).  

Note: AzureAD maintains DeviceAdminstrators role (and Global Administrator) which cannot be removed.  

See **\LocalAdminAddRemove** for a script to manually add/remove local admins.

Main Menu  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/WindowsRemoveAdmins/RemoveCloudAdmins.png alt="screenshot" width="500"/>

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
