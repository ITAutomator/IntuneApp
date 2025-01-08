  
# Windows Background Readme  

See Github to download and for details: https://github.com/ITAutomator/IntuneApp/tree/main/Windows%20Background  

## Overview  

Standardize a Windows desktop background image (and color) across endpoints.  
Optionally sets a lockscreen image too.  
  
Background  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/WindowsBackground/Background.png alt="screenshot" width="500"/>

## More information  

See also: <https://github.com/ITAutomator/IntuneApp/tree/main/Windows%20Background>  
See also: <https://github.com/ITAutomator/IntuneApp>  
  
## Setup Steps  

Main menu  
<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/WindowsBackground/MainScreen.png alt="screenshot" width="500"/>
  
1. Create a `\IntuneApp\Wallpaper\wallpaper1.png`  
   See *Common Display Resolutions* below for size suggestions but QHD 2560 x 1440 is a good start  
   These will end up in the common documents folder: `C:\users\public\documents\Walllpaper`  

2. Set the *Background Color* and *WallpaperStyle* in `SetDesktop.csv`  
   `Background Color`=`#040E4C` for *Dark Blue* (Hex color code from [www.color-hex.com](https://www.color-hex.com/))  
   `WallpaperStyle` = `Fill`. The Fill setting instructs Windows to fill the entire screen with the image, preserving the aspect ratio (AR) and cropping image as needed  
   Note: *Fill* obviates the need for *Background Color*; for smaller images, use *Center*  

3. (Optionally for lock screen) Create a `\IntuneApp\Wallpaper\lockscreen1.png` image of size QHD 2560 x 1440  
   Note: When user interacts with password box, this image will automatically be blurred in the background.  
   Set `LockScreen` = `lockscreen1.png`  

4. Test it  
   Double-click `SetDesktop.cmd` to test it  
   If you are scripting the installation use `SetDesktop.ps1 -mode install` to automatically install the wallpaper (or -mode uninstall)  

5. (Optional) For users of the *IntuneApp* app publishing system  
   Change `intune_settings.csv` to adjust publication audience  

## Settings in `SetDesktop.csv`  

Open `SetDesktop.csv` and adjust these values  
  
### Wallpaper  

`wallpaper`=`wallpaper1.png`  
The filename of the wallpaper (just name, no path)  
If this is left blank (or invalid) you’ll just get the background color  

#### Common Display Resolutions  

If you want to fill the entire display background, use an image (.png preferred) of this size.

|Display|Resolution (H x V)|Aspect Ratio|
|---    |---        |--- |
|4K     |3840 x 2160|16:9|
|QHD *  |2560 x 1440|16:9|
|FHD    |1920 x 1060|16:9|

\* Recommended  
  
### WallpaperStyle  

`WallpaperStyle`=`Fill`

#### Recommended settings  

Wallpaper that fills the screen: large `.png` file with QHD resolution using `Fill` WallpaperStyle  
Wallpaper showing background color: small `.png` using `Center` WallpaperStyle  and `BackgroundColor` matching image  
  
#### WallpaperStyle values  

|Style |Description                                                                                     |RegVal|Background Color may appear around edges |Image Crop may happen|Image Scale may happen|Image Aspect Ratio maintained|  
|---     |---                                                                                            |---   |---                                      |---|---|---|  
|Fill*   |Expands image to cover the screen, leaving some to hang off screen                             |10    |N                                        |Y|Y|Y|  
|Fit     |Shrinks image so that it can be entirely seen (letterbox)                                      |6     |Y (if AR of screen and image don’t match)|N|Y|Y|
|Center* |Centers the image on the screen                                                                |0     |Y                                        |Y|N|Y|  
|Stretch |Breaks aspect ratio of image (stretches each dimension) to align image edges with screen edges.|2     |N                                        |N|Y|N|  
|Span    |Pulls the image across multiple displays                                                       |22    |N                                        |Y|Y|Y|

\* Recommended  
  
### Background Color  

`Background Color`=`#040E4C` (for *Dark Blue*)  

Use the hex code for the color. [www.color-hex.com](https://www.color-hex.com/)  
If you choose the background color of your image, you will have a centered image that blends with the background.  
  
#### Some standard color examples  

|Color |Hex    |
|---   |---    |
|black |#000000|
|blue1 |#000040|
|blue2 |#040E4C|
|green1|#0C590C|
|green2|#1A241B|
  
## Settings in `intune_settings.csv` (Optional) for users of the *IntuneApp* app publishing system  

Open `\IntuneApp\intune_settings.csv` and adjust these values if you are using the *IntuneApp* app distribution system  

To make this a mandatory app (push to all users)

- set `PublishToOrgGroup` = `TRUE`  

To make this mandatory for new users only, but not for existing users, use this *IntuneApp* technique:  

- Publish once with `PublishToOrgGroup` = `FALSE` and `CreateExcludeGroup` = `TRUE`
- This creates an app-only exclude group (ending in `Exclude`).  
- Add all current users to the app-only exclude group.  
- Publish again with set `PublishToOrgGroup` to `TRUE` to pubish to any future users.
  
If you are replacing a previously pushed background, use this *IntuneApp* technique to overwrite previous installs:  

- Change `AppUninstallVersion` to match the last `AppVersion`
- If you don’t adjust this, endpoints with prior versions will not get the *new* wallpaper
  
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