# IntuneApp Setup Windows System  

## Description  

Basic Windows system setup  

- PC Local Accounts.ps1
  - Creates local admin accounts according to CSV file: PC Local Accounts.csv
  - Username,DisplayName,Description,Groups,EncryptionKey,Password,Comment
    - AdminUser with a random password (intended for LAPS use)
  - Disables local accounts according to CSV file: PC Local Accounts (To Disable).csv

- PC Visitor Account.ps1 (disabled)
  - Creates a guest account with easy password.
  - This can also serve as a honeypot so that wifi can be used. However, with wifi now available at the logon screen - the honeypot is somewhat less needed.

- PC SleepTimers.ps1
  - Sets some sleep defaults (users can adjust them after they are set)
  - Adjust the timers using: PC SleepTimers Settings.csv (In minutes, 0 means never)
    - Name, Value (These are Windows defaults)
    - display_battery, 5
    - sleep_battery, 10
    - display_plugggedin, 10
    - sleep_plugggedin, 30
  - Check timers using (Win+R) then paste: control /name Microsoft.PowerOptions /page pagePlanSettings

- PC WindowsMachinePrep.ps1
  - Removes Apps that are junk
  - Delete shortcuts on the public desktop
  - (Win 11) Remove Teams Personal from toolbar
  - Allows location services (for auto Timezone adjustment)

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
