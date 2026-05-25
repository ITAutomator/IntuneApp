<# -------- Custom Detection code
Put your custom code here
Delete this file from your package if it is not needed. Normally, it is not needed.
Winget and Choco packages detect themselves without needing this script.
Packages can also use AppUninstallName CSV entries for additional Winget detection (without needing this script)

Return value
$true if detected, $false if not detected
If the app is detected, the app will be considered installed and the setup script will not run.

Intune
Intune will show 'Installed' for those devices where app is detected

Notes
$app_detected may already be true if regular detection found via IntuneApps.csv or winget or choco
Your code can choose to accept or ignore this detection.
WriteHost commands, once injected, will be converted to WriteLog commands, and will log text to the Intune log (c:\IntuneApps)
This is because detection checking gets tripped up by writehost so nothing should get displayed at all.
Do not allow Write-Output or other unintentional ouput, other than the return value.
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_detection.ps1, and has those functions and variables available to it.
For instance, $IntuneApp.AppVar1 ... $IntuneApp.AppVar5 are injected from the intune_settings.csv, and are usable.
To debug this script, put a break in the script and run the parent ps1 file (Detection).
Detection and Requirements scripts are run every few hours (for all required apps), so they should be conservative with resources.
#>

# Check for registry key
$app_detected = $false
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
    }
}
if ($count_i -eq 0) {
	Write-Host "No Forticlient install found."
    $app_detected = $true # in this case, since the app is an uninstaller, no install means true
}
Return $app_detected
