###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")
Function AppRemove ($Appname, $isinteractive = $false)
	#########
	## Get-AppxPackage -AllUsers | Sort-Object Name  | Select-Object Name  ## Shows packages
    ##     Remove-AppxPackage
	## Get-AppxProvisionedPackage -online| Sort-Object DisplayName | Select-Object DisplayName
    ##     Remove-AppxProvisionedPackage -online -packagename $ProPackageFullName    | where {$_.Displayname -eq $App}).PackageName
    ## $Appname="Microsoft.MicrosoftSolitaireCollection"
    ## Get-AppxPackage -AllUsers "$Appname" | Remove-AppxPackage
    ## Get-AppxProvisionedPackage -online  | where {$_.Displayname -eq $Appname}
    ## $Packagename = "Microsoft.MicrosoftSolitaireCollection_3.7.1041.0_neutral_~_8wekyb3d8bbwe"
    ## Remove-AppxProvisionedPackage -Online -PackageName $Packagename
	## AppRemove "*CandyCrush*"
	## AppRemove "*phone*"
	## AppRemove "*zune*"
	## AppRemove "*SolitaireCollection*"
	## AppRemove "*XboxApp*"
	## AppRemove "*Twitter*"
	#########
	{  ## $Appname="Microsoft.XboxApp"

    If ($Appname -eq $null)
    {
        Get-AppxPackage -AllUsers | Sort-Object Name  | Select-Object Name
        return
    }
	$AppXNames=(Get-AppxPackage -AllUsers "$Appname")
 	If ($AppXNames)
		{
        $AppXName=$AppXNames[0].Name
		If ($isinteractive -and (($env:username).EndsWith("$")))
		{
			Write-Host "[APP REMOVE] $AppXName (this couldn't be removed by a system service because it has interactive features)"
			return
		}
        Write-Host "[APP REMOVE] $AppXName"
		Get-AppxPackage "$Appname" | Remove-AppXPackage
        #$ProvisonedPackages=Get-AppxProvisionedPackage -online  | where {$_.Displayname -eq $AppXName}
        if ($ProvisonedPackages)
            {
            $PackageName=$ProvisonedPackages[0].PackageName
            Write-Host "[PACKAGE REMOVE] $PackageName"
            Remove-AppXProvisionedPackage -Online -PackageName $PackageName
            }
		}
	else
		{
		Write-Host "[APP NOT FOUND] $Appname"
		}
	}

### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {Write-Host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
######################
$OS= Get-OSVersion
Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host "Removes unneeded apps"
Write-Host "-----------------------------------------------------------------------------"

If (-not(IsAdmin))
    {
    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
    }
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
#########################################
# Apps to remove
#########################################
# AppUninstallName will uninstall any product listed in apps (some will be missing) (wildcards OK)
# Get-Package -Provider Programs -IncludeWindowsInstaller | Sort-Object Name
#
# AppUninstallProcess will kill any process with that name prior to uninstall. (wildcards OK)
# Use Get-Process "MyDell*" to check for a match (it's not always the .exe name)
#########################################
$UninstallApps=@()
### Click to Run Microsoft
$UninstallApps+= [pscustomobject]@{AppUninstallName="Microsoft 365 - es-es";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Microsoft 365 - fr-fr";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Microsoft 365 - en-us";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
### Dell Apps
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell ControlVault*";AppUninstallVersion="";AppUninstallProcess="Dell.TechHub*";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell SupportAssist*";AppUninstallVersion="";AppUninstallProcess="DellSupportAssist*";IsInteractive=$true}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell Optimizer Servic*";AppUninstallVersion="";AppUninstallProcess="DellOptimizer*";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="My Dell";AppUninstallVersion="";AppUninstallProcess="MyDell";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell Support Assist";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell Digital Delivery Services";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell Digital Delivery";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell Performance";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell Customer Connect";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
$UninstallApps+= [pscustomobject]@{AppUninstallName="Dell Update*";AppUninstallVersion="";AppUninstallProcess="";IsInteractive=$false}
## $UninstallApps+= [pscustomobject]@{AppUninstallName="McAfee*";AppUninstallVersion="";AppUninstallProcess="McAfee*";IsInteractive=$false}$UninstallApps+= [pscustomobject]@{AppUninstallName="McAfee*";AppUninstallVersion="";AppUninstallProcess="McAfee*"}
$UninstallApps+= [pscustomobject]@{AppUninstallName="WebAdvisor by McAfee*";AppUninstallVersion="";AppUninstallProcess="McAfee*";IsInteractive=$false}
#########################################
#########################################
###
ForEach ($UninstallApp in $UninstallApps)
{ # Each UninstallApp
	Write-Host "Looking to Uninstall App: $($UninstallApp.AppUninstallName) $($UninstallApp.AppUninstallVersion) [and kill proc:$($UninstallApp.AppUninstallProcess)]"
	# App uninstall
	$version_in=$UninstallApp.AppUninstallVersion
	### convert to valid System.Version string
	if ($version_in -eq "") {$version_in = "0.0"}
	$appver_arr=$version_in.Split(".")
	if ($appver_arr.count -eq 0)
	{ # nothing -> 0.0
		$appver_arr="0","0"
	}
	elseif ($appver_arr.count -eq 1)
	{ # no minor -> x.0
		$appver_arr+="0"
	}
	$version_out=$appver_arr -join(".")
	### convert to valid System.Version string
	$installed="Not Installed"
	$msg = "App not found"
	#$gp=$null
	$exitcode=0
	### get list of packages
	$gps=@(Get-Package -Provider Programs -IncludeWindowsInstaller -Name $UninstallApp.AppUninstallName -ErrorAction SilentlyContinue)
	#$gps=@(Get-Package -Provider Programs -IncludeWindowsInstaller)
	#$gps=@(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "Dell Command*")
	#$gps | % {Write-host "$($_.Name)  $($_.ProviderName) QU:$($_.Metadata["QuietUninstallString"]) UN:$($_.Metadata["UninstallString"])"}
	foreach ($gp in $gps)
	{ ## each package
		$lowver = $false
		if (-not ($lowver))
		{
			$lowver = ($UninstallApp.AppUninstallVersion -eq "")
		}
		if (-not ($lowver))
		{
			$lowver = ([System.Version]$gp.Version -le $version_out)
		}
		if ($lowver)
			{
				$gp_lowver=$true
				$gp_msg="version is lower or equal than expected"
			}
		else
			{
				$gp_lowver=$false
				$gp_msg="version is higher than expected"
				$exitcode+=10
			}
		$msg = "$($gp.Name) v$($gp.Version) ($($gp_msg) [v$($version_out)])"
		Write-Host "Installed App: $($msg)"
		If (($IntuneApp.SystemorUser -eq "System") -and (-not(IsAdmin)))
		{
			$exitcode+=100; Write-Host "Err $exitcode : This script requires Administrator priviledges, re-run with elevation"
		}
		else
		{ # admin level ok
			If ($UninstallApp.IsInteractive -and (($env:username).EndsWith("$")))
			{ #interactive and service
				Write-Host "Uninstalling: $($msg) (this couldn't be removed by a system service because it has interactive features)"
				return
			}
			else
			{ #ok to uninstall - not a service
				if ($UninstallApp.AppUninstallProcess)
				{
					## ------- Kill any running apps
					Get-Process -Name $UninstallApp.AppUninstallProcess | ForEach-Object {Write-Host ("Stopping process: "+($_.name)+" ("+$_.ID+")") ; Stop-Process -ID $_.ID -Force}
				}
				## ------- Uninstall
				Write-Host "Uninstalling: $($msg)"
				$gp_result = Uninstall-Package -Name $gp.Name -ForceBootstrap
				if ($gp_result)
				{ # Uninstall-Package actually worked
					Write-Host "Uninstall-Package: OK"
				} # Uninstall-Package actually worked
				else
				{ # Uninstall-Package didn't work
					###
					[string]$cmd=$gp.Metadata["QuietUninstallString"]
					if ($cmd -eq "") {[string]$cmd=$gp.Metadata["UninstallString"]}
					$exeargs = CommandLineSplit $cmd
					#
					if ($exeargs[0].EndsWith("OfficeClickToRun.exe")) {$exeargs[1]+=" DisplayLevel=False"}
					if ($exeargs[0].EndsWith("DellOptimizer.exe")) {$exeargs[1]+=" -silent"}
					#
					$result=Start-Process $exeargs[0] -ArgumentList ($exeargs[1]) -PassThru -Wait
					if ($result.ExitCode -ne 0 )
					{
						$exitcode=105
						Write-Host ("Err $exitcode : Uninstall failed with error ($([string]$result.exitcode))")
					}
				} # Uninstall-Package didn't work
			} #ok to uninstall - not a service
		} # admin level ok
	} ## each package
} # Each UninstallApp
Write-Host "- Removing Store Programs"
AppRemove "Spotify*"
AppRemove "SpotifyAB.SpotifyMusic"
AppRemove "Microsoft.MicrosoftOfficeHub"
AppRemove "Microsoft.MicrosoftSolitaireCollection"
AppRemove "Microsoft.XboxApp"
AppRemove "king.com.CandyCrushSodaSaga"
AppRemove "9E2F88E3.Twitter"
AppRemove "PandoraMediaInc.29680B314EFC2"
AppRemove "4DF9E0F8.Netflix"
AppRemove "D52A8D61.FarmVille2CountryEscape"
AppRemove "Microsoft.SkypeApp"
AppRemove "Clipchamp.Clipchamp"
AppRemove "57540AMZNMobileLLC.AmazonAlexa"
AppRemove "MicrosoftTeams"

Write-Host "- Dell Programs"
AppRemove "DellInc.DellCustomerConnect"               
AppRemove "DellInc.DellDigitalDelivery"           
AppRemove "DellInc.DellSupportAssistforPCs"
AppRemove "DellInc.DellUpdate"
AppRemove "DellInc.MyDell"

#region Desktop Shortcuts
$ShortcutNames=@()
## Add shortcut names here
$ShortcutNames+="FortiClient.lnk"
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