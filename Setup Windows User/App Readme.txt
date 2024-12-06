This is the sample app.
-------------------------------
Copy this folder somewhere in the same folder structure as \!IntuneApp (next to it)

Updates to code base should only go here.
Treat this as the master code base for new apps.

For winget apps search here:
https://winstall.app/

For Chocolatey apps search here:
https://community.chocolatey.org/packages


Sample install commands
--------------------------------------------
winget install --id=Notepad++.Notepad++  -e  8.5.8
winget install --id=Zoom.ZoomOutlookPlugin  -e
choco install notepadplusplus

Folder structure
---------------------
App Name
| intune_command.cmd                                   (Double click to manually launch Intune commands. Optional but convenient)
| Misc un-packaged files
\-- Misc un-packaged folder1
\-- Misc un-packaged folder2
\-- IntuneApp                                          (Package folder)
    | intune_icon.png                                  (Package icon - Replace with app icon)
    | intune_settings.csv                              (Package settings - Edit app settings)
	| Misc templated files go here                     (Optional template files if needed by App - for advanced apps)
    \-- Intune Utils                                   (Managed code - do not touch. Added by AppPublish.ps1)
        | intune_command.cmd                           {Menu of Intune commands: Install, Uninstall, Detect, Requirements}
        | intune_command.ps1                           {Menu code}
        | intune_detection.ps1                         {App Detection. True: app is installed}
        | intune_detection_customcode_template.ps1     {Template}
        | intune_icon_template.png                     {Template}
        | intune_install.ps1                           {App Install}
        | intune_install_followup_template.ps1         {Template}
        | intune_requirements.ps1                      {App Requirements - True: this machine meet requirements for app install}
        | intune_requirements_customcode_template.ps1  {Template}
        | intune_settings_template.csv                 {Template}
        | intune_uninstall.ps1                         {App Uninstall}
        | intune_uninstall_followup_template.ps1       {Template}
        | README.txt                                   (Readme}