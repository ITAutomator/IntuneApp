###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
#########
#########
Function RegRemoveIfWrongType ($keymain, $keypath, $keyname, $keytype)
{
    $keyvalue =  Get-ItemProperty -Path "$($keymain):\$($keypath)"  -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $keyName -ErrorAction SilentlyContinue
    if ($null -ne $keyvalue)
    { # key exists
        Switch ($keymain)
        {
            "HKLM" {$RegGetregKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keypath, $false)}
            "HKCU" {$RegGetregKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($keypath, $false)}
            "HKCR" {$RegGetregKey = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($keypath, $false)}
        }
        if ($RegGetregKey)
        {# keymain
            $foundtype=$RegGetregKey.GetValueKind($keyname)
            If ($foundtype -eq "String") {$foundtype="REG_SZ"}
            If ($foundtype -eq "ExpandString") {$foundtype="REG_EXPAND_SZ"}
            if ($foundtype -ne $keytype)
            { # remove value if wrong type
                Remove-ItemProperty -Path "$($keymain):\$($keypath)" -Name $keyname
            }
        }# keymain
    } # key exists
} # function
$mode_auto = ($mode -eq "auto")
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-output "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
##$Globals=@{}
##$Globals.Add("Var1","Default")
##$Globals.Add("Var2","Default")
##$Globals=GlobalsLoad $Globals $scriptXML $false

$OS= Get-OSVersion

Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host "Does the following for Windows 7/10/11 basic prep. Run once per user."
Write-Host ""
#Write-Host "- Reset some of the User Shell Folders that roaming profiles can mess up"
#Write-Host "- Change the windows background to solid color : blue"
#Write-Host "- Always show all icons in the notification area"
#Write-Host "- Unhide the explorer ribbon"
Write-Host "- Setting screen saver lock (takes effect after logout / logon)"
Write-Host "- Show hidden files, show extensions"
#Write-Host "- Changes the My Computer icon text to include the actual computer's name"
#Write-Host "- Recycle bin display delete confirmation (by policy unfortunately - seems to require elevation)"
Write-Host "- (Win 10) Disable 'Occasionally show suggestions in Start' in Windows 10"
Write-Host "- (Win 10) Set cortana to be only an icon"
Write-Host "- (Win 11) Tablet mode off"
#Write-Host "- (Win 11) Move the Start Menu to the left"
Write-Host "- (Win 11) Turn off opening of Widgets on hover"
Write-Host "- (Win 11) Set Search to Hide Icon"
#Write-Host "- Set lid closed action to 'Do Nothing' (for laptops in docking stations)"
Write-Host "- Allows location services for store (for auto Timezone adjustment) User level"
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"

##If (-not(IsAdmin))
##    {
##    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
##    }
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}

####
# lock timeouts
#### as user
$screensave_mins=4*60
$screensave_lock=1
Write-Host "- Setting screen saver lock to mins: $($screensave_mins)"
# Set the screensaver timeout to 5 minutes (300 seconds)
$Regkey="Control Panel\Desktop"
$Regval="ScreenSaveTimeOut"
$Regset=$screensave_mins*60 #in seconds
$Regtype="REG_SZ"
RegRemoveIfWrongType "HKCU" $Regkey $Regval $Regtype
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
# Enable the screensaver
$Regkey="Control Panel\Desktop"
$Regval="ScreenSaveActive"
$Regset=$screensave_lock
$Regtype="REG_SZ"
RegRemoveIfWrongType "HKCU" $Regkey $Regval $Regtype
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
# Enable the requirement to enter a password when resuming from the screensaver
$Regkey="Control Panel\Desktop"
$Regval="ScreenSaverIsSecure"
$Regset=$screensave_lock
$Regtype="REG_SZ"
RegRemoveIfWrongType "HKCU" $Regkey $Regval $Regtype
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
####

#####
<#
Write-Host ""
Write-Host "- Reset some of the User Shell Folders that roaming profiles can mess up"
    $Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $Regval="Cache"
    $Regset="%USERPROFILE%\AppData\Local\Microsoft\Windows\INetCache"
    $Regtype="REG_EXPAND_SZ"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

    $Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $Regval="Cookies"
    $Regset="%USERPROFILE%\AppData\Local\Microsoft\Windows\INetCookies"
    $Regtype="REG_EXPAND_SZ"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

Write-Host ""
Write-Host "- Change the windows background to solid color : blue"
    $Regkey="Control Panel\Desktop"
    $Regval="Wallpaper"
    $Regset=""
    $Regtype="REG_SZ"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

    $Regkey="Control Panel\Colors"
    $Regval="Background"
    $Regset="0 56 99"  ## 193 64 0 = orange    0 99 177=blue
    $Regtype="REG_SZ"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

if ($os[1] -ne "Win 11")
{
Write-Host ""
Write-Host "- Always show all icons in the notification area"
    $Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    $Regval="EnableAutoTray"
    $Regset=0
    $Regtype="dword"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
}

Write-Host ""
Write-Host "- Unhide the explorer ribbon"
    $Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon"
    $Regval="MinimizedStateTabletModeOff"
    $Regset=0
    $Regtype="dword"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

Write-Host ""
#> 
Write-Host "- Show hidden files, show extensions"
$Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Regval="HideFileExt"
$Regset=0
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
$Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Regval="Hidden"
$Regset=1
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
$Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Regval="AutoCheckSelect"
$Regset=0
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
<#
Write-Host ""
Write-Host "- Changes the My Computer icon text to include the actual computer's name"
    $Regkey="Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    $Regval="{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
    $Regset=0
    $Regtype="dword"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
    $Regkey="Software\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
    $Regval="LocalizedString"
    $Regset="Computer ("+$env:computername+")"
    $Regtype="REG_EXPAND_SZ"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
if ($os[1] -ne "Win 11")
{
Write-Host ""
Write-Host "- Recycle bin display delete confirmation (by policy unfortunately - seems to require elevation)"
    $Regkey="Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $Regval="ConfirmFileDelete"
    $Regset=1
    $Regtype="dword"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
}
#>
#####
Write-Host ""
if ($os[1] -eq "Win 10")
{
    Write-Host "- (Win 10) Disable 'Occasionally show suggestions in Start' in Windows 10"
    $Regkey="Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $Regval="SystemPaneSuggestionsEnabled"
    $Regset=0
    $Regtype="dword"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
    Write-Host ""
    Write-Host "- (Win 10) Set cortana to be only an icon"
    $Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    $Regval="SearchboxTaskbarMode"
    $Regset=1
    $Regtype="dword"
    Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)
}
$restart_explorer=$false
if ($os[1] -eq "Win 11")
    {
    #- (Win 11) Tablet mode off 
    Write-Host ""
    Write-Host "- (Win 11) Tablet mode off: untick settings > personalization > taskbar > taskbar behaviors > optimize for touch interactions when this device is used as a tablet"
    $Regkey="Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $Regval="ExpandableTaskbar"
    $Regset=0
    $Regtype="dword"
    $result = RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype
    Write-Host $result
    if (-not($result.StartsWith("[Already set]"))) {$restart_explorer=$true}
    #move the start menu to the left
    # Write-Host ""
    # Write-Host "- (Win 11) Move the Start Menu to the left"
    # $Regkey="Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    # $Regval="TaskbarAl"
    # $Regset=0
    # $Regtype="dword"
    # $result = RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype
    # Write-Host $result
    # if (-not($result.StartsWith("[Already set]"))) {$restart_explorer=$true}
    #kill running widgets.exe
    Write-Host ""
    Write-Host "- (Win 11) Turn off opening of Widgets on hover"
    Get-Process widgets -ErrorAction Ignore | Stop-Process -ErrorAction Ignore
    #run reg as package
    Invoke-CommandInDesktopPackage -AppId "Widgets" -PackageFamilyName "MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" -Command reg.exe -Args "add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Dsh`" /v `"HoverEnabled`" /t REG_DWORD /d 0 /f"
    Write-Host ""
    Write-Host "- (Win 11) Set Search to Icon only"
    #0, the search box will be hidden
    #1 Icon only
    #2 Search box
    #3 Search button
    $searchchoice = 1
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchBoxTaskbarMode -Value $searchchoice -Type DWord -Force
}

Write-Host "- Show Windows notifications to this user (0=off 1=on recommended default)"
$Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"
$Regval="ToastEnabled"
$Regset=1
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

<#
## refresh background
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

Write-Host "- Set lid closed action to 'Do Nothing' (for laptops in docking stations)"
powercfg -setacvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
#>

#Allows location services for store (for auto Timezone adjustment) User level
$Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
$Regval="Value"
$Regset="Allow"
$Regtype="String"
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

if ($restart_explorer)
{
    Write-Host "- Restart explorer to see changes"
    taskkill /IM explorer.exe /F
    start explorer.exe
}
Else
{
    Write-Host "- Restart explorer not needed (no changes)"
}

#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}