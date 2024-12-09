Function GetPackages ($search_root="C:\Users\Public\Documents\IntuneApps")
{
    #region Search for packages (files named intune_settings.csv)
    If (-not (Test-Path $search_root -PathType Container)) {Return "search_root not found: $($search_root)"}
    $package_files= Get-ChildItem -Path $search_root -File -Recurse -Filter "intune_settings.csv"
    $package_paths = @()
    ForEach ($package_file in $package_files)
    { # each csv file
        $package_path=$package_file.FullName
        if (-not (Split-Path (Split-path (Split-Path $package_path -Parent) -Parent) -Leaf).StartsWith("!"))
        { #not a disabled package (grandparent folder has a ! in front)
            $package_path = $package_path.Replace("$($search_root)\","")
            $package_paths += $package_path
        }
    } # each csv file
    if ($package_paths.count -eq 0) {Return "Couldn't find any package files (intune_settings.csv): $($search_root)"}
    #endregion Search for packages (files named intune_settings.csv)
    $pkgobjs = @()
    $pkgupdated = @()
    $warningsallpkgs = @()
    ForEach ($pkg in $package_paths)
    { # Each pkg (csv) file
        $IntuneAppFolder = Split-Path "$($search_root)\$($pkg)" -Parent
        #region check required files
        $intune_settings_csvpath=Join-Path $IntuneAppFolder "intune_settings.csv"
        $intune_icon            =Join-Path $IntuneAppFolder "intune_icon.png"
        $intune_install         =Join-Path $IntuneAppFolder "IntuneUtils\intune_install.ps1"
        $intune_uninstall       =Join-Path $IntuneAppFolder "IntuneUtils\intune_uninstall.ps1"
        $intune_detection       =Join-Path $IntuneAppFolder "IntuneUtils\intune_detection.ps1"
        $intune_requirements    =Join-Path $IntuneAppFolder "IntuneUtils\intune_requirements.ps1"
        #
        $file_checks = @(
            $intune_settings_csvpath,
            $intune_icon,
            $intune_install,
            $intune_uninstall,
            $intune_detection,
            $intune_requirements
            )
        #Write-Host "Checking \IntuneApp folder for required files..."
        $IntuneAppValues_csv = Import-Csv $intune_settings_csvpath
        # create object out of csv values
        $pkgobj = [Ordered]@{}
        ForEach ($IntuneAppValue_csv in $IntuneAppValues_csv)
        {
            $pkgobj.Add( $IntuneAppValue_csv.Name , $IntuneAppValue_csv.Value )
        }
        # add some calculated fields
        $pkgobj.Add("AppNameVer"           , "$($pkgobj.AppName)$(if ($pkgobj.AppVersion) {"-v"})$($pkgobj.AppVersion)")
        # other info
        $pkgobj.Add("Fullpath"            , $IntuneAppFolder)
        $pkgobj.Add("Relpath"             , $pkg)
        $pkgobj.Add("PackageFolder"       , (Split-Path (Split-path (Split-Path $pkg -Parent) -Parent) -Leaf))
        $pkgobj.Add("Hash"                , "") # Calculated hash (later)
        $pkgobj.Add("Warnings"            , "")
        # convert to booleans
        $pkgobj.PublishToOrgGroup= [System.Convert]::ToBoolean($pkgobj.PublishToOrgGroup)
        $pkgobj.CompanyPortalFeaturedApp= [System.Convert]::ToBoolean($pkgobj.CompanyPortalFeaturedApp)
        $pkgobj.AvailableInCompanyPortal= [System.Convert]::ToBoolean($pkgobj.AvailableInCompanyPortal)
        #hash value
        $intune_packagehashxml=Join-Path $IntuneAppFolder "intune_packagehash.xml"
        if (Test-Path $intune_packagehashxml) {
            $hash_xml = Import-Clixml $intune_packagehashxml
            $pkgobj."Hash" = $hash_xml.hash
        }
        #region warnings
        $warnings=@()
        if ($pkgobj.PackageFolder -ne $pkgobj.AppName)
        {
            $warnings+="Name mismatch: Folder is [$($pkgobj.PackageFolder)] but App name from csv is [$($pkgobj.AppName)]. Generally it's one app per folder, and the folder should match the app."
        }
        $pkgdupes = @($pkgobjs | Where-Object AppName -eq $pkgobj.AppName)
        if ($pkgdupes)
        {
            $warnings+="This AppName [$($pkgobj.AppName)] is found at this path [$($pkgobj.Relpath)] and also this path [$($pkgdupes[0].Relpath)]. Delete or rename one of them."
        }
        $pkgobj.warnings = $warnings -join ", "
        $warningsallpkgs += $warnings
        #endregion warnings
        # append object of this package (the comma in front forces the values to be added as an additional array object in the parent list, vs within the same list)
        $pkgobjs += ,$pkgobj
    } #  # Each pkg (csv) file
    #region sResult
    $sResult = "OK: $($pkgobjs.count) Packages"
    if ($pkgupdated.count -gt 0)
    { # Updated
        $sResult += ". Updated: $($pkgupdated.count) [$($pkgupdated -join ', ')]"
    }
    If ($warningsallpkgs.count -gt 0)
    {
        $sResult += ". Warnings: $($warningsallpkgs.count) [$($warningsallpkgs -join ', ')]"
    }
    #endregion sResult
    Return $sResult,$pkgobjs
}
# Main Procedure
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$($scriptDir)\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
#region Transcript Open
$Transcript = [System.IO.Path]::GetTempFileName()               
Start-Transcript -path $Transcript | Out-Null
#endregion Transcript Open
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host " Lists and creates apps."
Write-Host ""
$pkg_root = Split-Path $scriptDir -Parent
$showmenu = $true
Do {
    Write-Host "-----------------------------------------------------------------------------"
	Write-Host "Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major)"
    Write-Host $scriptName -ForegroundColor Green -nonewline
    Write-Host " Menu"
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "L - List apps (to screen)"
    Write-Host "E - Export apps list to csv file"
    Write-Host "O - Open apps folder in explorer"
    Write-Host "U - Unblock any downloaded apps (Ticks the Unblock option in file properties)"
    Write-Host "B - Browse winget for app ids"
    Write-Host "C - Create a new app (using wizard)"
    Write-Host "-----------------------------------------------------------------------------"
    $choices = "E&xit","&List apps","&Export to CSV","&Open apps folder","&Unblock","&Browse Winget for app ids","&Create a new app"
    $choicen = AskForChoice "Choice:" -Choices ($choices) -DefaultChoice 0
    $choice  = $choices[$choicen].Replace("&","")
    if ($choice -eq "Exit")
    { # Exit
        $showmenu = $false
    }
    elseif ($choice -eq "List apps")
    { # List
        Write-Host "Refreshing list..." 
        $sResult,$pkgobjs=GetPackages -search_root $pkg_root
        $pkglist = $pkgobjs | Select-Object `
        @{Name = 'AppName'          ; Expression = {$_.AppName}} `
        ,@{Name = 'PublishToOrgGroup'; Expression = {if ($_.PublishToOrgGroup) {"Yes"} }} `
        ,@{Name = 'AppDescription'   ; Expression = {CropString $_.AppDescription.Replace("`n","").Replace("`r","")}} | Sort-object AppName
        Write-host ($pkglist | Format-table | Out-String)
        Write-Host "Result: $($sResult)"
    }
    elseif ($choice -eq "Unblock")
    { # List
        Write-Host "Unblocking all app files ... "
        $count_unblocked = 0
        $count_untouched = 0
        $folder = Split-Path $scriptDir -Parent
        if (-not (Test-Path $folder)) {
            Write-Host "Couldn't find folder: $($folder)"
            PressEnterToContinue
            Continue
        }
        Write-Host "Unblocking: " -NoNewline
        Write-Host $folder -ForegroundColor Green -NoNewline
        Write-Host " ..."
        Get-ChildItem -Path $folder -File -Recurse | ForEach-Object {
            # Check if the file is blocked by looking for the "Zone.Identifier" ADS
            if (Test-Path -LiteralPath "$($_.FullName):Zone.Identifier") {
                try {
                    # Unblock the file
                    Unblock-File -Path $_.FullName
                    # Write-Host "Unblocked: $($_.FullName)" -ForegroundColor Green
                    $count_unblocked += 1
                } catch {
                    Write-Host "Failed to unblock: $($_.FullName) - $_" -ForegroundColor Red
                }
            } else {
                # Write-Host "File is not blocked: $($_.FullName)" -ForegroundColor Yellow
                $count_untouched += 1
            }
        }
        # Get-ChildItem -Path "$($env:USERPROFILE)\Downloads" -Recurse | Unblock-File
        Write-Host "              Files unblocked: " -NoNewline
        Write-Host $count_unblocked -ForegroundColor Yellow
        Write-Host "Files already where unblocked: " -NoNewline
        Write-Host $count_untouched -ForegroundColor Green
        PressEnterToContinue
    }
    elseif ($choice -eq "Export to CSV")
    { # Export
        Write-Host "Exporting..." 
        $sResult,$pkgobjs=GetPackages -search_root $pkg_root
        #,@{Name = 'AppDescription'   ; Expression = {CropString $_.AppDescription.Replace("`n","").Replace("`r","")}} `
        $pkglist = $pkgobjs | Select-Object `
        @{Name = 'AppName'                    ; Expression = {$_.AppName                  }} `
        ,@{Name = 'AppDescription'            ; Expression = {$_.AppDescription           }} `
        ,@{Name = 'AppVersion'                ; Expression = {$_.AppVersion               }} `
        ,@{Name = 'AppInstaller'              ; Expression = {$_.AppInstaller             }} `
        ,@{Name = 'AppInstallName'            ; Expression = {$_.AppInstallName           }} `
        ,@{Name = 'AppInstallArgs'            ; Expression = {$_.AppInstallArgs           }} `
        ,@{Name = 'AppUninstallName'          ; Expression = {$_.AppUninstallName         }} `
        ,@{Name = 'AppUninstallVersion'       ; Expression = {$_.AppUninstallVersion      }} `
        ,@{Name = 'AppUninstallProcess'       ; Expression = {$_.AppUninstallProcess      }} `
        ,@{Name = 'SystemOrUser'              ; Expression = {$_.SystemOrUser             }} `
        ,@{Name = 'Publisher'                 ; Expression = {$_.Publisher                }} `
        ,@{Name = 'AppInstallerDownload1URL'  ; Expression = {$_.AppInstallerDownload1URL }} `
        ,@{Name = 'AppInstallerDownload1Hash' ; Expression = {$_.AppInstallerDownload1Hash}} `
        ,@{Name = 'AppInstallerDownload2URL'  ; Expression = {$_.AppInstallerDownload2URL }} `
        ,@{Name = 'AppInstallerDownload2Hash' ; Expression = {$_.AppInstallerDownload2Hash}} `
        ,@{Name = 'RestartBehavior'           ; Expression = {$_.RestartBehavior          }} `
        ,@{Name = 'Developer'                 ; Expression = {$_.Developer                }} `
        ,@{Name = 'Owner'                     ; Expression = {$_.Owner                    }} `
        ,@{Name = 'Notes'                     ; Expression = {$_.Notes                    }} `
        ,@{Name = 'InformationURL'            ; Expression = {$_.InformationURL           }} `
        ,@{Name = 'PrivacyURL'                ; Expression = {$_.PrivacyURL               }} `
        ,@{Name = 'CompanyPortalFeaturedApp'  ; Expression = {$_.CompanyPortalFeaturedApp }} `
        ,@{Name = 'AvailableInCompanyPortal'  ; Expression = {$_.AvailableInCompanyPortal }} `
        ,@{Name = 'PublishToOrgGroup'         ; Expression = {if ($_.PublishToOrgGroup) {"Yes"} }} `
        ,@{Name = 'AppVar1'                   ; Expression = {$_.AppVar1                  }} `
        ,@{Name = 'AppVar2'                   ; Expression = {$_.AppVar2                  }} `
        ,@{Name = 'AppVar3'                   ; Expression = {$_.AppVar3                  }} `
        ,@{Name = 'AppVar4'                   ; Expression = {$_.AppVar4                  }} `
        ,@{Name = 'AppVar5'                   ; Expression = {$_.AppVar5                  }} `
        ,@{Name = 'AppNameVer'                ; Expression = {$_.AppNameVer               }} `
        ,@{Name = 'Fullpath'                  ; Expression = {$_.Fullpath                 }} `
        ,@{Name = 'Relpath'                   ; Expression = {$_.Relpath                  }} `
        ,@{Name = 'PackageFolder'             ; Expression = {$_.PackageFolder            }} `
        ,@{Name = 'Hash'                      ; Expression = {$_.Hash                     }} `
        ,@{Name = 'warnings'                  ; Expression = {$_.warnings                 }} 
        # fields
        $csvfile = "$($pkg_root)\App list.csv"
        $pkglist | Export-Csv $csvfile -Force -NoTypeInformation
        Write-Host "Result: $($sResult)"
        Write-Host "   CSV: " -NoNewline
        Write-host $csvfile -ForegroundColor green
        $showlist = $false
    }
    elseif ($choice -eq "Open apps folder")
    { # Explore
        $expl = Split-Path $scriptDir -Parent
        Write-Host "Exploring the folder: $($expl)"
        Start-process "explorer" "'/e,`"$($expl)`""
    }
    elseif ($choice -eq "Browse Winget for app ids")
    { # Browse
        Write-host "--------------------------------"
        Write-host "Search for Winget apps here:"
        Write-host "https://winstall.app"
        Write-host "https://winget.run"
        Write-host ""
        Write-host "Search for Chocolatey apps here:"
        Write-host "https://community.chocolatey.org/packages"
        Write-host ""
        Write-host "--------------------------------"
        Write-host "Browsing to: " -NoNewline
        $url = "https://winstall.app"
        Write-host $url -ForegroundColor Green
        Start-Process $url
        $showlist = $false
    }
    elseif ($choice -eq "Create a new app")
    { # Create
        Write-host "App Creation Info"
        Write-host "--------------------------------"
        Write-host "Apps can use one of these installer technologies: winget,choco,msi,ps1"
        Write-host "winget - Native Winodows internet-sourced package tool (recommended)"
        Write-host "choco  - Popular Chocolatey internet-sourced package tool"
        Write-host "msi    - Legacy software installer"
        Write-host "ps1    - For custom PowerShell code"
        Write-host ""
        Write-host "Search for Winget apps here:"
        Write-host "https://winstall.app"
        Write-host "https://winget.run"
        Write-host ""
        Write-host "Search for Chocolatey apps here:"
        Write-host "https://community.chocolatey.org/packages"
        Write-host ""
        Write-host "--------------------------------"
        # check source
        $source = "$($scriptDir)\!App Template"
        if (-not (Test-Path($source) -PathType Container)){
            $showlist = $false;Write-Host "Couldn't find App Template folder: $($source)" -ForegroundColor Yellow;Start-Sleep 2;Continue}
        # get app name
        $Appname = Read-Host "Enter App name (blank to cancel)"
        if ($Appname -eq ""){
            $showlist = $false;Write-Host "Canceled" -ForegroundColor Yellow;Start-Sleep 2;Continue}
        # check target
        $target = "$(Split-Path $scriptDir -Parent)\$($Appname)"
        if (Test-Path $target -PathType Container)
        { # target folder exists
            Write-Host "Folder already exits: " -NoNewline
            Write-Host $target -ForegroundColor Yellow
            If (0 -eq (AskForChoice "Overwrite it?")){
                $showlist = $false;Write-Host "Canceled." -ForegroundColor Yellow;Start-Sleep 2;Continue}
            Write-Host "Removing old folder..."
            Remove-Item -Path $target -Recurse
            Start-Sleep 2
        } # target folder exists
        #region: Prompts
        Write-Host "Enter some info about the app. Everything can be changed later in the .CSV"
        $AppDescription = Read-Host "Enter a brief description"
        $AppInstaller = Read-Host "Enter AppInstaller type [winget,choco,msi,ps1]"
        if ($AppInstaller -eq "winget") {
            Write-host "--------------------------------"
            Write-host "Winget is the native Winodows internet-sourced package tool."
            Write-host "Use commands like 'winget -v' and 'winget list' at a command prompt."
            Write-host "Search for Winget apps here:"
            Write-host "https://winstall.app"
            Write-host "https://winget.run"
            Write-host "--------------------------------"
            $prompt = "Enter Winget ID (eg 7zip.7zip)"
        }
        elseif ($AppInstaller -eq "choco") {
            Write-host "--------------------------------"
            Write-host "Choco is the popular Chocolatey internet-sourced package tool."
            Write-host "Use commands like 'choco -v' and 'choco list' at a command prompt."
            Write-host "Search for Chocolatey apps here:"
            Write-host "https://community.chocolatey.org/packages"
            Write-host "--------------------------------"
            $prompt = "Enter choco ID (eg 7zip)"
        }
        elseif ($AppInstaller -eq "msi") {
            Write-host "--------------------------------"
            Write-host "Msi installer."
            Write-host "- The msi installer will be searched and found in the IntuneApp folder."
            Write-host "- It can also be downloaded directly from a web path."
            Write-host "- It can also be downloaded from Google Drive a public view only link (drive.google.com)."
            Write-host "- Downloaded zips will be extracted automatically."
            Write-host "- Add download URL to the intune_settings.csv under AppInstallerDownload1URL."
            Write-host "--------------------------------"
            $prompt = "Enter name of .msi file (eg setup.msi)"
        }
        elseif ($AppInstaller -eq "ps1") {
            Write-host "--------------------------------"
            Write-host "ps1 installer."
            Write-host "- ps1 allows for custom PowerShell script (.ps1) that will be run on install"
            Write-host "- See the _template.ps1 files in the IntuneUtils folder for samples. To use them, copy them to your IntuneApp folder and remove _template from the filename"
            Write-host "- Install: See intune_install_customcode_template.ps1 for sample code."
            Write-host "- Detection: (optional) Detection is normally handled automatically via the .csv in C:\IntuneApp. Use intune_detection_customcode_template.ps1 for more control."
            Write-host "- Uninstall: (optional) See intune_uninstall_followup_template.ps1 for a sample of code that runs when product is removed."
            Write-host "- Requirements: (optional) See intune_requirements_customcode_template.ps1 for a sample. Does the machine have the requirements to receive this package."
            Write-host "--------------------------------"
            $prompt = "Enter name of .ps1 file (eg setup.ps1)"
        }
        $AppID = Read-Host $prompt
        #endregion: Prompts
        # copy template to target
        Copy-Item -Path $source -Destination $target -Recurse
        # Rename files
        Rename-Item -Path "$($target)\IntuneApp\intune_settings_template.csv" -NewName "intune_settings.csv"
        Rename-Item -Path "$($target)\IntuneApp\intune_icon_template.png"     -NewName "intune_icon.png"
        # Inject new name into CSV
        $csvpath = "$($target)\IntuneApp\intune_settings.csv"
        $IntuneAppValues_csv = Import-Csv $csvpath
        # Update CSV file
        ($IntuneAppValues_csv | Where-Object Name -EQ Appname).Value    = $Appname
        ($IntuneAppValues_csv | Where-Object Name -EQ AppInstallName).Value = $AppID
        ($IntuneAppValues_csv | Where-Object Name -EQ AppInstaller).Value = $AppInstaller
        ($IntuneAppValues_csv | Where-Object Name -EQ AppDescription).Value = $AppDescription
        ($IntuneAppValues_csv | Where-Object Name -EQ AppVersion).Value = "100"
        ($IntuneAppValues_csv | Where-Object Name -EQ AppUninstallVersion).Value = ""
        ($IntuneAppValues_csv | Where-Object Name -EQ AppUninstallProcess).Value = ""
        ($IntuneAppValues_csv | Where-Object Name -EQ SystemOrUser).Value = "system"
        ($IntuneAppValues_csv | Where-Object Name -EQ Publisher).Value = ""
        ($IntuneAppValues_csv | Where-Object Name -EQ InformationURL).Value = ""
        ($IntuneAppValues_csv | Where-Object Name -EQ PublishToOrgGroup).Value = "FALSE"
        # Write file
        $IntuneAppValues_csv | Export-Csv $csvpath -NoTypeInformation
        # Browse to file
        Write-Host "Exploring the folder: $(Split-Path $csvpath -Parent)"
        Start-Process explorer.exe -ArgumentList "/select, ""$csvpath"""
        Write-Host "----------------------------"
        Write-Host "App Created: " -NoNewline
        Write-host $Appname -ForegroundColor Green
        Write-Host "----------------------------"
        Write-Host "Next Steps: "
        Write-Host "1 - Edit the .csv file with the settings of your app (AppDescription,Publisher,InformationURL,PublishToOrgGroup)."
        Write-Host "2 - Replace the .png file with a custom icon"
        Write-host "3 - Use the Install menu (intune_command.cmd) to test the installer"
        Write-host "4 - Use the Publish menu to publish the app to your org"
        Write-Host "----------------------------"
        Pause
    } # Create
    Start-Sleep 2
} While ($showmenu)
Write-Host "Done."