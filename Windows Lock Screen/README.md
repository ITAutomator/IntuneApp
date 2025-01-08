  
# Windows LockScreen Readme  

See Github to download and for details: https://github.com/ITAutomator/IntuneApp/tree/main/Windows%20LockScreen  

## Overview  

Standardize a Windows desktop LockScreen image across endpoints.  
  
LockScreen  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/WindowsLockScreen/Lockscreen.png alt="screenshot" width="500"/>

## More information  

See also: <https://github.com/ITAutomator/IntuneApp/tree/main/Windows%20LockScreen>  
See also: <https://github.com/ITAutomator/IntuneApp/tree/main/Windows%20Background>  
See also: <https://github.com/ITAutomator/IntuneApp>  
  
## Setup Steps  

Main menu  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/WindowsLockScreen/MainScreen.png alt="screenshot" width="500"/>
  
1. Create a `\IntuneApp\LockScreen\LockScreen1.png`  
   Use QHD 2560 x 1440 as a good start for size  
   These will end up in the common documents folder: `C:\users\public\documents\LockScreen`  
   Note: When user interacts with password box, this image will automatically be blurred in the background.  
   Set `LockScreen` = `lockscreen1.png`  

4. Test it  
   Double-click `SetLockScreen.cmd` to test it  
   If you are scripting the installation use `SetLockScreen.ps1 -mode install` to automatically install the LockScreen (or -mode uninstall)  

5. (Optional) For users of the *IntuneApp* app publishing system  
   Change `intune_settings.csv` to adjust publication audience  

## Settings in `SetLockScreen.csv`  

Open `SetLockScreen.csv` and adjust these values  
  
### LockScreen  

`LockScreen`=`LockScreen1.png`  
The filename of the LockScreen (just name, no path)  
If this is left blank (or invalid) you’ll just get the standard lockscreen  

#### Common Display Resolutions  

If you want to fill the entire display background, use an image (.png preferred) of this size.

|Display|Resolution (H x V)|Aspect Ratio|
|---    |---        |--- |
|4K     |3840 x 2160|16:9|
|QHD *  |2560 x 1440|16:9|
|FHD    |1920 x 1060|16:9|

\* Recommended  
  
#### Recommended settings  

LockScreen that fills the screen: large `.png` file with QHD resolution
  
## Settings in `intune_settings.csv` (Optional) for users of the *IntuneApp* app publishing system  

Open `\IntuneApp\intune_settings.csv` and adjust these values if you are using the *IntuneApp* app distribution system  

To make this a mandatory app (push to all users)

- set `PublishToOrgGroup` = `TRUE`  

To make this mandatory for new users only, but not for existing users, use this *IntuneApp* technique:  

- Publish once with `PublishToOrgGroup` = `FALSE` and `CreateExcludeGroup` = `TRUE`
- This creates an app-only exclude group (ending in `Exclude`).  
- Add all current users to the app-only exclude group.  
- Publish again with set `PublishToOrgGroup` to `TRUE` to pubish to any future users.
  
If you are replacing a previously pushed LockScreen, use this *IntuneApp* technique to overwrite previous installs:  

- Change `AppUninstallVersion` to match the last `AppVersion`
- If you don’t adjust this, endpoints with prior versions will not get the *new* LockScreen
  
## Technical Information  

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