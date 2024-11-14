Function GetPackages ($search_root="C:\Users\Public\Documents\IntuneApps")
{
    $LogFolder = "C:\IntuneApp"
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
        $pkgobj.Add("AppNameVer"           , "$($pkgobj.AppName)$(if ($pkgobj.AppVersion) {"-v"})$($pkgobj.AppVersion)")
        # other info
        $pkgobj.Add("Fullpath"            , $IntuneAppFolder)
        $pkgobj.Add("Relpath"             , $pkg)
        $pkgobj.Add("PackageFolder"       , (Split-Path (Split-path (Split-Path $pkg -Parent) -Parent) -Leaf))
        $pkgobj.Add("Hash"                , "") # Calculated hash (later)
        $pkgobj.Add("PublishedAppId"      , "")
        $pkgobj.Add("PublishedDate"       , "")
        $pkgobj.Add("PublicationStatus"   , "Unpublished") #Unpublished, Published, Needs Update, Package Missing
        $pkgobj.Add("Warnings"            , "")
        # convert to booleans
        $pkgobj.PublishToOrgGroup= [System.Convert]::ToBoolean($pkgobj.PublishToOrgGroup)
        $pkgobj.CompanyPortalFeaturedApp= [System.Convert]::ToBoolean($pkgobj.CompanyPortalFeaturedApp)
        $pkgobj.AvailableInCompanyPortal= [System.Convert]::ToBoolean($pkgobj.AvailableInCompanyPortal)
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
Write-Host " Creates a basic App."
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"
$pkg_root = Split-Path $scriptDir -Parent
$showmenu = $true
$showlist = $true
Do {
    if ($showlist)
    { # show list
        $sResult,$pkgobjs=GetPackages -search_root $pkg_root
        $pkglist = $pkgobjs | Select-Object `
        @{Name = 'AppName'          ; Expression = {$_.AppName}} `
        ,@{Name = 'PublishToOrgGroup'; Expression = {if ($_.PublishToOrgGroup) {"Yes"} }} `
        ,@{Name = 'AppDescription'   ; Expression = {CropString $_.AppDescription.Replace("`n","").Replace("`r","")}} | Sort-object AppName
        Write-host ($pkglist | Format-table | Out-String)
        Write-Host "Result: $($sResult)"
        #
    }
    else
    { # don't show list
        # flip it back to true for next time
        $showlist = $true
    }
    $choice = AskForChoice "Choice:" -Choices ("E&xit","&List apps","&Open apps folder","&Browse Winget for app ids","&Create a new app") -DefaultChoice 0
    if ($choice -eq 0)
    { # Exit
        $showmenu = $false
    }
    elseif ($choice -eq 1)
    { # List
        Write-Host "Refreshing list..." 
    }
    elseif ($choice -eq 2)
    { # Explore
        $expl = Split-Path $scriptDir -Parent
        Write-Host "Exploring the folder: $($expl)"
        Start-process "explorer" "'/e,`"$($expl)`""
    }
    elseif ($choice -eq 3)
    { # Browse
        $url = "https://winstall.app"
        #$url = "https://winget.run"
        Write-host "Browsing to: " -NoNewline
        Write-host $url -ForegroundColor Green
        Start-Process $url
        $showlist = $false
    }
    elseif ($choice -eq 4)
    { # Create
        $source = "$($scriptDir)\!App Template"
        if (-not (Test-Path($source) -PathType Container)){
            $showlist = $false;Write-Host "Couldn't find App Template folder: $($source)" -ForegroundColor Yellow;Start-Sleep 2;Continue}
        $Appname = Read-Host "Enter App name (blank to cancel)"
        if ($Appname -eq ""){
            $showlist = $false;Write-Host "Canceled" -ForegroundColor Yellow;Start-Sleep 2;Continue}
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
        }
        # copy template to target
        Copy-Item -Path $source -Destination $target -Recurse
        # Rename files
        Rename-Item -Path "$($target)\IntuneApp\intune_settings_template.csv" -NewName "intune_settings.csv"
        Rename-Item -Path "$($target)\IntuneApp\intune_icon_template.png"     -NewName "intune_icon.png"
        # Get ID
        $AppID = Read-Host "Enter Winget ID (eg 7zip.7zip) from web (https://winstall.app). It can be changed later"
        # Inject new name into CSV
        $csvpath = "$($target)\IntuneApp\intune_settings.csv"
        $IntuneAppValues_csv = Import-Csv $csvpath
        # Update CSV file
        ($IntuneAppValues_csv | Where-Object Name -EQ Appname).Value    = $Appname
        ($IntuneAppValues_csv | Where-Object Name -EQ AppInstallName).Value = $AppID
        ($IntuneAppValues_csv | Where-Object Name -EQ AppInstaller).Value = "winget"
        ($IntuneAppValues_csv | Where-Object Name -EQ AppDescription).Value = "This is the description of this app."
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