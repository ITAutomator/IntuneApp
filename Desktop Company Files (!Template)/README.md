
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

Double click `Desktop Company Files (As admin).cmd` to see the menu  

```code
--------------- Choices  ------------------
[B] Browse the source folder to make changes
[C] Copy company files to Public Desktop
[R] Remove company files from Public Desktop
[D] Detect company files on Public Desktop
[I] IntuneSettings.csv Injection (prep for publishing in IntuneApps)
-------------------------------------------
```
Choose `[B] Browse the source folder to make changes`  
The app package contains a source folder called `Public Desktop`.  
Here, create a `Company Files` folder (or several) which will get copied to the Public Desktop of computers.  
*Note: Files placed directly in the `Public Desktop` folder will be ignored.  Only folders are allowed in this root.*  
   
Copy files (e.g. shortcuts) and subfolders into the `Company Files` folder.  

## Test
To copy to the current machine choose `[C] Copy `  
To remove from the current machine choose `[R] Remove `  
To check if the current machine is up to date choose `[D] Detect `  

## IntuneApp Prep
To prep for IntuneApp publishing (see below) choose `[I] IntuneSettings.csv Injection`

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
