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

Write-Host "Updating Time zone based on IP..."
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
Start-Sleep 3