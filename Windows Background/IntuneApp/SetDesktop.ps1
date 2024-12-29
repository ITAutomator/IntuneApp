######################
### Parameters
######################
Param 
	( 
	 [string] $mode = "" # "" for manual menu, "auto" for auto-install
	)
######################
### Functions
######################
Function Set-OSCDesktopColor{
    param(
    [Parameter(Position=0)]
    $red=255,
    [Parameter(Position=1)]
    $green=255,
    [Parameter(Position=2)]
    $blue=255
    )

    # Define the required Windows API functions
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32
{
    [DllImport("user32.dll")]
    public static extern bool SetSysColors(int nChanges, int[] lpiElements, int[] lpiRgbValues);
}
"@
    # System color index for the desktop background
    $COLOR_DESKTOP = 1
    # RGB values for the desired background color
    $colorValue = ($blue * 65536) + ($green * 256) + $red
    # Apply the color change
    [Win32]::SetSysColors(1, [int[]]($COLOR_DESKTOP), [int[]]($colorValue)) | Out-Null
}

Function Set-Wallpaper($MyWallpaper){
    Add-Type @' 
using System.Runtime.InteropServices; 
namespace MyCode{ 
     public class SetPaper{ 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
         static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ; 
         
         public static void SetWallpaper(string thePath){ 
            SystemParametersInfo(20,0,thePath,3); 
         }
    }
 } 
'@
    [MyCode.SetPaper]::SetWallpaper($MyWallpaper) | Out-Null
}

Function Convert-Color {
    <#
    .Synopsis
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX)
    .Description
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX). Use it to convert your colors and prepare your graphics and HTML web pages.
    .Parameter RBG
    Enter the Red Green Blue value comma separated. Red: 51 Green: 51 Blue: 204 for example needs to be entered as 51,51,204
    .Parameter HEX
    Enter the Hex value to be converted. Do not use the '#' symbol. (Ex: 3333CC converts to Red: 51 Green: 51 Blue: 204)
    .Example
    .\convert-color -hex FFFFFF
    Converts hex value FFFFFF to RGB
    .Example
    .\convert-color -RGB 123,200,255
    Converts Red = 123 Green = 200 Blue = 255 to Hex value
    #>
    param(
        [Parameter(ParameterSetName = "RGB", Position = 0)]
        [ValidateScript( {$_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$'})]
        $RGB,
        [Parameter(ParameterSetName = "HEX", Position = 0)]
        [ValidateScript( {$_ -match '[A-Fa-f0-9]{6}'})]
        [string]
        $HEX
    )
    switch ($PsCmdlet.ParameterSetName) {
        "RGB" {
            if ($null -eq $RGB[2]) {
                Write-error "Value missing. Please enter all three values seperated by comma."
            }
            $red = [convert]::Tostring($RGB[0], 16)
            $green = [convert]::Tostring($RGB[1], 16)
            $blue = [convert]::Tostring($RGB[2], 16)
            if ($red.Length -eq 1) {
                $red = '0' + $red
            }
            if ($green.Length -eq 1) {
                $green = '0' + $green
            }
            if ($blue.Length -eq 1) {
                $blue = '0' + $blue
            }
            Write-Output $red$green$blue
        }
        "HEX" {
            $HEX = $HEX.Replace("#","")
            $red = $HEX.Remove(2, 4)
            $Green = $HEX.Remove(4, 2)
            $Green = $Green.remove(0, 2)
            $Blue = $hex.Remove(0, 4)
            $Red = [convert]::ToInt32($red, 16)
            $Green = [convert]::ToInt32($green, 16)
            $Blue = [convert]::ToInt32($blue, 16)
            Write-Output $red, $Green, $blue
        }
    }
}
### Main function header
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$scriptCSV      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".csv"  ### replace .ps1 with .xml
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# read scriptCSV for settings
$script_csv = Import-Csv $scriptCSV
$script_settings = @{}
$script_settings.Add("Wallpaper"          , ($script_csv | Where-Object Name -EQ Wallpaper).Value)
$script_settings.Add("WallpaperStyle"     , ($script_csv | Where-Object Name -EQ WallpaperStyle).Value)
$script_settings.Add("BackgroundColor"    , ($script_csv | Where-Object Name -EQ BackgroundColor).Value)
$script_settings.Add("UpdateatLogonOrNow" , ($script_csv | Where-Object Name -EQ UpdateatLogonOrNow).Value)

$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "This script uses the Wallpaper folder and the CSV file to set the wallpaper"
Write-Host ""
Write-Host "     Target Folder: $($env:PUBLIC)\Documents\Wallpaper"
Write-Host "     Source Folder: Wallpaper\"
$wps = Get-ChildItem "$($scriptDir)\Wallpaper"
ForEach ($wp in $wps) {
    Write-Host "                    $($wp.Name)"
}
Write-Host "-----------------------------------------------------------"
Write-Host "          CSV File: $(Split-Path $scriptCSV -Leaf)"
Write-Host "         Wallpaper: " -NoNewline
Write-Host $script_settings.Wallpaper -ForegroundColor Yellow
Write-Host "    WallpaperStyle: $($script_settings.WallpaperStyle)"
Write-Host "   BackgroundColor: $($script_settings.BackgroundColor)"
Write-Host "UpdateatLogonOrNow: $($script_settings.UpdateatLogonOrNow)"
Write-Host "-----------------------------------------------------------"
if ($mode -eq '') {
    PressEnterToContinue
} # ask for choice

$err_out= ""
# Set background color
$rgb = convert-color -hex $script_settings.BackgroundColor #convert from hex to rgb
$rgb_str = "$($rgb[0]) $($rgb[1]) $($rgb[2])"
$result = RegSetCheckFirst "HKCU" "Control Panel\Colors" "Background" $rgb_str "String"
Write-Host $result
if ((-not ($result.Contains("[Already set]"))) -and ($script_settings.UpdateatLogonOrNow -eq "Now")) {
    Write-Host "Background Color Changed: Issue refresh command"
    Set-OSCDesktopColor $rgb[0] $rgb[1] $rgb[2]
}

## set WallpaperStyle
$refresh_wallpaper=$false
if     ($script_settings.WallpaperStyle -eq "Center")  {$style_str="0"}
elseif ($script_settings.WallpaperStyle -eq "Fit")     {$style_str="6"}
elseif ($script_settings.WallpaperStyle -eq "Fill")    {$style_str="10"}
elseif ($script_settings.WallpaperStyle -eq "Stretch") {$style_str="2"}
elseif ($script_settings.WallpaperStyle -eq "Span")    {$style_str="22"}
else   {$style_str="0"}
$result = RegSetCheckFirst "HKCU" "Control Panel\Desktop" "WallpaperStyle" $style_str "String"
Write-Host $result
if (-not ($result.Contains("[Already set]"))) {
    $refresh_wallpaper=$true
}
## set WallpaperStyle

## make sure wallpaper exists if specified
$wallpaper_ok = $true
$wallpaperfile = ""
if ($script_settings.Wallpaper -ne '')
{
    $source = "$($scriptDir)\Wallpaper\$($script_settings.Wallpaper)"
    if (-not(Test-Path -Path $source))
        {$wallpaper_ok = $false}
    else
    { # source found
        # copy files to C:\Users\Public\Documents\Wallpaper so that everyone can use it
        $sourcefolder = "$($scriptDir)\Wallpaper"
        $targetfolder = "$($env:PUBLIC)\Documents\Wallpaper"
        $retcode, $retmsg= CopyFilesIfNeeded $sourcefolder $targetfolder -CompareMethod "date"
        # did anything change?
        if ($retcode -ne 0) {
            $refresh_wallpaper=$true
        }
        # set file name
        $wallpaperfile = "$($targetfolder)\$($script_settings.Wallpaper)"
    } # source found
}
if ($wallpaper_ok)
{# set wallpaper
    $result = RegSetCheckFirst "HKCU" "Control Panel\Desktop" "WallPaper" $wallpaperfile "String"
    Write-Host $result
    if (-not ($result.Contains("[Already set]"))) {
        $refresh_wallpaper=$true
    }
}# set wallpaper
else {
    $err_out= "Err: Couldn't find '$($script_settings.Wallpaper)' "
}
if (($refresh_wallpaper)-and ($script_settings.UpdateatLogonOrNow -eq "Now")) {
    Write-Host "** Refresh Wallpaper **"
    Set-Wallpaper $wallpaperfile
}
else {
    Write-Host "[Nothing changed - no refresh wallpaper needed]"
}
Write-Host "-----------------------------------------------------------"
Write-Host "Done."
Write-Host $err_out
if ($mode -eq '') {
    PressEnterToContinue
} # ask for choice
Return $err_out
