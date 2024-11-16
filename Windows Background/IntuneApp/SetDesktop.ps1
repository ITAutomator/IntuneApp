Function CopyFilesIfNeeded ($source, $target,$CompareMethod = "hash", $delete_extra=$false)
# Copies the contents of a source folder into a target folder (which must exist)
# Only copies files that need copying, based on date or hash of contents.
# Source can be a directory, a file, or a file spec.
# Target must be a directory (will be created if missing)
# 
<# Usage:
    $src = "C:\Downloads\src"
    $trg = "C:\Downloads\trg"
    $retcode, $retmsg= CopyFilesIfNeeded $src $trg "date"
    $retmsg | Write-Host
    Write-Host "Return code: $($retcode)"
#>
#
# $comparemethod
# hash : based on hash (hash computation my take a long time for large files)
# date : based on date,size
#
# $retcode
# 0    : No files copied
# 10   : Some files copied
#
# $delete_extra
# false : extra files in target are left alone
# true  : extra files in target are deleted. resulting empty folders also deleted. Careful with this.
#
# $retmsg
# Returns a list of files with status of each (an array of strings)
#
{
    $retcode=0 # 0 no files needed copying, 10 files needed copying but OK, 20 Error copying files
    $retmsg=@()
    ##
    
    if (Test-Path $target -PathType Leaf)
    {
        $retcode=20
        $retmsg+="ERR:20 Couldn't find target '$($target)'"
    }
    else
    { # Target folder exists
        # Figure out what the 'root' of the source is
        if (Test-Path $source -PathType Container) #C:\Source (a folder)
        {
            $soureroot = $source
        }
        else # C:\Source\*.txt  (a wildcard)
        {
            $soureroot = Split-Path $source -Parent
        }

        $retcode=0 #Assume OK
        $Files = Get-ChildItem $source -File -Recurse
        ForEach ($File in $Files)
        { # Each file
            $files_same=$false
            #############
            #$source
            #C:\Source\MSOffice Templates\MS Office Templates\Office2016_Themes
            #$file.FullName
            #C:\Source\MSOffice Templates\MS Office Templates\Office2016_Themes\MyTheme.thmx
            #$target
            #C:\Target\Microsoft\Templates\Document Themes
            #$target_path
            #C:\Target\Microsoft\Templates\Document Themes\MyTheme.thmx
            #
            $target_path = $file.FullName.Replace($soureroot,$target)
            if (Test-Path $target_path -PathType Leaf)
            { # File exists on both sides
                Write-Verbose "$($file.name) Bytes: $($file.length)"
                if ($CompareMethod -eq "hash")
                { #compare by hash
                    $source_check=Get-FileHash $File.FullName
                    $target_check=Get-FileHash $target_path
                    $compareresult = ($source_check.Hash -eq $target_check.Hash)
                } #compare by hash
                else
                { #compare by date,size
                    $target_file = Get-ChildItem -File $target_path
                    $compareresult = ($File.Name -eq $target_file.Name) `
                     -and ($File.Length -eq $target_file.Length) `
                     -and ($File.LastWriteTimeUtc -eq $target_file.LastWriteTimeUtc)
                } #compare by date,size
                if ($compareresult)
                {
                    $files_same=$true
                }
                else
                {
                    $files_same=$false
                    $copy_reason="Updated"
                }
            } # File exists on both sides
            else
            { # No Target file (or folder)
                $files_same=$false
                $copy_reason="Missing"
            } # No Target file (or folder)
            #########
            if ($files_same)
            { #files_same!
                $retmsg+= "OK:00 $($file.FullName.Replace($source,'')) [already same file]"
            } #files_same!
            else
            { #not files_same
                New-Item -Type Dir (Split-Path $target_path -Parent) -Force |Out-Null #create folder if needed
                Copy-Item $File.FullName -destination $target_path -Force
                $retmsg+= "CP:10 $($file.FullName.Replace($source,'')) [$($copy_reason)]"
                if ($retcode -eq 0) {$retcode=10} #adjust return
            } #not files_same
        } # Each file
        if ($delete_extra)
        { # Delete extra files from target
            #$retcode=0 #Assume OK
            $Files = Get-ChildItem $target -File -Recurse
            ForEach ($File in $Files)
            { # Each file in target
                $source_path = $file.FullName.Replace($target,$source)
                if (-not(Test-Path $source_path -PathType Leaf))
                { # No Source file, delete target
                    Remove-Item $File.FullName -Force | Out-Null
                    $retmsg+= "DL:20 $($file.FullName.Replace($target,'')) [extra file removed]"
                    if (($file.DirectoryName -ne $target) -and (-not (Test-Path -Path "$($file.DirectoryName)\*")))
                    { # is parent an empty folder, remove it
                        Remove-Item $File.DirectoryName -Force | Out-Null
                        $retmsg+= "DL:30 $($file.DirectoryName.Replace($target,'')) [empty folder removed]"
                    }
                } # No Source file, delete target
            } # Each file
        } # Delete extra files from target
    } # Target folder exists
    Return $retcode, $retmsg
}
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
    [Win32]::SetSysColors(1, [int[]]($COLOR_DESKTOP), [int[]]($colorValue))
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
    [MyCode.SetPaper]::SetWallpaper($MyWallpaper)
}
Function RegGet ($keymain, $keypath, $keyname)
{
    <#
    $ver=RegGet "HKCR" "Word.Application\CurVer"
    $ver=RegGet "HKLM" "System\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections"
    #>
    $result = ""
    Switch ($keymain)
        {
            "HKLM" {$RegGetregKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keypath, $false)}
            "HKCU" {$RegGetregKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($keypath, $false)}
            "HKCR" {$RegGetregKey = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($keypath, $false)}
        }
    if ($RegGetregKey)
        {
        $result=$RegGetregKey.GetValue($keyname, $null, "DoNotExpandEnvironmentNames")
        }
    $result
}

Function RegSet ($keymain, $keypath, $keyname, $keyvalue, $keytype)
{
    <#
    RegSet "HKCU" "Software\Microsoft\Office\15.0\Common\General)" "DisableBootToOfficeStart" 1 "dword"
    RegSet "HKCU" "Software\Microsoft\Office\15.0\Word\Options" "PersonalTemplates" "%appdata%\microsoft\templates" "ExpandString"
    #>
    ## Convert keytype string to accepted values keytype = String, ExpandString, Binary, DWord, MultiString, QWord, Unknown
    if ($keytype -eq "REG_EXPAND_SZ") {$keytype="ExpandString"}
    if ($keytype -eq "REG_SZ") {$keytype="String"}

    Switch ($keymain)
    {
        "HKCU" {If (-Not (Test-Path -path HKCU:)) {New-PSDrive -Name HKCU -PSProvider registry -Root Hkey_Current_User | Out-Null}}
    }
    $keymainpath = $keymain + ":\" + $keypath
    ## check if key even exists
    if (!(Test-Path $keymainpath))
        {
        ## Create key
        New-Item -Path $keymainpath -Force | Out-Null
        }
    ## check if value exists
    if (Get-ItemProperty -Path $keymainpath -Name $keyname -ea 0)
        ## change it
        {Set-ItemProperty -Path $keymainpath -Name $keyname -Type $keytype -Value $keyvalue}
    else
        ## create it
        {New-ItemProperty -Path $keymainpath -Name $keyname -PropertyType $keytype -Value $keyvalue | out-null }
}

Function RegSetCheckFirst ($keymain, $keypath, $keyname, $keyvalue, $keytype)
{
    <#
    RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype
    #>
    $x=RegGet $keymain $keypath $keyname
    if ($x -eq $keyvalue)
        {$ret="[Already set] $keyname=$keyvalue ($keymain\$keypath)"}
    else
        {
        if (($x -eq "") -or ($x -eq $null)) {$x="(null)"}
        RegSet $keymain $keypath $keyname $keyvalue $keytype
        $ret="[Reg Set] $keyname=$keyvalue [was $x] ($keymain\$keypath)"
        }
    $ret
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
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")

$scriptCSV      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".csv"  ### replace .ps1 with .xml
# read scriptCSV for settings
$script_csv = Import-Csv $scriptCSV
$script_settings = @{}
$script_settings.Add("Wallpaper"          , ($script_csv | Where-Object Name -EQ Wallpaper).Value)
$script_settings.Add("WallpaperStyle"     , ($script_csv | Where-Object Name -EQ WallpaperStyle).Value)
$script_settings.Add("BackgroundColor"    , ($script_csv | Where-Object Name -EQ BackgroundColor).Value)
$script_settings.Add("UpdateatLogonOrNow" , ($script_csv | Where-Object Name -EQ UpdateatLogonOrNow).Value)
Write-Host "-----------------------------------------------------------"
Write-Host "         Wallpaper: $($script_settings.Wallpaper)"
Write-Host "    WallpaperStyle: $($script_settings.WallpaperStyle)"
Write-Host "   BackgroundColor: $($script_settings.BackgroundColor)"
Write-Host "UpdateatLogonOrNow: $($script_settings.UpdateatLogonOrNow)"
Write-Host "-----------------------------------------------------------"
$err_out= ""
# Set background color
$rgb = convert-color -hex $script_settings.BackgroundColor #convert from hex to rgb
$rgb_str = "$($rgb[0]) $($rgb[1]) $($rgb[2])"
$result = RegSetCheckFirst "HKCU" "Control Panel\Colors" "Background" $rgb_str "String"
Write-Host $result
if ((-not ($result.Contains("[Already set]"))) -and ($script_settings.UpdateatLogonOrNow -eq "Now"))
{
    Write-Host "** Refresh BackgroundColor **"
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
        $retcode, $retmsg= CopyFilesIfNeeded $sourcefolder $targetfolder "date"
        # did anything change?
        if ($retcode -ne 0) {
            $refresh_wallpaper=$true
        }
        # set file name
        $wallpaperfile = "$($targetfolder)\$($script_settings.Wallpaper)"

<# 
        # copy files to C:\Users\Public\Documents\Wallpaper so that everyone can use it
        $targetfolder = "$($env:PUBLIC)\Documents\Wallpaper"
        New-Item -ItemType Directory -Force -Path $targetfolder | Out-Null # Create folder if needed
        Copy-Item "$($scriptDir)\Wallpaper\*" $targetfolder -Force | Out-Null
        $wallpaperfile = "$($targetfolder)\$($script_settings.Wallpaper)"
        # did anything change?
        $wallpaperfile_stamp = (Get-Item $wallpaperfile).LastWriteTime
        $wallpaperfile_source = "$($scriptDir)\Wallpaper\$($script_settings.Wallpaper)"
        $wallpaperfile_source_stamp = (Get-Item $wallpaperfile_source).LastWriteTime
        if ($wallpaperfile_stamp -ne $wallpaperfile_source_stamp) {
            $refresh_wallpaper=$true
        }
         #>
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
Start-Sleep 2
Return $err_out
