
# Printers With Exe Drivers Readme

See Github to download and for details: https://github.com/ITAutomator/IntuneApp/tree/main/Printers%20With%20Exe%20Drivers  

Main Menu  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/Printers/PrinterWithExeMenu.png alt="screenshot" width="600"/>

## Overview

`PrinterSetup.ps1` in this package adds the EXE based printers listed in `PrintersToAdd.csv` and in the `\Drivers` folder.
It also removes any printers listed in `PrintersToRemove.csv` (if found)

The program uses three key components, all added via the Printer Manager main menu:

1. **PrintersToAdd.csv**  
   A list of printers to add to PCs.  
   The list consists of printer names and their corresponding .exe file names  
   If the printer has an ARM64 exe, add a 2nd row with the same printer name that refers to the Arm exe file.  

2. **PrintersToRemove.csv**  
   An (optional) list of obsolete printers to remove from PCs.  

3. **IntuneApp/Drivers**  
   A folder of the .exe files used to install the added printers.  
   Both x64 and ARM64 drivers can be included.  
  
> Note: This package is specifically for exe-based drivers.  
The exe, provided by certain manufacturers (e.g. Ricoh), installs all the required drivers, settings, and the printer name via a single, silent exe file.  
To package regular printer drivers, see the *Printer Manager* based app instead:  https://github.com/ITAutomator/IntuneApp/tree/main/Printers

## Setup steps

1. Download  
   Download the `IntuneApp` folder from here: [link](https://github.com/ITAutomator/IntuneApp/tree/main/Printers%20With%20Exe%20Drivers)

2. Add rows to `PrintersToAdd.csv` for each printer  
   <img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/Printers/PrinterWithExeAdd.png alt="screenshot" width="300"/>  
   Enter values for these three columns  

   - CPU - Use `x64` (or `ARM64` if it's an ARM driver)  
   - Printer - Enter the *exact* name of the printer that is installed by the installer (used to detect if install is needed)  
   - Installer - Enter the file name of the `exe` installer  

3. Drivers  
   Copy the corresponding `exe` file into the `\Drivers` subfolder.  

4. Add rows to `PrintersToRemove.csv` for each obsolete printer to be removed (optional)  

5. Test the installer  
   Right-click and run `PrinterSetup (as Admin).cmd` to start the main menu.  
   `[I] Install`  
   `[U] Uninstall`  
   `[P] Prep for Intune`  

   Use `[I] Install` to test installation of the printers.  
   Use `[U] Uninstall` to test uninstallation of the printers.  

6. IntuneApp usage  
   If you are using the *IntuneApp* system, use `[P] Prep for Intune` to auto-configure `intune_settings.csv` with the correct values as per your printer lists (important for detection).  

> Note: To facilitate different printer lists for different groups, use multiple copies of the package in different folders and update the lists independently.

## Automation outside of the IntuneApp Publishing system

Use `PrinterSetup.ps1 -mode install` to install automatically.  
Use `PrinterSetup.ps1 -mode uninstall` to uninstall automatically.  

## IntuneApp Publishing System

This app was packaged for compatibility with the *IntuneApp* Publishing System.  
It can also be installed by other package delivdery systems.
It can also be installed manually or by other package delivdery systems. (use intune_command.cmd to manually install / uninstall this app).  
See below for more information about using this sytem to publish Windows apps to your Intune endpoints.  

- See here for the up to date readme: (readme.md) <https://github.com/ITAutomator/IntuneApp>  
- See here for the blog post (blog): <https://www.itautomator.com/intuneapp>  
- See here for the admin guide: (pdf) <https://github.com/ITAutomator/IntuneApp/blob/main/Readme%20IntuneApp.pdf>  
