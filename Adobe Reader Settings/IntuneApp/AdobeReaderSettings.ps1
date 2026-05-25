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
        Write-Host "OK: $regValueName not found in $regPath. Created and set to $regValueSettingDesired" -ForegroundColor Yellow
        New-ItemProperty -Path $regPath -Name $regValueName -Value $regValueSettingDesired -PropertyType DWord -Force | Out-Null

    }
} else {
    Write-Host "ERR: Setting not applicable to this PC (Registry key does NOT exist)"
}
#endregion Settings
