# WifiManager

`WifiManager.ps1` is a PowerShell menu script designed to package and update Wifi settings on endpoints.

<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/Wifi/WifiManagerMain.png alt="screenshot" width="500"/>

User guide: Click [here](https://github.com/ITAutomator/IntuneApp/tree/main/Wifi/IntuneApp)  
Download from GitHub as [ZIP](https://github.com/ITAutomator/IntuneApp/archive/refs/heads/main.zip)  
Or Go to GitHub [here](https://github.com/ITAutomator/IntuneApp) and click `Code` (the green button) `> Download Zip`  

## Features

- Uses the  `WifiManager Updates.csv` to add (and remove) wifi *known networks* in Windows.
- Can be integrated and deployed using the *IntuneApp* deployment system or other package manager.

## Installation

1. Clone or download this repository.
2. Place the `WifiManager` folder in a directory of your choice.

## Usage

1. Double-click `WifiManager.cmd` or run the `WifiManager.ps1` in PowerShell.
2. On the menu choose E to edit the list of wifis to add or remove.
3. To test it interactively use I to install the signals.

Notes:  
The script is careful about making changes, so that it can be run repeatedly, skipping items that are already OK.  

More info here: [www.itautomator.com](https://www.itautomator.com)