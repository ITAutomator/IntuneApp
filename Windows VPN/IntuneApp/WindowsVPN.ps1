######################
### Parameters
######################
Param 
	( 
	 [string] $mode = "" # "" for manual menu, "S" for setup printers, "H" for has drivers for this PC architecure, "T" for Detect if already installed
	)
######################
## Main Procedure
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
$psm1="$($scriptDir)\VPNCredentialsHelper.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

# Load settings
$csvFile = "$($scriptDir)\$($scriptBase) Settings.csv"
$settings = CSVSettingsLoad $csvFile
# Defaults
$settings_updated = $false
if ($null -eq $settings.ConnectionName) {$settings.ConnectionName = "ConnectionName"; $settings_updated = $true}
if ($null -eq $settings.ServerAddress) {$settings.ServerAddress = "ServerAddress"; $settings_updated = $true}
if ($null -eq $settings.PresharedKey) {$settings.PresharedKey = "PresharedKey"; $settings_updated = $true}
if ($null -eq $settings.Lancidrs_commaseparated) {$settings.Lancidrs_commaseparated = "lancidrs_commaseparated"; $settings_updated = $true}
if ($settings_updated) {$retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"}
# Read VPN credentials
$VPNCredsCSVPath = "$($scriptDir)\WindowsVPN Credentials.csv"
if (-not (Test-Path $VPNCredsCSVPath)) {
    Write-Host "Couldn't find csv file, creating template: " -NoNewline
    Write-Host $(Split-Path $VPNCredsCSVPath -Leaf) -ForegroundColor Yellow
    PressEnterToContinue -Prompt "Press Enter to create a template file you can edit."
    Add-Content -Path $VPNCredsCSVPath -Value "Type,UserOrComputer,vpn_user,vpn_password"
    Add-Content -Path $VPNCredsCSVPath -Value "(default),(default),vpnuser1,vpnuser1"
    Add-Content -Path $VPNCredsCSVPath -Value "Computer,HPLAPTOP1,vpnuser2,vpnuser2"
    Add-Content -Path $VPNCredsCSVPath -Value "User,JohnSmith,vpnuser3,vpnuser3"
    Start-Process $VPNCredsCSVPath
    PressEnterToContinue "Press Enter when done editing the CSV file"
}
$VPNCredS = Import-Csv -Path $VPNCredsCSVPath
# Use Settings
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -ForegroundColor Green
Write-Host ""
Write-Host "      Settings: "-NoNewline
Write-host "$($scriptBase) Settings.csv" -ForegroundColor Yellow
Write-Host ""
$AppDescription = "Adds Windows VPN Adapter: $($settings.ConnectionName) [Requires credentials from system admins]"
Write-Host $AppDescription
$ConnectionName = $settings.ConnectionName
$ServerAddress  = $settings.ServerAddress
$PresharedKey   = $settings.PresharedKey
$lancidrs       = @($settings.Lancidrs_commaseparated -split(","))
$splittunneling = ($settings.SplitTunneling -ne "false") # default is true (split tunneling sends only VPN traffic over the VPN)
# Get VPN credentials
$cred_source    = "Prompt on first connection"
$vpn_user       = ""
$vpn_password   = ""
# Default credentials
$vpncred = $vpncreds | Where-Object "Type" -eq  "(default)" | Select-Object -First 1
if ($null -ne $vpncred) {
    $vpn_user       = $vpncred.vpn_user
    $vpn_password   = $vpncred.vpn_password
    $cred_source    = "Default: $($vpncred.vpn_user)"
}
# (are overridden by) Computer credentials
$vpncred = $vpncreds | Where-Object "Type" -eq  "Computer" | Where-Object "UserOrComputer" -eq  "$($env:computername)" | Select-Object -First 1
if ($null -ne $vpncred) {
    $vpn_user       = $vpncred.vpn_user
    $vpn_password   = $vpncred.vpn_password
    $cred_source    = "Computer <$($env:computername)>: $($vpncred.vpn_user)"
}
# (are overridden by) User credentials
$vpncred = $vpncreds | Where-Object "Type" -eq  "User" | Where-Object "UserOrComputer" -eq  "$($env:username)" | Select-Object -First 1
if ($null -ne $vpncred) {
    $vpn_user       = $vpncred.vpn_user
    $vpn_password   = $vpncred.vpn_password
    $cred_source    = "User <$($env:username)>: $($vpncred.vpn_user)"
}
# (are overridden by) Computer\User credentials
$vpncred = $vpncreds | Where-Object "Type" -eq  "Computer\User" | Where-Object "UserOrComputer" -eq  "$($env:computername)\$($env:username)" | Select-Object -First 1
if ($null -ne $vpncred) {
    $vpn_user       = $vpncred.vpn_user
    $vpn_password   = $vpncred.vpn_password
    $cred_source    = "Computer\User <$($env:computername)\$($env:username)>: $($vpncred.vpn_user)"
}
# Menu
Do { # action
    $found = $false
    $conninfo = Get-VpnConnection -Name $ConnectionName -ErrorAction Ignore
    if ($conninfo) {
        $found = $true
    }
    if ($found) {
        $addcolor    = "DarkGray"
        $removecolor = "White"
    }
    else {
        $addcolor    = "White"
        $removecolor = "DarkGray"
    }
    Write-Host "--------------- VPN Adapter Menu ------------------"
    Write-Host "ConnectionName: " -NoNewline
    if ($found) {
        Write-host "$($settings.ConnectionName) [Found]" -ForegroundColor Green
    }
    else {
        Write-host "$($settings.ConnectionName) [Missing]" -ForegroundColor Yellow 
    }
    Write-Host " ServerAddress: " -NoNewline
    Write-host $($settings.ServerAddress) -ForegroundColor Green
    Write-Host "   Credentails: " -NoNewline
    Write-host $($cred_source) -ForegroundColor Green
    Write-Host ""
    Write-Host "[A] add    the VPN adapter for this user." -ForegroundColor $addcolor
    Write-Host "[R] remove the VPN adpater for this user." -ForegroundColor $removecolor
    Write-Host "[I] ntuneSettings.csv Injection (prep for publishing in IntuneApps)."
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
    $strReturn = "OK: $($scriptName) $($CmdLineInfo)"
    $exitcode = 0
    if ($choice -eq "A")
    { # add
        ## remove if found
        if ($found) {
            rasdial $ConnectionName /disconnect
            Remove-VpnConnection -Name $ConnectionName -Force
            Write-Host "VPN Adapter Removed" -ForegroundColor Green
        }
        $vpn_options_msg = ""
        ## create vpn connection (note absense of -AllUserConnection)
        Add-VpnConnection -Name $ConnectionName -ServerAddress $ServerAddress -TunnelType L2tp -L2tpPsk $PresharedKey -RememberCredential -AuthenticationMethod Pap -IdleDisconnectSeconds 3600 -Force
        Set-VpnConnection -Name $ConnectionName -SplitTunneling $splittunneling
        $vpn_options_msg += " [splittunneling: $($splittunneling)]"
        ## Add Credentials
        if ($vpn_user -ne "") {
            Set-VpnConnectionUsernamePassword -connectionname $ConnectionName -username $vpn_user -password $vpn_password -domain ''
            $cred_source
            $vpn_options_msg += " [Creds from $($cred_source)]"
        }
        ## Add Routes
        Write-Host "(The Warnings above can be safely ignored)" -ForegroundColor Yellow
        foreach ($lancidr in $lancidrs) {
            Add-VpnConnectionRoute -ConnectionName $ConnectionName -DestinationPrefix $lancidr.trim()
        }
        $vpn_options_msg += " [Routes: $($settings.Lancidrs_commaseparated)]"
        Write-Host "VPN Adapter Added: " -NoNewline
        Write-Host "$($ConnectionName)$($vpn_options_msg)" -ForegroundColor Green
        if ($mode -eq '') {PressEnterToContinue}
    } # add
    if ($choice -eq "R")
    { # remove
        if ($found) {
            rasdial $ConnectionName /disconnect
            Remove-VpnConnection -Name $ConnectionName -Force
            Write-Host "VPN Adapter Removed" -ForegroundColor Green
        }
        else {
            Write-Host "VPN Adapter not found to remove" -ForegroundColor Green
        }
        if ($mode -eq '') {PressEnterToContinue}
    } # remove
    if ($choice -eq "C")
    { # check
        if ($found) {
            $strReturn = "OK: $($scriptName) $($CmdLineInfo) [$($ConnectionName) found]"
            $exitcode = 0
        }
        else {
            $strReturn = "ERR: $($scriptName) $($CmdLineInfo) [$($ConnectionName) not found]"
            $exitcode = 99
        }
        Write-Host "Check: $($strReturn)"
        if ($mode -eq '') {PressEnterToContinue}
    } # check
    if ($choice -eq "I")
    { # intune_settings
        $IntuneSettingsCSVPath = "$($scriptDir)\intune_settings.csv"
        if (-not (Test-Path $IntuneSettingsCSVPath)) {
            Write-Host "Couldn't find csv file: $($IntuneSettingsCSVPath)"
        }
        else {
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
                Value = "ARGS:-mode A"
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppDescription"
                Value = $AppDescription
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppVar1"
                Value = "VPN Connection Name: $($ConnectionName)"
            } ; $intunesettings += $newRow
            Write-Host "Checking $(Split-Path $IntuneSettingsCSVPath -Leaf)"
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
            if ($haschanges) {
                $IntuneSettingsCSVRows | Export-Csv $IntuneSettingsCSVPath -NoTypeInformation -Force
                Write-Host "Updated $(Split-Path $IntuneSettingsCSVPath -Leaf)" -ForegroundColor Yellow
            }
            else {
                Write-Host "No changes required" -ForegroundColor Green
            }
            PressEnterToContinue
        } # found intune_settings.csv
    } # intune_settings
    if ($mode -ne '') {Break}
} While ($true) # loop until Break 
Write-Host "Done"
# Return result
Write-Output $strReturn
exit $exitcode