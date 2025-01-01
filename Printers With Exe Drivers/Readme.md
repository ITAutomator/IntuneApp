
# Printers With EXE Drivers Readme

See Github to download and for details: https://github.com/ITAutomator/IntuneApp/tree/main/Printers%20With%20Exe%20Drivers 

## Description of this App

Your app description goes here.
It should roughly match what you've entered in IntuneApp\intune_settings.csv

## IntuneApp Publishing System

This app was packaged for compatibility with the *IntuneApp* Publishing System.  
It can also be installed by other package delivdery systems.
It can also be installed manually or by other package delivdery systems. (use intune_command.cmd to manually install / uninstall this app).  
See below for more information about using this sytem to publish Windows apps to your Intune endpoints.  

- See here for the up to date readme: (readme.md) <https://github.com/ITAutomator/IntuneApp>  
- See here for the blog post (blog): <https://www.itautomator.com/intuneapp>  
- See here for the admin guide: (pdf) <https://github.com/ITAutomator/IntuneApp/blob/main/Readme%20IntuneApp.pdf>  


## Overview

Use Printer Manager to automatically set up a standard list of printers on your PCs.  
It works by ingesting printer drivers from a working PC and then packaging it for distribution. It handles both Intel and ARM drivers.  

Printer Manager is Intune and script friendly and designed to work within the IntuneApp system.

zipping a large drivers folder
see *Publishing your own zip file* in  

Enter the Drivers folder and ZIP the contents to your downloads folder calling it Printers (Contoso).zip. 
Run this powershell to get hash value from the zip file

gci $env:USERPROFILE\Downloads -filter *.zip -Recurse | Get-FileHash -Algorithm SHA256 | Select-Object Hash, @{n="File";e={Split-Path $_.Path -Leaf}}
(Paste it here)

The program uses three key components, all added via the Printer Manager main menu:

1. **PrinterManager PrintersToAdd.csv**  
   A list of printers to add to PCs.

2. **PrinterManager PrintersToRemove.csv**  
   An (optional) list of obsolete printers to remove from PCs.

3. **IntuneApp/Drivers**  
   A folder of drivers used to install the added printers.  
   Both x64 and ARM64 drivers can be included.  
   
Printer Manager Main Menu  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/Printers/MainMenu.png alt="screenshot" width="500"/>

---

# Setup Steps

Download the package and copy it to a central area.

Right-click and run `PrinterManager (as Admin).cmd` to start the main menu.

*Note: The 2 main CSV files will be created if they don’t exist.*

*Note: To facilitate different printer lists for different groups, use multiple copies of the package in different folders and update the lists independently:*

`Printers (Accounting Group)`

`Printers (Executive Group)`

### Main Menu

```
--------------- Printer Manager Menu ------------------  
(S) Setup all the CSV printers (to this PC) PC \<-- CSV  
(O) Setup one CSV printer (to this PC) PC \<-- CSV  
(V) Update a driver to the \Drivers folder PC --\> CSV  
(A) Add a local printer to CSV list PC --\> CSV  
(U) Uninstall the CSV listed printers PC (X) CSV  
(R) Local printer deletion PC (X)  
(D) Local driver deletion PC (X)  
(P) Local port deletion PC (X)  
(E) Edit CSV Files manually CSV  
(T) Detect if PC has CSV printers already CSV  
(I) Prep intune_settings.csv with these printers (for IntuneApp)  
(X) Exit
```

## Add a Printer

On a PC with the printer already installed use menu choice A.

`(A) Add a local printer to CSV list`

This will add the printer to the CSV and copy the drivers to the Drivers folder.

The printer is now included in the package and will be distributed to other PCs

Repeat adding as many printers as needed.

## Edit the CSV files

To fine tune your list use menu choice E

`(E) Edit CSV Files manually`

This will allow you to edit the list of printers.

Here you can also adjust the IP numbers if they change.

`PrinterManager PrintersToAdd.csv`

| Column Name | Example Contents | Explanation |
|------------------|-------------------------|------------------------------|
| Printer | Contoso Room 101 Copier | Printer display name |
| Driver-x64 | HP Universal\prnbrcl1.inf | \<Menu option (A) handles this\> |
| Driver-ARM64 | HP Universal\armbrc1.inf | \<Menu option (A) handles this\> |
| Port | 192.168.53.60 | \<Menu option (A) handles this\> |
| Model |  | \<optional helpful model info\> |
| URL |  | \<optional helpful url\> |
| Settings |  | \<Menu option (A) handles this\> |
| Location | Room 101 | \<optional helpful info displayed by Windows\> |

#### Settings column

Settings are for keywords that control the default settings (color, duplexing, etc) for the installed printer.

If the settings value is empty, the driver defaults will be used.

During the `Add a Printer` process you will be asked to choose from a list of default combinations of settings.

This list can be adjusted.

`PrinterManager Settings.csv`

| Description | Settings |
|------------------|------------------------------------------------------|
| Default | \<blank\> |
| LetterColor | Papersize=Letter,Collate=False,Color=True |
| LetterGreyscale | Papersize=Letter,Collate=False,Color=False |
| LetterColorDuplex | Papersize=Letter,Collate=False,Color=True,DuplexingMode=TwoSidedLongEdge |
| LetterGreyscaleDuplex | Papersize=Letter,Collate=False,Color=False,DuplexingMode=TwoSidedLongEdge |
| A4Color | Papersize=A4,Collate=False,Color=True |

### Summary of Settings

Settings are in the form: key=value,key=value,…

See here for a full list of these values: [Link](https://learn.microsoft.com/en-us/powershell/module/printmanagement/set-printconfiguration?view=windowsserver2025-ps)

| Key           | Value            |
|---------------|------------------|
| Papersize     | Letter or A4     |
| DuplexingMode | TwoSidedLongEdge |
| Collate       | True or False    |
| Color         | True or False    |

## Prep for Intune

If you are planning on distributing this package using the [**IntuneApp**](https://www.itautomator.com/intuneapp/) app package system, use menu choice I

`(I) Prep intune_settings.csv with these printers (for IntuneApp)`

This will make the necessary changes to the `intune_settings.csv` file so that Intune detection and installation will work properly in the IntuneApp system.

Essentially it puts the lists of printers in the app variables section of that csv file.

## A note about ARM drivers

The package is CPU aware. If you add a printer from an ARM machine, the driver will be added to the ARM driver folder and its own ARM column in the CSV.

If you want the printer to work in both types of CPUs, use A to add the printer from both PC types to get both driver packages. But you will have two CSV rows. Use the values from both driver columns to merge the two CSV rows into a single row.

## Manual installation of the printers

Copy the package folder to a target PC.

Right-click and run PrinterManager (as Admin).cmd to get to the main menu.

Use menu choice S or menu choice O to install the printers.

`(S) Setup all the CSV printers (to this PC)`

`(O) Setup one CSV printer (to this PC)`

Use menu choice N to Uninstall the printers.

`(U) Uninstall the CSV listed printers`

## Scripted installation of the printers

We recommend using the [**IntuneApp**](https://www.itautomator.com/intuneapp/) app package system as the easiest way of distributing the printer package.

Alternatively, use the -mode S command line to automate installations.

`PrinterManager.ps1 -mode S`

This will automatically make the menu choice S and install the printers.

`PrinterManager.ps1 -mode U`

This will automatically make the menu choice U and uninstall the printers.

`PrinterManager.ps1 -mode T`

This will automatically make the menu choice T to detect if the printers are installed.

## More information

See also: <https://www.itautomator.com/intuneapp>  
See also: <https://github.com/ITAutomator/IntuneApp>  







Description of this App
-------------------------------



Zipping the printer drivers to Google Drive (Optional)
-------------------------------
There is normally an IntuneApp\Drivers folder, but it can be large due to the drivers.
So a ZIP file can be created:
- Enter the Drivers folder and ZIP the contents to your downloads folder calling it Printers (Contoso).zip. 
- Run this powershell in downloads folder to get a hash value from the zip file
gci *.zip | Get-FileHash -Algorithm SHA256 | Select-Object Hash, @{n="File";e={Split-Path $_.Path -Leaf}}
(Paste it here)
Hash                                                             File
----                                                             ----
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Printers (Contoso).zip
- Upload to your Google Drive area
- Share the .zip : Anyone with the link > Viewer
(Paste it here)
https://drive.google.com/file/d/xxxxxxxxxxxxxxxxxxxxxxxxx/view?usp=sharing

- Update intune_settings.csv with these two values
AppInstallerDownload1URL (Share URL)
AppInstallerDownload1Hash (Hash value)

- See Printers Readme.txt for more information including the valid Settings values


This is an IntuneApp
-------------------------------
This app package is structured in a way that's friendly to Intune.
The IntuneApp codebase facilitate installing and publishing apps.
For up-to-date information (and to download the IntuneApp system) see here: https://github.com/ITAutomator/IntuneApp
For a brief guide to setting up the IntuneApp system, see below.

Setup your central Apps folder (do this once)
-------------------------------
- Create a folder for all your apps                     (Z:\Apps)
- Copy the !IntuneApp folder here                       (Z:\Apps\!IntuneApp)
- Put the main menu here                                (Z:\Apps\AppsMenu_Launcher.cmd and .ps1) 
- Double-click the main menu (AppsMenu_Launcher.cmd)

Setup your App
-------------------------------
- Choose [L] List / Create apps
- Choose [B] Browse Winget library for an AppID (e.g. Google.Chrome)
- Choose [C] Create a new app
- Update the 2 required files (Z:\Apps\Google Chrome\IntuneApp\intune_icon.png, intune_settings.csv
- Install, Test, Publish
   
Install and Test your App
--------------------------------
- Test by running intune_command.cmd (or choose [I] - Install / Uninstall apps)
- Requirements - should say REQUIREMENTS_MET on any machine that can have the app (others will say Not available in Intune).
- Detected - should say Detected or not detected (if the app is already installed)
- Install - installs the app
- Uninstall - uninstalls the app
- Logs can be found in C:\IntuneApp

Prep your M365 Org for apps
--------------------------------
- Must be done once per M365 tenant
- Choose P - Publish / Unpublish apps
- Choose O - Prep an Org for publishing
- Creates the registered app (in Entra) required to publish: IntuneApp Publisher
-   Requires admin credentials

Publish your app
--------------------------------
- Choose P - Publish app
- Publishing your app does the following
-   Puts the app in the company portal so users can self-install manually
-   Creates your app in the Intune apps list https://intune.microsoft.com/
-   Creates 3 groups (as needed) and attaches them to your app
-   IntuneApp Windows Users - Will receive mandatory apps (apps having PublishToOrgGroup in settings.csv)  If you want this to be everyone, convert it to a dynamic group with the dynamic rules neeced.
-   IntuneApp Windows Users Excluded - Are excluded from above
-   IntuneApp WindowsApp Google Chrome - Users that will get this app (and future versions) even if it isn't mandatory

Manually Installing Apps
--------------------------------
- Copy the App folder to the target machine Downloads folder
- Run intune_command.cmd and choose Install

Manually Installing Multiple Apps
--------------------------------
- Copy the Apps folders to the target machine (e.g. to Downloads folder)
- Or use your USB-based installer (see below) and run from there
- Copy the !IntuneApp folder and the root AppsMenu files along with your apps
- Run AppsInstall.cmd to install multiple apps without stopping

Creating a USB-based installer
--------------------------------
- This is useful to set up a machine without waiting for Intune
- Choose [C] - Copy apps (to a USB key)
- Copies your Apps to a thumbdrive folder (D:\Apps) using robocopy to make it fast.

Setting up your App package (Misc Info)
-------------------------------
- AppInstaller - one of these installer types
-   winget   Microsoft newish packaging system
-   choco    Chocolate is a popular pre-Microsoft packaging system (Open source)
-   ps1      Powershell script
-   cmd      Windows batch command
-   msi      MSI installer
-   exe      EXE installer
- AppInstallName
-   for winget and choco, provide the app package ID
-   for everything else, provide the installer filename (eg myps1.ps1 or setup.msi) (it must exist in the \IntuneApp folder)
- IntuneApp folder
-   contains the intune_settings.csv and intune_icon.png files
-   provide the installer file and any files / folders needed by the installer

AppInstallName For Winget and Chocolatey packages
-------------------------------
- These are the most common package types.
- You will need the package id for the AppInstallName settings
- For Winget apps search here: https://winstall.app/
- For Chocolatey apps search here: https://community.chocolatey.org/packages

AppInstallArgs For Ps1 packages
-------------------------------
- (Optional) Prefix your arguments with the 'ARGS:' keyword
- for ps1 with multiple parameters, it's best to use named parameters
- ARGS:-var1 xyz -var2 pdq
- for ps1 with single parameter, you can just pass the contents
- ARGS:use settings file.xml

AppInstallArgs For msi exe packages
-------------------------------
- (Optional) Prefix your arguments with the 'ARGS:' keyword
- for msi usually 
- ARGS:/quiet
- ARGS:/q /norestart

Folder structure
---------------------
App Name
| intune_command.cmd                                   (Double click to manually launch Intune commands. Optional but convenient)
| Misc un-packaged files                               (These files are not copied to Intune)
\-- Misc un-packaged folder1
\-- Misc un-packaged folder2
\-- IntuneApp                                          (Package folder - copied to Intune)
    | intune_icon.png                                  (Package icon - Replace with app icon)
    | intune_settings.csv                              (Package settings - Edit app settings)
	| Misc templated files go here                     (Optional template files if needed by App - for advanced apps)
    \-- IntuneUtils                                    (Managed code - do not touch. Added by AppPublish.ps1)
        | intune_command.cmd                           {Menu of Intune commands: Install, Uninstall, Detect, Requirements}
        | intune_command.ps1                           {Menu code}
        | intune_detection.ps1                         {App Detection. True: app is installed}
        | intune_detection_customcode_template.ps1     {Template}
        | intune_icon_template.png                     {Template}
        | intune_install.ps1                           {App Install}
        | intune_install_followup_template.ps1         {Template}
        | intune_requirements.ps1                      {App Requirements - True: this machine meet requirements for app install}
        | intune_requirements_customcode_template.ps1  {Template}
        | intune_settings_template.csv                 {Template}
        | intune_uninstall.ps1                         {App Uninstall}
        | intune_uninstall_followup_template.ps1       {Template}
        | README.txt                                   (Readme}