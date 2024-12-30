  
# Setup Windows System  

See Github to download and for details: https://github.com/ITAutomator/IntuneApp/tree/main/Windows%20Background  

<img src=https://github.com/user-attachments/assets/589ede97-71d5-4fd7-a121-7d06aeb1bda9 alt="screenshot" width="500"/>
  
## Overview  

Sets a Windows desktop background image and color .  
This is a per-user setting (the package is a user-based package)  
  
## More information  

See also: <https://www.itautomator.com/intuneapp>  
See also: <https://github.com/ITAutomator/IntuneApp>  
  
## Setup Steps  

- Create a `wallpaper1.png` (See *Common Display Resolutions* below for size suggestions but QHD 2560 x 1440 is a good start)
- Determine a background color e.g. `#040E4C` (Hex color code from [www.color-hex.com](https://www.color-hex.com/))  
- Put the `.png` file(s) in  
`\IntuneApp\Wallpaper`  
These will end up in the common documents folder: `C:\users\public\documents\Walllpaper`  
- Adjust the settings in the 2 `.csv` files:  
`SetDesktop.csv` to adjust wallpaper settings  
`intune_settings.csv`  if you are using the IntuneApp app distribution system
- If you are scriping the installation use  
`SetDesktop.ps1 -mode auto`  
to automatically install the wallpaper  
  
## Settings in `SetDesktop.csv`  

Open `SetDesktop.csv` and adjust these values  
  
### Wallpaper  

`wallpaper1.png`  
The filename of the wallpaper (just name, no path)  
If this is left blank (or invalid) you’ll just get the background color  
  
### WallpaperStyle  

`Fill`  
See below for further details

|Style|Description|
|---|---|
|Fill|Expands image to cover the screen, leaving some to hang off screen |
|Fit | Shrinks image so that it can be entirely seen (letterbox)|  
|Center|Centers the image on the screen|
|Stretch | Breaks aspect ratio of image (stretches each dimension) to align image edges with screen edges.|
|Span | Pulls the image across multiple displays|  
  
### Background Color  

`#040E4C`  
Use the hex code for the color. [www.color-hex.com](https://www.color-hex.com/)  
If you choose the background color of your image, you will have a centered image that blends with the background.  
  
### Some standard color examples  

|Color|Hex|
|---|---|
|black|#000000|
|blue1|#000040|
|blue2|#040E4C|
|green1|#0C590C|
|green2|#1A241B|
  
## Settings in `intune_settings.csv`  

Open `\IntuneApp\intune_settings.csv` and adjust these values  
  
`PublishToOrgGroup`  
To make this a mandatory app (push to all users), set `PublishToOrgGroup` to `TRUE`  
  
`AppUninstallVersion`  
If you are replacing a previously pushed background you must change `AppUninstallVersion` to match the last `AppVersion`. If you don’t adjust this, only new people will get the new wallpaper.  
  
## Technical Information  

### Recommended settings  

Wallpaper that fills the screen: large `.png` file with QHD resolution using `Fill` WallpaperStyle  
Wallpaper showing background color: small `.png` using `Center` WallpaperStyle  and `BackgroundColor` matching image  
  
### WallpaperStyle Details  

|Method|RegVal|Background Color may appear around edges|Image Crop may happen|Image Scale may happen|Image Aspect Ratio maintained|  
|---|---|---|---|---|---|  
|Fill|10|N|Y|Y|Y|  
|Fit|6|Y (if AR of screen and image don’t match)|N|Y|Y|
|Center|0|Y|Y|N|Y|  
|Stretch|2|N|N|Y|N|  
|Span|22|N|Y|Y|Y|  
  
### Common Display Resolutions  

If you want to fill the entire display background, use an image (.png preferred) of this size.

|Display|Resolution (H x V)|Aspect Ratio|  
|---|---|---|  
|4K|3840 x 2160|16:9|  
|QHD|2560 x 1440|16:9|  
|FHD|1920 x 1060|16:9|  
  