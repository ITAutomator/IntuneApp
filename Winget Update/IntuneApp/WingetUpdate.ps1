Param 
	( 
	 [string] $mode = "manual" #auto       ## -mode auto (Proceed without user input for automation. use 'if ($mode -eq 'auto') {}' in code)
	)
Function IsAdmin() 
{
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    $IsAdmin
}
Function GetTempFolder (
    $Prefix = "Powershell_"
    )
{
    $tempFolderPath = Join-Path $Env:Temp ($Prefix + $(New-Guid))
    New-Item -Type Directory -Path $tempFolderPath | Out-Null
    Return $tempFolderPath
}
#
Write-Host "Winget installer / updater" -ForegroundColor Green
Write-Host "mode: $($mode)"
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
Write-host "Current version: $($ver_current) [winget -v]"
# Is it upgradable (above 1.2)
if ([version]$ver_current.Replace("v","") -le [version]"1.2.0") {
    Write-Host "Winget must be 1.2 or above to be updated by this program.";Start-Sleep 2;exit 5
}
# Fetch the URI of the latest version of the winget-cli from GitHub releases
try{
    $latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object { $_.EndsWith('.msixbundle') }
    $ver_latest = ($latestWingetMsixBundleUri -split "/")[7]
}
catch{
    Write-Host "Couldn't find latest version online [https://api.github.com/repos/microsoft/winget-cli/releases/latest]";Start-Sleep 2;exit 12
}
Write-host " Latest version: $($ver_latest)"
# Is it already up to date?
if ([version]$ver_current.Replace("v","") -ge [version]$ver_latest.Replace("v","")) {
    Write-Host "Winget is already up to date.";Start-Sleep 2;exit 0
}
# Is the current process admin?
If (-not(IsAdmin)) {
    Write-Host "This script requires Administrator priviledges.";Start-Sleep 2;exit 10
}
Write-Host "About to update winget"
if ($mode -ne 'auto') {Pause}
# temp folder
Write-Host "1 - Creating a temp folder"
$TmpFld=GetTempFolder -Prefix "wingetinstall_"
# Download
Write-Host "2 - Downloading microsoft.ui.xaml.nupkg.zip"
$Pp_old=$ProgressPreference;$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml -OutFile "$($TmpFld)\microsoft.ui.xaml.nupkg.zip"
$ProgressPreference = $Pp_old
Write-Host "3 - Unzipping microsoft.ui.xaml.nupkg.zip"
Expand-Archive -Path "$($TmpFld)\microsoft.ui.xaml.nupkg.zip" -DestinationPath "$($TmpFld)\microsoft.ui.xaml.nupkg"  -Force
# Get the .appx file in the directory
$appxFile = Get-ChildItem -Path "$($TmpFld)\microsoft.ui.xaml.nupkg\tools\AppX\x64\Release" -Filter "*.appx" | Select-Object -First 1
# Install the .appx file
Write-Host "4 - Installing $($appxFile.Name)"
Try { Add-AppxPackage -Path $appxFile.FullName -ErrorAction Stop } Catch {}
Write-Progress -activity "done" -Completed

# Download the VCLibs .appx package from Microsoft
Write-Host "5 - Downloading Microsoft.VCLibs.x64.14.00.Desktop.appx"
$Pp_old=$ProgressPreference;$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "$($TmpFld)\Microsoft.VCLibs.x64.14.00.Desktop.appx"
$ProgressPreference = $Pp_old
# Try to install the VCLibs .appx package, suppressing any error messages
Write-Host "6 - Installing Microsoft.VCLibs.x64.14.00.Desktop.appx"
Try { Add-AppxPackage "$($TmpFld)\Microsoft.VCLibs.x64.14.00.Desktop.appx" -ErrorAction Stop } Catch {}
Write-Progress -activity "done" -Completed

# Extract the name of the .msixbundle file from the URI
$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split('/')[-1]
# Download the latest .msixbundle file of winget-cli from GitHub releases
Write-Host "7 - Downloading $($latestWingetMsixBundle)"
$Pp_old=$ProgressPreference;$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "$($TmpFld)\$latestWingetMsixBundle"
$ProgressPreference = $Pp_old

# Install the latest .msixbundle file of winget-cli
Write-Host "8 - Installing $($latestWingetMsixBundle)"
Try { Add-AppxPackage "$($TmpFld)\$latestWingetMsixBundle" -ErrorAction Stop} Catch {}
Write-Progress -activity "done" -Completed

# cleanup
Write-Host "Cleaning up temp folder"
Remove-Item $TmpFld -Recurse -Force

# updated ver
$ver_updated=winget -v
Write-host "Updated version: $($ver_updated)"
Write-host " Latest version: $($ver_latest)"
Write-Host "Done"

# Is it not up to date?
if ([version]$ver_updated.Replace("v","") -lt [version]$ver_latest.Replace("v","")) {
    Write-Host "ERR: Winget didn't make it to the latest version (check logs).";Start-Sleep 2;exit 10
}

if ($mode -ne 'auto') {Pause}
Exit 0