<# ####### Update Manually (Run elevated)
$GraphModules = Get-InstalledModule | Where {$_.Name -Match "Graph"}; $GraphModules 
foreach($module in $GraphModules){
	Write-Host "Update-Module $($module.Name)..."
	Update-Module -Name $module.Name
}
#>

##################################
### Functions
##################################
Function ModuleAction ($module="<none>",$action="update") 
{
    #check,update,install,uninstall,reinstall
    if ($action -notin ("check","update","install","uninstall","reinstall")) {
        Write-Host "Invalid action: $($action)" -ForegroundColor Red
        return
    }
    $action = -join ($action.Substring(0,1).ToUpper() + $action.Substring(1))
    Write-Host "$($action) module: " -NoNewline
    Write-Host $module -ForegroundColor Green
    Write-Host "Checking versions..."
    # latest online
    $fm = Find-Module $module
    Write-host "-------------------- Latest Version Online --------------------"
    (($fm | Select-Object Name,Version | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
    Write-host ""
    # installed
    $gms = @(Get-Module $module -ListAvailable)
    $gms = @($gms|Select-Object Name,Version,@{Name = 'NeedsUpdate';Expression = {$_.Version -lt $fm.Version}},@{Name = 'NeedsAdmin';Expression = {-not $_.ModuleBase.StartsWith("C:\Users")}},ModuleBase)
    Write-host "-------------------- Local Version(s)      --------------------"
    if ($gms.count -eq 0) {
        Write-Host "<none installed>"}
    else {
        (($gms | Select-Object Name,Version,NeedsUpdate,NeedsAdmin,ModuleBase | Format-Table -AutoSize | Out-String) -split "`r?`n")| Where-Object { $_.Trim() -ne "" } | Write-Host
    }
    Write-host ""
    # gms needing update?
    $gmneedsupd= @($gms | Where-Object NeedsUpdate -eq $true)
    $bOk=$true
    if ($action -eq "check")
    { # check
        $sReturn = "OK"
        if ($gmneedsupd.count -gt 0)
        {
            Write-Host "$($gmneedsupd.count) version needs updating. (Use Uninstall / Reinstall if needed)" -ForegroundColor Yellow
            $sReturn = "ERR: $($gmneedsupd.count) version needs updating."
        }
        # any module at all?
        if ($gms.count -eq 0) {
            $sReturn = "OK: Module not installed"
        }
    } # check
    else
    { # action ne check
        ForEach ($gm in $gms)
        { # each module that needs an update
            $IsAdmin = IsAdmin
            #if ($gm.NeedsAdmin -ne ($IsAdmin))
            if ($gm.NeedsAdmin -and (-not $IsAdmin))
            { # admin / user conflict
                $bOk=$false
                if ($gm.NeedsAdmin) {
                    Write-Host "Can't update a system level module as user. [$($gm.modulebase)]"
                }
                else {
                    Write-Host "Can't update a user level module as admin. [$($gm.modulebase)]"
                }
            }
            else
            { # admin / user ok
                if (($action -eq "update") -and ($gm.needsupdate))
                { # update
                    Write-Host "Updating to $($fm.Version) from $($gm.version) [$($gm.modulebase)]"
                    Write-Host "Update-Module -Name $module" -ForegroundColor Yellow
                    Update-Module -Name $module -Force
                    PressEnterToContinue
                } # update
                if ($action -in "uninstall","reinstall")
                { # uninstall reinstall
                    Write-Host "Uninstalling $($gm.version) [$($gm.modulebase)]"
                    Write-Host "Uninstall-Module -Name $module -RequiredVersion $($gm.version)" -ForegroundColor Yellow
                    Uninstall-Module -Name $module -RequiredVersion $gm.version
                    if (Test-Path $gm.ModuleBase) {
                        Write-Host "Failed to remove: $($gm.ModuleBase)"
                        if (AskForChoice "Force removal (remove this directory)?") {
                            Remove-Item $gm.ModuleBase -Force -Recurse | Out-Null
                            if (Test-Path $gm.ModuleBase) {
                                Write-Host "Failed to remove directory" -ForegroundColor Red
                                PressEnterToContinue
                            }
                            else {
                                Write-Host "Removal succeeded" -ForegroundColor Green
                                # is the module folder now empty? (remove it)
                                $DirectoryPath = Split-Path $gm.ModuleBase -parent
                                if ((Get-ChildItem -Path $DirectoryPath -Recurse | Measure-Object).Count -eq 0) {
                                    Remove-Item $DirectoryPath -ErrorAction SilentlyContinue
                                    if (Test-Path $DirectoryPath) {
                                        Write-Host "Removal of empty parent folder failed: $($DirectoryPath)"
                                    }
                                } # remove parent
                            } # removed ok
                        } # force remove?
                    } # module still there
                } # uninstall reinstall
            } # admin / user ok    
        } # each module that needs an update
        if ($action -in "install","reinstall")
        { # install reinstall
            Write-Host "Installing $($fm.version)"
            if ($IsAdmin) {
                Write-Host "Install-Module -Name $module -Scope AllUsers" -ForegroundColor Yellow
                Install-Module -Name $module -Scope AllUsers -Force
            } # install as admin
            Else {
                Write-Host "Install-Module -Name $module" -ForegroundColor Yellow
                Install-Module -Name $module -Force
            } # install as user
            Write-host "Finished installing." -ForegroundColor Green
            PressEnterToContinue
        } # install reinstall
        if ($bOk)
        {
            $sReturn= "OK"
        }
        else
        {
            $sReturn= "ERR"
        }
    } # action ne check
    Return $sReturn
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
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "PowerShell module management."
Write-Host ""
Write-Host "Modules can be installed in user context (default) or machine context (-Scope AllUsers)"
Write-Host "  Using machine context is preferred (requires local admin rights) to avoid version conflicts"
Write-Host "  You can re-launch this script as admin (see menu choice) in order to manage machine-level modules."
Write-Host ""
Write-Host "Modules are installed per PowerShell version (5 vs 7), See PSver above to identify the current environment."
Write-Host "  PowerShell searches for modules in `$env:PSModulePath, with each version managing its own modules."
Write-Host ""
Write-Host "Microsoft.Graph modules should be updated to the same version at the same time."
Write-Host "-----------------------------------------------------------------------------"
Write-Host ""
$IsAdmin = IsAdmin
Write-Host "Is Admin (elevated): " -NoNewline
Write-Host $IsAdmin -ForegroundColor Yellow
$csvfile = "$($scriptDir)\$($scriptBase).csv"
if (-not (Test-path $csvfile)) {
    Write-Host "Couldn't find csv file: $($csvfile)"
}
$rows = Import-Csv $csvfile
$modules = $rows.modules | Sort-Object
if (-not $modules){
    Write-Host "Couldn't find 'modules' column in file: $($csvfile)"
}
Do { # choose a module
    $i = 0
    Write-Host "Modules:" 
    $modules | ForEach-Object {$i+=1;Write-Host " $($i)] " -NoNewline;Write-Host $_ -ForegroundColor Yellow}
    Write-Host "------------------------------"
    $module = $null
    $module_numstr = Read-Host "Which module? (blank to exit)"
    if (($module_numstr -eq "x") -or ($null -eq $module_numstr) -or ($module_numstr -eq "")) {
        Break
    } # nothing entered
    else
    { # something entered
        # convert to number
        Try {$module_num = [int]$module_numstr -1} Catch {$module_num = -1}
        if (($module_num-ge 0) -and ($module_num -lt $modules.Count))
        {
            $module=$modules[$module_num]
        }
        else
        {Write-host "Invalid"}
    }
    $bMenuFirstDisplay=$true
    if ($module)
    { # has a module
        $NeedsUpdate = $true
        $NeedsUpdateMsg = ""
        $HasModule = $true
        Do { # action
            if ($bMenuFirstDisplay){
                $sReturn = ModuleAction -module $module -action "check"
                if ($sReturn.StartsWith("OK")) {
                    $NeedsUpdate = $false
                }
                else {
                    $NeedsUpdateMsg = $sReturn.Replace("ERR:","")
                }
                if ($sReturn -match "Module not installed") {
                    $HasModule = $false
                }
                else {
                    $HasModule = $true
                }
                $bMenuFirstDisplay = $false
            }
            Write-Host "------------------"
            Write-Host "Module: " -NoNewline
            Write-Host $module -ForegroundColor Green
            #Write-Host "IsAdmin: $($IsAdmin)" -ForegroundColor Yellow
            #$choices = @("E&xit this module","Relaunch as &Admin","&Check","Up&date","&Uninstall","&Install","&Reinstall")
            $choices = @("E&xit this module","&Check")
            Write-Host "C - Check Version"
            if ($isAdmin) {
                Write-Host "A - Relaunch as admin (is admin already)" -ForegroundColor DarkGray
            }
            else {
                Write-Host "A - Relaunch as admin (is not admin)"
                $choices += "Relaunch as &Admin"
            }
            if ($NeedsUpdate) {
                Write-Host "D - Update ($($NeedsUpdateMsg))"
                $choices += "Up&date"
            }
            else {
                Write-Host "D - Update (at latest version now)" -ForegroundColor DarkGray
            }
            if ($HasModule) {
                Write-Host "I - Install" -ForegroundColor DarkGray
                Write-Host "U - Uninstall"
                $choices += "&Uninstall"
                Write-Host "R - Reinstall (Uninstall / Install)"
                $choices += "&Reinstall"
            }
            else {
                Write-Host "I - Install"
                $choices += "&Install"
                Write-Host "U - Uninstall" -ForegroundColor DarkGray
                Write-Host "R - Reinstall (Uninstall / Install)" -ForegroundColor DarkGray
            }
            Write-Host "------------------"
            $choicenum = AskforChoice -Message "What do you want to do." -choices $choices -DefaultChoice 0
            $choice = $choices[$choicenum].replace("&","")
            if ($choice -eq "Exit this module") {
                break
            }
            elseif ($choice -eq "Relaunch as Admin")
            { # elevate
                if ($IsAdmin) {
                    "This process is already elevated as admin."
                    PressEnterToContinue
                }
                Else {
                    Elevate
                }
            }
            else
            { # Check Update Uninstall Install Reinstall
                if ((-not ($IsAdmin)) -and ($choice -eq "install"))
                {
                    If (0 -eq (AskForChoice "Are you sure you want to install as non-admin (in the user context)?"))
                    {Continue}
                }
                $sReturn = ModuleAction -module $module -action $choice
                if ($choice -ne "check") {
                    # Write-host "Result: $($sReturn)"
                    $bMenuFirstDisplay = $true
                }
            }
            #
            Start-Sleep 2
        } While ($true) # action
    } # has a module
} While ($true) # choose
Write-Host "Done"
Start-Sleep 2
Exit
##################################