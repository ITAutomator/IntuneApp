Description of this App
-------------------------------
Use Printer Manager to automatically set up a standard list of printers on your PCs.
The program uses 3 key components:

- PrinterManager PrintersToAdd.csv
A list of printers to add to PCs.

- PrinterManager PrintersToRemove.csv 
An (optional) list of obsolete printers to remove from PCs.

- IntuneApp\Drivers
A folder of drivers used to install the added printers.
Both x64 and ARM65 drivers can be included.

See Printer Manager Readme for more details.

Zipping the printer drivers to Google Drive
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