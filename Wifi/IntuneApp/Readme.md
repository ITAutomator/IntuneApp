# WifiManager

`WifiManager.ps1` is a PowerShell menu script designed to package and update Wifi settings on endpoints.

<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/Wifi/WifiManagerMain.png alt="screenshot" width="500"/>

User guide: Click [here](https://github.com/ITAutomator/IntuneApp/tree/main/Wifi/IntuneApp)  
Download from GitHub as [ZIP](https://github.com/ITAutomator/IntuneApp/archive/refs/heads/main.zip)  
Or Go to GitHub [here](https://github.com/ITAutomator/IntuneApp) and click `Code` (the green button) `> Download Zip`  

## Features

- Uses the  `WifiManager Updates.csv` to add (and remove) wifi *known networks* in Windows.
- Can be integrated and deployed using the *IntuneApp* deployment system or other package manager.
- What about Intune-native Wifi settings?  This is alternative way to add wifis for non-Intune or pre-Intune environments.  Additionally, Intune provides no native way to remove wifis.

## Installation

1. Clone or download this repository.
2. Place the `WifiManager` folder in a directory of your choice.

## Usage

1. Double-click `WifiManager.cmd` or run the `WifiManager.ps1` in PowerShell.
2. On the menu choose E to edit the list of wifis to add or remove.
3. To test it interactively use I to install the signals.

## Menu

| Menu Choice       | Description                                                                                         |
|-----------------  |----------------                                                                                     |
| `I` | to install managed wifis to this PC                                                                               |
| `U` | to uninstall managed wifis from this PC                                                                           |
| `D` | Detect if PC has wifis already                                                                                    |
| `S` | Setup intune_settings.csv with these wifis (for use with [IntuneApp](https://github.com/ITAutomator/IntuneApp))   |
| `E` | Edit the wifis CSV file                                                                                           |
| `X` | Exit                                                                                                              |

## Command line options

With no command line parameters, the script runs in interactive menu mode.

| Command line     | Description          |
|-----------------  |----------------     |
| `WifiManager.ps1 -mode I`   | Install   |
| `WifiManager.ps1 -mode U`   | Uninstall |

## Example CSV File

| AddRemove | WifiName       | WifiPass       | OpenOrWPA2 |
|-----------|----------------|----------------|------------|
| Add       | MyNewWifiSignal | MyNewWifiPass | WPA2       |
| Remove    | OldWifiSignal   |               |            |
| Add       | GuestWifi       | GuestPass123  | Open       |

## CSV File Column Descriptions

| Column Name       | Description       |
|-----------------  |----------------   |
| AddRemove  | `Add` or `Remove`                                                      |
| WifiName   | `MyNewWifiSignal` Signal name to add or remove                         |
| WifiPass   | `MyNewWifiPass` Signal password. Leave blank for remove or open signal |
| OpenOrWPA2 | `Open` or `WPA2` Signal type.  Leave blank for remove (unless you want uninstall to put it back)    |

Notes:  
Uninstall will remove added signals. If you also want uninstall to put back removed signals, include the password and signal type columns in `remove` entries.  
The script is careful about making changes, so that it can be run repeatedly, skipping items that are already OK.  

More info here: [www.itautomator.com](https://www.itautomator.com)