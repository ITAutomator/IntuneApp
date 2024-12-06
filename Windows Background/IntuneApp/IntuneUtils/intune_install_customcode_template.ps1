###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")

$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf

Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username PSver:"+($PSVersionTable.PSVersion.Major))
Write-host "Mode: $($mode)"
Write-Host "Installs a program using PowerShell. Use this when winget and .msi installers are not an option."
Write-Host ""
Write-Host "To enable this script:"
Write-Host "- remove _template from the filename and put it in your IntuneApp folder"
Write-Host "- IntuneSettings.csv should have AppInstallName:intune_install_customcode.ps1"
Write-Host ""
Write-Host "This script is meant to be called by intune_install.ps1 and has some dependence on it."
Write-Host "-----------------------------------------------------------------------------"
if (-not $mode_auto) {Pause}
$WingetApps = @()
$WingetApps += [pscustomobject]@{App="Dell.CommandUpdate.Universal";AppMin=$IntuneApp.AppUninstallVersion}
$WingetApps += [pscustomobject]@{App="Dell.CommandUpdate"          ;AppMin=""}
ForEach ($WingetApp in $WingetApps)
{ # uninstall old version
    # The csv specifies a winget app version to uninstall if found
    Write-Host "Checking for: $($WingetApp.App) $($WingetApp.AppMin)..." -NoNewline
    $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "list" -WingetApp $WingetApp.App -SystemOrUser "system" -WingetAppMin $WingetApp.AppMin
    if ($intReturnCode -ne 0)
    {
        Write-Host "Not Found" -ForegroundColor Yellow
    }
    Else
    { # version too low or installed
        Write-Host "Uninstalling..." -NoNewline
        Write-Host $strReturnMsg
        $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "uninstall" -WingetApp $WingetApp.App -SystemOrUser "system"
        Write-Host $strReturnMsg -ForegroundColor Yellow
    } # 
} # uninstall old version
# install new version
$WingetApp = $WingetApps[0]
Write-Host "Installing: $($WingetApp.App) $($WingetApp.AppMin)..." -NoNewline
$intReturnCode, $strReturnMsg = WingetAction -WingetVerb "install" -WingetApp $WingetApp -SystemOrUser "system"
if ($intReturnCode -ne 0)
{   
    Write-Host "Machine scope install failed: $($strReturnMsg)"
    Write-Host "Trying again with no scope..." -NoNewline
    $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "install" -WingetApp $WingetApp -SystemOrUser ""
}
Write-Host $strReturnMsg -ForegroundColor Yellow
