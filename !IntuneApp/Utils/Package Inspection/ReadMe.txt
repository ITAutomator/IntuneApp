Adjust a package to inspect contents
This is how to change an existing Intune package so that it will unzip into a local machine for inspection or re-packaging.

Intune > Apps > [packagename] > Properties
> assignments > edit
# required: remove all required entries so it doesn't install any longer
# available: add available entry to all users (or your testers) so it appears in Company Portal

> Program > Edit
> Program
# adjust the installer so it copies the package to a local folder
Installer type: Command line
Install Command: robocopy . "C:\IntuneApp\[packagename]" /E

> Detection rules (Optional - actually makes retries on Company Portal easier if you don't do this)
# adjust detection so it looks for the above created folder
Manual > File
Path: C:\IntuneApp
Folder: [packagename]
Detection method: intune_settings.csv

Company Portal > [packagename] > Install
Look for local folder to appear
#######

Packages and modified dates
The packaging process changes dates as follows
(Azure erroneously shifts the files by the difference between the Azure location TZ and the Packager's TZ)

Examples
Packager is UTC +0
Azure store is ET -5
Package files will be time shifted +5

Packager is CT -6
Azure store is ET -5
Package files will be time shifted -1
