<# -------- Custom Requirements code
Put your custom code here
delete this file from your package if it is not needed. It normally isn't needed.

Return value
$true if requirements met, $false if not met

Intune
Intune will show 'Not applicable' for those device where requirements aren't met

Notes
$requirements_met is assumed true coming in to this script
Write-host will log text to the Intune log (c:\IntuneApps)
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_requirements.ps1, and has those functions and variables available to it.
To debug this script, put a break in the script and run the parent ps1 file mentioned above.
Do not allow Write-Output or other unintentional ouput, other than the return value.
 
#>
# $requirements_met is assumed true coming in to this script

#region Check for file
# this sample code will check for required files
# if any of the files are found, it's OK to install here
$Filechecks = @()
## Look for dcu-cli
$Filechecks +="${Env:ProgramFiles}\Dell\CommandUpdate\dcu-cli.exe"
$Filechecks +="${Env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"

$bOK = $false
$i = 0
ForEach ($Filecheck in $Filechecks)
{ # Each config (teams ver)
    $i+=1
    if (Test-Path $Filecheck -PathType Leaf) {
		$fnd_msg = "Found"
		$bOK = $True
	}
	else {
		$fnd_msg = "Not found"
	}
    Write-Host "File check $($i): ($($fnd_msg)) $($Filecheck)"
	if ($bOK) {break}
}
$requirements_met = $bOK
#endregion Check for file
#
Write-Host "requirements_met (after custom code): $($requirements_met)"
Return $requirements_met