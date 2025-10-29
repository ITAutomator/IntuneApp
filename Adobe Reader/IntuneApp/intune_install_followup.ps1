###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
###
## -------- Custom Post Install code (intune_install_followup.ps1)
# put your custom uninstall code here
# delete this file from your package if it is not needed
# ----------
#region Desktop Shortcuts
$ShortcutName = "Adobe*"
Write-host "- Delete shortcuts on the user and public desktop named: $($ShortcutName)"
$dps=@()
$dps+=[Environment]::GetFolderPath("Desktop")
$dps+=[Environment]::GetFolderPath("CommonDesktopDirectory")
$i=0
$profile = [Environment]::GetFolderPath("UserProfile")
ForEach ($dp in $dps)
{ # Each desktop path
    $ShortcutFiles = Get-ChildItem -Path "$($dp)\$($ShortcutName)" -File
    ForEach ($ShortcutFile in $ShortcutFiles)
    {
        $i+=1
        $sfname = $ShortcutFile.FullName.Replace($profile,"")
        try {
            Remove-Item $ShortcutFile.FullName -ErrorAction Stop
            Write-Host  "$($i): Removing shortcut: $($sfname)"
        }
        catch {
            Write-Host  "$($i): Removing shortcut: $($sfname) (Failed - admin needed?)"
        }
    }
} # Each desktop path
#endregion Desktop Shortcuts
#region Settings
$regPath = 'HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown'
$regValueName = 'bAcroSuppressUpsell'
$regValueSettingDesired = 1
Write-Host "Checking for RegKey: $regPath"
# Check if the key exists
if (Test-Path $regPath) {
    # Check if the value exists
    $regValueSettingCurrent = Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regValueName -ErrorAction SilentlyContinue
    if ($null -ne $regValueSettingCurrent) {
        if ($regValueSettingCurrent -eq $regValueSettingDesired) {
            Write-Host "OK: '$regValueName' is already correctly set to $regValueSettingDesired" -ForegroundColor Green
        } else {
            Write-Host "OK: '$regValueName' exists but is set to $regValueSettingCurrent (expected $regValueSettingDesired) - updating it." -ForegroundColor Yellow
            Set-ItemProperty -Path $regPath -Name $regValueName -Value $regValueSettingDesired
        }
    } else {
        Write-Host "OK: '$regValueName' not found in $regPath, but created and set to $regValueSettingDesired" -ForegroundColor Yellow
        New-ItemProperty -Path $regPath -Name $regValueName -Value $regValueSettingDesired -PropertyType DWord -Force | Out-Null

    }
} else {
    Write-Host "ERR: Setting not applicable to this PC (Registry key does NOT exist)"
}
#endregion Settings
