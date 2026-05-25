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
#region Settings
$feature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
if ($feature.State -eq 'Enabled') {
    Write-Host "VirtualMachinePlatform state is Enabled."
    $app_detected = $true
} else {
    Write-Host "VirtualMachinePlatform state is $($feature.State)"
    $app_detected = $false
}
#endregion Settings
Write-Host "app_detected: $($app_detected)"
Return $app_detected