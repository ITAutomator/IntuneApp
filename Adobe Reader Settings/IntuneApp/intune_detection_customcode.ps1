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
$regPath = 'HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown'
$regValueName = 'bAcroSuppressUpsell'
$regValueSettingDesired = 1
Write-Host "Checking for RegKey: $regPath"
# Check if the key exists
if (Test-Path $regPath) {
    # Check if the value exists
    $regValueSettingCurrent = Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regValueName -ErrorAction SilentlyContinue
    if ($null -ne $regValueSettingCurrent) {
        if ($regValueSettingCurrent -eq $regValueSettingDesired) {
            Write-Host "OK: '$regValueName' is already correctly set to $regValueSettingDesired" -ForegroundColor Green
            $app_detected = $true
        } else {
            Write-Host "ERR: '$regValueName' exists but is set to $regValueSettingCurrent (expected $regValueSettingDesired)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ERR: $regValueName not found in $regPath." -ForegroundColor Yellow
    }
} else {
    Write-Host "ERR: Setting not applicable to this PC (Registry key does NOT exist)"
}
#endregion Settings
Write-Host "app_detected: $($app_detected)"
Return $app_detected