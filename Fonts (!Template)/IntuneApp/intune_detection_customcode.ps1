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
$app_detected = $true # assume installed unless there's a problem

Write-host "------ intune_settings.csv"
Write-host "AppVar1 is $($IntuneApp.AppVar1)" # Fonts to Add: Font1 Name, Font2 Name
Write-host "AppVar2 is $($IntuneApp.AppVar2)" # Fonts to Remove: Old Font1 Name, Old Font2 Name
# create some empty arrays
$FontsAdd = @()
$FontsRmv = @()
if ($IntuneApp.AppVar1 -match ":") {
    $Contents = ($IntuneApp.AppVar1 -split ":")[1].trim(" ") # grab the stuff after the :
    if ($Contents -ne '') {
        $FontsAdd += ($Contents -split ",").trim(" ") # array-ify the contents
    } # has contents
} # there's a : char
if ($IntuneApp.AppVar2 -match ":") {
    $Contents = ($IntuneApp.AppVar2 -split ":")[1].trim(" ") # grab the stuff after the :
    if ($Contents -ne '') {
        $FontsRmv += ($Contents -split ",").trim(" ") # array-ify the contents
    } # has contents
} # there's a : char
$fontFolder = "$([Environment]::GetFolderPath("Windows"))\Fonts"
if (Test-Path $fontFolder)
{ # Windows font folder exists
    ForEach ($Font in $FontsAdd)
    {
        $FontPath = "$($fontFolder)\$($Font)"
        if (-not (Test-Path $FontPath))
        {
            Write-Host "Not Found: $($FontPath)"
            $app_detected = $false
            break
        }
    }
    ForEach ($Font in $FontsRmv)
    {
        $FontPath = "$($fontFolder)\$($Font)"
        if (Test-Path $FontPath)
        {
            Write-Host "Found (should not be there): $($FontPath)"
            $app_detected = $false
            break
        }
    }
} # Windows font folder exists
Write-Host "app_detected (after): $($app_detected)"
Return $app_detected