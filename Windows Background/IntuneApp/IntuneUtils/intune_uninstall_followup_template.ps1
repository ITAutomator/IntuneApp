###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
###
## -------- Custom Uninstaller
# put your custom uninstall code here
# delete this file from your package if it is not needed

################## Run ps1
$ps1 = "$($scriptDir)\MyUninstaller.ps1"
& $ps1 -mode auto
################## Run ps1