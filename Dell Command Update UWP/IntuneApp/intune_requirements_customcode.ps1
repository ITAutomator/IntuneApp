<# -------- Custom Requirements code
Put your custom code here
delete this file from your package if it is not needed. It normally isn't needed.

Return value
$true if requirements met, $false if not met

Intune
Intune will show 'Not applicable' for those device where requirements aren't met

Notes
$requirements_met is assumed true coming in to this script
Write-host will log text to the Intune log (c:\IntuneApps)
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_requirements.ps1, and has those functions and variables available to it.
To debug this script, put a break in the script and run the parent ps1 file mentioned above.
Do not allow Write-Output or other unintentional ouput, other than the return value.
 
#>

# $requirements_met is assumed true coming in to this script
# Make sure this is a Dell computer

Write-Host "requirements_met (before): $($requirements_met)"
Function ComputerInfo
{
    ###############################################
    $computerInfo = Get-ComputerInfo
    $objProps = [ordered]@{ 
        Username              = $env:username
        Userdomain            = $env:userdomain
        CsName                = $computerInfo.CsName
        CsUserName            = $computerInfo.CsUserName
        LogonServer           = $computerInfo.LogonServer
        BiosManufacturer      = $computerInfo.BiosManufacturer
        BiosSeralNumber       = $computerInfo.BiosSeralNumber
        CsManufacturer        = $computerInfo.CsManufacturer
        CsModel               = $computerInfo.CsModel
        PowerPlatformRole     = $computerInfo.PowerPlatformRole.ToString()
        CsPCSystemType        = $computerInfo.CsPCSystemType.ToString()
        WindowsProductName    = $computerInfo.WindowsProductName
        } 
    $ComputerInfo = New-Object -TypeName psobject -Property $objProps 
    $ComputerInfo 
    ############################################### 
}
$computerNeeded = "Dell Inc."
$computerInfo = Get-computerInfo
Write-Host "   CsManufacturer: $($computerInfo.CsManufacturer)"
Write-Host "  BiosSeralNumber: $($computerInfo.BiosSeralNumber)"
Write-Host "          CsModel: $($computerInfo.CsModel)"
Write-Host "   CsPCSystemType: $($computerInfo.CsPCSystemType)"
if ($computerInfo.CsManufacturer -eq $computerNeeded )
{
    Write-Host "OK: CsManufacturer is $($computerNeeded )"
    $requirements_met=$true
}
else
{
    Write-Host "Requirements not met: CsManufacturer '$($computerInfo.CsManufacturer)' is not '$($computerNeeded )'"
    $requirements_met=$false
}
Write-Host "requirements_met (after): $($requirements_met)"
Return $requirements_met