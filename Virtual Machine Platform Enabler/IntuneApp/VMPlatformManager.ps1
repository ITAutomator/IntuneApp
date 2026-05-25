######################
### Parameters
######################
Param ( 
	 [string] $mode = "" # "" for manual menu, "I" to install wifis, "U" to uninstall wifis
	)
######################
### Functions
######################

######################
## Main Procedure
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "This script Installs, Uninstalls, and Detects Virtual Machine Platform (Windows Feature)."
Write-Host ""
if (-not(IsAdmin))
{
    write-host "This must be run as admin / elevated"
    Start-Sleep -Seconds 2
    return
}
if ($quiet) {Write-Host ("<<-quiet>>")}
Do { # action
    Write-Host "-------------------------------------------------------"
    Write-Host "Virtual Machine Platform status: " -NoNewline
    $feature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    Write-Host $feature.State -ForegroundColor Cyan
    Write-Host "--------------- Virtual Machine Platform Manager Menu ------------------"
    Write-Host "Use [I] to install Virtual Machine Platform.   [$($scriptName) -mode I]"
    Write-Host "Use [U] to uninstall Virtual Machine Platform. [$($scriptName) -mode U]"
    Write-Host "Use [D] to detect Virtual Machine Platform"
    Write-Host "[X] Exit"
    Write-Host "-------------------------------------------------------"
    if ($mode -eq '') {
        $choice = PromptForString "Choice [blank to exit]"
    } # ask for choice
    else {
        Write-Host "Choice: [$($mode)]  (-mode $($mode))"
        $choice = $mode
    } # don't ask (auto)
    if (($choice -eq "") -or ($choice -eq "X")) {
        Break
    } # Exit
    if ($choice -eq "D")
    { # detect
        $feature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        if ($feature.State -eq 'Enabled') {
            Write-Host "VirtualMachinePlatform state is Enabled."
        } else {
            Write-Host "VirtualMachinePlatform state is $($feature.State)"
        }
    } # detect
    if ($choice -in ("I"))
    { # install
        Write-Host "Installing Virtual Machine Platform..."
        $feature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        if ($feature.State -eq 'Enabled') {
            Write-Host "VirtualMachinePlatform is already Enabled - skipping."
        } else {
            Write-Host "VirtualMachinePlatform state is '$($feature.State)' - enabling now..."
            $result = Enable-WindowsOptionalFeature `
                -Online `
                -FeatureName VirtualMachinePlatform `
                -All `
                -NoRestart
            if ($result.RestartNeeded) {
                Write-Host "OK (but restart is needed)."
            } else {
                Write-Host "OK (no restart needed)."
            }
        }
    } # install
    if ($choice -in ("U"))
    { # uninstall
        Write-Host "Uninstalling Virtual Machine Platform..."
        $feature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        Write-Host "VirtualMachinePlatform state is '$($feature.State)'"
        if ($feature.State -eq 'Disabled') {
            Write-Host "VirtualMachinePlatform is already Disabled - skipping."
        } else {
            Write-Host "VirtualMachinePlatform state is '$($feature.State)' - disabling now..."
            $result = Disable-WindowsOptionalFeature `
                -Online `
                -FeatureName VirtualMachinePlatform `
                -NoRestart 
            if ($result.RestartNeeded) {
                Write-Host "OK (but restart is needed)."
            } else {
                Write-Host "OK (no restart needed)."
            }
        }
    } # uninstall
    if ($mode -ne "") {break}
    Write-Host "Done"
    Start-sleep 2
} While ($true) # loop until Break 
Write-Host "Done"
# Return result
if ($strWarnings.count -eq 0) {
    $strReturn = "OK: $($scriptName) $($CmdLineInfo)"
    $exitcode = 0
}
else {
    $strReturn = "ERR: $($scriptName) $($CmdLineInfo): $($strWarnings -join ', ')"
    $exitcode = 11
}
Write-host "Return: [$($exitcode)] $($strReturn)"
Write-Output $strReturn
exit $exitcode