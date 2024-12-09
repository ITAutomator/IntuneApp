Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")
	
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {Write-Host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
#Get-Command -module ITAutomator  ##Shows a list of available functions
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
Write-Host "Does the following for Windows 7/10 basic prep. Run once per machine."
Write-Host ""
Write-Host "- Removes Apps that are junk"
Write-Host "- Allows run as admin to see mapped drives. In other words, you can run .cmd files from network drives."
Write-Host "- Delete shortcuts on the public desktop"
Write-Host "- (Win 10) Change the logon screen to a solid background."
#Write-Host "- Make an apps folder on the public desktop"
Write-Host "- (Win 10) Change Windows Update to include Microsoft (Office) Updates"
Write-Host "- (Win 11) Remove chat from toolbar"
Write-Host "- Allows location services (for auto Timezone adjustment)"
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"
If (-not(IsAdmin))
    {
    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
    }
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}

if ($os[1] -eq "Win 10")
{
    ## Get-AppxPackage | Sort-Object Name | Select-Object Name
    Write-Host "- (Win 10) Removes Apps: Candy Crush, Phone, Zune, SolitaireCollection, etc"
    #AppRemove "Microsoft.MicrosoftOfficeHub"
    #AppRemove "Microsoft.MicrosoftSolitaireCollection"
    #AppRemove "Microsoft.XboxApp"
    AppRemove "king.com.CandyCrushSodaSaga"
    AppRemove "9E2F88E3.Twitter"
    AppRemove "PandoraMediaInc.29680B314EFC2"
    AppRemove "4DF9E0F8.Netflix"
    AppRemove "D52A8D61.FarmVille2CountryEscape"
    #AppRemove "Microsoft.SkypeApp"
    #AppRemove Disney.37853FC22B2CE
}
if ($os[1] -eq "Win 11")
{
    Write-Host "- (Win 11) Removes Apps: MicrosoftTeams (consumer), etc"
    AppRemove "MicrosoftTeams" # teams personal
    ##AppRemove "Microsoft.WindowsStore"  Really hard to get back
}

<#
Write-Host "- Make an apps folder on the public desktop"
$TargetFile = "$env:Public\Documents\Local Apps"
New-Item $TargetFile -type directory -force  | Out-Null
$ShortcutFile = "$env:Public\Desktop\Local Apps.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
#>

##
if ($os[1] -eq "Win 10")
{
    Write-Host "- (Win 10) Change Windows Update to include Microsoft (Office) Updates"
    $ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
    $ServiceManager.ClientApplicationID = "My App"
    $ServiceManager.AddService2( "7971f918-a847-4430-9279-4a52d1efe18d",7,"") | out-null
}
##
<#
Write-Host "- Allows run as admin to see mapped drives. In other words, you can run .cmd files from network drives."
$Regkey="Software\Microsoft\Windows\CurrentVersion\Policies\System"
$Regval="EnableLinkedConnections"
$Regset=1
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)
#>
<#
Write-Host "- Change the machine logon screen to a solid background."
$Regkey="SOFTWARE\Policies\Microsoft\Windows\System"
$Regval="DisableLogonBackgroundImage"
$Regset=1
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)
#>

<#
Write-Host "- Recycle bin display delete confirmation (by policy unfortunately"
$Regkey="Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$Regval="ConfirmFileDelete"
$Regset=1
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)
#>

# TimeZone: Enable location services so the time zone will be set automatically (even when skipping the privacy page in OOBE) when an administrator 
Write-Host "- Timezone Automatically Set"
#https://docs.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/cannot-set-timezone-automatically
# didn't used to need this. but it seems might need it now.
$Regkey="SYSTEM\CurrentControlSet\Services\tzautoupdate"
$Regval="Start"
$Regset="3"
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)

#Allows location services for store (for auto Timezone adjustment) Machine level
$Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
$Regval="Value"
$Regset="Allow"
$Regtype="String"
Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)

#Allows location services for store (for auto Timezone adjustment) User level
$Regkey="SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
$Regval="Value"
$Regset="Allow"
$Regtype="String"
Write-Host (RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype)

#Allows location service override (for auto Timezone adjustment)
$Regkey="SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
$Regval="SensorPermissionState"
$Regset="1"
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)

#Start location service
Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
# TimeZone

Write-Host "- Checks if Shutdown is in hiberboot mode, ie no updates applied. (0=off recommended so that updates are applied with shutdown, 1=on win default to not update) Note: Restart always applies updates"
$Regkey="SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Regval="HiberbootEnabled"
$Regset=0
$Regtype="dword"
Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)

if ($os[1] -eq "Win 11")
{
    Write-Host "- (Win 11) Remove chat from toolbar"
    $Regkey="SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
    $Regval="ChatIcon"
    $Regset=3
    $Regtype="dword"
    Write-Host (RegSetCheckFirst "HKLM" $Regkey $Regval $Regset $Regtype)
}

<# This is no longer needed in Windows 11
Write-Host "- Set lid closed action to 'Do Nothing' (for laptops in docking stations)"
powercfg -setacvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
#>

#region Desktop Shortcuts
$ShortcutNames=@()
## Add shortcut names that neeed removal here
#$ShortcutNames+="FortiClient.lnk"
#$ShortcutNames+="Google Chrome.lnk"
##
ForEach ($ShortcutName in $ShortcutNames)
{ # Each name
	Write-host "- Delete shortcuts on the user and public desktop named: $($ShortcutName)"
	$dps=@()
	$dps+=[Environment]::GetFolderPath("Desktop")
	$dps+=[Environment]::GetFolderPath("CommonDesktopDirectory")
	$i=0
	$profile = [Environment]::GetFolderPath("UserProfile")
	ForEach ($dp in $dps)
	{ # Each desktop path
		$ShortcutFiles = Get-ChildItem -Path "$($dp)\$($ShortcutName)" -File -ErrorAction Ignore
		ForEach ($ShortcutFile in $ShortcutFiles)
		{
			$i+=1
			$sfname = $ShortcutFile.FullName.Replace($profile,"")
			try {
				Remove-Item $ShortcutFile.FullName -ErrorAction Stop
				Write-Host  "$($i): Removing shortcut: $($sfname)"
			}
			catch {
				Write-Host  "$($i): Removing shortcut: $($sfname) (Failed - admin needed?)"
			}
		}
	} # Each desktop path
} # Each name
#endregion Desktop Shortcuts
	
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}