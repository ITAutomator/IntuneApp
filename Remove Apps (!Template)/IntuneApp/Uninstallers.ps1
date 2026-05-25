######################
### Parameters
######################
Param ( 
	 [string] $mode = "" # "" for manual menu, "auto" for auto mode
	)
Function Uninstall-Application {
    [CmdletBinding()]
    Param(
        # Mandatory parameter
        [Parameter(Mandatory = $true)]  [string] $App,
        [Parameter(Mandatory = $false)] [string] $UninstallOrList = 'List',
        [Parameter(Mandatory = $false)] [string] $Uninstallargs = ''
    )
    $apps_found = 0
    $apps_max = 5 # dont uninstall if more than x found 
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
            Write-Host "Found matching software: " -nonewline; Write-Host "$($appEntry.DisplayName) [$($appEntry.UninstallString)]" -ForegroundColor Yellow
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
                    if ($Uninstallargs -ne '') {
                        $uninstallCmd += " $Uninstallargs"
                    }
                }
                Write-Host "Running Uninstall Command (Silent): " -nonewline; Write-Host "$uninstallCmd" -ForegroundColor Yellow
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
        $list_apps_display = @($list_apps | Select-object @{N='Description'; E={"$($_.DisplayName) [$($_.UninstallString)]"}})
        $result = "OK: Listing apps [$($list_apps_display.count)] matching *$($App)*]"
        Write-Host $result
        #Write-Host "-------------------------------------------------------------"
        $list_apps_display.Description | Write-host 
        #Write-Host "-------------------------------------------------------------"
    }
    elseif ($apps_found -ne $apps_removed) {
        $result = "ERR: $($apps_found) apps found, but only $($apps_removed) uninstalled"
        Write-Host $result
    } 
    else {
        $result = "OK: $($apps_removed) uninstalled"
        Write-Host $result
    }
    Return $result
} # Uninstall-Application


######################
# Use a comma to force treating the inner array as a single object
# The uninstaller command is pulled from the registry, so it should be correct.
# If the uninstaller is an MSI, it will automatically add the /qn or /quiet parameter.
# If the uninstaller is not an MSI, you may need to add the /S or /silent or /qn or /quiet or other parameters as needed
######################
# Edit these variables to change the apps to uninstall
# Also edit the same list in the Uninstaller.ps1 script AND THE intune_detection_customcode.ps1 script
######################
######################
$AppNameArgs = @()
$AppNameArgs += ,@("Dell SupportAssist", "/S")
$AppNameArgs += ,@("Dell Optimizer", "-silent")
######################
######################

######################
## Main Procedure
######################
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
######################
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "This script uninstalls apps."
Write-Host "IntuneApp.AppVar1: $($IntuneApp.AppVar1)"
$appcount = 0
Write-Host "Uninstalling any of these apps:"
foreach ($AppNameArg in $AppNameArgs) {
    $appcount += 1
    Write-Host "$($appcount) - $($AppNameArg[0])"
}
Write-Host "-------------------------------------------------------------"
if ($mode -eq '') {Read-Host -Prompt 'Press [Enter] to continue'}
$appcount = 0
foreach ($AppNameArg in $AppNameArgs)
{ # appname
    $appname = $AppNameArg[0]
    $apparg = $AppNameArg[1]
    $appaction = "list"
    Write-Host "-------------------------------------------------------------"
    Write-Host "Checking for $($appname)"
    $result = Uninstall-Application -App $appname -UninstallOrList $appaction
    if  ($result.startswith("OK")) {
        $appcount++
        $appaction = "Uninstall"
        Write-Host "About to $appaction the listed apps " -ForegroundColor Yellow
        if ($mode -eq '') {Read-Host -Prompt 'Press [Enter] to continue'}
        $result = Uninstall-Application -App $appname -UninstallOrList $appaction -Uninstallargs $apparg
        Write-host "Result: $($result)"
    }
    else {
        Write-Host "$($appname): Not Found"
    } # result starts with OK
} # appname in $appnames
Write-Host "-------------------------------------------------------------"
# Return
Write-Host "Apps Uninstalled: $($appcount)"
Write-Host "Done."