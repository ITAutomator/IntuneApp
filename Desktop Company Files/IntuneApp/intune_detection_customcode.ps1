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

Function GetHashOfFiles ($FilePaths, $ByDateOrByContents="ByContents")
{
    # GetHashOfFiles - Give a list of filepaths, creates an MD5 hash of their content (ByContents) or their date time stamps (ByDate)
    # $sErr,$sHash = GetHashOfFiles $FilePaths ByDateOrByContents "ByDate"
	#
	# Sort so that files are always sorted the same across systems and cultures and powershells. Do this by sorting by the UTF8 byte array of each path.
    #$FilePaths = $FilePaths | Sort-Object {[system.Text.Encoding]::UTF8.GetBytes($_)|ForEach-Object ToString X2}
    $FilePaths = $FilePaths | Sort-Object {[system.Text.Encoding]::UTF8.GetBytes($_)}
    $sErr = "OK"
    $HashList = @()
    ForEach ($FilePath in $FilePaths)
    { # each file
        If (Test-Path $FilePath -PathType Leaf)
        { # file exists
            $Filethis = Get-ChildItem $FilePath
            # create object for results
            $entry_obj=[pscustomobject][ordered]@{
                Name          = $Filethis.Name
                LastWriteTime = $Filethis.LastWriteTime.ToUniversalTime().Tostring('yyyy-MM-dd HH:mm') # was yyyy-MM-dd hh:mm:ss but OneDrive changes ss by 1 as files are copied in out of OneDrive - also hh was 12 not 24
                Length        = $Filethis.Length
                HashType      = $ByDateOrByContents
                Hash          = ""
                Fullpath      = $FilePath
                }
            if ($ByDateOrByContents -eq "ByContents")
            { # ByContents (slower)
                $entry_obj.Hash = (Get-FileHash $FilePath -Algorithm MD5).Hash
            }
            else
            { # ByDate (date can be faked)
                $entry_obj.Hash ="$($entry_obj.name)|$($entry_obj.LastWriteTime)|$($entry_obj.Length)"
            }
            ### append object
            $HashList+=$entry_obj
        } # file exists
        Else
        { # file not found
            $sErr = "ERR: File not found: $($FilePath)"
        } # file not found
    } # each file
    # get a hash of all the strings
    $Hashstring= $HashList.Hash -join ", "
    $sHash= (Get-FileHash  -Algorithm MD5 -InputStream ([IO.MemoryStream]::new([char[]]$Hashstring))).Hash
    Return $sErr,$sHash,$HashList
}
#  AppVar1 format:
#  Company Files (Folder1)|511CA236B813559BF3485CBFEEC05599*Company Files (Folder2)|511CA236B813559BF3485CBFEEC05599
#  AppVar2 format:
#  Anti-spam policies - Microsoft Defender.url*DeleteMe Folder
$app_detected = $false
$FolderPubDesktop=[System.Environment]::GetFolderPath("CommonDesktopDirectory")
$SourceHashes = @()
if (($IntuneApp.AppVar1 -match "|") -and ($null -ne $IntuneApp.AppVar1) -and ($IntuneApp.AppVar1 -ne "")) {
    $SourceHashes = $IntuneApp.AppVar1 -split "\*"
} # has appvar1
$Removes = @()
if (($IntuneApp.Appvar2 -ne "") -and ($null -ne $IntuneApp.AppVar2) ){
    $Removes = $IntuneApp.Appvar2 -split "\*"
} # has appvar2
Write-Host "-----------------------------------------------------"
Write-Host "Detecting company files on Public Desktop"
$bMatchAll = $true
$count = 0
Foreach ($SourceHash in $SourceHashes) {
    # region: parse source name and hash
    $SourceNameHash = $SourceHash -split "\|"
    $SourceHash = @{
        SourceName = $SourceNameHash[0]
        Hash = $SourceNameHash[1]
    }
    # endregion: parse source name and hash
    Write-Host "$((++$count))) " -NoNewline
    Write-Host $SourceHash.SourceName -ForegroundColor Blue -NoNewline
    $TargetFiles = Get-ChildItem "$($FolderPubDesktop)\$($SourceHash.SourceName)" -File -Recurse
    $sErr,$sHash,$HashList = GetHashOfFiles $TargetFiles.FullName -ByDateOrByContents "ByDate"
    Write-Host " Files:" -NoNewline
    Write-host $TargetFiles.Count -ForegroundColor Blue -NoNewline
    Write-Host " Hash:" -NoNewline
    Write-host $sHash -ForegroundColor Blue -NoNewline
    if ($sHash -eq $SourceHash.Hash) {
        Write-Host " OK" -ForegroundColor Blue
    } # hash match
    else {
        Write-Host " MISMATCH" -ForegroundColor Yellow
        $bMatchAll = $false
    } # hash mismatch
} # each source hash
# Delete Checking
$bDeletesOK = $true
If ($Removes.Count -gt 0) {
    Write-Host "$(Split-Path $FilesToRemoveCSV -Leaf)"
    $count=0
    Foreach ($Remove in $Removes) {
        Write-Host "$((++$count))) " -NoNewline
        Write-Host $Remove -ForegroundColor Blue -NoNewline
        $PathToRemove = "$($FolderPubDesktop)\$($Remove)"
        if (Test-Path $PathToRemove) {
            $bDeletesOK = $false
            Write-Host " [Err, File found]" -ForegroundColor Yellow
        } # found
        else {
            Write-Host " [OK, Missing]" -ForegroundColor Blue
        } # missing
    } # each remove
} # has removes
Write-Host "Detect Result: " -NoNewline
if ($bMatchAll -and $bDeletesOK) {
    Write-Host "OK: All files detected. No removals needed." -ForegroundColor Blue
    $app_detected = $true
} # all good
else {
    $ErrMsg = @()
    if (-not $bMatchAll) {
        $ErrMsg += "Not all files matched."
    }
    if (-not $bDeletesOK) {
        $ErrMsg += "Not all FilesToRemove are deleted."
    }
    Write-Host "Err: $($ErrMsg -join ' ')" -ForegroundColor Yellow
    $app_detected = $false
} # has mismatches
Return $app_detected