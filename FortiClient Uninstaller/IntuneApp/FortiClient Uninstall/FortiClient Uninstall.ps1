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
#Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################

Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName)        Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major)" 
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host "Removes FortiClient."
Write-Host "-----------------------------------------------------------------------------"
# Define the registry path
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$count_i = 0
# Get all subkeys under the uninstall registry key
$keys = Get-ChildItem $regPath
foreach ($key in $keys) {
    # Retrieve the DisplayName property from the current key
    $props = Get-ItemProperty -Path $key.PSPath
    if ($props.DisplayName -eq "FortiClient") {
		$count_i += 1
        # Use the subkey name (typically a GUID) as the uninstall identifier
        $guid = $key.PSChildName
        Write-Host "$($count_i): Found FortiClient installation with GUID: $guid"
        # Build the uninstall command arguments
        $msiArgs = "/quiet /norestart /uninstall $guid"
        Write-Host "Executing: msiexec.exe $msiArgs"
        # Execute the uninstall command
        Start-Process -FilePath "C:\windows\system32\msiexec.exe" -ArgumentList $msiArgs -Wait
    }
}
if ($count_i -eq 0) {
	Write-Host "No Forticlient install found."
}
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}