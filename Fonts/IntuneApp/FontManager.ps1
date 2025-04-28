######################
### Parameters
######################
Param 
	( 
	 [string] $mode = "" # "" for manual menu, "I" to install fonts, "U" to uninstall fonts
	)
######################
### Functions
######################

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
## If script requires admin
If (-not(IsAdmin))
{# Elevate
    #ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
    # rebuild the argument list
    foreach($k in $MyInvocation.BoundParameters.keys)
    {
        switch($MyInvocation.BoundParameters[$k].GetType().Name)
        {
            "SwitchParameter" {if($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
            "String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
            "Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
            "Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
        }
    }
    $argumentlist ="-File `"$($scriptFullname)`" $($argsString)"
    # rebuild the argument list
    Write-Host "Restarting as elevated powershell.exe -File `"$($scriptname)`" $($argsString)"
    Try
    {
        Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
    }
    Catch {
        $exitcode=110; Write-Host "Err $exitcode : This script requires Administrator priviledges, re-run with elevation"
        Throw "Failed to start PowerShell elevated"
    }
    Exit
}# Elevate
#
$CmdLineInfo = "(none)"
if ($mode -ne ''){
    $CmdLineInfo = "-mode $($mode)"
}
# Get FontsToAdd
$FontsToAddFolder = "$($scriptDir)\Fonts"
#
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Parms: " -NoNewline
Write-host $($CmdLineInfo) -NoNewline -ForegroundColor Green
Write-Host ""
Write-Host "This script uses a CSV file for fonts to remove and a folder of fonts for fonts to add."
Write-Host ""
Write-Host "Use [I] to install fonts.   [$($scriptName) -mode I]"
Write-Host "Use [U] to uninstall fonts. [$($scriptName) -mode U]"
Write-Host "Use [S] to update the settings file for IntuneApp Settings.csv"
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"
if ($quiet) {Write-Host ("<<-quiet>>")}
$FntCSVPathRmv = "$($scriptDir)\FontsToRemove.csv"
if (-not (Test-Path $FntCSVPathRmv)) {
    Write-Host "Couldn't find csv file, creating template: $($FntCSVPathRmv)"
    Add-Content -Path $FntCSVPathRmv -Value "FontsToRemove"
}
Do { # action
    $strWarnings = @()
    # show  lists
    $count = 0
    $FontsToAdd = Get-ChildItem -Path $FontsToAddFolder -Include '*.ttf', '*.otf' -Recurse
    Write-Host "-------------- Fonts to add: $($FontsToAdd.count)"
    foreach ($font in $FontsToAdd)
    {
        $count += 1
        Write-Host "$($count)) $($font.Name)"

    }
    $count = 0
    $FntCSVRowsRmv      = Import-Csv $FntCSVPathRmv
    Write-Host "-------------- $(Split-Path $FntCSVPathRmv -Leaf): $($FntCSVRowsRmv.count)"
    foreach ($font in $FntCSVRowsRmv)
    {
        $count += 1
        Write-Host "$($count)) $($font.FontsToRemove)"
        if ($FontsToAdd | Where-Object Name -eq $font.FontsToRemove) {
            Write-Host " ... ERR: This font is in both the ADD and REMOVE lists (resolve this before continuing)"
            PressEnterToContinue
            Exit
        }
    }
    Write-Host "--------------- Font Manager Menu ------------------"
    Write-Host "[I] Install the Fonts Package"
    Write-Host "[U] Uninstall the Fonts Package"
    Write-Host "[D] Detect if PC has Fonts already"
    Write-Host "[S] Setup intune_settings.csv with these Fonts (for IntuneApp)"
    Write-Host "[E] Edit the Fonts Pacakge"
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
        Write-Host "Editing $(Split-Path $FntCSVPathRmv -Leaf) ..."
        Start-Process -FilePath $FntCSVPathRmv
        Write-Host "Editing $(Split-Path $FontsToAddFolder -Leaf) ..."
        Start-Process -FilePath $FontsToAddFolder
        PressEnterToContinue -Prompt "Press Enter when finished editing (to update list)."
    } # edit
    if ($choice -eq "S")
    { # intune_settings
        $IntuneSettingsCSVPath = "$($scriptDir)\intune_settings.csv"
        if (-not (Test-Path $IntuneSettingsCSVPath)) {
            Write-Host "Couldn't find csv file: $($IntuneSettingsCSVPath)"
        }
        else {
            # settings to check
            $AppDescription = "$($FontsToAdd.count) font(s) will be added by this app."
            if ($FntCSVRowsRmv.count -gt 0) {
                $AppDescription += " $($FntCSVRowsRmv.count) font(s) will be removed."
            }
            $AppFontsToAdd = $FontsToAdd.Name -join ","
            $AppFontsToRmv = $FntCSVRowsRmv.FontsToRemove -join ","
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
                Value = "Fonts to Add: $($AppFontsToAdd)"
            } ; $intunesettings += $newRow
            $newRow = [PSCustomObject]@{
                Name  = "AppVar2"
                Value = "Fonts to Remove: $($AppFontsToRmv)"
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
    if ($choice -in ("D"))
    {
        $app_detected = $true
        $fontFolder = "$([Environment]::GetFolderPath("Windows"))\Fonts"
        if (Test-Path $fontFolder)
        { # Windows font folder exists
            ForEach ($Font in $FontsToAdd.Name)
            {
                $FontPath = "$($fontFolder)\$($Font)"
                if (-not (Test-Path $FontPath))
                {
                    Write-Host "Not Found: $($FontPath)"
                    $app_detected = $false
                    break
                }
            }
            ForEach ($Font in $FntCSVRowsRmv.FontsToRemove)
            {
                $FontPath = "$($fontFolder)\$($Font)"
                if (Test-Path $FontPath)
                {
                    Write-Host "Found (should not be there): $($FontPath)"
                    $app_detected = $false
                    break
                }
            }
        } # Windows font folder exists
        if ($app_detected) {
            Write-Host "OK: PC is up-to-date with this Font package" -ForegroundColor Green
        }
        Else {
            Write-Host "ERR: PC is not up-to-date with this Font package" -ForegroundColor Yellow
        }
    } # Detect
    if ($choice -in "I")
    { # install 
        $fontFolder = "$([Environment]::GetFolderPath("Windows"))\Fonts"
        if (Test-Path $fontFolder)
        { # Windows font folder exists
            #------------ 
            #[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
            #$FontsBefore = (New-Object System.Drawing.Text.InstalledFontCollection).Families
            #Write-Host "Fonts Before ($($fontFolder)): $($FontsBefore.Count)"
            #------------
            Write-Host "Windows fonts before this routine ($($fontFolder)): $((Get-ChildItem -Path $fontfolder -File | Measure-Object).Count)"
            Write-host "--------------------------"
            Write-Host "FontsToAdd" -ForegroundColor Yellow
            Write-host "--------------------------"$count = 0
            # Process each font contained in the source directory
            foreach ($font in $FontsToAdd)
            { # each font to add
                $count += 1
                Write-Host "$($count)) $($font.Name)" -NoNewline
                $targetFontPath = Join-Path $fontFolder $font.Name
                if (Test-Path $targetFontPath)
                {
                    Write-Host " OK (Already exists)" -ForegroundColor Green -NoNewline
                }
                else
                {
                    Copy-Item $font.FullName -Destination $targetFontPath -Force
                    Write-Host " OK (Copied)" -ForegroundColor Green -NoNewline
                }
                # Set the registry
                Try
                {
                Add-Type -AssemblyName PresentationCore
                $fontdata = New-Object -TypeName Windows.Media.GlyphTypeface -ArgumentList $font.FullName
                $fontface = $($fontdata.Win32FaceNames.Values).Replace("Regular","")
                if ($fontface.Trim() -eq "")
                    {$fontname = "$($fontdata.Win32FamilyNames.Values)"}
                else
                    {$fontname = "$($fontdata.Win32FamilyNames.Values) $($fontdata.Win32FaceNames.Values)"}
                }
                Catch {$fontname=$font.name -replace ($font.Extension), ""}
                # what type of font
                if     ($font.extension -eq ".otf") {$fonttype = "OpenType"}
                elseif ($font.extension -eq ".ttf") {$fonttype = "TrueType"}
                $regpath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
                $regname = "$($fontname) ($($fonttype))"  #DMSerifDisplay-Regular.ttf -> DMSerifDisplay-Regular (TrueType)
                # remove any key values with this font file
                $regvalues = @((Get-ItemProperty $regpath).psobject.properties | Where-Object {$_.value -like $font.Name}|Select-Object name,value)
                ForEach ($regvalue in $regvalues)
                {
                    Remove-ItemProperty -Path $regpath -Name $regvalue.name -Force
                    Write-Host " (REG_DEL $($regvalue.name))" -NoNewline
                }
                # remove any key values with this font file
                New-ItemProperty -Path $regpath -Name $regname -Value $font.name -Type String -Force | Out-Null
                Write-Host " (REG_ADD $($regname))" -NoNewline
                # Set the registry
                Write-Host " Installed" -ForegroundColor Yellow
            } # each font to add
            ############# cleanup
            if ($FntCSVRowsRmv.count -gt 0)
            { # FntCSVRowsRmv exist
                Write-host "--------------------------"
                Write-Host "FontsToRemove.csv" -ForegroundColor Yellow
                Write-host "--------------------------"
                $count=0
                foreach ($font_remove in $FntCSVRowsRmv.FontsToRemove)
                { # each font to remove
                    if ($font_remove -ne "")
                    { # font not blank
                        $count += 1
                        Write-Host "$($count)) Remove $($font_remove)" -NoNewline
                        $targetFontPath = Join-Path $fontFolder $font_remove
                        if (Test-Path $targetFontPath)
                        {
                            Remove-LockedFile $targetFontPath
                            Write-Host " OK (Removed)" -ForegroundColor Green -NoNewline
                        }
                        else
                        {
                            Write-Host " OK (Already removed)" -ForegroundColor Green -NoNewline
                        }
                        # remove any key values with this font file
                        $regvalues = @((Get-ItemProperty $regpath).psobject.properties | where {$_.value -like $font_remove}|select name,value)
                        ForEach ($regvalue in $regvalues)
                        {
                            Remove-ItemProperty -Path $regpath -Name $regvalue.name -Force
                            Write-Host " (REG_DEL $($regvalue.name))" -NoNewline
                        }
                        # remove any key values with this font file
                        Write-Host " Uninstalled" -ForegroundColor Yellow
                    } # each font to remove
                } # font not blank
            } # FntCSVRowsRmv exist
        } # Windows font folder exists
    } # install
    if ($choice -in "U")
    { # uninstall 
        $fontFolder = "$([Environment]::GetFolderPath("Windows"))\Fonts"
        if (Test-Path $fontFolder)
        { # Windows font folder exists
            Write-Host "Windows fonts before this routine ($($fontFolder)): $((Get-ChildItem -Path $fontfolder -File | Measure-Object).Count)"
            Write-host "--------------------------"
            Write-Host "Removing Fonts" -ForegroundColor Yellow
            Write-host "--------------------------"$count = 0
            # Process each font contained in the source directory
            foreach ($font in $FontsToAdd)
            { # each font to add
                $count += 1
                Write-Host "$($count)) $($font.Name)" -NoNewline
                $targetFontPath = Join-Path $fontFolder $font.Name
                if (Test-Path $targetFontPath)
                {
                    $result = Remove-Item $targetFontPath -Force
                    Write-Host " OK (removed)" -ForegroundColor Green
                }
                else
                {
                    Write-Host " OK (Already removed)" -ForegroundColor Green
                }
            } # each font to add
        } # Windows font folder exists
    } # uninstall
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
Write-Output $strReturn
exit $exitcode