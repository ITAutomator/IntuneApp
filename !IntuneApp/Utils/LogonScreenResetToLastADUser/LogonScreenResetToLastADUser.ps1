<# 
.SYNOPSIS
  Set the Windows logon screen default user to a chosen Azure AD (Entra ID) account.

.DESCRIPTION
  Enumerates local profiles with Azure AD SIDs (S-1-12-1-*) and shows them ordered by LastUseTime (desc).
  You pick the desired account; the script writes LogonUI "last user" values accordingly.

.PARAMETER UserUPN
  (Optional) If provided, skips the menu and sets this user directly (must have signed in at least once).

.PARAMETER NoPolicyChange
  If set, the script will NOT modify HKLM\...\Policies\System\DontDisplayLastUserName.
  By default, the script sets it to 0 so the chosen user appears instead of "Other user".

.EXAMPLES
  .\Set-DefaultLogonUser.ps1
  .\Set-DefaultLogonUser.ps1 -NoPolicyChange
  .\Set-DefaultLogonUser.ps1 -UserUPN "alice@contoso.com"
#>

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    return $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AadSidFromUpn {
    param([Parameter(Mandatory=$true)][string]$Upn)
    try {
        $nt = New-Object System.Security.Principal.NTAccount("AzureAD", $Upn)
        return ($nt.Translate([System.Security.Principal.SecurityIdentifier])).Value
    } catch {
        throw "Could not resolve SID for AzureAD\$Upn. Ensure this user has signed in at least once on this device."
    }
}

function Get-AadProfiles {
    # Returns PSCustomObject: UPN, Account, SID, LastUseTime (UTC), LastUseLocal
    $list = @()
    try {
        $profiles = Get-CimInstance Win32_UserProfile | Where-Object {
            $_.SID -like 'S-1-12-1-*' -and $_.LocalPath -like 'C:\Users\*'
        } | Sort-Object -Property LastUseTime -Descending
    } catch {
        $profiles = @()
    }

    foreach ($p in $profiles) {
        try {
            $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID)
            $nt     = $sidObj.Translate([System.Security.Principal.NTAccount])
            $acct   = $nt.Value  # "AzureAD\user@domain"
            if ($acct -like 'AzureAD\*') {
                $upn = $acct.Split('\')[-1]
                $list += [PSCustomObject]@{
                    UPN          = $upn
                    Account      = $acct
                    SID          = $p.SID
                    LastUseTime  = $p.LastUseTime
                    LastUseLocal = [DateTime]::SpecifyKind($p.LastUseTime,[DateTimeKind]::Utc).ToLocalTime()
                }
            }
        } catch { continue }
    }
    return $list
}

function Choose-TargetAccount {
    param([Parameter(Mandatory=$true)][object[]]$Candidates)

    if (-not $Candidates -or $Candidates.Count -eq 0) {
        throw "No eligible Azure AD profiles found (S-1-12-1-*). Have the user sign in at least once."
    }

    Write-Host ""
    Write-Host "Eligible Azure AD accounts (most recent first):" -ForegroundColor Cyan
    $i = 1
    foreach ($c in $Candidates) {
        # e.g. [1] user@contoso.com  Last used: 2025-11-12 13:07
        Write-Host ("[{0}] {1,-35}  Last used: {2}" -f $i, $c.UPN, $c.LastUseLocal)
        $i++
    }
    Write-Host ""

    $default = 1
    $resp = Read-Host ("Select a number 1..{0} (default {1})" -f $Candidates.Count, $default)
    if ([string]::IsNullOrWhiteSpace($resp)) { $resp = $default }
    if (-not ($resp -as [int])) { throw "Invalid selection: '$resp'." }
    $sel = [int]$resp
    if ($sel -lt 1 -or $sel -gt $Candidates.Count) { throw "Selection out of range." }

    return $Candidates[$sel-1]
}
# Main Routine
$ScriptName = $MyInvocation.MyCommand.Name
Write-Host "-------------------------------"
Write-Host $ScriptName
Write-Host ""
Write-Host "Use this script to reset the logon screen to show a specific user as default."
Write-Host "Note: Only Cached, AzureAD, Non-logged on accounts are shown. "
Write-Host "-------------------------------"
if (-not (Test-Admin)) {
    Write-Error "Please run this script in an elevated PowerShell session."
	$null = Read-Host "Press Enter to continue"
    exit 1
}
# Values LogonUI reads to show the selected/last user
$logonUiKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
# Show the current LastLoggedOnUser (and related values if they exist)
if (Test-Path $logonUiKey) {
    $props = Get-ItemProperty -Path $logonUiKey -ErrorAction SilentlyContinue
    if ($props) {
        Write-Host "Current LogonUI values:" -ForegroundColor Cyan
        Write-Host ("  LastLoggedOnUser       : {0}" -f ($props.LastLoggedOnUser  | Out-String).Trim())
        Write-Host ("  LastLoggedOnDisplayName: {0}" -f ($props.LastLoggedOnDisplayName | Out-String).Trim())
        Write-Host ("  LastLoggedOnUserSID    : {0}" -f ($props.LastLoggedOnUserSID | Out-String).Trim())
        Write-Host ("  SelectedUser           : {0}" -f ($props.SelectedUser | Out-String).Trim())
    } else {
        Write-Host "No properties found under $logonUiKey" -ForegroundColor Yellow
    }
} else {
    Write-Host "Registry key not found: $logonUiKey" -ForegroundColor Red
}
# Determine target account
$target = $null
$cands = Get-AadProfiles
$target = Choose-TargetAccount -Candidates $cands
Write-Host "-------------------------------"
Write-Host ("Setting default logon user to: {0} (SID: {1})" -f $target.Account, $target.SID) -ForegroundColor Green
# Ensure keys
if (-not (Test-Path $logonUiKey)) { New-Item -Path $logonUiKey -Force | Out-Null }
# Set User
$props = @{
    'LastLoggedOnUser'        = $target.Account
    'LastLoggedOnDisplayName' = $target.UPN
    'LastLoggedOnUserSID'     = $target.SID
    'LastLoggedOnSAMUser'     = $target.Account
    'LastLoggedOnSAMUserSID'  = $target.SID
    'SelectedUser'            = $target.Account
    'UserSwitch'              = 1
}
foreach ($name in $props.Keys) {
    $value = $props[$name]
    if ($value -is [int]) { $type = 'DWord' } else { $type = 'String' }
    New-ItemProperty -Path $logonUiKey -Name $name -Value $value -PropertyType $type -Force | Out-Null
}
# # Policy
# $polKey     = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
# if (-not $NoPolicyChange) {
#     if (-not (Test-Path $polKey)) { New-Item -Path $polKey -Force | Out-Null }
#     New-ItemProperty -Path $polKey -Name 'DontDisplayLastUserName' -Value 0 -PropertyType DWord -Force | Out-Null
# } else {
#     Write-Host "Skipping policy change (DontDisplayLastUserName) due to -NoPolicyChange." -ForegroundColor Yellow
# }
Write-Host ""
Write-Host "Done. Sign out or switch user — the logon screen should default to:" -NoNewline
Write-Host "  $($target.Account)" -ForegroundColor Cyan
$null = Read-Host "Press Enter to continue"