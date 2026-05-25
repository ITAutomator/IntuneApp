Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")
	
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {Write-Host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
#Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
$OS= Get-OSVersion

Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host "Does the following for Windows basic prep. Run once per machine."
Write-Host ""
Write-Host "- Updates the TZ based on location"
Write-Host "- Disables TZ Automatic setting service.  The settings toggle will re-enable it (admins can do that)"
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"
If (-not(IsAdmin))  {
    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
    }
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
if ($os[1] -eq "Win 11")
{
    Write-Host "----------------------------------------------------"
    Write-Host "Disabling 'Auto Time Zone Updater' Service"
    Set-Service -Name tzautoupdate -StartupType Disabled -PassThru
    Stop-Service -Name tzautoupdate -Force
    Write-Host "----------------------------------------------------"
    Write-Host "Setting Time Zone based on location"
    # Mapping of IANA time zones to Windows time zones
    $ianaToWindowsTimeZoneMap = @{
        "America/New_York"      = "Eastern Standard Time"
        "America/Chicago"       = "Central Standard Time"
        "America/Denver"        = "Mountain Standard Time"
        "America/Phoenix"       = "US Mountain Standard Time"
        "America/Los_Angeles"   = "Pacific Standard Time"
        "America/Anchorage"     = "Alaskan Standard Time"
        "America/Adak"          = "Aleutian Standard Time"
        "Pacific/Honolulu"      = "Hawaiian Standard Time"
        "Europe/London"         = "GMT Standard Time"
        "Europe/Paris"          = "Romance Standard Time"
        "Asia/Tokyo"            = "Tokyo Standard Time"
        "Australia/Sydney"      = "AUS Eastern Standard Time"
        # Add more mappings as needed
    }
    
    # Function to get the time zone based on the public IP address
    function Get-TimeZoneFromIP {
        try {
            # Use an external API to get the time zone based on the public IP address
            $response = Invoke-RestMethod -Uri "https://ipapi.co/timezone/" -ErrorAction Stop
            return $response
        } catch {
            Write-Warning "Failed to retrieve time zone from IP address: $_"
            return $null
        }
    }
    
    # Get the current time zone
    $currentTimeZone = (Get-TimeZone).Id
    
    # Get the time zone based on the public IP address
    $detectedTimeZone = Get-TimeZoneFromIP
    
    if ($detectedTimeZone -and $ianaToWindowsTimeZoneMap.ContainsKey($detectedTimeZone)) {
        $windowsTimeZone = $ianaToWindowsTimeZoneMap[$detectedTimeZone]
        if ($currentTimeZone -ne $windowsTimeZone) {
            try {
                # Set the new time zone
                Set-TimeZone -Id $windowsTimeZone -ErrorAction Stop
                Write-Host "Time zone updated to: $windowsTimeZone"
            } catch {
                Write-Warning "Failed to update time zone: $_"
            }
        } else {
            Write-Host "Time zone is already correct: $windowsTimeZone"
        }
    } else {
        Write-Warning "Detected time zone '$detectedTimeZone' is not mapped to a valid Windows time zone."
    }
    Write-Host "----------------------------------------------------"
    Start-Sleep 3
}

#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}