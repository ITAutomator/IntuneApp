# Install.ps1
# Template .ps1 to call subscripts.
#
# Steps to modify for your use 
#
# 1. Update the line $NeedsAdmin with $true or $false depending on elevation requirements.  $true will self-elevate the script
#
# 2. Update the subscripts mentioned below "call ps1 files"
#    If params are needed (other than $mode) make adjustments
#
# 3. Update intune_settings.csv with these values
#    AppInstallName Setup.ps1
#    AppInstallArgs ARGS:-mode auto
#
# To enable scripts system-wide, run powershell as admin and type Set-ExecutionPolicy Unrestricted
#
Param (
	[string] $mode = "manual" #auto
)
$mode_auto = ($mode -eq "auto")
Function IsAdmin() 
{
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    $IsAdmin
}
Function ElevateViaRelaunch()
{
    # Will relaunch Powershell in an elevated session (if needed)
    if (IsAdmin) { Return 0} # not needed - just return
    # rebuild the argument list
    foreach($k in $MyInvocation.BoundParameters.keys)
    {
        switch($MyInvocation.BoundParameters[$k].GetType().Name)
        {
            "SwitchParameter" {if($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
            "String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
            "Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
            "Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
        }
    }
    $argumentlist ="-File `"$($scriptFullname)`" $($argsString)"
    # rebuild the argument list
    Write-Host "Restarting as elevated powershell.exe -File `"$($scriptname)`" $($argsString)"
    Try
    {
        # restart this ps1 elevated (note: if debugging, make sure debugger is running as admin. otherwise this code escapes debugging)
        Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
    }
    Catch {
        $exitcode=110; Write-Host "Err $exitcode : This script required Administrator priviledges, but elevation failed." -ForegroundColor Yellow
        Write-Host "Failed to start PowerShell elevated" -ForegroundColor Yellow
        Start-Sleep 2
        Throw "Failed to start PowerShell elevated"
    }
    Exit
}
###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}

######### indicate if elevation is needed
$NeedsAdmin = $false # True means this script requires elevation
$Isadmin = IsAdmin
#
Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username PSver:"+($PSVersionTable.PSVersion.Major))
Write-host "Mode: $($mode)      NeedsAdmin: $($NeedsAdmin)    IsAdmin: " -NoNewline
if ($NeedsAdmin -eq $Isadmin) {Write-Host $Isadmin} else {Write-Host $Isadmin -ForegroundColor Red}
Write-Host ""
Write-Host "Calls subscripts."
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
If ($NeedsAdmin) {
    If (-not ($Isadmin)) {
        Write-Host "Requires elevation.  Elevating.."
        ElevateViaRelaunch
    } IsAdmin
} # NeedsAdmin

######### call exe files
$exePath = "$($scriptDir)\Setup.exe" 
$arguments = '/install /quiet /norestart'
$process = Start-Process -FilePath $exePath -ArgumentList $arguments -Wait -PassThru
Write-Host "Process exited with code: $($process.ExitCode)"

#### registry keys
$regPath  = 'HKCU:\Software\Microsoft\VSTO\Security\Inclusion\c3364b77-1780-4def-965c-e1111c93f7c1'
$valueName = 'PublicKey'
$valueData = '<RSAKeyValue><Modulus>zYGWOK5covLB397Qq5WN1jydH4vDXYYuXfCxcvWrrIhqtdqxInsLyMilS5FeIhPp+fUjnbX0bnau7+6kPMfEwFlcP6uzczMmpmKBYXmhYvRuiJXQbt3Hn9KkURF2YbpwimWhlhaJp12B0ERm5dtWnkDK/Nx2JC5EMADl1n17lRHVWB2j6E8LyYjcotZTmWzKY8qZapqSXkxNEegv01tbXl9So3MtpbuERQ2MGRV2ywjamqZwFehN7Gn9XbJrj+0pUTc4i8ZGSRWUUJiw9Gik194JcWd0nneMHYVrl+rnX0XM4OZxDdFjAJN7MZiOC7QTvbPQ7vHfIe6pYGHuN0M9ww==</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>'
if (-not (Test-Path $regPath)) {New-Item -Path $regPath -Force | Out-Null}
New-ItemProperty -Path $regPath -Name $valueName -Value $valueData -PropertyType String -Force | Out-Null

$regPath  = 'HKCU:\Software\Microsoft\VSTO\Security\Inclusion\c3364b77-1780-4def-965c-e1111c93f7c1'
$valueName = 'Url'
$valueData = "file:///$($Env:LOCALAPPDATA.Replace("\","/"))/Apps/Microsoft/Fuzzy Lookup Add-In For Excel/Bin/FuzzyLookupAddInForExcel.vsto"
if (-not (Test-Path $regPath)) {New-Item -Path $regPath -Force | Out-Null}
New-ItemProperty -Path $regPath -Name $valueName -Value $valueData -PropertyType String -Force | Out-Null

$regPath  = 'HKCU:\Software\Microsoft\VSTO\SolutionMetadata'
$valueName = "$($Env:LOCALAPPDATA)\Apps\Microsoft\Fuzzy Lookup Add-In For Excel\Bin\FuzzyLookupAddInForExcel.vsto"
$valueData = "{4B88D36C-4A42-42BA-AFA0-B1C9B715163F}"
if (-not (Test-Path $regPath)) {New-Item -Path $regPath -Force | Out-Null}
New-ItemProperty -Path $regPath -Name $valueName -Value $valueData -PropertyType String -Force | Out-Null

$regPath  = 'HKCU:\Software\Microsoft\VSTO\SolutionMetadata\{4B88D36C-4A42-42BA-AFA0-B1C9B715163F}'
$valueName = "PreferredClr"
$valueData = "v4.0.30319"
if (-not (Test-Path $regPath)) {New-Item -Path $regPath -Force | Out-Null}
New-ItemProperty -Path $regPath -Name $valueName -Value $valueData -PropertyType String -Force | Out-Null

# Done
Start-Sleep 3
Write-Host "Done." -ForegroundColor Yellow
Exit $exitcode
