###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
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
##$Globals=@{}
##$Globals.Add("Var1","Default")
##$Globals.Add("Var2","Default")
##$Globals=GlobalsLoad $Globals $scriptXML $false

$OS= Get-OSVersion
# Load settings
$csvFile = "$($scriptDir )\$($scriptBase) Settings.csv"
$settings = CSVSettingsLoad $csvFile
# Defaults (change these in the .csv file - not here)
$settings_updated = $false
if ($null -eq $settings.display_battery) {$settings.display_battery = "15"; $settings_updated = $true}
if ($null -eq $settings.sleep_battery) {$settings.sleep_battery = "30"; $settings_updated = $true}
if ($null -eq $settings.display_plugggedin) {$settings.display_plugggedin = "30"; $settings_updated = $true}
if ($null -eq $settings.sleep_plugggedin) {$settings.sleep_plugggedin = "0"; $settings_updated = $true}
if ($settings_updated) {$retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"}

Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host "Sets some sleep defaults according to the CSV file."
Write-Host "  These settings are defaults that can be adjusted by the user"
Write-Host "  Company policy settings will override these settings."
Write-Host "  Time limits are in minutes.  0 means no limit."
Write-Host "  Hibernate limits are always 1 minute longer than sleep limits."
Write-Host ""
Write-Host "To check settings, copy the line below, open a CMD and paste (Or press Win+R and paste)"
Write-Host "control /name Microsoft.PowerOptions /page pagePlanSettings" -ForegroundColor Yellow
Write-Host ""
Write-Host "          CSV file: $(Split-Path $csvFile -Leaf)"
Write-Host ""
Write-Host "   display_battery: $($settings.display_battery)"
Write-Host "     sleep_battery: $($settings.sleep_battery)"
Write-Host ""
Write-Host "display_plugggedin: $($settings.display_plugggedin)"
Write-Host "  sleep_plugggedin: $($settings.sleep_plugggedin)"
Write-Host "-----------------------------------------------------------------------------"
# convert to integers
$display_battery    = [int]$settings.display_battery
$sleep_battery      = [int]$settings.sleep_battery
$display_plugggedin = [int]$settings.display_plugggedin
$sleep_plugggedin   = [int]$settings.sleep_plugggedin
#
If (-not(IsAdmin)) {
    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
}
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
####

### read settings from registry
# active key
$path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\Default\PowerSchemes"
$name="ActivePowerScheme"
$active_id=(Get-ItemProperty -Path $path -Name $name).$name
$path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\Default\PowerSchemes\$($active_id)"
$name="FriendlyName"
$active_name_dll=(Get-ItemProperty -Path $path -Name $name).$name
$active_name=($active_name_dll -split ",")[-1]
# hibernate
$Powerid="238c9fa8-0aad-41ed-83f4-97be242c8f20"
$Powerid_Idletimout="9d7815a6-7ee4-497e-8888-515a05f02364"
$path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$($active_id)\$($Powerid)\$($Powerid_Idletimout)"
$name="ACSettingIndex"
$hibernate_plugggedin_reg=(Get-ItemProperty -Path $path -Name $name -ErrorAction Ignore).$name
$name="DCSettingIndex"
$hibernate_battery_reg=(Get-ItemProperty -Path $path -Name $name -ErrorAction Ignore).$name
# sleep
$Powerid="238c9fa8-0aad-41ed-83f4-97be242c8f20"
$Powerid_Idletimout="29f6c1db-86da-48c5-9fdb-f2b67b1f44da"
$path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$($active_id)\$($Powerid)\$($Powerid_Idletimout)"
$name="ACSettingIndex"
$sleep_plugggedin_reg=(Get-ItemProperty -Path $path -Name $name -ErrorAction Ignore).$name
$name="DCSettingIndex"
$sleep_battery_reg=(Get-ItemProperty -Path $path -Name $name -ErrorAction Ignore).$name
# display
$Powerid="7516b95f-f776-4464-8c53-06167f40cc99"
$Powerid_Idletimout="3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"
$path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$($active_id)\$($Powerid)\$($Powerid_Idletimout)"
$name="ACSettingIndex"
$display_plugggedin_reg=(Get-ItemProperty -Path $path -Name $name -ErrorAction Ignore).$name
$name="DCSettingIndex"
$display_battery_reg=(Get-ItemProperty -Path $path -Name $name -ErrorAction Ignore).$name
### battery
Write-Host "- Power: monitor-timeout-dc $($display_battery)" -NoNewline
if ($display_battery_reg -eq $display_battery*60) {Write-host " Already OK" -ForegroundColor Green}
else {powercfg -change -monitor-timeout-dc $display_battery; Write-Host " Adjusted (from $($display_battery_reg/60) to $($display_battery))" -ForegroundColor Yellow}

Write-Host "- Power: standby-timeout-dc $($sleep_battery)" -NoNewline
if ($sleep_battery_reg -eq $sleep_battery*60) {Write-host " Already OK" -ForegroundColor Green}
else {powercfg -change -standby-timeout-dc $sleep_battery; Write-Host " Adjusted (from $($sleep_battery_reg/60) to $($sleep_battery))" -ForegroundColor Yellow}

$target_val = if ($sleep_battery -eq 0) { 0 } else { $sleep_battery+1 }
Write-Host "- Power: hibernate-timeout-dc $($target_val)" -NoNewline
if ($hibernate_battery_reg -eq $target_val*60) {Write-host " Already OK" -ForegroundColor Green}
else {powercfg -change -hibernate-timeout-dc $target_val; Write-Host " Adjusted (from $($hibernate_battery_reg/60) to $($target_val))" -ForegroundColor Yellow}

## pluggedin
Write-Host "- Power: monitor-timeout-ac $($display_plugggedin)" -NoNewline
if ($display_plugggedin_reg -eq $display_plugggedin*60) {Write-host " Already OK" -ForegroundColor Green}
else {powercfg -change -monitor-timeout-ac $display_plugggedin; Write-Host " Adjusted (from $($display_plugggedin_reg/60) to $($display_plugggedin))" -ForegroundColor Yellow}

Write-Host "- Power: standby-timeout-ac $($sleep_plugggedin)" -NoNewline
if ($sleep_plugggedin_reg -eq $sleep_plugggedin*60) {Write-host " Already OK" -ForegroundColor Green}
else {powercfg -change -standby-timeout-ac $sleep_plugggedin; Write-Host " Adjusted (from $($sleep_plugggedin_reg/60) to $($sleep_plugggedin))" -ForegroundColor Yellow}

$target_val = if ($sleep_plugggedin -eq 0) { 0 } else { $sleep_plugggedin+1 }
Write-Host "- Power: hibernate-timeout-ac $($target_val)" -NoNewline
if ($hibernate_plugggedin_reg -eq $target_val*60) {Write-host " Already OK" -ForegroundColor Green}
else {powercfg -change -hibernate-timeout-ac $target_val; Write-Host " Adjusted (from $($hibernate_plugggedin_reg/60) to $($target_val))" -ForegroundColor Yellow}
####

#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}