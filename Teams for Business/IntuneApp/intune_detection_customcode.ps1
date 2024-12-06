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
$Path=[Environment]::GetFolderPath("ProgramFiles")
$Filename="ms-teams.exe"
Write-Host "Finding: $($Filename)"
$Findfiles = Get-ChildItem -Path $Path -Filter $Filename -File -Recurse -Force -ErrorVariable FailedItems -ErrorAction SilentlyContinue
#
if ($Findfiles) {
    $fnd_msg = "Found"
    $bOK = $True
    $Findfiles.FullName | Write-Host
}
else {
    $fnd_msg = "Not found"
}
$app_detected = $bOK
Write-Host "app_detected (after): $($app_detected)"

Return $app_detected

#endregion Check for file