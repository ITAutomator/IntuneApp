<# -------- Custom Requirements code
Put your custom code here
delete this file from your package if it is not needed. It normally isn't needed.

Return value
$true if requirements met, $false if not met

Intune
Intune will show 'Not applicable' for those device where requirements aren't met

Notes
$requirements_met is assumed true coming in to this script
Write-host will log text to the Intune log (c:\IntuneApps)
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_requirements.ps1, and has those functions and variables available to it.
To debug this script, put a break in the script and run the parent ps1 file mentioned above.
Do not allow Write-Output or other unintentional ouput, other than the return value.
 
#>
# $requirements_met is assumed true coming in to this script

#region Check if app installed
# Look for Zoom
$app_to_find     = "Zoom*"
$app_ver_atleast = "0"
#$app_ver_atleast = $app_ver_atleast
#
$requirements_met = $false
$apps = WingetList
$apps_found = $apps | Where-Object Name -like $app_to_find
ForEach ($app_found in $apps_found)
{ # each found app
    if ([version]$app_found.version -lt (GetVersionFromString $app_ver_atleast))
    { # version is too low
        Write-Host "$($app_found.name) v$($app_found.version): Old (not at least $($app_ver_atleast))"
    } # version is too low
    Else
    { # version ok
		if ($app_found.id -eq $IntuneApp.AppInstallName)
		{ # exact app installed aleady
			Write-Host "$($app_found.name) v$($app_found.version): Not really Zoom (matches package id $($IntuneApp.AppInstallName))"
		}
		Else
		{ # this is the exact app (not Zoom)
			$requirements_met = $true
			Write-Host "$($app_found.name) v$($app_found.version): OK (is at least v$($app_ver_atleast))"
		}
	} # version ok
} # each found app
#endregion Check if app installd
Write-Host "requirements_met (after custom code): $($requirements_met)"
Return $requirements_met