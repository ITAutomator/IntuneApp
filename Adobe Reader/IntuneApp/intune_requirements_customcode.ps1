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
# this sample code will return requirements not met (false) (for install to be called) if an indicated app is already installed
# even if installed, requirements are only not met if if its version is higher than indicated
# warning: if the package itself is already installed, always show requirements_met, otherwise all installs will result in not applicable status
# 
$app_to_find     = "Adobe Acrobat*"
$app_ver_atleast = "0"
#logic here is that if you have any other Adobe Acrobat product then you don't meet requirements to install or uninstall Adobe Acrobat Reader
#so that translates to starts with Adobe Acrobat but isn't Adobe Acrobat Reader
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
		#if ($app_found.id -eq $IntuneApp.AppInstallName)
		#{ # exact app installed aleady
		#	Write-Host "$($app_found.name) v$($app_found.version): Installed (matches package id $($IntuneApp.AppInstallName))"
		#}
		#Else
		#{ # this is a different app
			if ($app_found.Name -like "Adobe Acrobat Reader*")
			{ # but it's still Reader
				Write-Host "$($app_found.name) v$($app_found.version): Installed (is some version of Reader)"
			}
			else
			{ # not Reader
				Write-Host "$($app_found.name) v$($app_found.version): This app blocks the install of Reader"
				if ($requirements_met) {$requirements_met = $false}
			}
		#} # this is a different app
    } # version ok
} # each found app
Write-Host "requirements_met (after): $($requirements_met)"
Return $requirements_met