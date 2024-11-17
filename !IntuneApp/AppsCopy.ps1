## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
# Get-Command -module ITAutomator  ##Shows a list of available functions
#region Load From XML
$Globals=@{}
$Globals=GlobalsLoad $Globals $scriptXML $false
$GlobalsChng=$false
# Note: these don't really work for booleans or blanks - if the default is false it's the same as not existing
if (-not $Globals.target_folder)       {$GlobalsChng=$true;$Globals.Add("target_folder","D:\IntuneApps")}
if ($GlobalsChng) {GlobalsSave $Globals $scriptXML}
#endregion Load From XML
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$source = Split-Path -Path $scriptDir -Parent
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "This script copies App installers to a staging folder (USB drive)."
Write-Host ""
Write-Host "Source: " -NoNewline
Write-Host $source -ForegroundColor Yellow
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"
# Search for packages in folder tree (intune_settings.csv)
$search_root  = Split-Path -Path $scriptdir -Parent
$package_files= Get-ChildItem -Path $search_root -File -Recurse -Filter "intune_settings.csv"
# to view the list:
# $package_files | Select-Object Fullname,DirectoryName,Name,LastWriteTime | Out-GridView\
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
    #
    if (-not $IntuneCSVValues.AppName.StartsWith("!"))
    { # not hidden app
        $entry_obj=@([pscustomobject][ordered]@{
            Package_Path                  = $package_path
            AppName                       = $IntuneCSVValues.AppName
            AppType                       = $IntuneCSVValues.SystemOrUser
            AppDescription                = $IntuneCSVValues.AppDescription
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
#region target
$target_folder = $Globals.target_folder
$msg = "Enter a target folder."
Write-Host $msg
$target_folder= [Microsoft.VisualBasic.Interaction]::InputBox($msg, "Target", $target_folder)
if (-not($target_folder)) {write-host "Aborted by user.";return $null}
Write-Host "Target Folder: $($target_folder)"
# see if source and target are same
if ($source -eq $target_folder)
{
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Wait a minute, the source and target folder are the same." -ForegroundColor Red
    Write-Host "Source: $($source)"
    Write-Host "Target: $($target_folder)"
    Write-Host "Aborting.  You need to run this from the actual source of these files." -ForegroundColor Yellow
    PressEnterToContinue
    exit
}
# check for mounted usb drive
$drive= $target_folder.SubString(0,2)
if (-not (Test-Path $drive))
{
    Write-Host "Target Folder Drive doesn't exist: $($drive)"
    $choice=AskForChoice -message "Target Folder Drive doesn't exist: $($drive)" -choices @("E&xit") -defaultChoice 0
    Exit
}
# check for target folder
if (Test-Path $target_folder)
{
    $choice=AskForChoice -message "Folder $($target_folder) exists. OK to update it?" -choices @("&Yes","No (E&xit)") -defaultChoice 0
    if ($choice -eq 1) {Exit}

}
else
{
    $choice=AskForChoice -message "Folder $($target_folder) doesn't exist. OK to create it?" -choices @("&Yes","No (E&xit)") -defaultChoice 0
    if ($choice -eq 1) {Exit}
    $result = $null
    $result = New-Item -ItemType Directory -Path $target_folder -Force -ErrorAction Ignore
    if (-not $result) {
        Write-Host "ERR: Couldn't create folder: $($target_folder)"
        PressEnterToContinue
        Exit
    }
}
if ($Globals.target_folder -ne $target_folder)
{
    $Globals.target_folder = $target_folder
    GlobalsSave  $Globals $scriptXML
}
#endregion target

### App Sets
$appsets_csvfile  = "$($scriptDir)\AppsInstall_AppGroups.csv"
if (Test-Path $appsets_csvfile)
{
    $appsets_csv = Import-Csv $appsets_csvfile
    $appsets_groups = $appsets_csv | Group-Object Name
    #
    ForEach ($entry in $appsets_groups)
    {
        $entry_obj=@([pscustomobject][ordered]@{
            AppName                       = $entry.Name
            AppType                       = "AppGroup"
            AppDescription                = ($entry.group.App | Sort-Object) -join ", "
            })
        ### append object
        $package_objs +=$entry_obj
    }
}
### All Apps
$entry_obj=@([pscustomobject][ordered]@{
    AppName                       = "AllApps"
    AppType                       = "AllApps"
    AppDescription                = "AllApps"
    })
### append object
$package_objs +=$entry_obj
### show packages
$package_objs = @($package_objs | Sort-Object SystemOrUser,AppType,AppName) #sort properly
$showmenu = $true
Do { # menu loop
    # Get choice
    Write-Host "Choose apps from the popup list: " -NoNewline
    $msg= "Select rows and click OK (Use Ctrl and Shift and Filter features to multi-select)"
    $pkgselects =  $package_objs | Out-GridView -PassThru -Title $msg
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
                {
                    $packages_selected +=$PKg
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
        Write-Host "These selected Packages will be copied:"
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
        if ((AskForChoice) -eq 0) {Write-Host "Aborting";Start-Sleep -Seconds 3; continue}
        Write-Host "---------------------------------"
        Write-Host "Copying: " -NoNewline
        Write-Host "Root files" -ForegroundColor Green -NoNewline
        # copy Root files (no subfolders)
        $retcode, $retmsg= CopyFilesIfNeeded $source $target_folder -CompareMethod "date" -delete_extra $false -deeply $false
        # $retmsg | Write-Host ; Write-Host "Return code: $($retcode)"
        # copy !IntuneApp folder (no subfolders)
        $retcode, $retmsg= CopyFilesIfNeeded "$($source)\!IntuneApp" "$($target_folder)\!IntuneApp" -CompareMethod "date" -delete_extra $true
        if ($retcode -eq 0) {Write-Host " OK"} else {Write-Host " Updated" -ForegroundColor Yellow; $retmsg  | Where-Object { $_ -notlike "OK*" } | ForEach-Object {Write-Host "  $($_)"}}
        # $retmsg | Write-Host ; Write-Host "Return code: $($retcode)"
        # get intunecmd path
        $intunecmd = "$($source)\!IntuneApp\!App Template\intune_command.cmd"
        $count_updated=0
        $count_i=0
        $count_i_total = $packages_selected.Count
        ForEach ($pkg in $packages_selected)
        { # Each package
            $count_i+=1
            Write-Host "Copying $($count_i) of $($count_i_total): " -NoNewline
            Write-Host $pkg.AppName -ForegroundColor Green -NoNewline
            # Copy Package ($pkg.Package_Path is ...7Zip\IntuneApp\intune_settings.csv)
            $source = Split-Path -Path (Split-Path -Path $pkg.Package_Path -Parent) -Parent
            $target = "$($target_folder)\$($pkg.AppName)"
            # Copy package
            $retcode, $retmsg= CopyFilesIfNeeded "$($source)\IntuneApp" "$($target)\IntuneApp" -CompareMethod "date" -delete_extra $true
            if ($retcode -eq 0) {Write-Host " OK"} else {$count_updated+=1;Write-Host " Updated" -ForegroundColor Yellow; $retmsg  | Where-Object { $_ -notlike "OK*" } | ForEach-Object {Write-Host "  $($_)"}}
            # Copy intunecmd (just one file)
            $retcode, $retmsg= CopyFilesIfNeeded "$($intunecmd)" "$($target)" -CompareMethod "date" -deeply $false
            # $retmsg | Write-Host ; Write-Host "Return code: $($retcode)"
        } # Each package
        Write-Host "---------------------------------"
        Write-Host "Packages Copied: $($count_i_total)"
        Write-Host "      Unchanged: $($count_i_total-$count_updated)"
        Write-Host "        Updated: " -NoNewline
        Write-Host                   $count_updated -ForegroundColor Yellow
        if ($count_updated -eq 0) {Write-host "               (Nothing needed updating)"}
        Write-Host "---------------------------------"
        $showmenu=$false
    } # apps selected
    PressEnterToContinue
} until (-not $showmenu)
start-sleep 1