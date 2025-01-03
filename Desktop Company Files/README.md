
# Desktop Company Files Readme

See Github to download and for details: https://github.com/ITAutomator/IntuneApp/tree/main/Desktop%20Company%20Files  

Main Screen  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/DesktopCompanyFiles/MainScreen.png alt="screenshot" width="600">

## Overview

Puts a Company Files folder on company computers.

<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/DesktopCompanyFiles/Folder.png alt="screenshot" width="50">

- This package will create a Company Files folder on company computers.
- The folder will be placed in the read-only Public Desktop folder (C:\Users\Public\Desktop).
- This is a machine-based folder that all users of the computer will see mixed in with their own desktop.

# Setup Steps

Drop your company files and folders into the Public Desktop folder within the app package folder
 
If you have previously deployed a file (or folder) that you want removed, add it's full path to
`Desktop Company Files ToRemove.csv`
If these files exist they will be removed  

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
