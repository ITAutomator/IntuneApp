##################################
### Functions
##################################
Function IsAdmin() 
{
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    $IsAdmin
}
Function GetTempFolder (
    $Prefix = "Powershell_"     
    )
    <#
    Usage:
    $TmpFld=GetTempFolder -Prefix "MyCode_"
    Write-Host $TmpFld
    #>
{
    $tempFolderPath = Join-Path $Env:Temp ($Prefix + $(New-Guid))
    New-Item -Type Directory -Path $tempFolderPath | Out-Null
    Return $tempFolderPath
}
######################
## Main Procedure
######################## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
# Get-Command -module ITAutomator  ##Shows a list of available functions
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Manually installs selectable packaged Apps."
Write-Host ""
Write-Host "- Intune will mark these apps as already installed (detected) in Endpoint Manager, and will skip the install."
Write-Host "- You don't have to wait for packages to come through the (potentially slow) Intune process."
Write-Host ""
Write-Host "Note: Use AppsCopy.ps1 to copy installers to removable media."
Write-Host "Note: Run this in user-mode, installers will self-elevate to admin-mode (if they are System packages)"
Write-Host "-----------------------------------------------------------------------------"
if (IsAdmin)
{
    Write-host "You have run this elevated (as admin). This is incorrect, so the program will end."
    Write-host "Installers will self-elevate to admin-mode (if they are System packages)."
    PressEnterToContinue
    Exit
}
# Search for packages in folder tree (intune_settings.csv)
$search_root  = Split-Path -Path $scriptdir -Parent
$package_files= Get-ChildItem -Path $search_root -File -Recurse -Filter "intune_settings.csv"
# to view the list:
# $package_files | Select-Object Fullname,DirectoryName,Name,LastWriteTime | Out-GridView
#
# ignore packagefolders with ! in front of them
$package_files = $package_files|  Where-object {-not $_.Fullname.Replace($search_root+"\","").StartsWith("!")}
#
$package_objs = @()
$count_i = 0
ForEach ($package_file in $package_files)
{ # each csv found
    $package_path=$package_file.FullName
    # read the intune_settings.csv for this package
    $IntuneAppValues_csv = Import-Csv $package_path
    $IntuneCSVValues = @{}
    $IntuneCSVValues.Add("AppName"              , ($IntuneAppValues_csv | Where-Object Name -EQ AppName).Value)
    $IntuneCSVValues.Add("AppVersion"           , ($IntuneAppValues_csv | Where-Object Name -EQ AppVersion).Value)
    $IntuneCSVValues.Add("AppNameVer"           , "$($IntuneCSVValues.AppName)$(if ($IntuneCSVValues.AppVersion) {"-v"})$($IntuneCSVValues.AppVersion)")
    $IntuneCSVValues.Add("SystemOrUser"         , ($IntuneAppValues_csv | Where-Object Name -EQ SystemOrUser).Value)
    $IntuneCSVValues.Add("AppDescription"       , ($IntuneAppValues_csv | Where-Object Name -EQ AppDescription).Value)
    $IntuneCSVValues.Add("PublishToOrgGroup"    , ($IntuneAppValues_csv | Where-Object Name -EQ PublishToOrgGroup).Value)
    $IntuneCSVValues.Add("AppInstaller"         , ($IntuneAppValues_csv | Where-Object Name -EQ AppInstaller).Value)
    $IntuneCSVValues.Add("AppInstallName"       , ($IntuneAppValues_csv | Where-Object Name -EQ AppInstallName).Value)
    #
    if (-not $IntuneCSVValues.AppName.StartsWith("!"))
    { # not hidden app
        $PublishToOrgGroup = If ($IntuneCSVValues.PublishToOrgGroup -eq "True") {"Yes"} else {""}
        $entry_obj=@([pscustomobject][ordered]@{
            AppType                       = $IntuneCSVValues.SystemOrUser
            AppName                       = $IntuneCSVValues.AppName
            Requirements                  = "-"
            Detection                     = "-"
            Mandatory                     = $PublishToOrgGroup
            AppInstaller                  = $IntuneCSVValues.AppInstaller
            AppInstallName                = $IntuneCSVValues.AppInstallName
            AppDescription                = $IntuneCSVValues.AppDescription
            Package_Path                  = $package_path
            })
        ### append object
        $package_objs +=$entry_obj
    } # not hidden app
} # each csv found
if ($package_objs.count -eq 0)
{
    Write-Host "   Couldn't find any package files (intune_settings.csv): $($search_root)" -ForegroundColor Yellow
    pause
    Exit 0
}

### App Sets
$appsets_csvfile  = "$($scriptDir)\$($scriptBase)_AppGroups.csv"
if (Test-Path $appsets_csvfile)
{
    $appsets_csv = Import-Csv $appsets_csvfile
    $appsets_groups = $appsets_csv | Group-Object Name
    $appgroup_showwarning = 1
    #
    ForEach ($entry in $appsets_groups)
    {
        $apps_notin = $entry.group.app |Where-Object {$_ -notin $package_objs.AppName}
        $apps_in    = $entry.group.app |Where-Object {$_ -in $package_objs.AppName}
        if (($appgroup_showwarning -eq 1) -and $apps_notin) {
            Write-Host "Warning: AppGroup [$($entry.Name)] includes $($apps_notin.count) apps in the group that were not found in this folder and will be skipped." -ForegroundColor Yellow
            Write-Host "Apps not found: $($apps_notin)"
            Write-host "- If you've copied a subset of apps, this is OK and the warning can be ignored."
            Write-host "- If you've copied ALL apps, you should adjust the csv file ($($scriptBase)_AppGroups.csv) to remove the missing apps from the group."
            $appgroup_showwarning = AskForChoice "Keep showing this warning (for this session)?" -DefaultChoice 1
        }
        $entry_obj=@([pscustomobject][ordered]@{
            AppType                       = "AppGroup"
            AppName                       = $entry.Name
            Requirements       = "-"
            Detection          = "-"
            Mandatory  = ""
            AppInstaller                  = ""
            AppInstallName                = ""
            AppDescription                = ($apps_in | Sort-Object) -join ", "
            Package_Path                  = ""
            })
        ### append object
        $package_objs +=$entry_obj
    }
}
### All Apps
$entry_obj=@([pscustomobject][ordered]@{
    AppType                       = "AllApps"
    AppName                       = "AllApps"
    Requirements       = "-"
    Detection          = "-"
    Mandatory  = ""
    AppInstaller                  = ""
    AppInstallName                = ""
    AppDescription                = "AllApps"
    Package_Path                  = ""
    })
### append object
$package_objs +=$entry_obj
### show packages
$package_objs = @($package_objs | Sort-Object AppType,AppName) #sort properly
# figure out columns to hide/show
$columnstoHide = @("Package_Path")
$columnsToShow = $package_objs[0].PSObject.Properties.Name | Where-Object { $_ -notin $columnsToHide }
$showmenu = $true
Do { # menu loop
    # Get choice
    Write-Host "Choose apps from the popup list: " -NoNewline
    $msg= "Select rows and click OK (Use Ctrl and Shift and Filter features to multi-select)"
    $pkgselects = $package_objs | Select-Object $columnsToShow | Out-GridView -PassThru -Title $msg
    if (-not $pkgselects)
    { # apps canceled
        Write-Host "Canceled"
        $showmenu = $false
    } # apps canceled
    else
    { # apps selected
        ### parse from prompt to unique package names
        $packages_selected = @()
        ForEach ($Pkg in $pkgselects)
        { # Each Selection
            ###
            if ($Pkg.AppType -eq "AppGroup")
            {# AppGroup
                $AppGroupMembers = @($Pkg.AppDescription.Split(","))
                $AppGroupMembers = $AppGroupMembers.Trim()
                ForEach ($AppGroupMember in $AppGroupMembers)
                {# AppGroup member
                    $AppGroupPkg = $package_objs | Where-Object -Property AppName -EQ $AppGroupMember
                    if ($AppGroupPkg.AppType -eq "AppGroup")
                    { # AppGroup containing another AppGroup
                        $AppGroupMembers2 = @($AppGroupPkg.AppDescription.Split(","))
                        $AppGroupMembers2 = $AppGroupMembers2.Trim()
                        ForEach ($AppGroupMember2 in $AppGroupMembers2)
                        {# AppGroup member2
                            $Pkg2 = $package_objs | Where-Object -Property AppName -EQ $AppGroupMember2
                            if ("System","User" -contains $Pkg2.AppType)
                            { # AppGroup containing Package
                                if (-not ($packages_selected | Where-Object -Property AppName -eq $Pkg2.AppName)) # make sure it's not already there
                                {
                                    $packages_selected +=$Pkg2
                                }
                            } # AppGroup containing Package
                            else
                            {
                                Write-Host "Warning: Couldn't find package in AppGroup '$($AppGroupMember)': " -NoNewline
                                Write-Host "$($AppGroupMember2)" -ForegroundColor Red
                            }
                        }# AppGroup member2
                    } # AppGroup containing another AppGroup
                    elseif ("System","User" -contains $AppGroupPkg.AppType)
                    { # AppGroup containing Package
                        if (-not ($packages_selected | Where-Object -Property AppName -eq $AppGroupPkg.AppName)) # make sure it's not already there
                        {
                            $packages_selected +=$AppGroupPkg
                        }
                    } # AppGroup containing Package
                    else
                    {
                        Write-Host "Warning: Couldn't find package in AppGroup '$($Pkg.AppName)' : " -NoNewline
                        Write-Host "$($AppGroupMember)" -ForegroundColor Red
                    }
                } # AppGroup member
            } # AppGroup
            elseif ("System","User" -contains $Pkg.AppType)
            { # System or User
                if (-not ($packages_selected | Where-Object -Property AppName -eq $PKg.AppName)) # make sure it's not already there
                { # append
                    $packages_selected += $package_objs | Where-Object -Property AppName -eq $PKg.AppName
                }
            } # System or User
            elseif ("AllApps" -eq $Pkg.AppType)
            { # All Apps
                $AllPkgs=@()
                $AllPkgs += $package_objs | Where-Object -Property AppType -EQ "System"
                $AllPkgs += $package_objs | Where-Object -Property AppType -EQ "User"
                ForEach ($AllPkg in $AllPkgs)
                { #AllPkg
                    if (-not ($packages_selected | Where-Object -Property AppName -eq $AllPkg.AppName)) # make sure it's not already there
                    {
                        $packages_selected +=$AllPkg
                    }
                } #AllPkg
            } # System or User
            else
            {
                Write-Host "Warning: Couldn't find package: " -NoNewline
                Write-Host "$($AppSelected)" -ForegroundColor Red
            }
        } # Each Selection
        if ($packages_selected.Count -eq 0)
        {
            Write-Host "No packages selected, Exiting"
            Start-Sleep -Seconds 2
            $showmenu = $false
            break
        }
        ###
        Write-Host "Selected packages:"
        $count_i= 0
        ### show packages selected
        $packages_selected = @($packages_selected | Sort-Object SystemOrUser,AppType,AppName) #sort properly
        ForEach ($package in $packages_selected)
        {
                $count_i +=1
                Write-Host "$($count_i.ToString("00")) - [$($package.AppType)] " -NoNewline
                Write-Host "$($package.AppName)" -ForegroundColor Green -NoNewline
                Write-Host " $($package.AppDescription)"
        }
        # ready?
        if ($packages_selected.count -eq 1) { # action: nothing to ask since mini-menu does that
            $action = 1}
        else{ # ask which action to take
            $action = AskForChoice "Action" -Choices "E&xit","&Install","&Uninstall","&Detect only"
            if ($action -eq 0) {Write-Host "Aborting";Start-Sleep -Seconds 3; continue}
        } # action
        $tmp_folder = ""
        # loop through twice: 1 for system, 2 for user
        For ($sysuser= 1; $sysuser -le 2; $sysuser++)
        { # sysuser 1 is system, 2 is user
            if ($sysuser -eq 1)
                {$AppType="System"}
            else
                {$AppType="User"}
            # create an installer .ps1
            $ps1filelines=@()
            $count_i=0
            $pkgs = @($packages_selected | Where-Object -Property AppType -eq $AppType)
            $pkgs_count=$pkgs.Count
            ForEach ($pkg in $pkgs)
            { # each pkg
                $count_i+=1
                $pkg_folder = Split-Path -Path (Split-Path -Path $pkg.Package_Path -Parent) -Parent #pkg_folder is grandparent of csv
                #region Cache: Make sure it's not an online folder (won't play nice with system installs)
                $need_caches = @(Get-ChildItem $pkg_folder -Recurse -Attributes Offline)
                if ($need_caches)
                { # cache needed for pkg
                    Write-Host "[$($pkg.AppName)] has online files that need downloading"
                    foreach ($need_cache in $need_caches)
                    { # cache file
                        Write-Host "- Cache file: $($need_cache.Name)"
                        $TempFile = New-TemporaryFile
                        Copy-Item -Path $need_cache.Fullname -Destination $TempFile
                        Remove-Item $TempFile
                    } # cache file
                } # cache needed for pkg
                #endregion Cache
                # each file line
                $ps1filelines+="Write-Host `"[$($AppType)] ($($count_i) of $($pkgs_count)) Starting package: $($pkg.Appname)`" -ForegroundColor Green"
                if ($packages_selected.count -eq 1)
                { # just 1 pkg selected, show UI menu
                    $intune_install="$($pkg_folder)\IntuneApp\IntuneUtils\intune_command.ps1"
                }
                else
                { # multiple pkgs, no menu
                    if ($action -eq 1) {
                        $ps1 = "intune_install.ps1"
                        if ($tmp_folder -eq "") {
                            $tmp_folder=GetTempFolder -Prefix "IntuneAppsInstall_"
                            Write-Host "Temp folder created: $(Split-Path $tmp_folder -Leaf)"
                        }
                        #copy folder to temp 
                        $source = "$($pkg_folder)\IntuneApp"
                        xcopy "$($source)" "$($tmp_folder)\$($pkg.AppName)" /E /I /H /Y > $null 2>&1
                        #run from temp
                        $intune_install="$($tmp_folder)\$($pkg.AppName)\IntuneUtils\$($ps1)"
                    }
                    elseif ($action -eq 2) {
                        $ps1 = "intune_uninstall.ps1"
                        $intune_install="$($pkg_folder)\IntuneApp\IntuneUtils\$($ps1)"
                    }
                }
                $ps1filelines+="& `"$($intune_install)`" -quiet"
            } # each pkg
            if ($pkgs)
            { #ps1s to call
                if ($action -eq 3)
                { # requirements and detections
                    foreach ($pkg in $pkgs)
                    {
                        $pkg_folder = Split-Path -Path (Split-Path -Path $pkg.Package_Path -Parent) -Parent #pkg_folder is grandparent of csv
                        #region Cache: Make sure it's not an online folder (won't play nice with system installs)
                        $need_caches = @(Get-ChildItem $pkg_folder -Recurse -Attributes Offline)
                        if ($need_caches)
                        { # cache needed for pkg
                            Write-Host "[$($pkg.AppName)] has online files that need downloading"
                            foreach ($need_cache in $need_caches)
                            { # cache file
                                Write-Host "- Cache file: $($need_cache.Name)"
                                $TempFile = New-TemporaryFile
                                Copy-Item -Path $need_cache.Fullname -Destination $TempFile
                                Remove-Item $TempFile
                            } # cache file
                        } # cache needed for pkg
                        #endregion Cache
                        Write-Host "-------- Detecting: $($pkg.AppName)" -ForegroundColor Green
                        $pkg.Requirements = & "$($pkg_folder)\IntuneApp\IntuneUtils\intune_requirements.ps1"
                        $pkg.Detection    = & "$($pkg_folder)\IntuneApp\IntuneUtils\intune_detection.ps1"
                    }
                } # requirements and detections 
                else
                { # installs and uninstalls
                    $ps1filelines_tmp=@()
                    $ps1filelines_tmp+="Write-Host `"[$($AppType)] Starting $($pkgs_count) actions (3 secs)`" -ForegroundColor Green"
                    $ps1filelines_tmp+="Start-Sleep 3"
                    $ps1filelines_tmp+= $ps1filelines
                    $ps1filelines_tmp+="Write-Host `"[$($AppType)] Done with $($pkgs_count) actions (3 secs)`" -ForegroundColor Green"
                    $ps1filelines_tmp+="Start-Sleep 3"
                    # create a tmp for output
                    $tmpfile = New-TemporaryFile
                    $tmp_name = "intune_appsinstall_$($tmpfile.BaseName).ps1"
                    Rename-Item -Path $tmpfile.FullName -NewName $tmp_name
                    $tmp_fullpath = "$($tmpfile.DirectoryName)\$($tmp_name)"
                    # write lines to ps1 temp file
                    [System.IO.File]::WriteAllLines($tmp_fullpath,$ps1filelines_tmp) # writes UTF8 file
                    # sytem or user
                    if ($AppType -eq "system")
                    { # system ps1s
                        # start installs in Bypass / RunAs
                        Start-Process -FilePath "PowerShell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($tmp_fullpath)`"" -Wait -verb RunAs
                    } # system ps1s
                    else
                    { # user ps1s
                        # start installs as User
                        Start-Process -FilePath "PowerShell.exe" -ArgumentList "-File `"$($tmp_fullpath)`"" -Wait
                    } # user ps1s
                    # cleanuup tempfiles
                    Remove-Item $tmp_fullpath
                    # refresh fields
                    ForEach ($pkg in $pkgs)
                    { # each pkg
                        $pkg.Detection          = "$($ps1) completed"
                    } # each pkg
                    # cleanup temp folder
                    if ($tmp_folder -ne "") {
                        Remove-Item -Path $tmp_folder -Recurse -Force
                        Write-Host "Temp folder removed: $(Split-Path $tmp_folder -Leaf)"
                    }
                } # installs and uninstalls
            } #ps1s to call
        } # sysuser 1 is system, 2 is user
        #$x=AskForChoice -message "All Done running $($ps1)" -choices @("&Done") -defaultChoice 0
    } # apps selected
} until (-not $showmenu)
start-sleep 1