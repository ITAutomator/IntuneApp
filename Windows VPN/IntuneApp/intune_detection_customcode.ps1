<# -------- Custom Detection code
Put your custom code here
Delete this file from your package if it is not needed. Normally, it is not needed.
Winget and Choco packages detect themselves without needing this script.
Packages can also use AppUninstallName CSV entries for additional Winget detection (without needing this script)

Return value
$true if detected, $false if not detected
If the app is detected, the app will be considered installed and the setup script will not run.

Intune
Intune will show 'Installed' for those devices where app is detected

Notes
$app_detected may already be true if regular detection found via IntuneApps.csv or winget or choco
Your code can choose to accept or ignore this detection.
WriteHost commands, once injected, will be converted to WriteLog commands, and will log text to the Intune log (c:\IntuneApps)
This is because detection checking gets tripped up by writehost so nothing should get displayed at all.
Do not allow Write-Output or other unintentional ouput, other than the return value.
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_detection.ps1, and has those functions and variables available to it.
For instance, $IntuneApp.AppVar1 ... $IntuneApp.AppVar5 are injected from the intune_settings.csv, and are usable.
To debug this script, put a break in the script and run the parent ps1 file (Detection).
Detection and Requirements scripts are run every few hours (for all required apps), so they should be conservative with resources.
 
#>

<#
#region Check if app installed
#
Write-Host "app_detected (before): $($app_detected)"
if ($app_detected)
{
    Write-Host "App has already been detected (via C:\IntuneApp\IntuneApps.csv). Custom code ignored"
}
else
{
	# This sample code will detect if there's already an app installed of at least a certain version (using winget)
    $app_to_find     = "Adobe Acrobat*"
    #$app_ver_atleast = "24.2"
    $app_ver_atleast = $IntuneApp.AppUninstallVersion
    #
    $apps = WingetList
    $apps_c = $apps | Where-Object Name -like $app_to_find  # for match by name
    #$apps_c = $apps | Where-Object Id -eq $app_to_find     # for exact match by id
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
    Write-Host "app_detected (after): $($app_detected)"
}
Return $app_detected

#endregion Check if app installd
#>

Write-host "------ intune_settings.csv"
Write-host "AppVar1 is $($IntuneApp.AppVar1)" # Printers to Remove: Old Printer1 Name, Old Printer2 Name
if ($IntuneApp.AppVar1 -match ":") {
    $Contents = ($IntuneApp.AppVar1 -split ":")[1].trim(" ") # grab the stuff after the :
} # there's a : char

$found = $false
if ($Contents -ne '') {
    $conninfo = Get-VpnConnection -Name $Contents -ErrorAction Ignore
    if ($conninfo) { #has vpn
        $found = $true
    }
} # has contents
if ($found){
    $app_detected = $true
}
else {
    $app_detected = $false
}
Return $app_detected
