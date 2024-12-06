<# -------- Custom Detection code
Put your custom code here
delete this file from your package if it is not needed

Return value
$true if detected, $false if not detected

Intune
Intune will show 'Installed' for those devices where app is detected

Notes
$app_detected may already be true if regular detection code already found something
Write-host will log text to the Intune log (c:\IntuneApps)
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_detection.ps1, and has those functions and variables available to it.
To debug this script, put a break in the script and run the parent ps1 file mentioned above.
Do not allow Write-Output or other unintentional ouput, other than the return value.
 
#>
$app_detected = $false
# This sample code will detect if there's already an app installed of at least a certain version (using winget)
$app_to_find     = "Dell Command*"
#$app_ver_atleast = "24"
$app_ver_atleast = $IntuneApp.AppUninstallVersion
#
$apps = WingetList
$apps_c = $apps | Where-Object Name -like $app_to_find
ForEach ($app_c in $apps_c)
{
	if ([version]$app_c.version -lt (GetVersionFromString $app_ver_atleast))
	{
		Write-Host "$($app_c.name) v$($app_c.version): Old (not at least $($IntuneApp.AppUninstallVersion))"
	}
	Else
	{
		Write-Host "$($app_c.name) v$($app_c.version): OK (is at least $($IntuneApp.AppUninstallVersion))"
		if (-not $app_detected) {$app_detected = $true}
	}
}
# Write-Host "app_detected (after): $($app_detected)"

Return $app_detected