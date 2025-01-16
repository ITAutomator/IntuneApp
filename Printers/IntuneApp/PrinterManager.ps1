######################
### Parameters
######################
Param 
	( 
	 [string] $mode = "" # "" for manual menu, "S" for setup printers, "H" for has drivers for this PC architecure, "T" for Detect if already installed
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
function Write-PrnCSVRowsAdd {
    param (
        $PrnCSVRowsAdd
        ,$Printers
        ,$ShowNumbers = $true
    )
    if (-not $PrnCSVRowsAdd){
        Write-Host "(none)"
    }
    else {
        # show a list
        Write-Host "Printer To Add [from CSV]                              Port            Status                  Driver"
        Write-Host "------------------------------------------------------ --------------- ----------------------- ----------------"
        $index = 0
        ForEach ($obj in $PrnCSVRowsAdd) {
            $index+=1
            if ($ShowNumbers) {
                $firstcol = "[$($index)] $($obj.Printer.PadRight(50))"}
            else {
                $firstcol = $_.Printer
            }
            $status="(Will be added)"
            if($Printers.Name -contains $obj.Printer) {$status="OK: is added already"}
            else {
                if ($obj."Driver-$($Arch)" -eq '') {
                    $status="SKIP: No $($Arch) driver"
                }
            }
            Write-Host "$($firstcol.PadRight(50)) $($obj.Port.PadRight(15)) $($status.PadRight(23)) $($obj."Driver-$($Arch)".PadRight(15))"
        } # each object
    } # show list
}
function Write-PrnCSVRowsRmv {
    param (
        $PrnCSVRowsRmv
        ,$Printers
        ,$ShowNumbers = $true
    )
    if (-not $PrnCSVRowsRmv){
        Write-Host "(none)"
    }
    else {
        # show a list
        Write-Host "Printer To Remove [from CSV]                           Status"
        Write-Host "------------------------------------------------------ -------------"
        $index = 0
        ForEach ($obj in $PrnCSVRowsRmv) {
            $index+=1
            if ($ShowNumbers) {
                $firstcol = "[$($index)] $($obj.PrintersToRemove.PadRight(50))"}
            else {
                $firstcol = $obj.PrintersToRemove
            }
            $status="OK: removed already"
            if($Printers.Name -contains $obj.PrintersToRemove) {$status="Will be removed"}
            Write-Host "$($firstcol.PadRight(50)) $($status.PadRight(23))"
        } # each object
    } # show list
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
$Arch = GetArchitecture # Get OS Arch type (x64 or ARM64)
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)     Computer: $($env:computername) User: $($env:username) PSVer:$($PSVersionTable.PSVersion.Major)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-host "         Filtering CSV entries with drivers for this CPU: " -NoNewline
Write-host $($Arch) -ForegroundColor Green
Write-Host ""
Write-Host "This script uses two CSV files and a Drivers folder to create a package for setting up a list of printers."
Write-Host ""
Write-Host "Use [A] dd to ingest a new printer and driver to your list from the current device."
Write-Host "Use [V] to update driVers (or add ARM drivers to an existing driver folder) using the current device's drivers."
Write-Host "Use [S] etup to apply this list to the current device. (Use -mode auto to automate)"
Write-Host ""
Write-Host "Note: You will need to be an admin to remove drivers, but you can still remove printers as non-admin"
$PrnCSVPathAdd = "$($scriptDir)\$($scriptBase) PrintersToAdd.csv"
$PrnCSVPathRmv = "$($scriptDir)\$($scriptBase) PrintersToRemove.csv"
$PrnCSVSettings = "$($scriptDir)\$($scriptBase) Settings.csv"
#
if (-not (Test-Path $PrnCSVPathAdd)) {
    Write-Host "Couldn't find csv file, creating template: $($PrnCSVPathAdd)"
    Add-Content -Path $PrnCSVPathAdd -Value "Printer,Driver-x64,Driver-ARM64,Port,Model,URL,Settings,Location,Comments"
    Add-Content -Path $PrnCSVPathAdd -Value "Contoso Room 101 Copier,,,192.168.53.60,<optional model info>,<optional helpful url>,,Room 101,"
}
if (-not (Test-Path $PrnCSVPathRmv)) {
    Write-Host "Couldn't find csv file, creating template: $($PrnCSVPathRmv)"
    Add-Content -Path $PrnCSVPathRmv -Value "PrintersToRemove"
}
if (-not (Test-Path $PrnCSVSettings)) {
    Write-Host "Couldn't find csv file, creating template: $($PrnCSVSettings)"
    Add-Content -Path $PrnCSVSettings -Value "Description,Settings"
    Add-Content -Path $PrnCSVSettings -Value "Default,"
    Add-Content -Path $PrnCSVSettings -Value 'LetterColor,"Papersize=Letter,Collate=False,Color=True"'
    Add-Content -Path $PrnCSVSettings -Value 'LetterGreyscale,"Papersize=Letter,Collate=False,Color=False"'
    Add-Content -Path $PrnCSVSettings -Value 'LetterColorDuplex,"Papersize=Letter,Collate=False,Color=True,DuplexingMode=TwoSidedLongEdge"'
    Add-Content -Path $PrnCSVSettings -Value 'LetterGreyscaleDuplex,"Papersize=Letter,Collate=False,Color=False,DuplexingMode=TwoSidedLongEdge"'
    Add-Content -Path $PrnCSVSettings -Value 'A4Color,"Papersize=A4,Collate=False,Color=True"'
}
$PrnCSVRowsAdd      = Import-Csv $PrnCSVPathAdd
$PrnCSVRowsRmv      = Import-Csv $PrnCSVPathRmv
$PrnCSVRowsSettings = Import-Csv $PrnCSVSettings
# Add a numbered column
$i = 1; $PrnCSVRowsSettings | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name "Num" -Value $i; $i++}
Do { # action
    $strWarnings = @()
    # Get Printer info from this PC
    $PortMonsToInclude = @("TCPMON.DLL","WSD Port Monitor")
    $DrvrMfrsToExclude = @("Microsoft","Adobe")
    $PrinterPorts   = Get-PrinterPort   | Where-Object {($PortMonsToInclude -Contains $_.PortMonitor)}
    $PrinterDrivers = Get-PrinterDriver | Where-Object {($DrvrMfrsToExclude -NotContains $_.Manufacturer)}
    $Printers       = Get-Printer       | Where-Object {($PrinterPorts.Name -Contains $_.PortName)}
    # Add numbered columns (for menu selection)
    $PrinterPortsNum   = $PrinterPorts   | ForEach-Object -Begin {$i = 1} -Process {$_ | Add-Member -MemberType NoteProperty -Name "Num" -Value $i -PassThru | Add-Member -MemberType NoteProperty -Name "Used By" -Value ($Printers | Where-Object PortName -eq $_.Name | Select-Object Name -ExpandProperty Name) -PassThru; $i++}
    $PrinterDriversNum = $PrinterDrivers | ForEach-Object -Begin {$i = 1} -Process {$_ | Add-Member -MemberType NoteProperty -Name "Num" -Value $i -PassThru | Add-Member -MemberType NoteProperty -Name "Used By" -Value ($Printers | Where-Object DriverName -eq $_.Name | Select-Object Name -ExpandProperty Name) -PassThru; $i++}
    $PrintersNum       = $Printers       | ForEach-Object -Begin {$i = 1} -Process {$_ | Add-Member -MemberType NoteProperty -Name "Num" -Value $i -PassThru; $i++}
    # 
    Write-Host "-------------- $(Split-Path $PrnCSVPathAdd -Leaf): $($PrnCSVRowsAdd.count)"
    Write-PrnCSVRowsAdd $PrnCSVRowsAdd $Printers
    # show a list
    Write-Host "-------------- $(Split-Path $PrnCSVPathRmv -Leaf): $($PrnCSVRowsRmv.count)"
    Write-PrnCSVRowsRmv $PrnCSVRowsRmv $Printers
    # Check for invalid printers
    $PrnCSVRowsBad = @()
    $PrnCSVRowsBad += $PrnCSVRowsAdd.Printer          | Where-Object {$_ -match ","}
    $PrnCSVRowsBad += $PrnCSVRowsRmv.PrintersToRemove | Where-Object {$_ -match ","}
    if ($PrnCSVRowsBad.count -gt 0) {
        Write-Host "Invalid printer names: $($PrnCSVRowsBad -join " ") [No commas allowed]" -ForegroundColor Red
        PromptForString "Script wil end now (Press Enter)"
        Return "ERR: Invalid printer names"
    }
    Write-Host "--------------- Printer Manager Menu ------------------"
    Write-Host "[S] Setup all the CSV printers (to this PC)  PC <-- CSV"
    Write-Host "[O] Setup one CSV printer (to this PC)       PC <-- CSV"
    Write-Host "[V] Update a driver to the \Drivers folder   PC --> CSV"
    Write-Host "[A] Add a local printer to CSV list          PC --> CSV"
    Write-Host "[U] Uninstall the CSV listed printers        PC (X) CSV"
    Write-Host "[R] Local printer deletion                   PC (X)"
    Write-Host "[D] Local driver deletion                    PC (X)"
    Write-Host "[P] Local port deletion                      PC (X)"
    Write-Host "[E] Edit CSV Files manually                  CSV"
    Write-Host "[T] Detect if PC has CSV printers already    CSV"
    Write-Host "[I] Prep intune_settings.csv with these printers (for IntuneApp)"
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
        Write-Host "Editing $(Split-Path $PrnCSVPathRmv -Leaf) ..."
        Start-Process -FilePath $PrnCSVPathRmv
        Write-Host "Editing $(Split-Path $PrnCSVPathAdd -Leaf) ..."
        Start-Process -FilePath $PrnCSVPathAdd
        PressEnterToContinue -Prompt "Press Enter when finished editing (to update list)."
        $PrnCSVRowsAdd = Import-Csv $PrnCSVPathAdd
        $PrnCSVRowsRmv = Import-Csv $PrnCSVPathRmv
    } # edit
    if ($choice -eq "I")
    { # intune_settings
        $IntuneSettingsCSVPath = "$($scriptDir)\intune_settings.csv"
        if (-not (Test-Path $IntuneSettingsCSVPath)) {
            Write-Host "Couldn't find csv file: $($IntuneSettingsCSVPath)"
        }
        else {
            # settings to check
            $p64   = $PrnCSVRowsAdd | Where-Object 'Driver-x64' -ne ''
            $pArm  = $PrnCSVRowsAdd | Where-Object 'Driver-ARM64' -ne ''
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
                Value = "ARGS:-mode S"
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
                $IntuneSettingsCSVRows | Export-Csv $IntuneSettingsCSVPath -NoTypeInformation -Force
                Write-Host "Updated $(Split-Path $IntuneSettingsCSVPath -Leaf)" -ForegroundColor Yellow
            }
            else {
                Write-Host "No changes required" -ForegroundColor Green
            }
            PressEnterToContinue
        } # found intune_settings.csv
    } # intune_settings
    if ($choice -in ("V","A","S","O")) {
        # Update, Add: need a list of drivers from pnputil extraction tool
        $pnpdrivers = PNPUtiltoObject "pnputil.exe /enum-drivers"
    }
    # Menu processing
    if ($choice -eq "R")
    { # remove printer
        if (-not ($PrintersNum)) {
            Write-Host "There are no removable Printers"
            PressEnterToContinue
            Continue
        } # No drivers
        Write-Host "Installed Printers" -ForegroundColor Yellow
        (($PrintersNum       | Select-Object Num,Name,DriverName,PortName | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
        Write-Host ""
        $choice = PromptForString "Which Printer should we remove [blank to exit]"
        if ($choice -ne "")
        { # chose printer
            $printername   = $PrintersNum[$choice-1].Name
            write-host "----- Removing: $($printername)"
            $strReturn = RemovePrinter $printername
            Write-Host $strReturn
            PressEnterToContinue
        } # chose printer
    } # remove printer
    if ($choice -in "P")
    { # port removal
        if (-not ($PrinterPortsNum)) {
            Write-Host "There are no removable Ports"
            PressEnterToContinue
            Continue
        } # No drivers
        Write-Host "Installed Ports" -ForegroundColor Yellow
        (($PrinterPortsNum       | Select-Object Num,Name,'Used By' | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
        Write-Host ""
        $num = PromptForString "Which Port should we delete (won't work if it's being used by a printer) [blank to exit]"
        if ($num -ne "")
        { # chose port
            $PrinterPort = $PrinterPortsNum[$num-1].Name
            Try {
                Remove-PrinterPort -Name $printerport -ErrorAction Stop
                Write-Host "Port removed: " -NoNewline
                Write-Host $printerport -ForegroundColor Yellow
            }
            Catch { # catch
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Warning "Could not remove $($printerport) $($FailedItem)- $($ErrorMessage)"     
            } # catch
            PressEnterToContinue
        } # chose port
    } # port removal
    if ($choice -in "V","D")
    { # update/delete driver
        if (-not ($PrinterDriversNum)) {
            Write-Host "There are no Drivers (Excluding $($DrvrMfrsToExclude -join ', '))"
            PressEnterToContinue
            Continue
        } # No drivers
        Write-Host "Installed Drivers" -ForegroundColor Yellow
        (($PrinterDriversNum       | Select-Object Num,Name,Manufacturer,PrinterEnvironment,'Used By' | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
        Write-Host ""
        if ($choice -eq "D") {
            $action = "remove from this PC (won't work if it's being used by a printer)"
        }
        else { # U
            $action = "extract to the \Drivers folder"
        }
        $num = PromptForString "Which Driver should we $($action) [blank to exit]"
        if ($num -ne "")
        { # chose driver
            $PrinterDriver = $PrinterDriversNum[$num-1]
            if ($choice -eq "D")
            { # remove driver
                $PrinterDriver=$PrinterDriver.Name
                Try {
                    Remove-PrinterDriver -Name $PrinterDriver -RemoveFromDriverStore -ErrorAction Stop
                    Write-Host "Driver removed: " -NoNewline
                    Write-Host $PrinterDriver -ForegroundColor Yellow
                }
                Catch { # catch
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    Write-Warning "Could not remove $($PrinterDriver) $($FailedItem)- $($ErrorMessage)"
                } # catch
            } # remove driver
            else # U
            { # extract driver
                $inf_orig = Split-Path $PrinterDriver.InfPath -Leaf
                $pnp = $pnpdrivers | Where-Object {$_."Original Name" -eq $inf_orig}
                if ($pnp.Count -gt 1)
                {
                    Write-Warning "Multiple drivers found for $($inf_orig): $($pnp.'Driver Version' -join ", "). Using 1st listed driver."
                    $pnp = $pnp[0]
                }
                $inf_pub = $pnp.'Published Name'
                ### folder
                $PrnEnv = $PrinterDriver.PrinterEnvironment.replace('Windows ','')
                $folder = "$($scriptDir)\Drivers\$($PrnEnv)"
                $folder_driver = "$($folder)\$($PrinterDriver.name)"
                # clear old folder first, then create new
                if (Test-Path $folder_driver){
                    Remove-Item -Path $folder_driver -Recurse -Force | Out-Null
                }
                New-Item -ItemType Directory -Force -Path $folder_driver | Out-Null
                # export driver using pnp
                Write-Host "--- Extracting Driver"
                Write-Host "> pnputil.exe /export-driver $($inf_pub) Drivers\$($PrnEnv)\$($PrinterDriver.name)" -ForegroundColor Green
                Try {
                    pnputil.exe /export-driver $inf_pub $folder_driver | Out-Host
                }
                Catch { # catch
                    $ErrorMessage = $_.Exception.Message
                    Write-Warning "$($FailedItem). The error message was $($ErrorMessage)"
                } # catch
                Write-Host "------------------------"
                Write-Host "   Driver: " -NoNewline
                Write-host $PrinterDriver.name -ForegroundColor Yellow
                Write-Host "DriverInf: " -NoNewline
                Write-Host "Drivers\$($PrnEnv)\$($PrinterDriver.name)" -NoNewline -ForegroundColor Green
                Write-host $DriverInf -ForegroundColor Yellow
                Write-Host "------------------------"
            } # extract driver
            PressEnterToContinue
        } # chose driver
    } # update/delete driver
    if ($choice -eq "A")
    { # add to csv
        Write-Host "Installed Printers" -ForegroundColor Yellow
        $data = $PrintersNum | Select-Object Num,Name,DriverName,PortName,Status
        foreach ($d in $data) {
            if ($d.Name -in $PrnCSVRowsAdd.Printer) {
                $d.Status = "OK: in CSV already"
            }
        }
        (($data       | Select-Object * | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
        Write-Host ""
        $choice = PromptForString "Which printer (and driver) should we add to the CSV [blank to exit]"
        if ($choice -ne "")
        { # chose printer
            $x = $PrintersNum[$choice-1]
            $printername = $x.("Name")
            $printerdriver = $x.("DriverName")
            $printerport = $x.("PortName")
            write-host "-----Printer $($printername)"
            # Settings
            (($PrnCSVRowsSettings | Select-Object Num,Description,Settings | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
            $choice = PromptForString "Which special setting (enter for default)"
            if ($choice -eq "") {
                $choice = "1"
            }
            # choices for setting
            $Settings = $PrnCSVRowsSettings | Where-Object Num -eq $choice | Select-Object Settings -ExpandProperty Settings
            # Location
            $Location = PromptForString -Prompt "Location (Optional)" -defaultValue ""
            # Extract driver files
            ### Export using pnputil
            $PrinterDriver = @($PrinterDrivers | Where-Object Name -eq $x.DriverName)
            if ($PrinterDriver.count -eq 0) {
                Write-Host "Warning: No driver found matching printer's driver: $($x.DriverName)"
                PressEnterToContinue
            }
            else { # drivers listed
                $PrinterDriver = $PrinterDriver[0] #De-array-ify
                $inf_orig = Split-Path $PrinterDriver.InfPath -Leaf
                $pnp = $pnpdrivers | Where-Object {$_."Original Name" -eq $inf_orig}
                if ($pnp.Count -gt 1)
                {
                    Write-Warning "Multiple drivers found for $($inf_orig): $($pnp.'Driver Version' -join ", "). Using 1st listed driver."
                    $pnp = $pnp[0]
                }
                $inf_pub = $pnp.'Published Name'
                ### folder
                $PrnEnv = $PrinterDriver.PrinterEnvironment.replace('Windows ','')
                $folder = "$($scriptDir)\Drivers\$($PrnEnv)"
                $folder_driver = "$($folder)\$($PrinterDriver.name)"
                # clear old folder first, then create new
                if (Test-Path $folder_driver){
                    Remove-Item -Path $folder_driver -Recurse -Force | Out-Null
                }
                New-Item -ItemType Directory -Force -Path $folder_driver | Out-Null
                # export driver using pnp
                Write-Host "--- Extracting Driver"
                Write-Host "> pnputil.exe /export-driver $($inf_pub)" -ForegroundColor Green
                Try {
                    pnputil.exe /export-driver $inf_pub $folder_driver | Out-Host
                }
                Catch { # catch
                    $ErrorMessage = $_.Exception.Message
                    Write-Warning "$($FailedItem). The error message was $($ErrorMessage)"
                    PressEnterToContinue
                } # catch
                $DriverInf = "$($printerdriver.Name)\$($inf_orig)"
            } # drivers listed
            # All set
            Write-Host "------------------------"
            Write-Host "     Name: " -NoNewline
            Write-host $printername -ForegroundColor Green
            Write-Host "     Port: " -NoNewline
            Write-host $printerport -ForegroundColor Green
            Write-Host "Driver-$($PrnEnv): " -NoNewline
            Write-Host "$($PrnEnv)\" -NoNewline -ForegroundColor Yellow
            Write-host $DriverInf -ForegroundColor Green
            Write-Host " Settings: " -NoNewline
            Write-host $settings -ForegroundColor Green
            Write-Host " Location: " -NoNewline
            Write-host $Location -ForegroundColor Green
            Write-Host "------------------------"
            # Define the new row as an object
            $newRow = [PSCustomObject]@{
                Printer    = $printername
                "Driver-$($PrnEnv)"    = $DriverInf
                Port       = $printerport
                Settings   = $Settings
                Location   = $Location
            }
            # Append the row to the CSV file
            $newRow | Export-Csv -Path $PrnCSVPathAdd -Append -NoTypeInformation -Force
            $PrnCSVRowsAdd = Import-Csv $PrnCSVPathAdd
            Write-Host "Added to: $(Split-Path $PrnCSVPathAdd -Leaf)" -ForegroundColor Green
            Write-Host "Use [E]dit to adjust the name, port etc." -ForegroundColor Green
            PressEnterToContinue
        } # chose printer
    } # add to csv
    if ($choice -in ("T")) {
        # Has printers from CSV. Note if a printer is in both CSVs it will be ignored from removal considerations (won't be reinstalled)
        $PrnCSVRowsAdd | Where-object "Driver-$($Arch)" -ne "" | Where-object Printer -NotIn $Printers.Name | ForEach-Object {$strWarnings += "PC is missing printer from PrintersToAdd.CSV: $($_.Printer)"}
        $PrnCSVRowsRmv | Where-object PrintersToRemove -NotIn $PrnCSVRowsAdd.Printer | Where-object PrintersToRemove -In $Printers.Name | ForEach-Object {$strWarnings += "PC has a printer from PrintersToRemove.CSV: $($_.PrintersToRemove)"}
        if ($mode -eq "") {
            if ($strWarnings.count -eq 0) {
                Write-Host "OK: PC is up-to-date with the CSV files" -ForegroundColor Green
            }
            else {
                $strWarnings | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
            }
            PressEnterToContinue
            Continue
        }
        else {
            Break
        }
    } # # Has printers from CSV
    if ($choice -in "S","O","U")
    { # setup all, one or uninstall 
        Write-Host "----- Printers Before Setup -----------------" -ForegroundColor Yellow
        (($PrintersNum       | Select-Object Num,Name,DriverName,PortName | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
        Write-Host ""
        #region PrnCSVRowsRmv
        if (($choice -eq "S") -and ($PrnCSVRowsRmv.count -gt 0))
            { # Remove
                # filter PrintersToRemove for printers we have
                $entries = $Printers | Where-Object -Property Name -In $PrnCSVRowsRmv.PrintersToRemove
                $i = 0
                foreach ($x in $entries)
                { #each printer to remove
                    $i+=1
                    $printername   = $x.("Name")
                    $printerdriver = $x.("DriverName")
                    $printerport   = $x.("PortName")
                    write-host "----- Removing $($i) of $($entries.count): $($printername)"
                    $strReturn = RemovePrinter $printername
                    if ($strReturn.StartsWith("ERR")) {
                        $strWarnings += $strReturn
                    } # removeprinter error
                } #each printer to remove
            } # Remove
        #endregion PrnCSVRowsRmv
        #region PrnCSVRowsAdd
        if ($PrnCSVRowsAdd.count -eq 0)
        { # no printers in csv
            Write-Host "No Printers in CSV"
        } # no printers in csv
        else
        { # printers in csv
            # show a list
            Write-PrnCSVRowsAdd $PrnCSVRowsAdd $Printers
            # show a list
            if ($choice -ne "O") { # Setup One requires menu choice
                $entries = $PrnCSVRowsAdd
            } # Setup One requires menu choice
            else { # Setup one
                $choice = PromptForString "Which CSV printer to install [blank to exit]"
                if ($choice -eq "") { # exit
                    Continue
                }
                else { # chose printer
                    $entries = $PrnCSVRowsAdd[$choice-1]
                }
            } # Setup one
            if ($choice -eq "U") { $action = "Uninstalling"} else {$action = "Adding"}
            $i = 0
            ForEach ($item in $entries)
            { ## each entry
                $i += 1
                $printername  = $item.("Printer")
                $inffile      = $item.("Driver-$($Arch)")
                $infDriverName= ($inffile -split "\\")[0]
                $port         = $item.("Port")
                $comments     = $item.("Comments")
                $location     = $item.("Location")
                $settings     = $item.("Settings")
                write-host "----- $($action) $($i) of $($entries.count): $($printername)"
                if ($choice -eq "U") { # Uninstall
                    $strReturn = RemovePrinter $printername
                    Write-Host $strReturn
                    if ($strReturn.StartsWith("ERR")) {
                        $strWarnings += $strReturn
                    } # removeprinter error
                    Continue # move to next entry
                } # Uninstall
                if ($choice -ne "U") { # Setup or One
                    if ($Printers.Name -contains $printername) {
                        Write-Host "OK: skipping (already has this printer)"
                        Continue # move to next entry
                    } # skip if printer already here
                } # Uninstall
                if ($inffile -eq "") {
                    Write-Host "No driver for this CPU Arch (skipping): $($Arch)"
                    Continue # move to next entry
                }
                $OKtoinstall = $true
                ######## Add Port
                if ($printerports | Where-Object Name -eq $port) {
                    Write-Host "OK: Port $($port) already exists"
                }
                Else
                { ## no port already: add
                    Try {  
                        Add-PrinterPort -Name $port -PrinterHostAddress $port
                        Write-Host "OK: Added Port $($port)"
                    }
                    Catch { # catch
                        $ErrorMessage = $_.Exception.Message
                        $FailedItem = $_.Exception.ItemName
                        $strWarning = "ERR: Port $($FailedItem). The error message was $($ErrorMessage)"
                        Write-Host $strWarning -ForegroundColor Yellow
                        $strWarnings += $strWarning
                        $OKtoinstall = $false
                        #Break
                    } # catch
                } ## no port already: add
                ######## Add Driver
                $printDriverExists = Get-PrinterDriver -Name $infDriverName -ErrorAction SilentlyContinue
                if ($printDriverExists) {
                    Write-Host "OK: Driver $($infDriverName) already exists"
                } # driver already exists
                Else
                { # no driver already: add   
                    if  ([string]::IsNullOrEmpty($inffile))
                    { #empty csv
                        $strWarning = "ERR: The .inf file entry $("Driver-$($Arch)") is empty in the CSV"
                        Write-Host $strWarning -ForegroundColor Yellow
                        $strWarnings += $strWarning
                        $OKtoinstall = $false
                    } #empty csv
                    else
                    { #nonempty csv
                        # Search for driver in these paths
                        $inffilepaths=@()
                        $inffilepaths+="$($scriptDir)\Drivers\$($Arch)\$($inffile)"
                        $inffilefound = $false
                        foreach ($inffilepath in $inffilepaths) {
                            If (Test-Path $inffilepath)
                                { # found file
                                    $inffilefound = $true
                                    break
                                } # found file
                            }
                        if (-not $inffilefound) {
                            $strWarning = "ERR: Couldn't find file 'Drivers\$($Arch)\$($inffile)'"
                            Write-Host $strWarning -ForegroundColor Yellow
                            $strWarnings += $strWarning
                            $OKtoinstall = $false 
                        }
                        else
                        { #found driver file
                            Write-Host "OK: Adding Driver $($infDriverName)"
                            #region driverstore
                            $inf_orig = Split-Path $inffile -leaf
                            $pnp = $pnpdrivers | Where-Object {$_."Original Name" -eq $inf_orig}
                            if (-not $pnp)
                            { # not in driverstore: add to driverstore
                                if (!(IsAdmin)) {
                                    $strWarning ="ERR: Admin privs required to add driver '$($inffile)'.  (Re-run as admin)"
                                    Write-Host $strWarning -ForegroundColor Yellow
                                    $strWarnings += $strWarning
                                    $OKtoinstall = $false
                                }
                                else
                                { #is admin
                                    # Add Driver to Windows Driver store area using pnputil
                                    Try {
                                        Write-Host "--- Adding Driver"
                                        Write-Host "> pnputil.exe /add-driver $(Split-Path $inffilepath -Leaf) /install" -ForegroundColor Green
                                        pnputil.exe /add-driver $inffilepath /install | Out-Host
                                        Write-Host "---"
                                    }
                                    Catch { # catch
                                        $ErrorMessage = $_.Exception.Message
                                        $FailedItem = $_.Exception.ItemName
                                        $strWarning = "ERR: pnputil $($FailedItem). The error message was $($ErrorMessage)"
                                        Write-Host $strWarning -ForegroundColor Yellow
                                        $strWarnings += $strWarning
                                        $OKtoinstall = $false
                                    } # catch
                                } #is admin
                                # Add-PrinterDriver from Windows Driver store area
                            } # not in driverstore: add to driverstore
                            #endregion driverstore
                            Try {
                                Add-PrinterDriver -Name $infDriverName -ErrorAction Stop
                            }
                            Catch { # catch
                                $ErrorMessage = $_.Exception.Message
                                $FailedItem = $_.Exception.ItemName
                                $strWarning = "ERR: Add-PrinterDriver $($FailedItem). The error message was $($ErrorMessage)"
                                Write-Host $strWarning -ForegroundColor Yellow
                                $strWarnings += $strWarning
                                $OKtoinstall = $false
                            } # catch
                        } #found driver file
                    } #nonempty csv
                } # no driver already: add
                # Install the Printer, now that the port and driver are established
                if (!($OKtoinstall)) {
                    $strWarning = "ERR: Not installing printer due to above warnings: $($printername)"
                    Write-Host $strWarning -ForegroundColor Yellow
                    $strWarnings += $strWarning
                }
                else
                { # ok to install
                    $printerExists = $false
                    # Exists, Remove, Check
                    Get-Printer | Where-Object Name -eq $printername | Remove-Printer -Confirm:$false | Out-Null
                    if (Get-Printer | Where-Object Name -eq $printername) {
                        $printerExists = $true
                    }
                    if ($printerExists) {
                        $strWarning = "ERR: Can't replace exising printer [try manual deletion]: $($printername)"
                        Write-Host $strWarning -ForegroundColor Yellow
                        $strWarnings += $strWarning
                    } # couldn't remove old printer
                    Else 
                    { # Add Printer
                        $AddedOK=$false
                        # comments 
                        if([string]::IsNullOrEmpty($comments)) {
                            $comments = "IP = $($port) Driver = $($infDriverName)"
                        }
                        else {
                            $comments += "`n"
                            $comments += "IP = $($port) Driver = $($infDriverName)"
                        }
                        # Add Printer
                        Try {
                            ###if the port is not the printer's actual IP it will get stuck trying to connect 
                            Add-Printer -Name $printername -PortName $port -DriverName $infDriverName -Comment $comments -Location $location
                            Write-Host "OK: Added PRINTER $($printername) with DRIVER $($infDriverName) and PORT $($port)"
                            $AddedOK=$true
                        }
                        Catch
                        { # catch
                            $ErrorMessage = $_.Exception.Message
                            $FailedItem = $_.Exception.ItemName
                            $strWarning = "ERR: Add-Printer $($FailedItem). The error message was $($ErrorMessage)"
                            Write-Host $strWarning -ForegroundColor Yellow
                            $strWarnings += $strWarning
                            Break
                        } # catch
                        ### Add Printer
                        ##### Settings
                        if ($AddedOK)
                        { # printeraddedok
                            if ($settings)
                            { # settings
                                #Papersize=Letter,Collate=False,Color=True,DuplexingMode=TwoSidedLongEdge
                                $settings_arr = $null
                                $settings_arr = $settings -split ","
                                foreach ($setting in $settings_arr)
                                {# each setting
                                    #Color=True
                                    $setting_val = $setting -split "="
                                    if ($setting_val.count -ne 2)
                                    {# setting bad
                                        $strWarning = "    Err: Settings for '$($printername)' ($($settings)) should be formatted a=b and comma separated."
                                        Write-Host $strWarning -ForegroundColor Yellow
                                        $strWarnings += $strWarning
                                    }# setting bad
                                    else
                                    {# setting ok
                                        #### convert to target val
                                        $setting_val_setting = $setting_val[0]
                                        if ($setting_val[1] -eq "false") {
                                            $setting_val_target=$False
                                        }
                                        elseif ($setting_val[1] -eq "true") {
                                            $setting_val_target=$True
                                        }
                                        else {
                                            $setting_val_target=$setting_val[1]    
                                        }
                                        #### convert to target val
                                        $PrintConfiguration = Get-PrintConfiguration -PrinterName $printername
                                        if ($PrintConfiguration.$setting_val_setting -eq $setting_val_target) {
                                            Write-Host "    Setting: $($setting_val_setting)=$($setting_val_target) (already set)"
                                        } # setting already OK
                                        else {
                                            Write-Host "    Setting: $($setting_val_setting)=$($setting_val_target) (was $($PrintConfiguration.$setting_val_setting))"
                                            $PrintConfiguration.$setting_val_setting=$setting_val_target
                                            $PrintConfiguration | Set-PrintConfiguration
                                        } # setting needs changing
                                    }# setting ok
                                }# each setting
                            } # settings
                        }# add printer
                    } # Add Printer
                } # ok to install
            } ## each entry
            #
            $PortMonsToInclude = @("TCPMON.DLL","WSD Port Monitor")
            $DrvrMfrsToExclude = @("Microsoft","Adobe")
            $PrinterPorts   = Get-PrinterPort   | Where-Object {($PortMonsToInclude -Contains $_.PortMonitor)}
            $PrinterDrivers = Get-PrinterDriver | Where-Object {($DrvrMfrsToExclude -NotContains $_.Manufacturer)}
            $Printers       = Get-Printer       | Where-Object {($PrinterPorts.Name -Contains $_.PortName)}
            # Add numbered columns (for menu selection)
            $PrinterPortsNum   = $PrinterPorts   | ForEach-Object -Begin {$i = 1} -Process {$_ | Add-Member -MemberType NoteProperty -Name "Num" -Value $i -PassThru | Add-Member -MemberType NoteProperty -Name "Used By" -Value ($Printers | Where-Object Port -eq $_.Name | Select-Object Name -ExpandProperty Name) -PassThru; $i++}
            $PrinterDriversNum = $PrinterDrivers | ForEach-Object -Begin {$i = 1} -Process {$_ | Add-Member -MemberType NoteProperty -Name "Num" -Value $i -PassThru | Add-Member -MemberType NoteProperty -Name "Used By" -Value ($Printers | Where-Object DriverName -eq $_.Name | Select-Object Name -ExpandProperty Name) -PassThru; $i++}
            $PrintersNum       = $Printers       | ForEach-Object -Begin {$i = 1} -Process {$_ | Add-Member -MemberType NoteProperty -Name "Num" -Value $i -PassThru; $i++}
            # 
            Write-Host "----- Printers After Setup -----------------" -ForegroundColor Yellow
            (($PrintersNum       | Select-Object Num,Name,DriverName,PortName | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
            Write-Host ""
            if ($mode -ne '') {
                Write-Host "Exiting [$($CmdLineInfo)]"
                Break
            }
            PressEnterToContinue
        } # printers in csv
        #endregion PrnCSVRowsAdd
    } # setup all, one or uninstall
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
Write-Output $strReturn
exit $exitcode