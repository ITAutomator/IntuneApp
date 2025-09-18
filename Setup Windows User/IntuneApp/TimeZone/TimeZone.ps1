$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username PSver:"+($PSVersionTable.PSVersion.Major))
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
$pubip = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip
Write-Host "Updating Time zone based on current Public IP [$($pubip)] ... "
# Get the time zone based on the public IP address
$IPTimezone = Get-TimeZoneFromIP
if ($IPTimezone) {
    Write-Host "Detected IANA Time Zone from IP address: $IPTimezone"
    #region: Load Time Zone Mappings from XML
    #
    # Path to the offline XML file (pre-downloaded from CLDR)
    # https://github.com/unicode-org/cldr/blob/main/common/supplemental
    $xmlPath = "$($scriptDir)\windowsZones.xml"
    # Load the XML
    [xml]$xml = Get-Content $xmlPath
    # Extract mappings from the XML into a hashtable (ianaToWindowsMap)
    $ianaToWindowsMap = @{}
    foreach ($mapZone in $xml.supplementalData.windowsZones.mapTimezones.mapZone) {
        $windows = $mapZone.other
        $territory = $mapZone.territory
        $ianaList = $mapZone.type -split " "
        # We'll use mappings where territory is "001" (world-wide)
        if ($territory -eq "001") {
            foreach ($iana in $ianaList) {
                if (-not $ianaToWindowsMap.ContainsKey($iana)) {
                    $ianaToWindowsMap[$iana] = $windows
                }
            }
        }
    }
    #endregion: Load Time Zone Mappings from XML
    # Check if the detected time zone is in the mapping
    $WindowsTimeZonebyIP = $ianaToWindowsMap[$IPTimezone]
    if ($WindowsTimeZonebyIP){
        Write-Host "Which is an IANA time zone known to Windows as: $WindowsTimeZonebyIP"
        # Get the current time zone from Windows
        $WindowsTimeZoneCurrent = (Get-TimeZone).Id
        # Has it changed?
        if ($WindowsTimeZoneCurrent -ne $WindowsTimeZonebyIP) {
            try {
                # Set the new time zone
                Set-TimeZone -Id $WindowsTimeZonebyIP -ErrorAction Stop
                Write-Host "Time zone updated to: $WindowsTimeZonebyIP (from $($WindowsTimeZoneCurrent))"
            } catch {
                Write-Warning "Failed to update time zone: $_"
            }
        } else {
            Write-Host "Time zone is already correct: $WindowsTimeZoneCurrent (no change needed)."
        }
    } else {
        Write-Warning "Detected time zone [$($IPTimezone)] wasn't found in windowsZones.xml mapping table [$($ianaToWindowsMap.count) time zones]."
    }
} else {
    Write-Warning "Could not detect time zone from IP address."
}
Write-Host "-----------------------------------------------------------------------------"
Start-Sleep 3