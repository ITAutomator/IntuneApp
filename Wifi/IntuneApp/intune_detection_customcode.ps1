######################
### Functions
######################
function WifiAddRemove {  
    param (
        [ValidateSet("Add", "Remove","Detect")]
        [string]$AddRemoveDetect = "Add"
        ,[string]$WifiName = "<YourNetworkName>"
        ,[string]$WifiPass = ""
        ,[ValidateSet("Open", "WPA2", "")]
        [string]$OpenOrWPA2 = "WPA2"
        ,[switch]$ConnectAfterAdd = $false
        ,[switch]$Verbose = $false
    )
    If ($WifiName -eq "<YourNetworkName>") {
        Return "ERR: Usage is .\WifiAddRemove.ps1 -WifiName <YourNetworkName> -WifiPass <YourNetworkPassword> -AddRemoveDetect <Add|Remove> -OpenOrWPA2 <Open|WPA2>"
        Exit
    }
    if ($OpenOrWPA2 -eq "") { # OpenOrWPA2 is empty - default to WPA2 if password is provided
        if ($WifiPass -eq "") {
            $OpenOrWPA2 = "Open"
        } # Open
        else {
            $OpenOrWPA2 = "WPA2"
        } # WPA2
    } # OpenOrWPA2 is empty 

    if ($AddRemoveDetect -eq "Add")
    { # Add
        # Create a temporary XML profile
        if ($OpenOrWPA2 -eq "Open")
        { # Open network
        #region XMLOpen
        $profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$WifiName</name>
    <SSIDConfig>
        <SSID>
            <name>$WifiName</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>manual</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>open</authentication>
                <encryption>none</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
        </security>
    </MSM>
</WLANProfile>
"@
        #endregion XMLOpen
        } # Open network
        else 
        { # WPA2-secured network
        #region XMLWPA2
        $profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$WifiName</name>
    <SSIDConfig>
        <SSID>
            <name>$WifiName</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>manual</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$WifiPass</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@
        #endregion XMLWPA2
        } # WPA2-secured network
        if (($OpenOrWPA2 -eq "WPA2") -and ($WifiPass.Length -lt 8))
        { # password too short
            $strReturn = "Err: [$($WifiName)] Password length ($($WifiPass.Length)) must be at least (8) [$($OpenOrWPA2)]"
        } # password too short
        Else
        { # password length ok
            $tempXmlPath = "$env:TEMP\wifi_profile_$($WifiName).xml"
            $profileXml | Out-File -Encoding ASCII -FilePath $tempXmlPath
            # Add the Wi-Fi profile
            $sResult = netsh wlan add profile filename="$tempXmlPath" user=current
            if ($sResult -and $Verbose) {Write-Host $sResult -ForegroundColor Blue}
            if ($ConnectAfterAdd) {
                # Connect to the network
                $sResult = netsh wlan connect name="$WifiName"
                if ($sResult -and $Verbose) {Write-Host $sResult -ForegroundColor Blue}
            } # ConnectAfterAdd
            # Clean up the temp file
            Remove-Item -Path $tempXmlPath -Force | Out-Null
            # Return success message
            $strReturn = "OK: [$($WifiName)] Added [$($OpenOrWPA2) $($WifiPass)]"
        } # password length ok
    } # Add
    elseif ($AddRemoveDetect -eq "Remove")
    { # Remove 
        $sResult = netsh wlan delete profile name="$WifiName"
        if ($sResult -and $Verbose) {Write-Host $sResult -ForegroundColor Blue}
        # Return success message
        $strReturn = "OK: [$($WifiName)] Removed"
    } # Remove 
    elseif ($AddRemoveDetect -eq "Detect")
    { # Detect 
        # List all Wi-Fi profiles
        # Grab any User Profile line
        $profiles = netsh wlan show profiles |
            Select-String "User Profile\s*:\s*(.+)$" |
            ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
        if (-not ($profiles -contains $WifiName)) {
            $strReturn = "ERR: [$($WifiName)] not found"
        } # profile not found
        else
        { # profile found
            $strReturn = "OK: [$($WifiName) found]"
            <# 
            $profileInfo = netsh wlan show profile name="$WifiName" key=clear
            # Extract the Key Content line
            $keyLine = $profileInfo | Select-String "Key Content\s*:\s*(.+)$"
            if (($OpenOrWPA2 -eq "WPA2") -and (-not $keyLine)) {
                $strReturn = "ERR: [$($WifiName) found but has no password]"
            } # no key line
            if ($keyLine) {
                if ($OpenOrWPA2 -eq "Open") {
                    $strReturn = "ERR: [$($WifiName) found but has a password]"
                } # Open
                else { # WPA2
                    $storedKey = $keyLine.Matches[0].Groups[1].Value.Trim()
                    if ($storedKey -eq $WifiPass) {
                        $strReturn = "OK: [$($WifiName) found and password matches]"
                    } # password matches
                    else {
                        $strReturn = "ERR: [$($WifiName) found but password doesn't match]"
                    } # password doesn't match
                } # WPA2
            } # key line
            else
            { # no key line
                if ($OpenOrWPA2 -eq "WPA2") {
                    $strReturn = "ERR: [$($WifiName) found but has no password]"
                } # WPA2
                else {
                    $strReturn = "OK: [$($WifiName) found with no password]"
                } # Open
            } # no key line
            #>
        } # profile found
    } # Detect  
    Return $strReturn
}
<# -------- Custom Detection code
Put your custom code here
Delete this file from your package if it is not needed. Normally, it is not needed.
Winget and Choco packages detect themselves without needing this script.
Packages can also use AppUninstallName CSV entries for additional Winget detection (without needing this script)

Return value
$true if detected, $false if not detected
If the app is detected, the app will be considered installed and the setup script will not run.

Intune
Intune will show 'Installed' for those devices where app is detected

Notes
$app_detected may already be true if regular detection found via IntuneApps.csv or winget or choco
Your code can choose to accept or ignore this detection.
WriteHost commands, once injected, will be converted to WriteLog commands, and will log text to the Intune log (c:\IntuneApps)
This is because detection checking gets tripped up by writehost so nothing should get displayed at all.
Do not allow Write-Output or other unintentional ouput, other than the return value.
This must be a stand-alone script - no local files are available, it will be copied to a temp folder and run under system context.
However this script is a child process of intune_detection.ps1, and has those functions and variables available to it.
For instance, $IntuneApp.AppVar1 ... $IntuneApp.AppVar5 are injected from the intune_settings.csv, and are usable.
To debug this script, put a break in the script and run the parent ps1 file (Detection).
Detection and Requirements scripts are run every few hours (for all required apps), so they should be conservative with resources.
 
#>
$app_detected = $true # assume installed unless there's a problem

Write-host "------ intune_settings.csv"
Write-host "AppVar1 is $($IntuneApp.AppVar1)" # Wifis to Add: Wifi1 Name, Wifi2 Name
Write-host "AppVar2 is $($IntuneApp.AppVar2)" # Wifis to Remove: Old Wifi1 Name, Old Wifi2 Name
# create some empty arrays
$WifisAdd = @()
$WifisRmv = @()
if ($IntuneApp.AppVar1 -match ":") {
    $Contents = ($IntuneApp.AppVar1 -split ":")[1].trim(" ") # grab the stuff after the :
    if ($Contents -ne '') {
        $WifisAdd += ($Contents -split ",").trim(" ") # array-ify the contents
    } # has contents
} # there's a : char
if ($IntuneApp.AppVar2 -match ":") {
    $Contents = ($IntuneApp.AppVar2 -split ":")[1].trim(" ") # grab the stuff after the :
    if ($Contents -ne '') {
        $WifisRmv += ($Contents -split ",").trim(" ") # array-ify the contents
    } # has contents
} # there's a : char
ForEach ($Wifi in $WifisAdd)
{
    
    $result = WifiAddRemove -AddRemoveDetect "Detect" -WifiName $wifi
    $bDetected = $result.StartsWith("OK")
    if (-not $bDetected)
    {
        Write-Host "Wifi Not Found: [$($wifi)] that should be added"
        $app_detected = $false
        break
    }
}
ForEach ($Wifi in $WifisRmv)
{
    $result = WifiAddRemove -AddRemoveDetect "Detect" -WifiName $wifi
    $bDetected = $result.StartsWith("OK")
    if ($bDetected)
    {
        Write-Host "Wifi Found: [$($wifi)] that should be removed"
        $app_detected = $false
        break
    }
}





Write-Host "app_detected (after): $($app_detected)"
Return $app_detected