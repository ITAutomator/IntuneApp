<# -------- Custom Detection code
Put your custom code here
delete this file from your package if it is not needed

Return value
$true if detected, $false if not detected

Intune
Intune will show 'Installed' for those devices where app is detected

Notes
$app_detected may already be true if regular detection code already found something
Write-host will log text to the Intune log (c:\IntuneApps)
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_detection.ps1, and has those functions and variables available to it.
To debug this script, put a break in the script and run the parent ps1 file mentioned above.
Do not allow Write-Output or other unintentional ouput, other than the return value.
 
#>
$app_detected = $false
#region Detection code
Write-Host "Detecting 1Password..."
$app_detected = $false
# Admin
# $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*1Password*" }
# $installed   = Get-AppxPackage -AllUsers -Name "*1Password*"
# if ($provisioned -or $installed) { $detected = $true }
# Write-Host "Provisioned package : $(if ($provisioned) {$provisioned.DisplayName} else {'(none)'})"
# Write-Host "Installed package   : $(if ($installed)   {$installed.Name}        else {'(none)'})"
# User
$installed   = Get-AppxPackage -Name "*1Password*"
if ($installed) { $detected = $true }
Write-Host "Installed package   : $(if ($installed)   {$installed.Name}        else {'(none)'})"
#
if ($app_detected) {
    Write-Host "1Password IS detected."
} else {
    Write-Host "1Password IS NOT detected."
}
#endregion Detection code
Write-Host "app_detected: $($app_detected)"
Return $app_detected