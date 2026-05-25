# IntuneApp  

## Description of this App (Claude desktop)

This script Installs, Uninstalls, and Detects Claude.
- Machine-level install for all users. Requires admin / elevated permissions.
- Downloads latest version.
- Works on x64 and arm64 devices.
- The Cowork feature will only activate if the Virtual Machine Platform (Windows feature and separate package) is enabled

Download URLs for latest MSIX packages
url_x64 = "https://claude.ai/api/desktop/win32/x64/msix/latest/redirect"
url_arm64 = "https://claude.ai/api/desktop/win32/arm64/msix/latest/redirect"

This is the technique used to install
```powershell
Add-AppxProvisionedPackage -Online -PackagePath "Claude.msix" -SkipLicense -Regions "all"
```
These settings are omitted since the defaults are already the recommended values)
```powershell
# Set machine-wide settings (recommended - but the defaults are already the recommended values)
New-Item -Path "HKLM:\SOFTWARE\Policies\Claude" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Claude" -Name "disableAutoUpdates" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Claude" -Name "autoUpdaterEnforcementHours" -Value 72 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Claude" -Name "isDesktopExtensionEnabled" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Claude" -Name "isDesktopExtensionDirectoryEnabled" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Claude" -Name "isLocalDevMcpEnabled" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Claude" -Name "isClaudeCodeForDesktopEnabled" -Value 1 -Type DWord
```
See here for the Claude directions (Deploy Claude Desktop for Windows)
https://support.claude.com/en/articles/12622703-deploy-claude-desktop-for-windows?gclsrc=aw.ds&utm_source=google&utm_campaign=23743002854&utm_medium=cpc&utm_content=804695033424&utm_term=content+planning+assistant&targetid=kwd-2416613289048&gad_source=1&gad_campaignid=23743002854&gclid=Cj0KCQjw2MbPBhCSARIsAP3jP9zU5ahv08oXzJZnspmwgqTelLiM0mydHZnhxBqtt4Wy2Hvk3e-ZrM0aAnQTEALw_wcB


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
