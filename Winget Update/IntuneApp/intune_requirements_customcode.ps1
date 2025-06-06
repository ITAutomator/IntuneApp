<# -------- Custom Requirements code
Put your custom code here
delete this file from your package if it is not needed. It normally isn't needed.

Return value
$true if requirements met, $false if not met

Intune
Intune will show 'Not applicable' for those device where requirements aren't met

Notes
$requirements_met is assumed true coming in to this script
Writehost commands, once injected, will be converted to WriteLog commands, and will log text to the Intune log (c:\IntuneApps)
This is because requirements checking gets tripped up by writehost so nothing should get displayed at all.
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_requirements.ps1, and has those functions and variables available to it.
For instance, $intuneapp.appvar1-5 which is injected from the intune_settings.csv, is usable.
To debug this script, put a break in the script and run the parent ps1 file mentioned above.
Do not allow Write-Output or other unintentional ouput, other than the return value.
 
#>
$requirements_met = $true
# add a possible path to winget
$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
if ($ResolveWingetPath)
{ # change path to include winget.exe (for this session)
    $WingetPath = $ResolveWingetPath[-1].Path
    $env:Path   = $env:Path+";"+$WingetPath
}
$cmdpath=(Get-Command winget.exe -ErrorAction Ignore).Source
if (-not $cmdpath) {$cmdpath="<path-not-found>"}
# show command
Write-Host "Command: $($cmdpath)\winget.exe -v"
# current ver
try{
    $ver_current=winget -v
}
Catch{
    $ver_current="0.0"
}
Write-host "Current version: $($ver_current)"
if ($null -eq $ver_current) {$ver_current="v0.0.0"}
if ("" -eq $ver_current) {$ver_current="v0.0.0"}
# Is it upgradable (above 1.2)
if ([version]$ver_current.Replace("v","") -le [version]"1.2.0") {
    Write-Host "Winget must be 1.2 or above to be updated by this program."
    $requirements_met = $false  
}
Write-Host "requirements_met (after custom code): $($requirements_met)"
Return $requirements_met