<# -------- Custom Detection code
Put your custom code here
delete this file from your package if it is not needed

Return value
$true if detected, $false if not detected

Intune
Intune will show 'Installed' for those devices where app is detected

Notes
$app_detected may already be true if regular detection code already found something
Writehost commands, once injected, will be converted to WriteLog commands, and will log text to the Intune log (c:\IntuneApps)
This is because detection checking gets tripped up by writehost so nothing should get displayed at all.
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_detection.ps1, and has those functions and variables available to it.
To debug this script, put a break in the script and run the parent ps1 file mentioned above.
Do not allow Write-Output or other unintentional ouput, other than the return value.
 
#>

$Filechecks = @()
## Look for files
$folder_common = "$([Environment]::GetFolderPath("ProgramFiles"))\PC Info"
$Filechecks +="$folder_common\PC Info Setup.ps1"
$Filechecks +="$folder_common\PC Info.lnk"
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
$app_detected = $bOK
Write-Host "app_detected (after): $($app_detected)"

Return $app_detected

#endregion Check for file