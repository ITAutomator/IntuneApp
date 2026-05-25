###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "auto" #auto
	)
$mode_auto = ($mode -eq "auto")

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
Write-Host "Configures Dell Update to download and install updates automatically (without rebooting)"
Write-Host "dcu-cli.exe /configure -scheduleAuto -silent -scheduleAction=DownloadInstallAndNotify"
Write-Host ""
Write-Host "Downloads any pending Dell Updates"
Write-Host "dcu-cli.exe /scan -silent"
Write-Host ""
Write-Host "Installs any downloaded Dell Updates"
Write-Host "dcu-cli.exe /applyUpdates -silent -autoSuspendBitLocker=enable -reboot=disable"
Write-Host "-----------------------------------------------------------------------------"
If (-not(IsAdmin))
    {
    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
    }
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
#########################################

# https://www.dell.com/support/manuals/en-us/command-update/dcu_rg/dell-command-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-usc15e8ed&lang=en-us
###################    
# find exe
## Look for dcu-cli
$exename = "${Env:ProgramFiles}\Dell\CommandUpdate\dcu-cli.exe"
If (!(Test-Path $exename))
{
	$exename_64=$exename
	$exename = "${Env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"
}
If (!(Test-Path $exename)){
	$exitcode=108; Write-Host "Err $($exitcode): Can't find required file: '$($exename_64)' or '$($exename)'" -quiet $quiet
	exit($exitcode)
}
else
{ #dcu-cli.exe found
	#### DCU /configure
	Write-Host "Configuring dcu for: Download, Install and Notify" -ForegroundColor Green
	#$logfile = $Logfile1
	$exeargs = @()
	$exeargs += "/configure" #configure dcu
	$exeargs += "-scheduleAuto" #schedule auto updates
	$exeargs += "-silent" #silent mode
	$exeargs += "-scheduleAction=DownloadInstallAndNotify" #schedule action
	Write-Host ("$(Split-Path $exename -Leaf) $($exeargs -join ' ')")
	#$exeargs += " -outputLog=$($Logfile)"
	$result=Start-Process $exename -ArgumentList $exeargs -PassThru -Wait -NoNewWindow
	if ($result.ExitCode -ne 0 )
	{
		$ExitCode=104; Write-Host "Err $($ExitCode): Configure failed with error '$([string]$result.exitcode)' check log $($Logfile)"
		Exit ($ExitCode)
	}
} #dcu-cli.exe found
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}