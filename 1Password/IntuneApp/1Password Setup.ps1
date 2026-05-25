######################
### Parameters
######################
Param ( 
	 [string] $AutoMenuChoice = "" # "" 
)
######################
### Functions
######################

######################
## Main Procedure
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Parameters passed: " -NoNewline
Write-Host $(if ($AutoMenuChoice -eq ''){"(none)"} else {"-mode $($AutoMenuChoice)"}) -ForegroundColor Yellow
Write-Host ""
Write-Host "This script Installs, Uninstalls, and Detects 1Password."
Write-Host "- User-level install."
Write-Host "- Downloads latest version."
Write-Host "- Works on x64 and arm64 devices."
Write-Host ""
# if (-not(IsAdmin))
# {
#     write-host "This must be run as admin / elevated"
#     Start-Sleep -Seconds 2
#     return
# }
$strWarnings = @()
Do { # action
    Write-Host "-------------------------------------------------------"
    Write-Host "Use [I] to Install 1Password."
    Write-Host "Use [U] to Uninstall 1Password."
    Write-Host "Use [D] to Detect 1Password"
    Write-Host "[X] Exit"
    Write-Host "-------------------------------------------------------"
    if ($AutoMenuChoice -eq '') {
        $choice = PromptForString "Choice [blank to exit]"
    } # ask for choice
    else {
        Write-Host "Choice: [$($AutoMenuChoice)]  (-AutoMenuChoice $($AutoMenuChoice))"
        $choice = $AutoMenuChoice
    } # don't ask (auto)
    if (($choice -eq "") -or ($choice -eq "X")) {
        Break
    } # Exit
    if ($choice -eq "D")
    { # detect
        Write-Host "Detecting 1Password..."
        $app_detected = $false
        # Admin
        # $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*1Password*" }
        # $installed   = Get-AppxPackage -AllUsers -Name "*1Password*"
        # if ($provisioned -or $installed) { $app_detected = $true }
        # Write-Host "Provisioned package : $(if ($provisioned) {$provisioned.DisplayName} else {'(none)'})"
        # Write-Host "Installed package   : $(if ($installed)   {$installed.Name}        else {'(none)'})"
        # User
        $installed   = Get-AppxPackage -Name "*1Password*"
        if ($installed) { $app_detected = $true }
        Write-Host "Installed package   : $(if ($installed)   {$installed.Name}        else {'(none)'})"
        #
        if ($app_detected) {
            Write-Host "1Password IS detected."
        } else {
            Write-Host "1Password IS NOT detected."
        }
    } # detect
    if ($choice -in ("I"))
    { # install
        Write-Host "Installing 1Password..."
        # Download URLs for latest MSIX packages
        $url_x64   = "https://c.1password.com/dist/1P/win8/1PasswordSetup-latest.msixbundle"
        $url_arm64 = "https://c.1password.com/dist/1P/win8/1PasswordSetup-latest.msixbundle"
        # Determine system architecture
        if ([System.Environment]::Is64BitOperatingSystem) {
            if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) {
                $url = $url_arm64
            } else {
                $url = $url_x64
            }
        } else {
            $errMsg = "1Password can only be installed on a 64-bit operating system."
            Write-Host $errMsg -ForegroundColor Red
            $strWarnings += $errMsg
            Start-Sleep -Seconds 2
            Break
        }
        $TmpFld = GetTempFolder -Prefix "1password_"
        $msixpath = "$TmpFld\1PasswordSetup-latest.msixbundle"
        # Download the latest MSIX to a temp folder
        Write-Host "Downloading the latest 1Password MSIX ..." -ForegroundColor Cyan
        Write-Host $url -ForegroundColor Green
        $ProgressPreference_Old = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        $response = Invoke-WebRequest -Uri $url -OutFile $msixpath -UseBasicParsing -MaximumRedirection 10
        $ProgressPreference = $ProgressPreference_Old
        if (-not (Test-Path $msixpath))
        { # download failed
            $errMsg = "Failed to download the MSIX from $url. Status code: $($response.StatusCode)"
            Write-Host $errMsg -ForegroundColor Yellow
            $strWarnings += $errMsg
            Start-Sleep -Seconds 2
        } # download failed
        else 
        { # downloaded OK
            # Provision the package for all users (Requires Admin)
            Write-Host "Provisioning 1Password machine-wide..." -ForegroundColor Cyan
            $AddResult = Add-AppxPackage -Path $msixpath
            # Show results
            Write-Host "Successfully provisioned 1Password." -ForegroundColor Green
            # Write-Host "Restart needed: $($AddResult.RestartNeeded)" -ForegroundColor Yellow
            Start-Sleep 2
            # Clean up temp file
            Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
            Remove-Item -Recurse -Force $TmpFld
            Write-Host "Done" -ForegroundColor Green
            Start-sleep 2
        } # downloaded OK
    } # install
    if ($choice -in ("U"))
    { # uninstall
        Write-Host "Uninstalling 1Password..."
        $getpackage = Get-AppxPackage | Where-Object { $_.Name -like "*Agilebits.1Password*" }
        if (-not $getpackage) {
            Write-Host "No installed 1Password package found." -ForegroundColor Yellow 
        } else {
            Write-Host "Removing provisioned package: $($getpackage.PackageName)" -ForegroundColor Cyan
            $RemoveResult = $getpackage | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName }
            Write-Host "Successfully uninstalled 1Password." -ForegroundColor Green
        }
    } # uninstall
    Start-Sleep -Seconds 2
    if ($AutoMenuChoice -ne '') {Break} # if auto choice, only do one loop
} While ($true) # loop until Break 
Write-Host "Done"
# Return result
if ($strWarnings.count -eq 0) {
    $strReturn = "OK: $($scriptName) $(if ($AutoMenuChoice -ne '') {"-AutoMenuChoice $($AutoMenuChoice)"})"
    $exitcode = 0
}
else {
    $strReturn = "ERR: $($scriptName) $($CmdLineInfo): $($strWarnings -join ', ')"
    $exitcode = 11
}
Write-host "Return: [$($exitcode)] $($strReturn)"
Write-Output $strReturn
exit $exitcode