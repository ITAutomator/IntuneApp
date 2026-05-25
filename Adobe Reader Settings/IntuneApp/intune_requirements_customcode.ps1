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

#region Settings
$regPath = 'HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown'
Write-Host "Checking for RegKey: $regPath"
# Check if the key exists
if (Test-Path $regPath) {
    # Check if the value exists
    Write-Host "OK: Setting applicable to this PC (Registry key does exist)"
    $requirements_met = $true
} else {
    Write-Host "ERR: Setting not applicable to this PC (Registry key does NOT exist)"
    $requirements_met = $false
}
#endregion Settings
Write-Host "requirements_met (after): $($requirements_met)"
Return $requirements_met