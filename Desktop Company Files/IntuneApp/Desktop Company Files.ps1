######################
### Parameters
######################
Param 
	( 
	 [string] $mode = "" # "" for manual menu, "S" for setup printers, "H" for has drivers for this PC architecure, "T" for Detect if already installed
	)

######################
## Main Procedure
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################
# cmd line info
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
# for exporting to CSV.  Example: Export-Csv -Path $csvFile -NoTypeInformation -Force -Encoding $utf8Encoding
$utf8Encoding = if ($PSVersionTable.PSEdition -eq 'Core') { 'utf8BOM' } else { 'utf8' } # UTF8-with-BOM string based on PowerShell Edition
# create subfolder Public Desktop if not exists
$SourceRoot="$($scriptDir)\Public Desktop"
if (-not (Test-Path $SourceRoot)) {
    New-Item -ItemType Directory -Path $SourceRoot | Out-Null
}
$FolderPubDesktop=[System.Environment]::GetFolderPath("CommonDesktopDirectory")
if (-not (Test-Path $FolderPubDesktop)) {
    ErrorMsg -Fatal -ErrCode 101 -ErrMsg "C:\Users\Public Desktop folder could not be found. [GetFolderPath(CommonDesktopDirectory)]"
}
$FilesToRemoveCSV="$($scriptDir)\Desktop Company Files To Remove.csv"
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -ForegroundColor Green
Write-Host ""
$AppDescription = "Creates a Public Desktop folder with company files."
Write-Host $AppDescription
Write-Host ""
# Menu
Do { # action
    # region: list source files and hashes
    Write-Host "--------------- Source Files -------------"
    Write-Host "SourceRoot: " -NoNewline
    Write-host $(Split-Path $SourceRoot -Leaf) -ForegroundColor Blue
    $count = 0
    $Sources = Get-ChildItem $SourceRoot -Directory
    $SourceHashes = @()
    Foreach ($Source in $Sources) {
        Write-Host "$((++$count))) " -NoNewline
        Write-Host $Source.Name -ForegroundColor Blue -NoNewline
        $SourceFiles = Get-ChildItem $Source.Fullname -File -Recurse
        $sErr,$sHash,$HashList = GetHashOfFiles $SourceFiles.FullName -ByDateOrByContents "ByDate"
        Write-Host " Files:" -NoNewline
        Write-host $SourceFiles.Count -ForegroundColor Blue -NoNewline
        Write-Host " Hash:" -NoNewline
        Write-host $sHash -ForegroundColor Blue
        $SourceHashes += [PSCustomObject]@{
            SourceName = $Source.Name
            FileCount  = $SourceFiles.Count
            Hash       = $sHash
            HashList   = $HashList
        }
    }
    $sSourceHashesAll = ($SourceHashes | ForEach-Object {"$($_.SourceName)|$($_.Hash)"}) -join "*"
    if ($Sources.count -eq 0) {
        Write-Host "(No folders to copy)" -ForegroundColor Yellow
    }
    # List Removes
    $Removes = @()
    If (Test-Path $FilesToRemoveCSV) {
        Write-Host "--------------------------"
        Write-Host "$(Split-Path $FilesToRemoveCSV -Leaf)"
        $RemovesCSV = Import-Csv $FilesToRemoveCSV
        $Removes += $RemovesCSV | Where-Object RemoveOrIgnore -eq "Remove" | Sort-Object "Name"
        # Look for problems
        $problems = $Removes | Where-object Name -in $SourceHashes.SourceName
        if ($problems.Count -gt 0) {
            Write-Host "WARNING: There are entries in the CSV that are also folders to copy. They should be removed from the CSV (but will be ignored)." -ForegroundColor Yellow
            Write-Host "CSV rows to ignore: " -NoNewline
            Write-Host ($problems.Name -join ", ") -ForegroundColor Yellow
            Start-Sleep 3
            # remove problems from removes
            $Removes = @()
            $Removes += $RemovesCSV | Where-Object RemoveOrIgnore -eq "Remove" | Where-object Name -notin $SourceHashes.SourceName | Sort-Object "Name"
        }
        # Show removes
        $count = 0
        Foreach ($Remove in $Removes) {
            Write-Host "$((++$count))) " -NoNewline
            Write-Host $Remove.Name -ForegroundColor Blue
        }
    }
    else {
        Write-Host "$(Split-Path $FilesToRemoveCSV -Leaf) " -NoNewline
        Write-Host "(Not found)" -ForegroundColor Blue
    }
    $sRemovesAll = ($Removes | ForEach-Object {"$($_.Name)"}) -join "*"
    # endregion: list source files and hashes
    # region: check for files
    $SourceProblems = Get-ChildItem $SourceRoot -File
    if ($SourceProblems.Count -gt 0) {
        Write-Host "WARNING: SourceRoot contains $($SourceProblems.Count) files. This script doesn't support putting files directly into the Public Desktop folder." -ForegroundColor Yellow
        $count = 0
        Foreach ($SourceProblem in $SourceProblems) {
            Write-Host "$((++$count))) " -NoNewline
            Write-Host $SourceProblem.Name -ForegroundColor Yellow
        }
        Write-Host "Browse the source folder and move these files into subfolders." -ForegroundColor Yellow
        Start-Sleep 3
    }
    # endregion: check for files
    Write-Host "--------------- Choices  ------------------"
    Write-Host "[B] Browse the source folder to make changes"
    Write-Host "[E] Edit the To Remove.csv list."
    Write-Host "[C] Copy company files to Public Desktop"
    Write-Host "[R] Remove company files from Public Desktop"
    Write-Host "[D] Detect company files on Public Desktop"
    Write-Host "[I] IntuneSettings.csv Injection (prep for publishing in IntuneApps)"
    Write-Host "-------------------------------------------"
    if ($mode -eq '') {
        $choice = PromptForString "Choice [blank to exit]"
    } # ask for choice
    else {
        Write-Host "Choice: [$($mode)]  (-mode $($mode))"
        $choice = $mode
    } # don't ask (auto)
    if (($choice -eq "") -or ($choice -eq "X")) {
        Break
    } # Exit
    $strReturn = "OK: $($scriptName) $($CmdLineInfo)"
    $exitcode = 0
    if ($choice -eq "B")
    { # browse
        Invoke-Item $SourceRoot
        PressEnterToContinue "Make your changes in the opened folder, then press <Enter> to continue. Use [I] to reflect changes in IntuneSettings.csv" -ForegroundColor Green
    } # browse
    if ($choice -eq "E")
    { # edit FilesToRemove.csv
        Write-Host (Split-Path $FilesToRemoveCSV -Leaf) -ForegroundColor Blue -NoNewline
        Write-Host " lists files/folders to REMOVE from the Public Desktop folder."
        If (Test-Path $FilesToRemoveCSV) {
            Write-Host "The current file has $($Removes.Count) entries."
            $choice = AskForChoice "Edit the list? (Y to edit, N to cancel, C to clear the list)" -Choices "&Yes","&No","&Clear" -ReturnString
            if ($choice -eq "Clear") {
                Remove-Item $FilesToRemoveCSV -Force
                Write-Host "The list has been cleared.  Use [E] to edit it later. Use [I] to reflect changes in IntuneSettings.csv" -ForegroundColor Green
                PressEnterToContinue
                Continue
            } # user chose to clear list
            if ($choice -eq "No") {
                Continue
            } # user chose not to edit
        }
        If (-not (Test-Path $FilesToRemoveCSV)) {
            If (-not (AskForChoice "None found. Create a sample file now?")) {
                Continue
            } # user cancelled
            Write-Host "It will be created with some example entries."
            # Create a sample from the Public Desktop folder
            $files = @()
            $files += Get-ChildItem $FolderPubDesktop
            # Creat an array of objects
            $Removes = @()
            ForEach ($file in $files) {
                $RelativePath = $file.Fullname.Substring($FolderPubDesktop.Length+1)
                $Remove = [PSCustomObject]@{
                    RemoveOrIgnore="Ignore"
                    Name=$RelativePath
                }
                $Removes += $Remove
            }
            # Create a sample csv file
            $utf8Encoding = if ($PSVersionTable.PSEdition -eq 'Core') { 'utf8BOM' } else { 'utf8' } # UTF8-with-BOM string based on PowerShell Edition
            $Removes | Export-Csv $FilesToRemoveCSV -NoTypeInformation -Force -Encoding $utf8Encoding
        } # not found
        Invoke-Item $FilesToRemoveCSV
        PressEnterToContinue "Make your changes in the opened file, change RemoveOrIgnore to Remove then press <Enter> to continue.  Use [I] to reflect changes in IntuneSettings.csv"
    } # edit FilesToRemove.csv
    if ($choice -eq "C")
    { # copy
        Write-Host "-----------------------------------------------------"
        Write-Host "Copying company files to Public Desktop"
        Write-Host "SourceRoot: " -NoNewline
        Write-host $(Split-Path $SourceRoot -Leaf) -ForegroundColor Blue
        Write-Host "TargetRoot: " -NoNewline
        Write-host $FolderPubDesktop -ForegroundColor Blue
        # check if admin
        If (-not(IsAdmin)) {
            ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
        }
        $count = 0
        $Sources = Get-ChildItem $SourceRoot -directory
        $SourceHashes = @()
        Foreach ($Source in $Sources) {
            Write-Host "$((++$count))) " -NoNewline
            Write-Host $Source.Name -ForegroundColor Blue
            # determine target folder
            $TargetFolder = "$($FolderPubDesktop)\$($Source.Name)"
            $retcode, $retmsg = CopyFilesIfNeeded $Source.Fullname $TargetFolder "date" -delete_extra $true
            foreach ($line in $retmsg) {
                if ($line.StartsWith("OK:00")) {
                    Write-Host $line -ForegroundColor Blue
                }
                else {
                    Write-Host $line -ForegroundColor Green
                }
            } # each retmsg line
        } # each source
        # Delete Removes
        If ($Removes.Count -gt 0) {
            Write-Host "--------------------------"
            Write-Host "$(Split-Path $FilesToRemoveCSV -Leaf)"
            $count=0
            Foreach ($Remove in $Removes) {
                Write-Host "$((++$count))) " -NoNewline
                Write-Host $Remove.Name -ForegroundColor Blue -NoNewline
                $PathToRemove = "$($FolderPubDesktop)\$($Remove.Name)"
                if (Test-Path $PathToRemove) {
                    $oldProgressPreference = $ProgressPreference
                    $ProgressPreference = 'SilentlyContinue'
                    Remove-Item -Path $PathToRemove -Recurse -Force
                    $ProgressPreference = $oldProgressPreference
                    # double check
                    if (Test-Path $PathToRemove) {
                        Write-Host " [ERR, Deleted but still there]" -ForegroundColor Yellow
                    } # has path
                    else {
                        Write-Host " [OK, Deleted]" -ForegroundColor Green
                    } # missing
                } # found
                else {
                    Write-Host " [OK, Already Missing]" -ForegroundColor Blue
                } # missing
            } # each remove
        } # has removes
        if ($mode -eq '') {PressEnterToContinue}
    } # copy
    if ($choice -eq "R")
    { # remove
        Write-Host "-----------------------------------------------------"
        Write-Host "Removing company files from Public Desktop"
        Write-Host "SourceRoot: " -NoNewline
        Write-host $(Split-Path $SourceRoot -Leaf) -ForegroundColor Blue
        Write-Host "TargetRoot: " -NoNewline
        Write-host $FolderPubDesktop -ForegroundColor Blue
        # check if admin
        If (-not(IsAdmin)) {
            ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
        }
        $count = 0
        $Sources = Get-ChildItem $SourceRoot -Directory
        $SourceHashes = @()
        Foreach ($Source in $Sources) {
            Write-Host "$((++$count))) " -NoNewline
            Write-Host $Source.Name -ForegroundColor Blue
            # determine target file path
            $RelativePath = $Source.Fullname.Substring($SourceRoot.Length)
            $TargetFilePath = "$($FolderPubDesktop)$($RelativePath)"
            if (Test-Path $TargetFilePath) {
                $oldProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Remove-Item -Path $TargetFilePath -Recurse -Force
                $ProgressPreference = $oldProgressPreference
                # double check
                if (Test-Path $TargetFilePath) {
                    Write-Host "ERR: $($TargetFilePath) [Deleted but still there]" -ForegroundColor Yellow
                } # has path
                else {
                    Write-Host "OK: $($TargetFilePath) [Deleted]" -ForegroundColor Green
                } # missing
            } # has path
            else {
                Write-Host "OK: $($TargetFilePath) [Already missing]" -ForegroundColor Blue
            } # missing
        } # each source
        if ($mode -eq '') {PressEnterToContinue}
    } # remove
    if ($choice -eq "D")
    { # detect
        Write-Host "-----------------------------------------------------"
        Write-Host "Detecting company files on Public Desktop"
        $bMatchAll = $true
        $count = 0
        Foreach ($SourceHash in $SourceHashes) {
            Write-Host "$((++$count))) " -NoNewline
            Write-Host $SourceHash.SourceName -ForegroundColor Blue -NoNewline
            $TargetFiles = Get-ChildItem "$($FolderPubDesktop)\$($SourceHash.SourceName)" -File -Recurse
            $sErr,$sHash,$HashList = GetHashOfFiles $TargetFiles.FullName -ByDateOrByContents "ByDate"
            Write-Host " Files:" -NoNewline
            Write-host $TargetFiles.Count -ForegroundColor Blue -NoNewline
            Write-Host " Hash:" -NoNewline
            Write-host $sHash -ForegroundColor Blue -NoNewline
            if ($sHash -eq $SourceHash.Hash) {
                Write-Host " [OK]" -ForegroundColor Blue
            } # hash match
            else {
                Write-Host " [MISMATCH]" -ForegroundColor Yellow
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
                Write-Host $Remove.Name -ForegroundColor Blue -NoNewline
                $PathToRemove = "$($FolderPubDesktop)\$($Remove.Name)"
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
        } # has mismatches
        if ($mode -eq '') {PressEnterToContinue}
    } # detect
    if ($choice -eq "I")
    { # intune_settings
        $IntuneSettingsCSVPath = "$($scriptDir)\intune_settings.csv"
        if (-not (Test-Path $IntuneSettingsCSVPath)) {
            Write-Host "Couldn't find csv file: $($IntuneSettingsCSVPath)"
        }
        else {
            # create array of objects
            $intunesettings = @()
            $newRow = [PSCustomObject]@{
                Name  = "AppName"
                Value = Split-path (Split-Path $scriptDir -Parent) -Leaf
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppInstaller"
                Value = "ps1"
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppInstallName"
                Value = $scriptName
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppInstallArgs"
                Value = "ARGS:-mode C"
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppDescription"
                Value = $AppDescription
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppVar1"
                Value = $sSourceHashesAll
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppVar2"
                Value = $sRemovesAll
            } ; $intunesettings += $newRow
            Write-Host "Checking $(Split-Path $IntuneSettingsCSVPath -Leaf)"
            Write-Host "-------------------------------------"
            $IntuneSettingsCSVRows = Import-Csv $IntuneSettingsCSVPath
            $haschanges = $false
            foreach ($intunesetting in $intunesettings) {
                $IntuneSettingsCSVRow =  $IntuneSettingsCSVRows | Where-Object Name -eq $intunesetting.Name
                Write-Host "$($IntuneSettingsCSVRow.Name) = $($IntuneSettingsCSVRow.Value) " -NoNewline
                if ($IntuneSettingsCSVRow.Value -eq $intunesetting.Value) {
                    Write-Host "OK" -ForegroundColor Blue
                } # setting match
                else {
                    $IntuneSettingsCSVRow.Value = $intunesetting.Value
                    Write-Host "Changed to $($intunesetting.Value)" -ForegroundColor Green
                    $haschanges = $true
                } # setting is different
            } # each setting
            if ($haschanges) {
                $IntuneSettingsCSVRows | Export-Csv $IntuneSettingsCSVPath -NoTypeInformation -Force -Encoding $utf8Encoding
                Write-Host "Updated $(Split-Path $IntuneSettingsCSVPath -Leaf)" -ForegroundColor Green
            }
            else {
                Write-Host "No changes required" -ForegroundColor Blue
            }
        } # found intune_settings.csv
        if ($mode -eq '') {PressEnterToContinue}
    } # intune_settings
    if ($mode -ne '') {Break}
} While ($true) # loop until Break 
Write-Host "Done"
# Return result
Write-Output $strReturn
exit $exitcode