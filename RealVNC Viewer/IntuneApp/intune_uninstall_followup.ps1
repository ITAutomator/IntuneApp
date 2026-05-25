###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
###
## -------- Custom Uninstaller
# 8wekyb3d8bbwe is Microsoft's package publisher name
#
$regKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RealVNC.VNCViewer_Microsoft.Winget.Source_8wekyb3d8bbwe"
if (Test-Path -Path $regKeyPath) {
    Remove-Item -Path $regKeyPath -Recurse -Force
    Write-Host "Registry key deleted successfully: $(Split-Path $regKeyPath -leaf)"
} else {
    Write-Host "Registry key does not exist: $(Split-Path $regKeyPath -leaf)"
}

