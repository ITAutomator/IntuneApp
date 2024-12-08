
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
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host " Update public desktop folder with company files."
Write-Host ""
Write-Host "Source :" -NoNewline
Write-Host $folderpubdesktop_source -ForegroundColor Yellow
Write-Host "Target :" -NoNewline
Write-Host $folderpubdesktop_target -ForegroundColor Yellow
Write-Host ""
Write-Host "    mode: $($mode)"
Write-Host "-----------------------------------------------------------------------------"
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
If (-not(IsAdmin))
{
    ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
}
if ($mode -ne 'auto') {PressEnterToContinue}
$retcode, $retmsg= CopyFilesIfNeeded $folderpubdesktop_source $folderpubdesktop_target "date"
$retmsg | Write-Host
Write-Host "Return code: $($retcode)"

if ($mode -ne 'auto') {PressEnterToContinue}
