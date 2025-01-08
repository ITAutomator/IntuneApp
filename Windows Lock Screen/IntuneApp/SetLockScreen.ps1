######################
### Parameters
######################
Param 
	( 
    [string] $mode = "" # "" for manual menu, "auto" or "install" for auto-install, "uninstall" for uninstall
	)
### Main function header
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$scriptCSV      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".csv"  ### replace .ps1 with .xml
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# read scriptCSV for settings
$script_csv = Import-Csv $scriptCSV
$script_settings = @{}
$script_settings.Add("LockScreen"         , ($script_csv | Where-Object Name -EQ LockScreen).Value)
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "This script uses the LockScreen folder and the CSV file to set the lock screen"
Write-Host ""
Write-Host "     Target Folder: $($env:PUBLIC)\Documents\LockScreen"
Write-Host "     Source Folder: LockScreen\"
$wps = Get-ChildItem "$($scriptDir)\LockScreen"
ForEach ($wp in $wps) {
    Write-Host "                    $($wp.Name)"
}
Write-Host "-----------------------------------------------------------"
Write-Host "          CSV File: $(Split-Path $scriptCSV -Leaf)"
Write-Host "        LockScreen: " -NoNewline
Write-Host $script_settings.LockScreen -ForegroundColor Yellow
Write-Host "-----------------------------------------------------------"
if (-not (IsAdmin)) {
    Write-Host "Admin is required to run this script."; Start-Sleep 3; Exit 88
}
if ($mode -eq '') {
    PressEnterToContinue
}
$err_out= ""
if ($mode -eq 'uninstall') {
    if ($script_settings.LockScreen -ne "") {
        Write-Host "Removing LockScreen Regkey"
        RegDel "HKLM" "SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" "LockScreenImagePath"
        RegDel "HKLM" "SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" "LockScreenImageUrl"
        RegDel "HKLM" "SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" "LockScreenImageStatus"
        # Note: if this isn't working, also clear HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization\LockScreenImage
        # This is locked by (but not as good as above) Control Panel > Personalization > Force a specific default lock screen and logon image
    }
} # uninstall
else { # install
    #region: make sure lockscreen exists if specified
    $lockscreen_ok = $false
    $lockscreenfile = ""
    if ($script_settings.LockScreen -ne '')
    {
        $source = "$($scriptDir)\LockScreen\$($script_settings.LockScreen)"
        if (-not(Test-Path -Path $source))
        {
            $lockscreen_ok = $false
            $err_out= "Err: Couldn't find '$($script_settings.LockScreen)' "
        }
        else
        { # source found
            $lockscreen_ok = $true
            # copy files to C:\Users\Public\Documents\lockscreen so that everyone can use it
            $sourcefolder = "$($scriptDir)\LockScreen"
            $targetfolder = "$($env:PUBLIC)\Documents\LockScreen"
            $retcode, $retmsg= CopyFilesIfNeeded $source $targetfolder -CompareMethod "date"
            # set file name
            $lockscreenfile = "$($targetfolder)\$($script_settings.LockScreen)"
        } # source found
    }
    #endregion: make sure lockscreen exists if specified
    if ($lockscreen_ok)
    {# set lockscreen
        $result = RegSetCheckFirst "HKLM" "SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" "LockScreenImagePath" $lockscreenfile "String"
        Write-Host $result
        $result = RegSetCheckFirst "HKLM" "SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" "LockScreenImageUrl" $lockscreenfile "String"
        Write-Host $result
        $result = RegSetCheckFirst "HKLM" "SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" "LockScreenImageStatus" 1 "DWord"
        Write-Host $result
    }# set lockscreen
    Write-Host "-----------------------------------------------------------"
    Write-Host "Done."
    Write-Host $err_out
} # install
if ($mode -eq '') {
    PressEnterToContinue
} # ask for choice
Return $err_out
