This is an Intune App
-------------------------------
This app package is structured in a way that's friendly to Intune.
The IntuneApp codebase facilitate installing and publishing apps.

Setup your central Apps folder (do this once)
-------------------------------
1. Create a folder for all your apps                     (Z:\Apps)
2. Copy the !IntuneApp folder to there                   (Z:\Apps\!IntuneApp)

Setup your App
-------------------------------
1. Create an empty folder for your new app                        (Z:\Apps\7Zip)
2. Copy the contents of !App Template to your app folder          (Z:\Apps\!IntuneApp\!App Template)
3. Update the 2 required files, rename them to remove '_template' (Z:\Apps\7Zip\IntuneApp)
   intune_icon.png, intune_settings_template.csv
4. Test Install and Publish
   
Test your App
--------------------------------
1. Test by running intune_command.cmd
2. Requirements - should say REQUIREMENTS_MET on any machine that can have the app (others will say Not available in Intune).
3. Detected - should say Detected or not detected (if the app is already installed)
4. Install - installs the app
5. Uninstall - uninstalls the app

Publish your app
--------------------------------
-  Set up your org tenant by adding it to AppsPublish_OrgList.csv (for apps with AvailableInCompanyPortal setting)
-  Run AppsPublish.ps1 to publish to Intune (you will need Intune credentials to proceed)
-  AppsPublish:
Puts the app in the company portal so users can self install manually ()
Creates your app in the Intune apps list https://intune.microsoft.com/
Creates 3 groups (as needed) and attaches them to your app
Intune Windows Users - Will receive apps with the PublishToOrgGroup settings.  If you want this to be everyone, convert it to a dynamic group with the dynamic rules neeced.
Intune Windows Users Excluded - Are excluded from above
Intune WindowsApp 7Zip - Users that are selected to get this app (and future versions)

Manually Installing Apps
--------------------------------
-  Copy the App folder to the target machine Downloads folder
-  Run intune_command.cmd and choose Install

Manually Installing Multiple Apps
--------------------------------
-  Copy the Apps folders to the target machine Downloads folder
-  Or use your USB copy (see below) and run from there
-  Copy the !IntuneApp folder along with your apps
-  Run AppsInstall.cmd to install multiple apps without stopping

Creating a USB-based installer
--------------------------------
-  This is useful to set up a machine without waiting for Intune
-  Copy your Apps to a thumbdrive folder (D:\Apps)
-  Dbl-click AppsCopy.cmd to Create / Refresh your thumbdrive folder   (Z:\Apps\!IntuneApp\AppsCopy.cmd)
-  AppsCopy.cmd: 
Only copies the IntuneApp folders needed to install.
Smartly copies using robocopy to only copy changes.

Setting up your App package
-------------------------------
-  AppInstaller - one of these installer types
winget   Microsoft newish packaging system
choco    Chocolate is a popular pre-Microsoft packaging system (Open source)
ps1      Powershell script
cmd      Windows batch command
msi      MSI installer
exe      EXE installer
- AppInstallName
for winget and choco, provide the app package ID
for everything else, provide the installer filename (eg myps1.ps1 or setup.msi) (it must exist in the \IntuneApp folder)
- IntuneApp folder
contains the intune_settings.csv and intune_icon.png files
provide the installer file and any files / folders needed by the installer

AppInstallName For Winget and Chocolatey packages
-------------------------------
-  These are the most common package types.
-  You will need the package id for the AppInstallName settings
-  For Winget apps search here: https://winstall.app/
-  For Chocolatey apps search here: https://community.chocolatey.org/packages

AppInstallArgs For Ps1 packages
-------------------------------
(Optional) Prefix your arguments with the 'ARGS:' keyword
for ps1 with multiple parameters, it's best to use named parameters
ARGS:-var1 xyz -var2 pdq
for ps1 with single parameter, you can just pass the contents
ARGS:use settings file.xml

AppInstallArgs For msi exe packages
-------------------------------
(Optional) Prefix your arguments with the 'ARGS:' keyword
for msi usually 
ARGS:/quiet
ARGS:/q /norestart

About the template app
--------------------------------------------
Updates to code base should only go here.
Treat this as the master code base for new apps.

Folder structure
---------------------
App Name
| intune_command.cmd                                   (Double click to manually launch Intune commands. Optional but convenient)
| Misc un-packaged files
\-- Misc un-packaged folder1
\-- Misc un-packaged folder2
\-- IntuneApp                                          (Package folder)
    | intune_icon.png                                  (Package icon - Replace with app icon)
    | intune_settings.csv                              (Package settings - Edit app settings)
	| Misc templated files go here                     (Optional template files if needed by App - for advanced apps)
    \-- IntuneUtils                                   (Managed code - do not touch. Added by AppPublish.ps1)
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