###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
###
## -------- Custom Uninstaller
# put your custom uninstall code here
# delete this file from your package if it is not needed
################## Run ps1
$ps1 = "$($scriptDir)\1Password Setup.ps1"
& $ps1 -AutoMenuChoice U
################## Run ps1