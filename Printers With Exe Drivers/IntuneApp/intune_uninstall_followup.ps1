###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
###
## -------- Custom Uninstaller
################## Run ps1
$ps1 = "$($scriptDir)\PrinterSetup.ps1"
& $ps1 -mode uninstall
################## Run ps1