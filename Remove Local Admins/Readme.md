# IntuneApp Remove Local Admins  

## Description   

Removes users from the local administrators group.  (De-elevates them)  
The primary purpose would be to remove the initial joining user – who is automatically made a local administrator.  

Main Menu  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/RemoveLocalAdmins/RemoveLocalAdmins.png alt="screenshot" width="500"/>

## Menu
- D Detect if there are any admin accounts to fix  
- R Remove (de-elevate the detected accounts)  
- I Inject these settings into the `intune_settings.csv` (Optional: for the IntuneApp system)  

## Notes  
- Removals are from the Local Administrators group (Manged via Windows+X > [G] Computer Management)  
- Changes take effect at the *next* logon session  
- AzureAD built-in roles DeviceAdminstrators, GlobalAdministrator, etc are not touched.  
- This script is configured via the `RemoveLocalAdmins Settings.csv` file  

| Name | Value | Description |
| --- | --- | --- |
| `AdminsToAllow` | `AdminContoso,AdminFabrikant,AzureAD\JohnSmith` | List of local accounts to allow (comma separated) |
| `AdminsToRemove` | `AzureAD\*,.\*` | List of local accounts remove (de-elevate). This list removes all AzureAD and Local accounts|


- `AdminsToAllow` List any exceptions here. Leave blank to allow no exceptions to the remove list.  
`.\AdminContoso` is the same as `AdminContoso` (`.\` means local user - do not supply a PC name)
  
- `AdminsToRemove` Leave blank to remove nothing.  
 `AzureAD\*` removes AzureAD users. `.\*` removes Local users

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
