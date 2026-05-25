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
For instance, $intuneapp.appvar1-5 which is injected from the intune_settings.csv, is usable.
To debug this script, put a break in the script and run the parent ps1 file (Detection).
Detection and Requirements scripts are run every few hours (for all required apps), so they should be conservative with resources.
 
#>
Function GetArchitecture
{
    $architecture = $ENV:PROCESSOR_ARCHITECTURE
    switch ($architecture) {
        "AMD64" { "x64" }
        "ARM64" { "ARM64" }
        "x86"   { "x86" }
        default { "Unknown architecture: $architecture" }
    }
}
Write-Host "app_detected (before): $($app_detected)"
$Arch = GetArchitecture # Get OS Arch type (x64 or ARM64)
Write-host "------ intune_settings.csv"
Write-host "   Arch is $($Arch)"
Write-host "AppVar1 is $($IntuneApp.AppVar1)" # Printers to Remove: Old Printer1 Name, Old Printer2 Name
Write-host "AppVar2 is $($IntuneApp.AppVar2)" # Printers to Add x64: Printer1 Name, Printer2 Name
Write-host "AppVar3 is $($IntuneApp.AppVar3)" # Printers to Add ARM64: Printer1 Name, Printer2 Name
# get the installed printers
$Printers = Get-Printer
# create some empty arrays
$PrnCSVRowsAdd = @()
$PrnCSVRowsRmv = @()
# 
if ($IntuneApp.AppVar1 -match ":") {
    $Contents = ($IntuneApp.AppVar1 -split ":")[1].trim(" ") # grab the stuff after the :
    if ($Contents -ne '') {
        $PrnCSVRowsRmv += ($Contents -split ",").trim(" ") # array-ify the contents
    } # has contents
} # there's a : char
# Choose the correct AppVanN: AppVar2 for x64, Appvar3 for ARM64
if ($Arch -eq "ARM64") {
    $AppVarN = "AppVar3"
}
Else {
    $AppVarN = "AppVar2"
}
if ($IntuneApp.$AppVarN -match ":") {
    $Contents = ($IntuneApp.$AppVarN -split ":")[1].trim(" ") # grab the stuff after the :
    if ($Contents -ne '') {
        $PrnCSVRowsAdd += ($Contents -split ",").trim(" ") # array-ify the contents
    } # has contents
} # there's a : char
# see if there are any warnings
$strWarnings = @() 
$PrnCSVRowsAdd | Where-object {$_ -NotIn $Printers.Name} |                                        ForEach-Object {$strWarnings += "PC is missing a printer from PrintersToAdd.CSV: $($_)"}
$PrnCSVRowsRmv | Where-object {$_ -NotIn $PrnCSVRowsAdd} | Where-object {$_ -In $Printers.Name} | ForEach-Object {$strWarnings += "PC has a printer in PrintersToRemove.CSV: $($_)"}
# results
if ($strWarnings.Count -eq 0){ # detected OK
    $app_detected = $true
} # no warnings - OK
Else {
    $app_detected = $false
    ForEach ($strWarning in $strWarnings) {
        Write-Host $strWarning
    }
} # warnings - not detected
Write-Host "app_detected (after): $($app_detected)"
Return $app_detected