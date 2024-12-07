# IntuneApp

Create and publish Windows apps to your Intune endpoints  
See here for the blog post: <https://www.itautomator.com/intuneapp>   
See here for the admin guide: [pdf](https://github.com/ITAutomator/IntuneApp/blob/main/Readme%20IntuneApp.pdf)   

- Main Screen2
![image](https://github.com/user-attachments/assets/a5307e75-4a19-424a-8bfe-4f68f78d4d72)

## Quick Start

Download IntuneApps
-------------------------------

Download as [ZIP](https://github.com/ITAutomator/IntuneApp/archive/refs/heads/main.zip)
Or Go [here](https://github.com/ITAutomator/IntuneApp) and click Code (the green button) > Download Zip
Extract Zip into C:\IntuneAppMain (or anywhere)

Test a pre-packaged installer
-------------------------------

This will test a package on your machine.

Open C:\IntuneAppMain \7zip
Double click intune_command.cmd
Choose (D)etect – Look for the last line of info – it should say whether you already have 7zip.
Choose (I)nstall – This will install 7zip
Note: (D)etect, (R)equirements, (I)nstall, (U)ninstall are the four core Intune actions for Windows packages. Here, you are able to run them manually to see what Intune does behind the scenes.

Test installing a few apps at once
-------------------------------

Open C:\IntuneAppMain and run AppsMenu_Launcher.cmd
Choose (I)nstall apps
On the list of apps that pops up, ctrl – click (select) one or more apps.
Choose (I)nstall
The installers should run for all the apps

Publish Prep
-------------------------------

This will prep your org for publishing

Choose (P) to begin publishing
Choose (O) Prep a new Org for publishing apps
Enter your org’s primary domain name.
Modules: There are modules that need to be on the publishing machine: Microsoft.Graph and IntuneWin32App
These will be checked during the process, but you may need to install these before proceeding.
Follow the prompts to install the publishing app in Entra.

Publish Apps
-------------------------------

This will publish / update apps to your org

Choose (P) to begin publishing
Choose your org from the list of prepped orgs (see above)
On the list of apps that pops up, ctrl – click (select) one or more apps.
After publishing the apps, look in Intune for the Apps themselves.
Look in Entra for assignment groups starting with IntuneApp

Push (Assign) Apps to Users
-------------------------------

This will push apps to endpoint machines

Published apps are assigned by Entra Groups.
IntuneApp Windows Users
This group is where mandatory apps get published. Put all your Windows users in this group. It can be dynamic.
IntuneApp Windows Users Excluded
This group excludes people from any publishing
IntuneApp [Appname]
Each app will have a group where you can add people that are supposed to get the app.

Manually install an App for a User
-------------------------------

This is how you can manually install an app (as a user).

Published apps are available to users in the Company Portal app and can be installed from there (no admin rights are required).
Check the C:\IntuneApps folder on the endpoint for logging etc.

Admins looking to manually install can copy the individual app folders to the endpoint and run intune_command.cmd (see above).

## Intune Apps

-------------------------------
This app package is structured in a way that's friendly to Intune.
The IntuneApp codebase facilitate installing and publishing apps.
For up-to-date information (and to download the IntuneApp system) see here: <https://github.com/ITAutomator/IntuneApp>

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
- Requires admin credentials

Publish your app
--------------------------------

- Choose P - Publish app
- Publishing your app does the following
- Puts the app in the company portal so users can self-install manually
- Creates your app in the Intune apps list <https://intune.microsoft.com/>
- Creates 3 groups (as needed) and attaches them to your app
- IntuneApp Windows Users - Will receive mandatory apps (apps having PublishToOrgGroup in settings.csv)  If you want this to be everyone, convert it to a dynamic group with the dynamic rules neeced.
- IntuneApp Windows Users Excluded - Are excluded from above
- IntuneApp WindowsApp Google Chrome - Users that will get this app (and future versions) even if it isn't mandatory

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
- winget   Microsoft newish packaging system
- choco    Chocolate is a popular pre-Microsoft packaging system (Open source)
- ps1      Powershell script
- cmd      Windows batch command
- msi      MSI installer
- exe      EXE installer
- AppInstallName
- for winget and choco, provide the app package ID
- for everything else, provide the installer filename (eg myps1.ps1 or setup.msi) (it must exist in the \IntuneApp folder)
- IntuneApp folder
- contains the intune_settings.csv and intune_icon.png files
- provide the installer file and any files / folders needed by the installer

### AppInstallName For Winget and Chocolatey packages


- These are the most common package types.
- You will need the package id for the AppInstallName settings
- For Winget apps search here: <https://winstall.app/>
- For Chocolatey apps search here: <https://community.chocolatey.org/packages>

### AppInstallArgs For Ps1 packages

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

### Folder structure

App Name
| intune_command.cmd                                   (Double click to manually launch Intune commands. Optional but convenient)
| Misc un-packaged files                               (These files are not copied to Intune)
+-- Misc un-packaged folder1
+-- Misc un-packaged folder2
+-- IntuneApp                                          (Package folder - copied to Intune)
    | intune_icon.png                                  (Package icon - Replace with app icon)
    | intune_settings.csv                              (Package settings - Edit app settings)
 | Misc templated files go here                     (Optional template files if needed by App - for advanced apps)
    +-- IntuneUtils                                    (Managed code - do not touch. Added by AppPublish.ps1)
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
