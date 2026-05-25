# Windows VPN  

![VPN Menu](<https://raw.githubusercontent.com/ITAutomator/Assets/main/WindowsVPN/WindowsVPNMenu.png>)

## Description of this App

Install a pre-configured Windows VPN client (L2TP/IPSec with pre-shared key) network adapter in the user context.  
See here for the *Windows VPN* blog post (blog): <https://www.itautomator.com/windows-vpn>  

## Server Setup: Meraki

Open the Meraki control panel at <https://account.meraki.com/login>

- Go to *Security & SD-WAN > Client VPN > IPsec Settings*
- Client VPN server: Enabled
- Hostname: Copy the Meraki-provided hostname (or you can use the public IP of the WAN connection)
- Subnet: Enter a suitable (unused and non-conflicting) subnet for VPN connections e.g. 192.168.111.0/24
- Shared secret: Create a suitable random PSK for this connection to use
- Authentication: Meraki Cloud Authentication
- Users: Add users under User Management

## Server Setup: Ubiquiti

Open the Unifi control panel at <https://unifi.ui.com/>  

- Go to *Settings > VPN > VPN Server*  
- Create / Edit an L2TP Server  
- Pre-Shared Key (PSK): *Copy or create a random value*  
- Server Address: *Copy*
- Advanced: Unifi will auto-create a non-conflicting /24 subnet for the VPN connections.  
- To change the subnet click *Manual* and click the *Refresh* circle (or change it manually)  
- Users: Add user / password pairs as needed

## CSV Setup

### WindowsVPN Settings.csv

Update the Settings file as follows

| Name                   | Value                         | Description                              |
|------------------------|------------------------------ |-----------                               |
| ConnectionName         | Portland Office               | Desired local name for the VPN           |
| ServerAddress          | 24.110.110.82                 | Public IP or Hostname of the VPN Server (from above) |
| PresharedKey           | oojwoiejpoijwefefshca6Np8Ztvg | PSK  (from above)                        |
| SplitTunneling         | TRUE                          | FALSE means all traffic is sent through the tunnel. TRUE means only CIDRs mentioned below are sent through the tunnel |
| lancidrs_commaseparated| 192.168.150.0/24              | Comma separated list of CIDRs (office networks) to route through the VPN |

*Note: SplitTunneling in FALSE mode will send all traffic through the office gateway which may be desired for security purposes, but will almost certainly slow down internet browsing.*  

### WindowsVPN Credentials.csv

You can choose to save VPN credentials within the CSV file so that the user does not need to provide them.
Caution: The credentials are saved in clear text. These provide remote network access and should be protected similar to SSID passcodes. One method is to zip encrypt the entire package folder.

The first 2 columns are the lookup keys, the second 2 columns are the vpn user and vpn password that will be used.  
`(default),(default)` is the default passoword (if desired)  
`Computer,MY_PC_NAME` is a password for a particular device, regardless of user  
`User,MY_USERNAME` is a password for a particular user, regardless of device  
`Computer\User,MY_PC_NAME\MY_USERNAME` is a passoword for a specific user on a specific device  

Note: If no passwords are provided, no password will be pre-cached in the VPN. Windows will prompt for credentials on first connection.  VPN credentials can be removed via *VPN > More VPN Settings > Down Arrow > Remove*

`WindowsVPN Credentials.csv` (sample file)

| Type           | UserOrComputer        | vpn_user   | vpn_password  |
|----------------|-----------------------|------------|---------------|
| (default)      | (default)             | vpnuser1   | vpnuser1      |
| Computer       | MY_PC_NAME            | HP9XG      | pikachu79379  |
| User           | MY_USERNAME           | JohnSmith  | pikachu77229  |
| Computer\User  | MY_PC_NAME\MY_USERNAME| JohnSmith  | pikachu77229  |

## Usage

Double-click `WindowsVPN.cmd` (PowerShell launcher) or run `WindowsVPN.ps1` in PowerShell.

`--------------- VPN Adapter Menu ------------------`  
`ConnectionName: Portland Office`  
`ServerAddress : 24.110.110.82`  
`Credentails   : User <JohnSmith>: JohnSmith`  
`[A] add    the VPN adapter for this user.`  
`[R] remove the VPN adpater for this user.`  
`[I] ntuneSettings.csv Injection (prep for publishing in IntuneApps).`  
`-------------------------------------------------------`  

Choose `[A] add` to add the adapter.
Choose `[R] remove` to remove the adapter.

You will see the VPN Adapter in Windows.  
Look for your networking icon in the system tray and select VPN.  

## IntuneApp Publishing System

If you are using the IntuneApp system  
Choose `[I] ntuneSettings.csv` to prepare the IntuneSettings.csv file with the correct values.

This app was packaged for compatibility with the *IntuneApp* Publishing System. It can also be installed\:

- automatically by other package delivdery systems using  
  `Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File IntuneUtils\intune_install.ps1 -quiet`  
- manually by double-clicking `intune_command.cmd`  

Information about the *IntuneApp* Publishing System  

- See here for the *IntuneApp* readme: (readme.md) <https://github.com/ITAutomator/IntuneApp>  
- See here for the *IntuneApp* blog post (blog): <https://www.itautomator.com/intuneapp>  
- See here for the *IntuneApp* admin guide: (pdf) <https://github.com/ITAutomator/IntuneApp/blob/main/Readme%20IntuneApp.pdf>  
- Is this code used for [a business](https://github.com/ITAutomator/IntuneApp/blob/main/LICENSE)? Become a sponsor: https://github.com/sponsors/ITAutomator
