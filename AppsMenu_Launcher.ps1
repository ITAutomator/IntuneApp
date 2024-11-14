##################################
### Functions
##################################

######################
## Main Procedure
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
#if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
$launcherps1 = "$($scriptDir)\!IntuneApp\$($scriptName)".replace("_Launcher","")
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "This script launches a .ps1 of the same name in the \!IntuneApp folder."
Write-Host ""
Write-Host "Launcher: .\!IntuneApp\$($scriptName)"
Write-Host "-----------------------------------------------------------------------------"
cls
If (Test-Path $launcherps1)
{
    & $launcherps1
}
Else
{
    Write-Host "Err: Script not found $($launcherps1)"
    Write-Host "You will need to copy the \!IntuneApp folder into this directory too."
    Pause
}
################