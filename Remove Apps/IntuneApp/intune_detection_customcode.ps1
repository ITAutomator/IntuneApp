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
Function Uninstall-Application {
    [CmdletBinding()]
    Param(
        # Mandatory parameter
        [Parameter(Mandatory = $true)]  [string] $App,
        [Parameter(Mandatory = $false)] [string] $UninstallOrList = 'List'
    )
    $apps_found = 0
    $apps_max = 1 # dont uninstall if more than x found 
    $apps_removed = 0

    # Registry paths to check (64-bit and 32-bit on 64-bit OS)
    $uninstallKeyPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $list_apps=@() 
    foreach ($keyPath in $uninstallKeyPaths) {
        # Get any registry entries whose DisplayName contains $App
        $apps = @()
        $apps += Get-ItemProperty $keyPath -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like "*$App*"}
        if ($UninstallOrList -ne "uninstall") {
            $apps_found += $apps.count
            $list_apps += $apps
            Continue # go to next item in loop
        }
        if ($apps.count -gt $apps_max) {
            Write-Host "ERR: Too many apps found [$($apps.count)] matching *$($App)*. The max is: $($apps_max)"
            #Write-Host "-------------------------------------------------------------"
            $apps.DisplayName | Write-host 
            #Write-Host "-------------------------------------------------------------"
            return "ERR: Too many apps found [$($apps.count)] matching *$($App)*. The max is: $($apps_max)"
        }
        foreach ($appEntry in $apps) {
            $apps_found += 1
            Write-Host "Found matching software: $($appEntry.DisplayName)"
            if ($null -ne $appEntry.UninstallString) {
                # Copy the original uninstall command from the registry
                $uninstallCmd = $appEntry.UninstallString

                # Detect MSI-based uninstallers
                if ($uninstallCmd -match 'MsiExec') {
                    # If /qn or /quiet isn't in the string, append /qn
                    if ($uninstallCmd -notmatch '/q') {
                        $uninstallCmd += ' /qn'
                    }
                }
                else {
                    # For non-MSI uninstallers, try appending /silent
                    # (Some may require /S, /quiet, or other parameters. Adjust as needed.)
                    $uninstallCmd += ' /silent'
                }
                Write-Host "Running Uninstall Command (Silent): $uninstallCmd"
                try {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $uninstallCmd -Wait -NoNewWindow
                    Write-Host "$($appEntry.DisplayName) uninstalled successfully."
                    $apps_removed += 1
                }
                catch {
                    Write-Warning "Failed to uninstall $($appEntry.DisplayName): $_"
                }
            }
            else {
                Write-Warning "No valid uninstall string found for $($appEntry.DisplayName)."
            } # uninstall string found
        } # each app found
    } # each reg key
    If ($apps_found -eq 0) {
        $result = "ERR: No matching app found: *$($App)*"
        Write-Host $result
    }
    elseif ($UninstallOrList -ne "uninstall") {
        $list_apps_display = @($list_apps.DisplayName | Select-Object -Unique | Sort-Object)
        $result = "OK: Listing apps [$($list_apps_display.count) unique] of [$($list_apps.count) matching *$($App)*]"
        Write-Host $result
        #Write-Host "-------------------------------------------------------------"
        $list_apps_display | Write-host 
        #Write-Host "-------------------------------------------------------------"
    }
    elseif ($apps_found -ne $apps_removed) {
        $result = "ERR: $($apps_found) apps found, but only $($apps_removed) uninstalld"
        Write-Host $result
    } 
    else {
        $result = "OK: $($apps_removed) uninstalled"
        Write-Host $result
    }
    Return $result
} # Uninstall-Application

#####################
# Main script starts here
#####################

#####################
# Edit these variables to change the apps to uninstall
# Also edit the same list in the Uninstaller.ps1 script
#####################
$appnames = @()
$appnames += "7-Zip"

###
$appcount = 0
Write-Host "Checking for any of these apps: $($appnames -join(", "))"
foreach ($appname in $appnames)
{ # appname
    $appaction = "list"
    Write-Host "Checking for $($appname)"
    $result = Uninstall-Application -App $appname -UninstallOrList $appaction
    if  ($result.startswith("OK")) {
        $appcount++
        Write-Host "$($appname): Found"
    }
    else {
        Write-Host "$($appname): Not Found"
    } # result starts with OK
    Write-Host "-------------------------------------------------------------"
} # appname in $appnames
$app_detected = $appcount -eq 0
# Return
Write-Host "app_detected indicates if uninstaller (the app detected) has been run for all these apps."
Write-Host "True  = uninstall not needed"
Write-Host "False = uninstall needed"
Write-Host "app_detected: $($app_detected)"
Return $app_detected