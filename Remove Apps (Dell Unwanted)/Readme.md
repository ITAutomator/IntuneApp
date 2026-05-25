# IntuneApp  

## Description of this App

This app is a removal app. It uninstalls other apps.  
Edit the list of apps to remove at the top of the `Uninstaller.ps1` script and `intune_detection_customcode.ps1` scripts.  
The idea is that if the device shows *this removal app* as detected or installed, it has verified the removal of the apps scripted for removal.  

## Intune_settings.csv note

Adjust these entries as needed in your tenant

| Setting              | Default | Description |
|----------------------|---------|-------------|
| PublishToOrgGroup    | TRUE    | (Required) App will be pushed immediately to the PublishToGroup group (usually *IntuneApp Windows Users*) from AppsPublish_OrgList.csv (ie as a required app). False means do not push app to that group. Independent of this, apps are always published to its own IntuneApp [appname] group |
| CreateExcludeGroup   | FALSE   | (Optional) If TRUE, creates an exclusion group for the app, if you want certain users not to receive it. |

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
