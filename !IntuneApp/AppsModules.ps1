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
Function ModuleAction ($module="<none>",$action="update") #check,update,install,uninstall,reinstall
{
    Write-Host "$($action) module: " -NoNewline
    Write-Host $module -ForegroundColor Green
    $fm = Find-Module $module
    Write-host "Latest Version Online:"
    Write-Host ($fm | Select-Object Name,Version | Format-Table | Out-String)
    $gms = @(Get-Module -ListAvailable $module)
    #Get-InstalledModule $module | Format-List Name,Version,InstalledLocation 
    $gms = @($gms|Select-Object Name,Version,@{Name = 'NeedsUpdate';Expression = {$_.Version -lt $fm.Version}},@{Name = 'NeedsAdmin';Expression = {-not $_.ModuleBase.StartsWith("C:\Users")}},ModuleBase)
    Write-host "Local Version:"
    if ($gms.count -eq 0) {
        Write-Host "<none installed>"}
    else {
        Write-host ($gms | Select-Object Name,Version,NeedsUpdate,NeedsAdmin,ModuleBase | Format-Table | Out-String)
    }
    # gms needing update?
    $gmneedsupd= @($gms | Where-Object NeedsUpdate -eq $true)
    $actions=@()
    $bOk=$true
    if ($action -eq "check")
    { # check
        $sReturn = "OK"
        if ($gmneedsupd.count -gt 0)
        {
            Write-Host "$($gmneedsupd.count) version needs updating. (Use Uninstall / Reinstall if needed)" -ForegroundColor Yellow
            $sReturn = "ERR: $($gmneedsupd.count) version needs updating."
        }
    } # check
    else
    { # action ne check
        ForEach ($gm in $gms)
        { # each module that needs an update
            if ($gm.NeedsAdmin)
            { # this module needs admin rights to update
                If (IsAdmin)
                {
                    if (($action -eq "update") -and ($gm.needsupdate))
                    {
                        Write-Host "Updating to $($fm.Version) from $($gm.version) [$($gm.modulebase)]"
                        Update-Module -Name $module
                    }
                    if ($action -in "uninstall","reinstall")
                    {
                        Write-Host "Uninstalling $($gm.version) [$($gm.modulebase)]"
                        Uninstall-Module -Name $module
                        Pause
                    }
                    if ($action -in "install","reinstall")
                    {
                        Write-Host "Installing $($fm.version)"
                        Install-Module -Name $module
                        Write-host "Finished installing." -ForegroundColor Green
                        Write-Host "Some modules will not work properly without a restart."
                        Pause
                    }
                }
                else
                {
                    $bOk=$false
                    Write-Host "Can't action $($gm.version) to $($fm.version). Can't update a system level module as user. [$($gm.modulebase)]"
                }
            } # admin
            else
            { # this module must be run as the user
                If (IsAdmin)
                {
                    $bOk=$false
                    Write-Host "Can't action $($gm.version) to $($fm.version). Can't update a user level module as admin. [$($gm.modulebase)]"
                }
                else
                {                
                    if (($action -eq "update") -and ($gm.needsupdate))
                    {
                        Write-Host "Updating to $($fm.Version) from $($gm.version) [$($gm.modulebase)]"
                        Update-Module -Name $module
                    }
                    if ($action -in "uninstall","reinstall")
                    {
                        Write-Host "Uninstalling $($gm.version) [$($gm.modulebase)]"
                        Uninstall-Module -Name $module
                        Pause
                    }
                    if ($action -in "install","reinstall")
                    {
                        Write-Host "Installing $($fm.version)"
                        Install-Module -Name $module
                        Write-host "Finished installing." -ForegroundColor Green
                        Write-Host "Some modules will not work properly without a restart."
                        Pause
                    }
                }
            } # user      
        } # each module that needs an update
        #### install 
        if ($action -in "install","reinstall")
        {
            Write-Host "Installing $($fm.version)"
            Install-Module -Name $module
            Write-host "Finished installing." -ForegroundColor Green
            Write-Host "Some modules will not work properly without a restart."
            Pause
        }
        #
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
Write-Host "This script manages the modules needed."
Write-Host ""
Write-Host "You may need to re-launch as admin in order to manage machine-level modules."
Write-Host "-----------------------------------------------------------------------------"
Write-Host ""
$modules = @()
$modules += "IntuneWin32App"
$modules += "Microsoft.Graph"
$modules += "MicrosoftTeams"
$modules += "ExchangeOnlineManagement"
Do { # choose a module
    $i = 0
    Write-Host "Modules:" -ForegroundColor Yellow
    $modules | ForEach-Object {$i+=1;Write-Host " $($i)] $($_)"}
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
    if ($module)
    { # has a module
        Do { # action
            Write-Host "------------------"
            Write-Host "Module: " -NoNewline
            Write-Host $module -ForegroundColor Green
            Write-Host "IsAdmin: $(IsAdmin)" -ForegroundColor Yellow
            Write-Host "R - Relaunch as admin"
            Write-Host "C - Check version"
            Write-Host "U - Uninstall"
            Write-Host "I - Install"
            Write-Host "------------------"
            $choice = AskforChoice -Message "What do you want to do." -choices @("E&xit this module","&Relaunch as Admin","&Check","&Uninstall","&Install") -DefaultChoice 2
            if ($choice -eq 0)
            {break}
            elseif ($choice -eq 1)
            { # elevate
                Elevate
            }
            elseif ($choice -eq 2)
            { # check
                $sReturn = ModuleAction -module $module -action "check"
            }
            elseif ($choice -eq 3)
            { # uninstall
                $sReturn = ModuleAction -module $module -action "uninstall"
            }
            elseif ($choice -eq 4)
            { # install
                if (-not (IsAdmin))
                {
                    If (0 -eq (AskForChoice "Are you sure you want to install as non-admin (in the user context)?"))
                    {Continue}
                }
                $sReturn = ModuleAction -module $module -action "install"
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