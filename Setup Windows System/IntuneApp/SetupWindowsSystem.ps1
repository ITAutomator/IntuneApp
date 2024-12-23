###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")

Function IsAdmin() 
{
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    $IsAdmin
}
Function ElevateViaRelaunch()
{
    # Will relaunch Powershell in an elevated session (if needed)
    if (IsAdmin) { Return 0} # not needed - just return
    # rebuild the argument list
    foreach($k in $MyInvocation.BoundParameters.keys)
    {
        switch($MyInvocation.BoundParameters[$k].GetType().Name)
        {
            "SwitchParameter" {if($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
            "String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
            "Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
            "Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
        }
    }
    $argumentlist ="-File `"$($scriptFullname)`" $($argsString)"
    # rebuild the argument list
    Write-Host "Restarting as elevated powershell.exe -File `"$($scriptname)`" $($argsString)"
    Try
    {
        # restart this ps1 elevated (note: if debugging, make sure debugger is running as admin. otherwise this code escapes debugging)
        Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
    }
    Catch {
        $exitcode=110; Write-Host "Err $exitcode : This script required Administrator priviledges, but elevation failed." -ForegroundColor Yellow
        Throw "Failed to start PowerShell elevated"
    }
    Exit
}

###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username PSver:"+($PSVersionTable.PSVersion.Major))
Write-host "Mode: $($mode)"
Write-Host "Calls subscripts to set up basic windows system components."
Write-Host "-----------------------------------------------------------------------------"
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
If (-not (Isadmin))
{
	Write-Host "Requires elevation.  Elevating.."
	ElevateViaRelaunch
}

######### call ps1 files
$ps1 = "$($scriptDir)\PC Local Accounts.ps1"       ; $cmd_out = & $ps1 -mode $mode
$ps1 = "$($scriptDir)\PC MachinePrep.ps1"          ; $cmd_out = & $ps1 -mode $mode
$ps1 = "$($scriptDir)\PC SleepTimers.ps1"          ; $cmd_out = & $ps1 -mode $mode
if ($cmd_out) {$cmd_out = $null}
Start-Sleep 3
Write-Host "Done." -ForegroundColor Yellow
Exit $exitcode