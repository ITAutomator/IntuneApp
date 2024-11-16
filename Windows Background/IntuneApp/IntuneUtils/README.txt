IntuneApp Utils README.txt
-------------------------------------------------
- Do not touch the files in IntuneUtils. This is a managed folder and the files will be ovewritten when the package is published.

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
		
Publishing, Installing and Copying Packages
------------------------------------------------
AppsCopy.cmd                  (Copy packages in bulk to a USB key for manual installs)
AppsCopy.ps1                  ()
AppsCopy.xml                  ()
AppsInstall.cmd               (Manually install packages and groups of packages)
AppsInstall.ps1               ()
AppsInstall.xml               ()
AppsInstall_AppGroups.csv     (Define package groups here)
AppsPublish.ps1               (Publish apps to M365 Intune - Requires Global Admin access)
AppsPublishFixes.txt          ()
AppsPublish_OrgList.csv       (Define valid orgs to publish to)
AppsPublish_Template.ps1      (Managed code - gets injected info Intune Utils)