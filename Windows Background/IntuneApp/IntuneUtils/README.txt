-------------------------------------------------------------------------------------
IntuneApp Utils README.txt
-------------------------------------------------------------------------------------
- Do not touch the files in IntuneUtils. This is a managed folder and the files will be ovewritten when the package is published.
- Architects: These files are updated via the AppsPublish_Template.ps1 master file.

Folder structure (AppPackages\AppName)
-------------------------------------------------------------------------------------
AppName
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
        | intune_detection.ps1                         {D - App Detection. True: app is installed}
        | intune_detection_customcode_template.ps1     {Template} *
        | intune_icon_template.png                     {Template}
        | intune_install.ps1                           {I - App Install}
        | intune_install_followup_template.ps1         {Template} *
        | intune_requirements.ps1                      {R - App Requirements - True: this machine meet requirements for app install}
        | intune_requirements_customcode_template.ps1  {Template} *
        | intune_settings_template.csv                 {Template}
        | intune_uninstall.ps1                         {U - App Uninstall}
        | intune_uninstall_followup_template.ps1       {Template} *
        | README.txt                                   (Readme}

IntuneApp template files (* Optional file)
-------------------------------------------------------------------------------------
These files go in the IntuneApp folder, if needed.
To activate them, remove _template from the end of the filename.

  intune_icon_template.png                     Icon for Company Portal and Intune admin center
  intune_settings_template.csv                 Settings for app
* intune_detection_customcode_template.ps1     Custom app detection code (see inside for samples)
* intune_install_followup_template.ps1         Post-install code
* intune_requirements_customcode_template.ps1  Custom app requirements code (see inside for samples)
* intune_uninstall_followup_template.ps1       Post-uninstall code


Publishing, Installing and Copying Packages (AppPackages\!IntuneApp)
-------------------------------------------------------------------------------------
AppsMenu                      Main menu for all operations
AppsCopy.cmd                  Copy packages in bulk to a USB key for manual installs
AppsInstall.cmd               Manually install packages and groups of packages
AppsInstall_AppGroups.csv     Define package groups here
AppsPublish.ps1               Publish apps to M365 Intune - Requires Global Admin access
AppsPublish_OrgList.csv       Define valid orgs to publish to
AppsPublish_Template.ps1      Managed code for (R,D,I,U commands)