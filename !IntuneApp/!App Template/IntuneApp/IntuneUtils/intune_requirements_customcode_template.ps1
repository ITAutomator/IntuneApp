<# -------- Custom Requirements code
Put your custom code here
Delete this file from your package if it is not needed. Normally, it is not needed.

Return value
$true indicates requirements are met, $false indicates requirements are not met.
If requiremeents are met, the app will be considered installable and the setup script will run.
If requiremeents are not met, the machine will be considered inapplicable for the app to be installed.

Intune
Intune will show 'Not applicable' for those device where requirements aren't met

Notes
$requirements_met is assumed true coming in to this script
WriteHost commands, once injected, will be converted to WriteLog commands, and will log text to the Intune log (c:\IntuneApps)
This is because requirements checking gets tripped up by write-host (and write-output) so only use write-host for informational display.
Do not allow Write-Output or unintentional ouput, other than the return value.
This must be a stand-alone script with no local files available. It will be copied to a temp folder and run under system context.
However this script is a child process of intune_requirements.ps1, and has those functions and variables available to it.
For instance, $IntuneApp.AppVar1 ... $IntuneApp.AppVar5 are injected from the intune_settings.csv, and are usable.
To debug this script, put a break in the script and run the parent ps1 file (Requirements).
Detection and Requirements scripts are run every few hours (for all required apps), so they should be conservative with resources.
 
#>
# $requirements_met is assumed true coming in to this script

<#
#region Check if app installed
#
# checks for conflicting app.  if no app preset, it's OK to install here
# this sample code will return requirements not met (false) (for install to be called) if an indicated app is already installed
# even if installed, requirements are only not met if if its version is higher than indicated
# note: this checks if the package itself is already installed. In this case you must show requirements_met, otherwise all installs will result in not applicable status
# 
$app_to_find     = "Adobe Acrobat*"
$app_ver_atleast = "0"
#$app_ver_atleast = $app_ver_atleast
#
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
			Write-Host "$($app_found.name) v$($app_found.version): Installed (matches package id $($IntuneApp.AppInstallName))"
		}
		Else
		{ # this is a conflicting app so don't install package
		Write-Host "$($app_found.name) v$($app_found.version): OK (is at least v$($app_ver_atleast))"
		if ($requirements_met) {$requirements_met = $false}
	}
} # version ok
} # each found app

#endregion Check if app installd
#>

#region Check for file
#
# this sample code will check for required files
# if any of the files are found, it's OK to install here
$Filechecks = @()
$Filechecks +="$($env:ProgramData)\My Company\Wallpaper\$($intuneapp.appvar1)"
$Filechecks +="$($env:USERPROFILE)\AppData\Roaming\Microsoft\Teams\desktop-config.json"
$Filechecks +="$($env:USERPROFILE)\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\app_settings.json"
$bOK = $false
$i = 0
ForEach ($Filecheck in $Filechecks)
{ # Each config (teams ver)
    $i+=1
    if (Test-Path $Filecheck -PathType Leaf) {
		$fnd_msg = "Found"
		$bOK = $True
	}
	else {
		$fnd_msg = "Not found"
	}
    Write-Host "File check $($i): ($($fnd_msg)) $($Filecheck)"
	if ($bOK) {break}
}
$requirements_met = $bOK
#endregion Check for file

#
Write-Host "requirements_met (after custom code): $($requirements_met)"
Return $requirements_met