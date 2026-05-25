###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
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
	### Log file reset
	#$Logfolder = "$($IntuneApp.LogFolder)\DellCommandUpdateLogs"
	#Write-Host "Dell command line update logs: $($Logfolder)"
	# [System.IO.Path]::GetTempPath() Not allowed as per docs
	# "C:\ProgramData\Dell" recommended by Dell but not normal folder
	#New-Item -ItemType Directory -Path $Logfolder -Force | Out-Null
	#$Logfile1 = '"'+"$($Logfolder)\DellCommandUpdate_configure.log"+'"'
	#$Logfile2 = '"'+"$($Logfolder)\DellCommandUpdate_scan.log"+'"'
	#$Logfile3 = '"'+"$($Logfolder)\DellCommandUpdate_applyupdate.log"+'"'
	#if (Test-Path $Logfile1) {Remove-Item $Logfile1}
	#if (Test-Path $Logfile2) {Remove-Item $Logfile2}
	#if (Test-Path $Logfile3) {Remove-Item $Logfile3}
	#
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
	Else
	{ # configure OK
		#### DCU /scan
		Write-Host "Scanning dcu for Updates" -ForegroundColor Green
		# $logfile = $Logfile2
		$exeargs = @()
		$exeargs += "/scan" #scan for updates
		$exeargs += "-silent" #silent mode
		Write-Host ("$(Split-Path $exename -Leaf) $($exeargs -join ' ')")
		#$exeargs += " -outputLog=$($Logfile)"
		$result=Start-Process $exename -ArgumentList $exeargs -PassThru -Wait -NoNewWindow
		switch ($result.ExitCode) {
			500 {Write-Host ("OK: 500 - No updates were found for the system when a scan operation was executed.");break}
			0 {Write-Host ("OK: 0 - Success.");break}
			1 {$exitcode=501;Write-Host ("Warning 501 : /scan failed with error '$([string]$result.exitcode)' A reboot was required.");break}
			default {Write-Host ("Warning 506 : /scan failed with error '$([string]$result.exitcode)' check log '$($Logfile)'"); break}
		}
		#### DCU /applyupdates
		Write-Host "Applying dcu updates" -ForegroundColor Green
		#$logfile = $Logfile3
		$exeargs = @()
		$exeargs += "/applyUpdates" #apply updates
		$exeargs += "-silent" #silent mode
		$exeargs += "-autoSuspendBitLocker=enable" #auto suspend BitLocker
		$exeargs += "-reboot=disable" #disable reboot
		Write-Host ("$(Split-Path $exename -Leaf) $($exeargs -join ' ')")
		#$exeargs += " -outputLog=$($Logfile)"
		$result=Start-Process $exename -ArgumentList $exeargs -PassThru -Wait -NoNewWindow
		switch ($result.ExitCode) {
			500 {Write-Host ("OK: 500 - No updates were found for the system.");break}
			1 {$exitcode=601;Write-Host ("Warning 601: /applyUpdates failed with errror '$([string]$result.exitcode)' A reboot was required.");break}
			0 {Write-Host ("OK: 0 - Success.");break}
			default {$exitcode=606;Write-Host ("Warning 606: /applyUpdates failed with error '$([string]$result.exitcode)' check log '$($Logfile)'");;break}
		}
	} # configure OK
} #dcu-cli.exe found
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}