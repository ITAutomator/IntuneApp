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
$ShortcutName = "Zoom*"
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
