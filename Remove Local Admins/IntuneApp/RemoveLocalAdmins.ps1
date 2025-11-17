######################
### Parameters
######################
Param 
	( 
	 [string] $mode = "" # "" for manual menu, "S" for setup printers, "H" for has drivers for this PC architecure, "T" for Detect if already installed
	)
Function Convert-AzureAdSidToObjectId {
<#
.SYNOPSIS
Convert a Azure AD SID to Object ID
 
.DESCRIPTION
Converts an Azure AD SID to Object ID.
Author: Oliver Kieselbach (oliverkieselbach.com)
The script is provided "AS IS" with no warranties.
 
.PARAMETER ObjectID
The SID to convert
#>

    param([String] $Sid)

    $text = $sid.Replace('S-1-12-1-', '')
    $array = [UInt32[]]$text.Split('-')

    $bytes = New-Object 'Byte[]' 16
    [Buffer]::BlockCopy($array, 0, $bytes, 0, 16)
    [Guid]$guid = $bytes

    return $guid
}
Function GetLocalAdmins ($AdminsToRemove, $AdminsToAllow)
{
    # Get Admins to remove and allow as arrays
    $AdminsToRemoveArray = @()
    $AdminsToAllowArray = @()
    ForEach ($AllowRemove in "Allow","Remove")
    { # each Allow and Remove
        # Split comma string into array
        if ($AllowRemove -eq "Allow") {
            $AdminElems = $AdminsToAllow.Split(",")
        }
        if ($AllowRemove -eq "Remove") {
            $AdminElems = $AdminsToRemove.Split(",")
        }
        # Process each admin element
        ForEach ($AdminElem in $AdminElems)
        { # each admin element
            $AdminElem = $AdminElem.Trim()
            if ($AdminElem -eq "") {Continue}
            $AdminSrch = $AdminElem.Replace("*","")
            $AdminSrch = $AdminSrch.Replace(".\","$($env:COMPUTERNAME)\")
            if ($AdminSrch  -notlike "*\*" ) {$AdminSrch = "$($env:COMPUTERNAME)\$($AdminElem)"}
            # Create object
            $obj_this = [PSCustomObject]@{
                Elem = $AdminElem
                Srch = $AdminSrch
                Type = $AllowRemove
            } # create object
            # Add to correct array
            if ($AllowRemove -eq "Allow") {
                $AdminsToAllowArray += $obj_this
            }
            if ($AllowRemove -eq "Remove") {
                $AdminsToRemoveArray += $obj_this
            }
        } # each admin element
    } # each Allow and Remove
    # Get local admins
    $LocalUsers = Get-LocalGroupMember -SID "S-1-5-32-544"
    $locadmins = @()
    ForEach ($LocalUser in $LocalUsers)
    {
        # Create custom object and append to array
        $user_this = [PSCustomObject]@{
            Name = $LocalUser.Name
            NameClean = $LocalUser.Name
            NameOrig = $LocalUser.Name
            SID  = $LocalUser.SID.value
            Class = $LocalUser.ObjectClass
            Source = $LocalUser.PrincipalSource
            Enabled = $true
            Status = ""
        } # create object
        # Adjust Name for AzureAD accounts
        if ($user_this.SID.StartsWith("S-1-12-1-"))
        {
            $user_this.Name = "AzureAD ObjectID " + (Convert-AzureAdSidToObjectId -Sid $user_this.SID)
        }
        # Check if enabled
        if ($user_this.Class -eq "User") {
            $locuser = Get-LocalUser -SID $user_this.SID -ErrorAction SilentlyContinue
            if ($locuser) {
                $user_this.Enabled = $locuser.Enabled
            } # is found
        } # is User
        # Name fixes
        if ($user_this.NameClean -eq $user_this.SID) {
            $user_this.NameClean = $user_this.Name
        }
        if ($user_this.Source -notin "Local","AzureAD") {
            $user_this.Status = "OK: Account source is ignored by this script [$($user_this.Source)]"
        } # account source ignored
        else
        { # account source not ignored
            # ToRemove
            $toRemove = $false
            $RemoveVia = ""
            ForEach ($AdminToRemove in $AdminsToRemoveArray) {
                if ($user_this.NameClean -like "*$($AdminToRemove.Srch)*" ) {
                    $toRemove = $true; $RemoveVia=$AdminToRemove.Elem ;break
                }
            }
            # ToAllow
            $toAllow = $false
            $AllowVia = ""
            ForEach ($AdminToAllow in $AdminsToAllowArray) {
                if ($user_this.NameClean -like "*$($AdminToAllow.Srch)*" ) {
                    $toAllow = $true; $AllowVia=$AdminToAllow.Elem ;break
                }
            }
            if ($toAllow)
            { # marked to allow
                if ($toRemove) {
                    if ($user_this.Enabled) {
                        $user_this.Status = "OK: Allowed (overrides removal) [AllowVia $($AllowVia), RemoveVia $($RemoveVia)]"
                    }
                    else {
                        $user_this.Status = "OK: Allowed (overrides removal), but account is disabled [AllowVia $($AllowVia), RemoveVia $($RemoveVia)]"
                    }
                } # allowed and marked to remove
                else {
                    if ($user_this.Enabled) {
                        $user_this.Status = "OK: Allowed [AllowVia $($AllowVia)]"
                    }
                    else {
                        $user_this.Status = "OK: Allowed, but account is disabled [AllowVia $($AllowVia)]"
                    }
                } # allowed and not marked to remove
            } # marked to allow
            else
            { # not marked to allow
                if ($toRemove) {
                    if ($user_this.Enabled) {
                        $user_this.Status = "Action: Needs removal (will be de-elevated) [RemoveVia $($RemoveVia)]"
                    }
                    else {
                        $user_this.Status = "OK: Marked for removal (but is disabled so no action needed) [RemoveVia $($RemoveVia)]"
                    }
                } # marked to remove
                else {
                    if ($user_this.Enabled) {
                        $user_this.Status = "OK: Not marked for removal"
                    }
                    else {
                        $user_this.Status = "OK: Not marked for removal (and is disabled already)"
                    }
                } # not marked to remove
            } # not marked to allow
            
        } # account source not ignored
        # Append to array
        $locadmins += $user_this
    }
    return $locadmins
} # GetLocalAdmins
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

# Load settings
$csvFile = "$($scriptDir)\$($scriptBase) Settings.csv"
$settings = CSVSettingsLoad $csvFile
# Defaults
$settings_updated = $false
if ($null -eq $settings.AdminsToAllow) {$settings.AdminsToAllow = "AdminContoso,AdminFabrikant,AzureAD\JohnAdmin"; $settings_updated = $true}
if ($null -eq $settings.AdminsToRemove) {$settings.AdminsToRemove = "AzureAD\*,.\*"; $settings_updated = $true}
if ($settings_updated) {$retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"}
# cmd line info
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -ForegroundColor Green
Write-Host ""
Write-Host "      Settings: "-NoNewline
Write-host "$($scriptBase) Settings.csv" -ForegroundColor Yellow
Write-Host ""
$AppDescription = "Removes Local Admins [De-elevates to a regular user] (Does not affect the built-in AzureAD DeviceAdmin or Microsoft accounts)`n"
Write-Host $AppDescription
$AppDescription += "AdminsToRemove: $($settings.AdminsToRemove)`n"
$AppDescription += "AdminsToAllow: $($settings.AdminsToAllow)`n"
# Menu
Do { # action
    Write-Host "Admins To Remove: " -NoNewline
    Write-Host $settings.AdminsToRemove -ForegroundColor cyan
    Write-Host "Admins To Allow : " -NoNewline
    Write-Host $settings.AdminsToAllow -ForegroundColor cyan
    Write-Host "--------------- Choices  ------------------"
    Write-Host "[R] Remove Local Admins (de-elevate)"
    Write-Host "[D] Detect Local Admins to de-elevate"
    Write-Host "[E] Edit Settings CSV file"
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
    if ($choice -eq "E")
    { # edit settings
        Invoke-Item $csvFile
        PressEnterToContinue
        $settings = CSVSettingsLoad $csvFile
    } # edit settings
    if ($choice -eq "R")
    { # remove
        Write-Host "-----------------------------------------------------"
        Write-Host "Local Admin Accounts on this machine"
        Write-Host "-----------------------------------------------------"
        $NoneToRemove = $true
        $LocalAdmins = GetLocalAdmins -AdminsToRemove $settings.AdminsToRemove -AdminsToAllow $settings.AdminsToAllow
        if ($LocalAdmins.count -eq 0) {
            Write-Host "No local admins" -ForegroundColor Yellow
        }
        else
        { # LocalAdmins found
            ForEach ($LocalAdmin in $LocalAdmins | Sort-Object Source,NameClean)
            { # each local admin
                Write-Host "[$($LocalAdmin.Source)] $($LocalAdmin.NameClean) " -NoNewline
                if ($LocalAdmin.Status -like "Action:*") {
                    if ($NoneToRemove) {$NoneToRemove = $false}
                    Write-Host $LocalAdmin.Status -ForegroundColor yellow
                } # action required
                else {
                    Write-Host $LocalAdmin.Status -ForegroundColor Green
                } # no action
            } # each local admin
        }  # LocalAdmins found
        Write-Host "-----------------------------------------------------"
        if ($NoneToRemove) {
            $strReturn = "OK: $($scriptName) $($CmdLineInfo) [No local admins found to remove]"
            $exitcode = 0
        }
        else {
            $adminsremoved = @()
            Write-Host "Removing from Administrators: (Effective for NEXT logon)"
            ForEach ($LocalAdmin in $LocalAdmins | Sort-Object Source,NameClean | Where-Object Status -like "Action:*")
            { # each local admin
                Write-Host "Removing admin from [$($LocalAdmin.Source)] $($LocalAdmin.NameClean)" -ForegroundColor Yellow
                Remove-LocalGroupMember -SID "S-1-5-32-544" -Member $LocalAdmin.SID -Confirm:$False
                $adminsremoved += $LocalAdmin.NameClean
            } # each local admin
            $strReturn = "OK: $($scriptName) $($CmdLineInfo) Admins removed [$($adminsremoved -join ", ")]"
            $exitcode = 0
        }
        Write-Host "Check: $($strReturn)"
        if ($mode -eq '') {PressEnterToContinue}
    } # remove
    if ($choice -eq "D")
    { # detect
        Write-Host "-----------------------------------------------------"
        Write-Host "Local Admin Accounts on this machine"
        Write-Host "-----------------------------------------------------"
        $NoneToRemove = $true
        $LocalAdmins = GetLocalAdmins -AdminsToRemove $settings.AdminsToRemove -AdminsToAllow $settings.AdminsToAllow
        if ($LocalAdmins.count -eq 0) {
            Write-Host "No local admins" -ForegroundColor Yellow
        }
        else
        { # LocalAdmins found
            ForEach ($LocalAdmin in $LocalAdmins | Sort-Object Source,NameClean)
            { # each local admin
                Write-Host "[$($LocalAdmin.Source)] $($LocalAdmin.NameClean) " -NoNewline
                if ($LocalAdmin.Status -like "Action:*") {
                    if ($NoneToRemove) {$NoneToRemove = $false}
                    Write-Host $LocalAdmin.Status -ForegroundColor yellow
                } # action required
                else {
                    Write-Host $LocalAdmin.Status -ForegroundColor Green
                } # no action
            } # each local admin
        }  # LocalAdmins found
        Write-Host "-----------------------------------------------------"
        if ($NoneToRemove) {
            $strReturn = "OK: $($scriptName) $($CmdLineInfo) [No local admins found to remove]"
            $exitcode = 0
        }
        else {
            $strReturn = "ERR: $($scriptName) $($CmdLineInfo) [Local admin found to remove]"
            $exitcode = 99
        }
        Write-Host "Check: $($strReturn)"
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
                Value = "ARGS:-mode R"
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppDescription"
                Value = $AppDescription
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppVar1"
                Value = "Admins to Remove: $($settings.AdminsToRemove)"
            } ; $intunesettings += $newRow
            
            $newRow = [PSCustomObject]@{
                Name  = "AppVar2"
                Value = "Admins to Allow: $($settings.AdminsToAllow)"
            } ; $intunesettings += $newRow
            Write-Host "Checking $(Split-Path $IntuneSettingsCSVPath -Leaf)"
            Write-Host "-------------------------------------"
            $IntuneSettingsCSVRows = Import-Csv $IntuneSettingsCSVPath
            $haschanges = $false
            foreach ($intunesetting in $intunesettings) {
                $IntuneSettingsCSVRow =  $IntuneSettingsCSVRows | Where-Object Name -eq $intunesetting.Name
                Write-Host "$($IntuneSettingsCSVRow.Name) = $($IntuneSettingsCSVRow.Value) " -NoNewline
                if ($IntuneSettingsCSVRow.Value -eq $intunesetting.Value) {
                    Write-Host "OK" -ForegroundColor Green
                } # setting match
                else {
                    $IntuneSettingsCSVRow.Value = $intunesetting.Value
                    Write-Host "Changed to $($intunesetting.Value)" -ForegroundColor Yellow
                    $haschanges = $true
                } # setting is different
            } # each setting
            if ($haschanges) {
                $IntuneSettingsCSVRows | Export-Csv $IntuneSettingsCSVPath -NoTypeInformation -Force
                Write-Host "Updated $(Split-Path $IntuneSettingsCSVPath -Leaf)" -ForegroundColor Yellow
            }
            else {
                Write-Host "No changes required" -ForegroundColor Green
            }
            PressEnterToContinue
        } # found intune_settings.csv
    } # intune_settings
    if ($mode -ne '') {Break}
} While ($true) # loop until Break 
Write-Host "Done"
# Return result
Write-Output $strReturn
exit $exitcode