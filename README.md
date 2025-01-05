# IntuneApp  
  
Create and publish Windows apps to your Intune endpoints  

- See here for the up-to-date readme: (readme.md) <https://github.com/ITAutomator/IntuneApp>  
- See here for the blog post (blog): <https://www.itautomator.com/intuneapp>  
- See here for the admin guide: (pdf) <https://github.com/ITAutomator/IntuneApp/blob/main/Readme%20IntuneApp.pdf>  
- Is this product used for [a business](https://github.com/ITAutomator/IntuneApp/blob/main/LICENSE)? Become a sponsor: https://github.com/sponsors/ITAutomator  

Main Screen  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/IntuneApp/MainScreen.png alt="screenshot" width="600">
  
## Quick Start  
  
### Download IntuneApps  

Download as [ZIP](https://github.com/ITAutomator/IntuneApp/archive/refs/heads/main.zip)  
Or Go [here](https://github.com/ITAutomator/IntuneApp) and click `Code` (the green button) `> Download Zip`  
Extract Zip into `C:\Apps` or a shared folder `Z:\Apps` (or anywhere)  

### Unblock Downloaded Files  

Windows native security will [block](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-7.4) downloaded `.cmd` and `.ps1` files.  
This prevents them from running directly from Explorer (as a security measure).  
You can unblock each `.cmd` manually via *File > Properties > Unblock*  
Or use these steps to unblock all the code files at once:  
Open `Z:\Apps` and double-click `AppsMenu_Launcher.cmd`  (Click *More info > Run anyway* on the block message)  
Choose `[L] - List / Create apps`  
Choose `[U] - Unblock any downloaded apps`  
  
### Test a pre-packaged installer  

This will test a simple package (7-Zip) on your machine.  
  
Open `Z:\Apps\7zip`  
Double click `intune_command.cmd`  
Choose `(D)etect` – Look for the last line of info – it should say whether you already have 7zip.  
Choose `(I)nstall` – This will install 7zip  
Note: `(D)etect`, `(R)equirements`, `(I)nstall`, `(U)ninstall` are the four core Intune actions for Windows packages.  
Here, you are able to run them manually to see what Intune does behind the scenes.  
  
### Test installing a few apps at once  

Open `Z:\Apps` and run `AppsMenu_Launcher.cmd`  
Choose `(I)nstall apps`  
On the list of apps that pops up, ctrl – click (select) one or more apps.  
Choose `(I)nstall`  
The installers should run for all the apps  
  
### Publish Prep  

This will prep your org for publishing  
  
Choose `(P) Publish` to begin publishing  
Choose `(O) Org Prep` to connect and prepare Org for publishing apps  
Enter your org’s primary domain name.  
Follow the prompts to install the publishing app in Entra.  

> ℹ️ A note about modules: These modules need to be on the publishing machine:  
*`Microsoft.Graph`*  
*`IntuneWin32App`*  
Use the `(M) Modules` menu to install them, or install them manually.  
Hint: Use the `Relaunch as (A)dmin` option so that modules are installed machine-wide.  
  
### Publish Apps  

This will publish / update apps in your org  
  
- Choose `(P) Publish` to begin publishing  
- Choose your org from the list of prepped orgs (see *Org Prep* above)  
- On the list of apps that pops up, ctrl – click (select) one or more apps.  
- After publishing the apps, look at the Intune list: *Intune Admin > Apps > Windows*  
- Adjust the assignment groups (names start with IntuneApp): *Entra Admin > Groups*  
  
### Push (Assign) Apps to Users  

This will push apps to endpoint machines  
Published apps are assigned by these *Entra Groups*.  

`IntuneApp Windows Users`  
This is a special group where *all* mandatory apps get published.  
Put all your Windows users in this group.  
It is created as a static group, but can be changed to be dynamic (see *dynamic* below).  
`IntuneApp Windows Users Excluded`  
This is a special exclusion group to exclude people from *all* mandatory apps.  
When first rolling out, you may want to make the include group dynamic for everyone, and *statically* add everyone to the exclude group.  This will exclude everyone except for new users.  You can then slowly remove people's exclusions to test that everything is working as expected.
`IntuneApp <Appname>`  
Each app will have a group where you can add people that are supposed to get the app.  

## Group and App Creation  

### App Creation

The app and all its required groups are created entirely by the code.  You can adjust the created app, but it will be overwritten by any future updates applied by the code.
To avoid getting overwritten, rename the app after making manual adjustments.  But then no updates will be applied to the renamed app *and* the old app name will be re-created if it is again published.

### Group creation  

The system creates all groups as static user groups (initally empty).  Since all checking is done by name (rather than ID), the underlying structure of the created groups can be changed to device groups and / or dynamic groups and they will not be adjusted by the code.

### User Groups vs Device Groups  

Generally speaking, device groups should be avoided.  A device will be considered to be a member of a user group as long as its *primary user* is a member of the group, which should be good enough and everyone's primary device will receive the app.  
With user groups, the user should always get the assigned apps even if they are issued a new device.

## Intune Apps  

App packages are structured in a way that's friendly to Intune.  
The `IntuneApp` codebase facilitate installing and publishing apps.  
For up-to-date information (and to download the IntuneApp system) see here: <https://github.com/ITAutomator/IntuneApp>  
  
### Setup your central Apps folder (do this once)  

- Create a folder for all your apps                     `Z:\Apps`  
- Copy the !IntuneApp folder here                       `Z:\Apps\!IntuneApp`  
- Put the main menu here                                `Z:\Apps\AppsMenu_Launcher.cmd` and `.ps1`  
- Double-click the main menu (AppsMenu_Launcher.cmd)  
  
### Setup your App  

- Choose `[L] List / Create apps`  
- Choose `[B] Browse Winget library` for an AppID (e.g. Google.Chrome)  
- Choose `[C] Create a new app`  
- Update the 2 required files `Z:\Apps\Google Chrome\IntuneApp\intune_icon.png`, `intune_settings.csv`  
- Install, Test, Publish  
  
### Install and Test your App  

- Test by running `intune_command.cmd` (or choose `[I] - Install` / Uninstall apps)  
- `Requirements` - should say `REQUIREMENTS_MET` on any machine that can have the app (others will say Not available in Intune).  
- `Detected` - should say Detected or not detected (if the app is already installed)  
- `Install` - installs the app  
- `Uninstall` - uninstalls the app  
- Logs can be found in `C:\IntuneApp`  
  
### Prep your M365 Org for apps  

- Must be done once per M365 tenant  
- Choose `P - Publish` / Unpublish apps  
- Choose `O - Prep` an Org for publishing  
- Creates the registered app (in Entra) required to publish: `IntuneApp Publisher`  
- Requires admin credentials  
  
### Publish your app

- Choose `P - Publish app`  
- Publishing your app does the following  
  - Puts the app in the company portal so users can self-install manually  
  - Creates your app in the Intune apps list <https://intune.microsoft.com/>  
  - Attaches up to 4 required groups (as per options set in `intunesettings.csv`). The groups are created if not found, but existing groups are left as-is.
    - `IntuneApp Windows Users` - Will receive mandatory apps (apps having `PublishToOrgGroup`=TRUE)  If you want this to be everyone, convert it to a dynamic group with the dynamic rules needed.  
    - `IntuneApp Windows Users Excluded` - Are excluded from above  
    - `IntuneApp Google Chrome` - Users that will get this app (and future versions) even if it isn't mandatory  
    - `IntuneApp Google Chrome Excluded` - Users that will be excluded from this app (optional based on `intunesettings.csv`)
  
## Installation methods

Use any of these methods to install your app(s)

### Manually Installing Apps  

- Copy the App folder to the target machine Downloads folder  
- Run intune_command.cmd and choose Install  

### Manually install an App for a User  

This is how you can manually install an app (as a user).  
  
Published apps are available to users in the Company Portal app and can be installed from there (no admin rights are required).  
Check the `C:\IntuneApps folder` on the endpoint for logging etc.  
  
Admins looking to manually install can copy the individual app folders to the endpoint and run `intune_command.cmd` (see above).  
  
### Manually Installing Multiple Apps  

- Copy the Apps folders to the target machine (e.g. to Downloads folder)  
- Or use your USB-based installer (see below) and run from there  
- Copy the !IntuneApp folder and the root AppsMenu files along with your apps  
- Run AppsInstall.cmd to install multiple apps without stopping  
  
### Creating a USB-based installer  

- This is useful to set up a machine without waiting for *Intune* to install them in the background.  
- Choose [C] - Copy apps (to a USB key)  
- Copies your Apps to a thumbdrive folder (e.g. `D:\Apps`).  
- Bring the thumbdrive to your target machine and run `AppsMenu_Launcher.cmd` and choose I to install.

### Install / Uninstall via a generic package installer

- Create the package for delivery  
Zip the entire `\IntuneApp` folder for delivery to your endpoint  
Use the these commands to initiate the various actions  
You can double-click `intune_command.cmd` to see a menu to run them interactively  
- Install command  
`Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File IntuneUtils\intune_install.ps1 -quiet`  
- Uninstall command  
`Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File IntuneUtils\intune_uninstall.ps1 -quiet`  
- Detection command  
`Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File IntuneUtils\intune_detection.ps1 -quiet`  
- Requirements command  
`Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File IntuneUtils\intune_requirements.ps1 -quiet`  

## Common Actions  

### Publishing to All Users

If an App is to be an Intune Required App for *all* users, two items need to be checked.

- The app’s `intune_settings.csv` file needs to have `PublishToOrgGroup=TRUE.` This will ensure the `IntuneApp Windows Users` group is assigned to the app as required.  
- The `IntuneApp Windows Users` group membership must include the users, either statically or dynamically.  

### Converting to a dynamic group

Normally, the `IntuneApp Windows Users` group should include everyone in the organization. However, manually maintaining a *static* group as users join the organization will be cumbersome.  
Here's how to convert the `IntuneApp Windows Users` group from a *static* group (where users are manually added), to a *dynamic* group (that automatically includes everyone).  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/IntuneApp/GroupPropertiesDynamic.png alt="screenshot" width="300">  

- Open the `IntuneApp Windows Users` group in Entra and click on *Properties*
- Change the type from *Assigned* to *Dynamic User*
- Click *Add Dynamic Query > Edit Query* and paste the query from below.

> This query means: All Licensed users, that are not disabled, and not any of these named users

```text
(user.assignedPlans -any (assignedPlan.servicePlanId -ne "[noplanplaceholder]" -and assignedPlan.capabilityStatus -eq "Enabled"))
-and (user.accountEnabled -eq True)
```

### Checking App publishing status in Intune

Open *Intune Admin > Apps > Windows > (App) > Overview*  
This will show details about who has received the app  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/IntuneApp/AppPropertiesOverview.png alt="screenshot" width="300">  

### Publishing an update to an App (Re-publishing)

*IntuneApp* handles versions differently than native *Intune* versioning and dependency, which would be too complicated to maintain.
*IntuneApp* maintains versions within the `intune_settings.csv` file as follows.

#### **AppVersion vs AppUninstallVersion**

During the publishing process, if any changes are detected since the last publish (using the content hash file), the `AppVersion` is automatically incremented. In Intune, the old app is erased and replaced with the new version of the App, and 0 devices will have it installed.

When Intune next checks in (every few hours), the detection process will determine if the new app is detected or not.  

- *If not,* it will be installed.
- *If its detected,* the device count will be incremented in the App Overview section.

The default behavior of an *IntuneApp* is to detect based on the `AppUninstallVersion` in the `intune_settings.csv` file. If `AppUninstallVersion` is blank (the default), the app is considered detected if any prior version of the app has been installed.

If you are replacing a previously pushed version and you want to trigger a re-install for existing devices, you must change `AppUninstallVersion` to match the `AppVersion`. If you don’t adjust this, only new devices will get the new version of the app.

### Debugging at the endpoint

All logging and endpoint information is kept in the `C:\IntuneApp` folder, in `csv` and `txt` files.  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/IntuneApp/EndpointLogs.png alt="screenshot" width="300">  

#### **Logs**

The `Log *.txt` files in the `C:\IntuneApp` folder show logging output from the scripts' `Write-host` commands.  

- These files self-purge once they hit a certain size, so as not to impact disk space.  
- Inspect the log files for debugging purposes.  
- You should expect *Intune*'s regular detection routine to update these files every few hours (when Intune makes sure the required apps are still installed).  

#### **Install Tracking via `IntuneApp.csv`**

The `IntuneApp.csv` in the `C:\IntuneApp` folder keeps track of installs and detections and versions.  If this file is deleted, all `.ps1` installs will be considered undetected and will be installed again unless custom detections dictate otherwise.  
For debugging purposes you can remove rows to trigger re-detect and re-install events for an app.  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/IntuneApp/EndpointIntuneApp.png alt="screenshot" width="300">  

## Setting up your App package (Misc Info)  

### Package folder

The root package folder name (e.g. `7Zip`) will be your App Name.  
It must match the `App name` value in `intune_settings.csv`.  

<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/IntuneApp/AppFolders.png alt="screenshot" width="300">  

The root package folder contains:

- the `IntuneApp` folder with the `intune_settings.csv` for core settings, the `intune_icon.png` icon file, and other package files to install the app
- the `intune_command.cmd` which is an optional file to manually kick off the install, uninstall, detect, and requiment actions (for testing)

### Folder structure  

```text
\ App Name                                             Package Root (Folder name must match App Name in intune_settings.csv)  
| intune_command.cmd                                   Double click to manually launch Intune commands (Optional but convenient)  
| Misc un-packaged files                               Reference files (not copied to Intune)  
\-- Misc un-packaged folder1                           Reference files (not copied to Intune)  
\-- Misc un-packaged folder2                           Reference files (not copied to Intune)  
\-- IntuneApp                                          Package folder - copied to Intune  
    | intune_icon.png                                  Package icon - Replace with app icon  
    | intune_settings.csv                              Package settings - Edit app settings  
    | (optional) intune_detection_customcode.ps1       Optional code file if needed - for advanced apps  
    | (optional) intune_requirements_customcode.ps1    Optional code file if needed - for advanced apps  
    | (optional) intune_install_followup.ps1           Optional code file if needed - for advanced apps  
    | (optional) intune_uninstall_followup.ps1         Optional code file if needed - for advanced apps  
    \-- IntuneUtils                                    Managed code - do not touch. Added by AppPublish.ps1  
        | intune_command.cmd                           Menu of Intune commands: Install, Uninstall, Detect, Requirements  
        | intune_command.ps1                           Menu code  
        | intune_detection.ps1                         App Detection. True: app is installed  
        | intune_detection_customcode_template.ps1     Template code for optional file   
        | intune_icon_template.png                     Template code for optional file  
        | intune_install.ps1                           App Install  
        | intune_install_followup_template.ps1         Template  
        | intune_requirements.ps1                      App Requirements - True: this machine meet requirements for app install  
        | intune_requirements_customcode_template.ps1  Template code for optional file  
        | intune_uninstall.ps1                         App Uninstall  
        | intune_uninstall_followup_template.ps1       Template code for optional file  
        | README.txt                                   Readme  
```

### `intune_settings.csv` Detailed settings information

|Name                      |Value                 |Comment|
|---------                 |---------             |-------|
|AppName                   |7Zip                  |(Required) Base package name (e.g 7zip) (Remove ! Character which hides sample apps)|
|AppVersion                |111                   |(Optional) Package version. Whole numbers beginning with 100. Nothing to do with product version. (e.g. 100 for 7zip-v100) (Recommended)|
|AppInstaller              |winget                |(Required) winget,choco,exe,msi,ps1. If winget choco is used leave AppUninstallName blank unless you want to uninstall an additional app|
|AppInstallName            |7zip.7zip             |(Required) winget appid (case sensitive) or choco appid or filename of .exe or .msi or .ps1 or .cmd (wildcard OK). See https://winstall.app or https://community.chocolatey.org/packages for package ids.|
|AppInstallArgs            |                      |(Optional) Prefix with ARGS: Installer arguments for msi,ps1,exe (for msi usually /quiet or /q /norestart) (for ps1 with multi param try -var1 xyz -var2 pdq named format or else entire value is first param)|
|AppDescription            |zip file management   |(Required) Info for company portal|
|AppUninstallName          |                      |(Optional) winget name or winget id (Use 'winget list' to show them) to detect/uninstall (also done prior to install). This is in addition to the normal choco,winget uninstall. This field is required for non-winget packages, unless customcode.ps1 is used, as it is the only way to detect an app|
|AppUninstallVersion       |22                    |(Optional) Winget product version (e.g. 4.5.0) below which to the app is considered not detected. Below this version will be uninstalled / reinstalled. Blank=All versions are OK and will not be reinstalled. Use current version to repackage an app to upgrade everyone to latest version.|
|AppUninstallProcess       |\*7zip\*                |(Optional) Processes to end prior to uninstall. (e.g. Acrobat\*) Show running names via powershell: get-process -Name Acrob*. Wildcards can be used|
|SystemOrUser              |system                |(Required) System to install as system User to install as user|
|Publisher                 |Igor Pavlov of 7Zip   |(Required) Info for company portal|
|AppInstallerDownload1URL  |                      |Enter a URL to download into install folder before installer starts. Can be a public share from Google Drive (drive.google.com). Zip files will be extracted automatically.|
|AppInstallerDownload1Hash |                      |Enter the file hash (optional) Get-FileHash -Algorithm SHA256|
|AppInstallerDownload2URL  |                      ||
|AppInstallerDownload2Hash |                      ||
|RestartBehavior           |allow                 |Allow Installer to Restart (Default is allow)|
|Developer                 |                      |Info for company portal|
|Owner                     |                      |Info for company portal|
|Notes                     |                      |Info for company portal|
|InformationURL            |https://www.7-zip.org |Info for company portal|
|PrivacyURL                |                      |Info for company portal|
|CompanyPortalFeaturedApp  |FALSE                 |(Required) Company Portal Featured (Default is FALSE)|
|AvailableInCompanyPortal  |TRUE                  |(Required) Company Portal Availability (Default is TRUE)|
|PublishToOrgGroup         |TRUE                  |(Required) App will be pushed immediately to the PublishToGroup group from AppsPublish_OrgList.csv (as a required app). False means do not push app to that group. Independent of this, apps are always published to its own `IntuneApp [appname]` group (Default is FALSE)|
|CreateExcludeGroup        |FALSE                 |(Optional) When app is published, create both Include and Exclude groups specific to the app. (Default is FALSE)|
|AppVar1                   |                      |Custom var useable by ps1 files|
|AppVar2                   |                      |Custom var useable by ps1 files|
|AppVar3                   |                      |Custom var useable by ps1 files|
|AppVar4                   |                      |Custom var useable by ps1 files|
|AppVar5                   |                      |Custom var useable by ps1 files|

### `AppInstaller` the type of the installer  

  `winget`   Microsoft's command line packaging system  
  `choco`    Chocolate is a popular pre-Microsoft packaging system (Open source)  
  `ps1`      Powershell script  
  `msi`      MSI installer  
  `exe`      EXE installer  

### `AppInstallName` the name of the installer  

for `winget` and `choco`  

- `winget` and `choco` are the most common Windows package installers  
- if `AppInstaller` is `winget` or `choco`, set the `AppInstallName` to the app package ID as defined within those syetems  
- For *Winget* apps (e.g. `Google.Chrome`) search here: <https://winstall.app/>  
- For *Chocolatey* apps (e.g. `googlechrome`) search here: <https://community.chocolatey.org/packages>  

for everything else (e.g. `msi`)  

- set the `AppInstallName` to the installer filename (eg `myps1.ps1` or `setup.msi`) (it must exist as a file or as a download in the `\IntuneApp` folder)  

### `AppInstallArgs` Installer arguments

#### `AppInstallArgs` For `Ps1` packages  
  
- (Optional) Prefix your arguments with the `ARGS:` keyword  
- for `ps1` with multiple parameters, it's best to use named parameters  
`ARGS:-var1 xyz -var2 pdq`  
- for `ps1` with single parameter, you can just pass the contents  
`ARGS:use settings file.xml`  
  
#### `AppInstallArgs` For `msi` and `exe` packages  
  
- (Optional) Prefix your arguments with the 'ARGS:' keyword  
- for msi usually  
`ARGS:/quiet`  
`ARGS:/q /norestart`  

### Downloading package files from the web

If there's a file (folder) in `\IntuneApp` that should be downloaded prior to install or uninstall, use the `AppInstallerDownload1URL` setting.
This is useful for large installers that exceed the maximum package size.  
Note: Downloads are not available for *detection* or *requirements* actions, only *install* and *uninstall*.  This is because *detection* and *requirements* actions run every few hours on all endpoints, so a large download size would be problematic.  

#### Download an existing file from the web  

Include the URL in `AppInstallerDownload1URL`  
If you want to ensure a hash is matched (file contents haven't changed), see *Read the hash value* below

#### Publishing your own zip file  

For instance, to zip a subfolder called `\Installer` , publish it, and include as a downloaded portion of your app:

- Create the Zip  
Right-click the `\Installer` folder and ZIP it to your downloads folder calling it `InstallerFolder.zip` or similar.  
Use 7-zip or any zipping tool, but the contents of the zip will be merged into the `\IntuneApp` folder.  

- Read the hash value (optional)  
This ensures the hash from the download matches (file contents haven't changed) from when the package was originally set up.  
*Note: In the future, if the download is updated the hash will no longer match and will need to be re-calculated and updated in the .csv (or removed)*  
Run this powershell command to see the hash value from the zip file in the Downloads folder  
`gci $env:USERPROFILE\Downloads -filter *.zip -Recurse | Get-FileHash -Algorithm SHA256 | Select-Object Hash, @{n="File";e={Split-Path $_.Path -Leaf}}`  
Record the Hash value for pasting into the `intune_settings.csv`  

- Upload the zip file to your Google Drive area and share publicly  
*Note: This assumes Google Drive is being used to share files, but use any public URL as needed.  However, the installers know how to deal with either simple download URLs or Google URLs (can be an indirect download).*  
In the Google Drive interface: *Right-click the ZIP > Share the .zip > Anyone with the link > Viewer*  
Record the Share URL for pasting into the `intune_settings.csv`  

- Update `intune_settings.csv` with the two values
*Note: `AppInstallerDownload1Hash` is optional. If omitted, the downloaded file's hash will not be checked.*  
`AppInstallerDownload1URL`: (Share URL)  
`AppInstallerDownload1Hash`: (Hash value)  
