
##################################
### Parameters
##################################
Param 
	( 
	 [string] $mode = "manual" #auto       ## -mode auto (Proceed without user input for automation. use 'if ($mode -eq 'auto') {}' in code)
	)

##################################
### Functions
##################################


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

#######################
## Main Procedure Start
#######################
$folderpubdesktop_source="$($scriptDir)\Public Desktop"
$folderpubdesktop_target=[System.Environment]::GetFolderPath("CommonDesktopDirectory")
$CmdLineInfo = "(none)"
if ($mode -ne ''){$CmdLineInfo = "-mode $($mode)"}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host " Update public desktop folder with company files."
Write-Host ""
Write-Host "Source :" -NoNewline
Write-Host $folderpubdesktop_source -ForegroundColor Yellow
Write-Host "Target :" -NoNewline
Write-Host $folderpubdesktop_target -ForegroundColor Yellow
Write-Host ""
if (-not(Test-Path $folderpubdesktop_source)){
    Write-Host "Couldn't find folder: $($folderpubdesktop_source)"
  Start-Sleep 3
  Exit 98
}
if (-not(Test-Path $folderpubdesktop_target)){
    Write-Host "Couldn't find folder: $($folderpubdesktop_target)"
    Start-Sleep 3
    Exit 99
}
# get paths to remove
$PrnCSVPathRmv = "$($scriptDir)\$($scriptBase) ToRemove.csv"
if (-not (Test-Path $PrnCSVPathRmv)) {
    Write-Host "Couldn't find csv file, creating template: $($PrnCSVPathRmv)"
    Add-Content -Path $PrnCSVPathRmv -Value "FullPathsToRemove"
}
$PrnCSVRowsRmv      = @(Import-Csv $PrnCSVPathRmv)
if ($PrnCSVRowsRmv.count -gt 0) {
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "$($scriptBase) ToRemove.csv [rows]: " -NoNewline
    Write-Host $PrnCSVRowsRmv.count -ForegroundColor Yellow
    $PrnCSVRowsRmv.FullPathsToRemove | ForEach-Object {Write-Host "- $($_)"}
}
Write-Host "-----------------------------------------------------------------------------"
If (-not(IsAdmin)) {
    ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
}
if ($mode -ne 'auto') {PressEnterToContinue}
# Remove Files
$entries = $PrnCSVRowsRmv.FullPathsToRemove
if ($entries.count -gt 0) {
    Write-Host "--- Removing files"
}
$i = 0
foreach ($FullPath in $entries)
{ #each path to remove
    $i+=1
    if (-not ($FullPath -like "$folderpubdesktop_target\*")) {
        Write-Host "ERR: Del ($FullPath) [The path must be within $($folderpubdesktop_target)]" -ForegroundColor Yellow
    } # path outside of C:\Public\Desktop
    else
    { # path starts with C:\Public\Desktop

    } # path starts with C:\Public\Desktop
    if (Test-Path $FullPath) {
        Remove-Item -Path $FullPath -Recurse -Force
        # double check
        if (Test-Path $FullPath) {
            Write-Host "ERR: Del ($FullPath) [Deleted but still there]" -ForegroundColor Yellow
        } # has path
        else {
            Write-Host "OK: Del ($FullPath) [Deleted]"
        } # missing
    } # has path
    else {
        Write-Host "OK: Del ($FullPath) [Already missing]"
    } # missing
} # each path to remove
# Add Files
Write-Host "--- Adding files"
$retcode, $retmsg= CopyFilesIfNeeded $folderpubdesktop_source $folderpubdesktop_target "date" -delete_extra $false
$retmsg | Write-Host
Write-Host "CopyFilesIfNeeded code: $($retcode)"
# Done
Write-Host "--- Done"
if ($mode -ne 'auto') {PressEnterToContinue}