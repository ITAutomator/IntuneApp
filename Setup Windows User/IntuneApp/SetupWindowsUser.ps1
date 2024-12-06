###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")

###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}

# call ps1 file and discard output
Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username PSver:"+($PSVersionTable.PSVersion.Major))
Write-host "Mode: $($mode)"
Write-Host "Calls subscripts to set up basic windows system components."
Write-Host "-----------------------------------------------------------------------------"
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}

######### call ps1 files
$ps1 = "$($scriptDir)\User StartMenu Cleanup.ps1" ; $cmd_out = & $ps1 -mode $mode
$ps1 = "$($scriptDir)\User UserPrep.ps1"          ; $cmd_out = & $ps1 -mode $mode
$ps1 = "$($scriptDir)\RemovePersonalTeams.ps1"    ; $cmd_out = & $ps1 -mode $mode
if ($cmd_out) {$cmd_out = $null}
Start-Sleep 3
Write-Host "Done." -ForegroundColor Yellow
Exit 0