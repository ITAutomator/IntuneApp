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
## Show Local admins

function Convert-AzureAdSidToObjectId {
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
$app_detected = $false
Write-host "------ intune_settings.csv"
Write-host "AppVar1 is $($IntuneApp.AppVar1)" # AdminsToRemove
if ($IntuneApp.AppVar1 -match ":") {
    $Contents = ($IntuneApp.AppVar1 -split ":")[1].trim(" ") # grab the stuff after the :
} # there's a : char
$AdminsToRemove = $Contents

Write-host "AppVar2 is $($IntuneApp.AppVar2)" # AdminsToAllow
if ($IntuneApp.AppVar1 -match ":") {
    $Contents = ($IntuneApp.AppVar2 -split ":")[1].trim(" ") # grab the stuff after the :
} # there's a : char
$AdminsToAllow = $Contents
Write-Host "Admins To Remove: " -NoNewline
Write-Host $AdminsToRemove -ForegroundColor cyan
Write-Host "Admins To Allow : " -NoNewline
Write-Host $AdminsToAllow -ForegroundColor cyan
if ($true) {
    Write-Host "-----------------------------------------------------"
    Write-Host "Local Admin Accounts on this machine"
    Write-Host "-----------------------------------------------------"
    $NoneToRemove = $true
    $LocalAdmins = GetLocalAdmins -AdminsToRemove $AdminsToRemove -AdminsToAllow $AdminsToAllow
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
        # $strReturn = "OK: $($scriptName) $($CmdLineInfo) [No local admins found to remove]"
        # $exitcode = 0
        $app_detected = $true
    }
    else {
        # $strReturn = "ERR: $($scriptName) $($CmdLineInfo) [Local admin found to remove]"
        # $exitcode = 99
        $app_detected = $false
    }
    Write-Host "Check: $($strReturn)"
    # if ($mode -eq '') {PressEnterToContinue}
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "App detected (No Removal needed): $($app_detected)"
Return $app_detected
