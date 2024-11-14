IntuneApp README.txt
-------------------------------------------------

- Do not touch the files in IntuneUtils. This is a managed folder and the files will be ovewritten when the package is published.


Folder structure
---------------------
App Name
| intune_command.cmd
| (Misc un-packaged files)
|
\-- (Misc un-packaged folder1)
\-- (Misc un-packaged folder2)
\-- IntuneApp                  (Package folder)
    \-- Intune Utils           (Managed code - do not touch)
        | intune_command.com
		| intune_command.ps1
		| README.txt
    | intune_icon.png          (Package icon)
	| intune_settings.csv      (Package settings)

