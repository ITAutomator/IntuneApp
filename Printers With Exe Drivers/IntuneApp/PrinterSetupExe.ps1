######################
### Parameters
######################
Param 
	( 
	 [string] $mode = 'menu' # 'menu' for menu, 'install' for auto-install, 'uninstall' for auto-uninstall, 'intune' for intune prep
	)
######################
### Functions
######################
function RemovePrinter {
    param (
        $printername
    )
    $strReturn = ""
    $strWarnings = @()
    $printerremoved = $false
    $PToRemove = Get-Printer |Where-Object Name -eq $printername
    if (-not ($PToRemove)) {
        $strReturn ="OK: Printer already removed: $($printername)"
        return $strReturn
    } # no such printer
    Try
    { # remove-printer
        Remove-Printer -Name $printername -ErrorAction Stop
        # Verify removal
        if (Get-Printer |Where-Object Name -eq $printername) {
            $strWarnings += "ERR: Printer remains after: Remove-Printer -Name `"$($printername)`""
            $printerremoved = $false
        }
        else {
            $printerremoved = $true
        }
    } # remove-printer
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem   = $_.Exception.ItemName
        $strWarnings += "Remove-Printer failure: $($FailedItem)- $($ErrorMessage) [Try to remove manually]"
    } # remove-printer catch
    If ($printerremoved){
        Try {
            Remove-PrinterDriver -Name $PToRemove.DriverName -RemoveFromDriverStore -ErrorAction Stop
            #Write-Host "Driver $($PToRemove.DriverName) removed"
        }
        Catch { # catch
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $strWarnings += "Remove-PrinterDriver failure: $($PToRemove.DriverName) $($FailedItem)- $($ErrorMessage)"
        } # catch Remove-PrinterDriver
    } # driver
    If ($printerremoved){
        $portToRemove = $PToRemove.PortName
        $port = Get-PrinterPort | Where-Object { $_.Name -eq $portToRemove }
        if ($port) {
            # Remove the printer port
            try {
                Remove-PrinterPort -Name $portToRemove -ErrorAction Stop
            } catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                $strWarnings += "Remove-PrinterPort failue: $($portToRemove) $($FailedItem)- $($ErrorMessage)" 
            } # catch Remove-PrinterPort
        } # has port
    } # port
    if ($printerremoved) {
        if ($strWarnings.count -eq 0) {
            $strReturn = "OK: Printer removed: $($printername)"
        }
        else {
            $strReturn = "OK: Printer removed: $($printername), Warnings: $($strWarnings -join ", ")"
        } # there were warnings
    } # printer was removed
    else {
        $strReturn = "ERR: Printer not removed: $($printername). Warnings: $($strWarnings -join ", ")"
    } # printer wasn't removed
    return $strReturn
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
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################
$exitcode = 0
$Arch = GetArchitecture # Get OS Arch type (x64 or ARM64)
$CmdLineInfo = "(none)"
if ($mode -ne ''){$CmdLineInfo = "-mode $($mode)"}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-host "                   this CPU: " -NoNewline
Write-host $($Arch) -ForegroundColor Green
Write-Host ""
Write-Host "This script adds the EXE based printers listed in PrintersToAdd.csv and in the Drivers folder."
Write-Host "It also removes any printers listed in PrintersToRemove.csv (if found)"
Write-Host ""
# get printers to remove
$PrnCSVPathRmv = "$($scriptDir)\$($scriptBase) PrintersToRemove.csv"
if (-not (Test-Path $PrnCSVPathRmv)) {
    Write-Host "Couldn't find csv file, creating template: $($PrnCSVPathRmv)"
    Add-Content -Path $PrnCSVPathRmv -Value "PrintersToRemove"
}
# get printers to add
$PrnCSVPathAdd = "$($scriptDir)\$($scriptBase) PrintersToAdd.csv"
if (-not (Test-Path $PrnCSVPathAdd)) {
    Write-Host "Couldn't find csv file, creating template: $($PrnCSVPathAdd)"
    Add-Content -Path $PrnCSVPathAdd -Value "CPU,Printer,Installer"
}
$PrnCSVRowsRmv      = @(Import-Csv $PrnCSVPathRmv)
$PrnCSVRowsAdd      = @(Import-Csv $PrnCSVPathAdd)
$PrnCSVRowsAddThisCPU = @($PrnCSVRowsAdd | Where-Object CPU -eq $Arch)
# display
Write-Host "PrintersToAdd.csv ($($PrnCSVRowsAdd.Count) rows, $($PrnCSVRowsAddThisCPU.count) for this CPU [$($Arch)])"
$PrnCSVRowsAdd | ForEach-Object {Write-Host "- [$($_.CPU)] $($_.Printer) ($($_.Installer)) $(if ($_.CPU -ne $Arch) {' SKIP: not for this CPU'})"}
Write-Host "PrintersToRemove.csv ($($PrnCSVRowsRmv.Count) rows)"
if ($PrnCSVRowsRmv.Count -gt 0) {
    $PrnCSVRowsRmv | ForEach-Object {Write-Host "- $($_.PrintersToRemove)"}
}
Write-Host "-----------------------------------------------------------------------------"
$exitcode = 0
if (!(IsAdmin)) {
    $strWarning ="ERR: Admin privs required (Re-run as admin)"
    Write-Host $strWarning -ForegroundColor Yellow
    Start-Sleep 2
    Exit 99
}
if ($mode -eq 'menu') {
    $interactive = $true
    $choices = "E&xit","&Install","&Uninstall","&Prep for Intune"
    $choice = AskForChoice "Choice:" -Choices ($choices) -ReturnString
    if     ($choice -eq "Exit") {Exit}
    elseif ($choice -eq "Install")         {$mode = 'install'}
    elseif ($choice -eq "Uninstall")       {$mode = 'uninstall'}
    elseif ($choice -eq "Prep for Intune") {$mode = 'intune'}
} # menu
else {
    $interactive = $false
} # nomenu
if ($mode -eq 'intune')
{ # mode intune settings (for detection)
    $IntuneSettingsCSVPath = "$($scriptDir)\intune_settings.csv"
    if (-not (Test-Path $IntuneSettingsCSVPath)) {
        Write-Host "Couldn't find csv file: $($IntuneSettingsCSVPath)"
    }
    else {
        # settings to check
        $p64   = $PrnCSVRowsAdd | Where-Object 'CPU' -eq 'x64'
        $pArm  = $PrnCSVRowsAdd | Where-Object  'CPU' -eq 'ARM64'
        $AppDescription = "$($p64.count) printer(s) will be added by this app"
        if ($pArm.count -gt 0) {
            $AppDescription += ". For ARM64 CPUs there are $($pArm.count) printer(s)."
        }
        $AppPrintersToRmv = $PrnCSVRowsRmv.PrintersToRemove -join ","
        $AppPrintersToAddx64   = $p64.Printer -join ","
        $AppPrintersToAddARM64 = $pArm.Printer -join ","
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
            Value = "ARGS:-mode install"
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppDescription"
            Value = $AppDescription
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppVar1"
            Value = "Printers to Remove: $($AppPrintersToRmv)"
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppVar2"
            Value = "Printers to Add x64: $($AppPrintersToAddx64)"
        } ; $intunesettings += $newRow
        $newRow = [PSCustomObject]@{
            Name  = "AppVar3"
            Value = "Printers to Add ARM64: $($AppPrintersToAddARM64)"
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
            $IntuneSettingsCSVRows | Export-Csv $IntuneSettingsCSVPath
            Write-Host "Updated $(Split-Path $IntuneSettingsCSVPath -Leaf)" -ForegroundColor Yellow
        }
        else {
            Write-Host "No changes required" -ForegroundColor Green
        }
        PressEnterToContinue
        Exit
    } # found intune_settings.csv
} # mode intune 
# get names to uninstall
if ($mode -eq 'uninstall') {
    Write-Host "[-mode uninstall] Removing the printers from PrintersToAdd.csv" -ForegroundColor Yellow
    $PrnUninstall = $PrnCSVRowsAdd.Printer
}
else {
    $PrnUninstall = $PrnCSVRowsRmv.PrintersToRemove
}
# get printers that are installed
write-host "------ Removing Printers"
$Printers       = Get-Printer
if (($Printers.count -gt 0) -and ($PrnUninstall.count -gt 0))
{ # Remove
    # filter PrintersToRemove for printers we have
    $entries = $PrnUninstall
    $i = 0
    foreach ($x in $entries)
    { #each printer to remove
        $i+=1
        $printername   = $x
        write-host "-- Removing $($i) of $($entries.count): $($printername)"
        $strReturn = RemovePrinter $printername
        Write-Host $strReturn
        if ($strReturn.StartsWith("ERR")) {
            Start-Sleep 3
        } # removeprinter error
    } #each printer to remove
} # Remove
else {
    Write-Host "No printers to remove"
}
if ($mode -ne 'uninstall')
{ # install mode
    write-host "------ Adding Printers"
    # Write-host "------------------------------"
    # Write-host ($PrnCSVRowsAddThisCPU.Printer -join ", ")
    # Write-host "------------------------------"
    if ($PrnCSVRowsAddThisCPU.count -gt 0)
    { # Add
        $entries = $PrnCSVRowsAddThisCPU
        $i = 0
        foreach ($x in $entries)
        { #each printer to add
            $i+=1
            $printername   = $x.Printer
            $exename       = $x.Installer
            write-host "----- Adding $($i) of $($entries.count): $($printername)"
            $Printer = $Printers | Where-Object -Property Name -eq $printername
            if ($Printer) {
                Write-Host "Already installed (OK)"
            } # installed already
            else {
                $exepath = "$($scriptDir)\Drivers\$($exename)"
                if (Test-Path $exepath) {
                    Write-Host "Starting installer: $($exename)"
                    Start-Process $exepath -NoNewWindow -Wait
                } # has exe
                Else {
                    Write-Host "Couldn't find exe: $($exename)" -ForegroundColor Yellow
                    $exitcode = 51
                    Start-Sleep 3
                } # no exxe
            } # not installed
        } # each printer to add
    } # Add
    else {
        Write-Host "No printers to add for this CPU ($Arch)"
    } # nothing to add
} # install mode
write-host "------ Done"
if ($interactive) {PressEnterToContinue}
if ($exitcode -ne 0) {
    Write-Host "Exiting with Errorcode $($exitcode)"
}
exit $exitcode