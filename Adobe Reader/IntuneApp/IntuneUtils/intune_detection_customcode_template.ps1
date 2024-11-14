###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
###
## -------- Custom Post Install code
# put your custom uninstall code here
# delete this file from your package if it is not needed
<#
IntuneLog "- Delete shortcuts on the user and public desktop"
$dps=@()
$dps+=[Environment]::GetFolderPath("Desktop")
$dps+=[Environment]::GetFolderPath("CommonDesktopDirectory")
ForEach ($dp in $dps)
{ # Each desktop path
    Remove-Item "$($dp)\Adobe*" -whatif  ## display and logging purposes
    Remove-Item "$($dp)\Adobe*"
} # Each desktop path
#>