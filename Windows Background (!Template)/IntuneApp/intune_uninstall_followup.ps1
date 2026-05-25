$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
## -------- Custom Uninstaller
$ps1 = "$($scriptDir)\SetDesktop.ps1"
& $ps1 -mode uninstall
Start-Sleep 1