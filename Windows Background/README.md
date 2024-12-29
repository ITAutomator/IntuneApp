  
# Windows Background Readme  
See Github to download and for details: https://github.com/ITAutomator/IntuneApp/tree/main/Windows%20Background   
  
## Overview  
Sets a Windows desktop background image and color .   
This is a per-user setting; the package is a user-based package   
  
## More information  
See also: <https://www.itautomator.com/intuneapp>  
See also: <https://github.com/ITAutomator/IntuneApp>  
  
## Setup Steps  
Create a wallpaper1.png and determine a background color (#Hex code)  
Put .png file in \IntuneApp\Wallpaper (these will end up in C:\users\public\documents\Walllpaper)  
Adjust the settings in the 2 .csv files: SetDesktop.csv and intune_settings.csv  
  
Settings in SetDesktop.csv  
Open \IntuneApp\SetDesktop.csv and adjust these values  
  
SetDesktop.csv  
  
  
### Wallpaper  
wallpaper1.png  
The filename of the wallpaper (just name, no path)  
If this is left blank (or invalid) you’ll just get the background color  
  
### WallpaperStyle  
Center – Centers the image on the screen (best choice for widest variety of screen sizes)  
Fit – Shrinks image so that it can be entirely seen (letterbox)  
Fill – Expands image to cover the screen, leaving some to hang off screen (crop)  
Stretch – Breaks aspect ratio of image (stretches each dimension) to align image edges with screen edges.  
Span – Pulls the image across multiple displays  
  
### Background Color  
Use the hex code for the color.  (Google color picker: link)  
If you choose the background color of your image, you will have a centered image that blends with the background.  
  
### Some standard color examples.  
black|#FFFFFF  
blue1|#000040  
blue2|#040E4C  
green1|#0C590C  
green2|#1A241B  
  
## Settings in intune_settings.csv  
Open \IntuneApp\intune_settings.csv and adjust these values  
  
`PublishToOrgGroup`  
To make this a mandatory push, set `PublishToOrgGroup` to `TRUE`  
  
`AppUninstallVersion`  
If you are replacing a previously pushed background you must change `AppUninstallVersion` to match the `AppVersion`. If you don’t adjust this, only new people will get the new wallpaper.  
  
## Technical Information  
Recommended settings  
Wallpaper hides background color: QHD using Fill  
Wallpaper showing background color: FHD using Center and BackgroundColor matching image  
  
### Wallpaper Methods  
|Method|RegVal|Background Color may appear around edges|Image Crop may happen|Image Scale may happen|Image Aspect Ratio maintained|  
|---|---|---|---|---|---|  
|Fill|10|N|Y|Y|Y|  
|Fit|6|Y|(if AR of screen and image don’t match)|N|Y|Y|  
|Center|0|Y|Y|N|Y|  
|Stretch|2|N|N|Y|N|  
|Span|22|N|Y|Y|Y|  
  
### Common Display Resolutions  
|Name|Resolution (H x V)|Aspect Ratio|  
|---|---|---|  
|4K|3840 x 2160|16:9|  
|QHD|2560 x 1440|16:9|  
|FHD|1920 x 1060|16:9|  
  
