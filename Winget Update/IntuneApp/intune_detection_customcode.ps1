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

# add a possible path to winget
$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
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
if ($null -eq $ver_current) {$ver_current="v0.0.0"}
if ("" -eq $ver_current) {$ver_current="v0.0.0"}
Write-host "Current version: $($ver_current) [winget -v]"
# Is it upgradable (above 1.2)
if ([version]$ver_current.Replace("v","") -le [version]"1.2.0") {
    Write-Host "Winget must be 1.2 or above to be updated by this program.";Start-Sleep 2;exit 5
}
# Fetch the URI of the latest version of the winget-cli from GitHub releases
$ver_latest = "v1.2.0"
try{
    $latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object { $_.EndsWith('.msixbundle') }
    $ver_latest = ($latestWingetMsixBundleUri -split "/")[7]
}
catch{
    Write-Host "Couldn't find latest version online [https://api.github.com/repos/microsoft/winget-cli/releases/latest]";Start-Sleep 2
}
Write-host " Latest version: $($ver_latest) [https://api.github.com]"
# Is it already up to date?
if ([version]$ver_current.Replace("v","") -ge [version]$ver_latest.Replace("v","")) {
    Write-Host "Winget is already up to date."
    $app_detected = $true
}
Else {
    Write-Host "Winget not up to date."
    $app_detected = $false
}
Return $app_detected















Write-Host "app_detected (before): $($app_detected)"
if ($app_detected)
{
    Write-Host "App has already been detected (via C:\IntuneApp\IntuneApps.csv). Custom code ignored"
}
Else
{
	$Filechecks = @()
	## Look for files
    $Filechecks +="$($Env:ProgramData)\My Company\Wallpaper\$($intuneapp.appvar1)"
	$Filechecks +="$($Env:ProgramFiles)\Dell\CommandUpdate\dcu-cli.exe"
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
	$app_detected = $bOK
    Write-Host "app_detected (after): $($app_detected)"
}
Return $app_detected
#endregion Check for file