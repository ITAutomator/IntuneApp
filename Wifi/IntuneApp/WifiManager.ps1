######################
### Parameters
######################
Param ( 
	 [string] $mode = "" # "" for manual menu, "I" to install wifis, "U" to uninstall wifis
	)
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
    <connectionMode>auto</connectionMode>
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
    <connectionMode>auto</connectionMode>
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
            $strReturn = "OK: [$($WifiName)] Added [$($OpenOrWPA2)]"
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
        # List all Wi-Fi profiles, Grab any User Profile line
        $profiles = netsh wlan show profiles |
            Select-String "User Profile\s*:\s*(.+)$" |
            ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
        if (-not ($profiles -contains $WifiName)) {
            $strReturn = "ERR: [$($WifiName)] not found"
        } # profile not found
        else
        { # profile found
            $strReturn = "OK: [$($WifiName) found]"
        } # profile found
    } # Detect  
    Return $strReturn
}
function IntuneSettingsUpdate {
    param (
        [string] $IntuneSettingsCSVPath = ""
        ,$wifiadds = @()
        ,$wifirmvs = @()
    )
    #########
    if (-not (Test-Path $IntuneSettingsCSVPath)) {
        Write-Host "Couldn't find csv file: $(Split-Path $IntuneSettingsCSVPath -Leaf)" -ForegroundColor Yellow
        Start-sleep 3
    }
    else {
        # settings to check
        $AppwifisToAdd = $wifiadds.WifiName -join ","
        $AppwifisToRmv = $wifirmvs.WifiName -join ","
        $AppDescription = "Wifi signals will be updated by this app."
        $AppDescription += "`r`nWifis to add ($($wifiadds.count)): $($AppwifisToAdd)"
        if ($wifirmvs.count -gt 0) {
            $AppDescription += "`r`nWifis to remove ($($wifirmvs.count)): $($AppwifisToRmv)"
        }
        # create array of objects
        $intunesettings = @()
        $newRow = [PSCustomObject]@{
            Name  = "AppName"
            Value = Split-path (Split-Path $scriptDir -Parent) -Leaf
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppInstaller"
            Value = "ps1"
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppInstallName"
            Value = $scriptName
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppInstallArgs"
            Value = "ARGS:-mode I"
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppDescription"
            Value = $AppDescription
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppVar1"
            Value = "wifis to Add: $($AppwifisToAdd)"
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppVar2"
            Value = "wifis to Remove: $($AppwifisToRmv)"
        } ; $intunesettings += $newRow
        Write-Host "Checking: " -noNewline
        Write-Host $(Split-Path $IntuneSettingsCSVPath -Leaf) -foregroundColor Yellow
        Write-Host "-------------------------------------"
        $IntuneSettingsCSVRows = Import-Csv $IntuneSettingsCSVPath
        $haschanges = $false
        foreach ($intunesetting in $intunesettings) {
            $IntuneSettingsCSVRow =  $IntuneSettingsCSVRows | Where-Object Name -eq $intunesetting.Name
            Write-Host "$($IntuneSettingsCSVRow.Name) = $($IntuneSettingsCSVRow.Value) " -NoNewline
            if ($IntuneSettingsCSVRow.Value -eq $intunesetting.Value) {
                Write-Host "OK" -ForegroundColor Green
            } # setting match
            else {
                $IntuneSettingsCSVRow.Value = $intunesetting.Value
                Write-Host "Changed to $($intunesetting.Value)" -ForegroundColor Yellow
                $haschanges = $true
            } # setting is different
        } # each setting
        Write-Host "Done Updating " -noNewline
        Write-Host $(Split-Path $IntuneSettingsCSVPath -Leaf) -foregroundColor Yellow -noNewline
        Write-Host ": " -noNewline
        if ($haschanges) {
            $IntuneSettingsCSVRows | Export-Csv $IntuneSettingsCSVPath -NoTypeInformation -Force
            Write-Host "Updates were made" -ForegroundColor Yellow
        }
        else {
            Write-Host "OK No changes required" -ForegroundColor Green
        }
    } # found intune_settings.csv
}
######################
## Main Procedure
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "This script uses a CSV file for wifis to remove and add."
Write-Host ""
Write-Host "Use [I] to install managed wifis.   [$($scriptName) -mode I]"
Write-Host "Use [U] to uninstall managed wifis. [$($scriptName) -mode U]"
Write-Host "Use [S] to update the settings file (IntuneApp Settings.csv)"
Write-Host ""
if ($quiet) {Write-Host ("<<-quiet>>")}
$WifiCSVPath = "$($scriptDir)\$($scriptBase) Updates.csv"
$IntuneSettingsCSVPath = "$($scriptDir)\intune_settings.csv"
if (-not (Test-Path $WifiCSVPath)) {
    Write-Host "Couldn't find csv file, creating template: " -NoNewline
    Write-Host $(Split-Path $WifiCSVPath -Leaf) -ForegroundColor Yellow
    PressEnterToContinue -Prompt "Press Enter to create a template file you can edit."
    Add-Content -Path $WifiCSVPath -Value "AddRemoveDetect,WifiName,WifiPass,OpenOrWPA2"
    Add-Content -Path $WifiCSVPath -Value "Add,MyNewWifiSignal,MyNewWifiPass,WPA2"
    Add-Content -Path $WifiCSVPath -Value "Remove,MyOldWifiSignal,,"
    Start-Process $WifiCSVPath
    PressEnterToContinue "Press Enter when done editing the CSV file"
}
Do { # action
    $strWarnings = @()
    $strReturn = ""
    Write-Host "-------------- $(Split-Path $WifiCSVPath -Leaf) ------------------"
    $i=0
    $wifiupdates = Import-Csv -Path $WifiCSVPath
    $wifiupdates | ForEach-Object { Write-Host " $((++$i)) $($_.WifiName) [$($_.AddRemoveDetect)]" }
    $wifiadds = $wifiupdates | Where-Object { $_.AddRemoveDetect -eq "Add" }
    $wifirmvs = $wifiupdates | Where-Object { $_.AddRemoveDetect -eq "Remove" }
    Write-Host "--------------- wifi Manager Menu ------------------"
    Write-Host "[I] to install managed wifis to this PC"
    Write-Host "[U] to uninstall managed wifis from this PC"
    Write-Host "[D] Detect if PC has wifis already"
    Write-Host "[S] Setup intune_settings.csv with these wifis (for IntuneApp)"
    Write-Host "[E] Edit the wifis CSV file"
    Write-Host "[X] Exit"
    Write-Host "-------------------------------------------------------"
    if ($mode -eq '') {
        $choice = PromptForString "Choice [blank to exit]"
    } # ask for choice
    else {
        Write-Host "Choice: [$($mode)]  (-mode $($mode))"
        $choice = $mode
    } # don't ask (auto)
    if (($choice -eq "") -or ($choice -eq "X")) {
        Break
    } # Exit
    if ($choice -eq "E")
    { # edit
        Write-Host "Editing $(Split-Path $WifiCSVPath -Leaf) ..."
        Start-Process -FilePath $WifiCSVPath
        PressEnterToContinue -Prompt "Press Enter when finished editing (will update intune_settings.csv)."
        IntuneSettingsUpdate -IntuneSettingsCSVPath $IntuneSettingsCSVPath -wifiadds $wifiadds -wifirmvs $wifirmvs
        Start-Sleep 3
    } # edit
    if ($choice -eq "S")
    { # intune_settings
        IntuneSettingsUpdate -IntuneSettingsCSVPath $IntuneSettingsCSVPath -wifiadds $wifiadds -wifirmvs $wifirmvs
        PressEnterToContinue
    } # intune_settings
    if ($choice -in ("I","D","U"))
    { # install
        $actions = @("Add", "Remove")
        ForEach ($action in $actions)
        { # action (add/remove)
            if ($choice -eq "D") {
                $action_lbl = $action
                if ($action -eq "Add") {
                    $action_lbl = "Detect added"
                } # Add
                else {
                    $action_lbl = "Detect removed"
                } # Remove
            } # Detect
            else {
                $action_lbl = $action
            } # Add/Remove
            $wifiActions = $wifiupdates | Where-Object { $_.AddRemoveDetect -eq $action }
            if ($wifiActions)
            { # $wifiadds
                #------------ 
                $installaction = $action
                $uninstall_label = ""
                if ($choice -eq "U") {
                    if ($action -eq "Add") {
                        $installaction="Remove"}
                    else {
                        $installaction="Add"
                    }
                    $uninstall_label = " [Uninstall changes $($action) to $($installaction)]"
                } # Uninstall
                Write-host "--------------------------"
                Write-Host "$($action_lbl) wifis: $($wifiActions.count) $($uninstall_label)" # -ForegroundColor Yellow
                Write-host "--------------------------"
                $count = 0
                foreach ($wifi in $wifiActions)
                { # each wifi
                    $count += 1
                    Write-Host "$($count)) $($wifi.WifiName) ... " -NoNewline
                    $result = WifiAddRemove -AddRemoveDetect "Detect" -WifiName $wifi.WifiName -WifiPass $wifi.WifiPass -OpenOrWPA2 $wifi.OpenOrWPA2
                    $bDetected = $result.StartsWith("OK")
                    if ($installaction -eq "Add")
                    { # add wifi
                        if ($choice -eq "D")
                        { # detect 
                            if ($bDetected) {
                                Write-Host "$($result)" -ForegroundColor Green
                            } # already added
                            else  {
                                Write-Host "$($result)" -ForegroundColor Yellow
                                $strWarnings += "Err: Wifi [$($wifi.WifiName)] not found"
                            } # already added
                        } # detect
                        else
                        { # Add/Remove
                            if ($bDetected) {
                                Write-Host "OK: Already added" -ForegroundColor Green
                            } # already added
                            else {
                                if ($choice -eq "U") {
                                    if ($wifi.OpenOrWPA2 -eq "") {
                                        Write-Host "Did not add Wifi [$($wifi.WifiName)] because OpenOrWPA2 was empty in CSV" -ForegroundColor Yellow
                                    } # OpenOrWPA2 is empty
                                    else {
                                        $result = WifiAddRemove -AddRemoveDetect "Add" -WifiName $wifi.WifiName -WifiPass $wifi.WifiPass -OpenOrWPA2 $wifi.OpenOrWPA2
                                        Write-Host "$($result)" -ForegroundColor Yellow
                                    } # OpenOrWPA2 is not empty
                                } # uninstall choice
                                else {
                                    $result = WifiAddRemove -AddRemoveDetect "Add" -WifiName $wifi.WifiName -WifiPass $wifi.WifiPass -OpenOrWPA2 $wifi.OpenOrWPA2
                                    Write-Host "$($result)" -ForegroundColor Yellow
                                } # not uninstall
                            } # not already added
                        } # Add/Remove
                    } # add wifi
                    if ($installaction -eq "Remove")
                    { # remove wifi
                        if ($choice -eq "D")
                        { # detect
                            if ($bDetected) {
                                Write-Host "ERR: [$($wifi.WifiName)] found" -ForegroundColor Yellow
                                $strWarnings += "ERR: [$($wifi.WifiName)] found"
                            } # not removed
                            else {
                                Write-Host "OK: Already removed" -ForegroundColor Green
                            } # already removed
                        } # detect
                        else { # Add/Remove
                            if ($bDetected) {
                                $result = WifiAddRemove -AddRemoveDetect "Remove" -WifiName $wifi.WifiName
                                Write-Host "$($result)" -ForegroundColor Yellow
                            } # detected
                            else { 
                                Write-Host "Already removed" -ForegroundColor Green
                            } # not detected
                        } # Add/Remove
                    } # remove wifi
                } # each wifi
            } # $wifiadds
        } # action (add/remove)
    } # install
    if ($mode -ne "") {break}
    Write-Host "Done"
    Start-sleep 2
} While ($true) # loop until Break 
Write-Host "Done"
# Return result
if ($strWarnings.count -eq 0) {
    $strReturn = "OK: $($scriptName) $($CmdLineInfo)"
    $exitcode = 0
}
else {
    $strReturn = "ERR: $($scriptName) $($CmdLineInfo): $($strWarnings -join ', ')"
    $exitcode = 11
}
Write-host "Return: [$($exitcode)] $($strReturn)"
Write-Output $strReturn
exit $exitcode