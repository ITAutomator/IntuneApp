Param (
    [string] $mode = "menu" # (blank),menu = show a menu of choices, check, install, uninstall
)

### Functions go here
#region Functions
Function IsAdmin() 
{
    <#
    .SYNOPSIS
    Checks if the running process has elevated priviledges.
    .DESCRIPTION
    To get elevation with powershell, right-click the .ps1 and run as administrator - or run the ISE as administrator.
    .EXAMPLE
    if (-not(IsAdmin))
        {
        write-host "No admin privs here, run this elevated"
        return
        }
    #>
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    $IsAdmin
}
Function AskForChoice
{
    ### Presents a list of choices to user
    # Default is Continue Y/N? with Y being default choice
    # Selections are ordered 0,1,2,3... (Unless it's Y/N, in this case Y=1 N=0
    # Note: Powershell ISE will immediately stop code if X is clicked
    # Choosedefault doesn't stop to ask anything - just displays choice made
    ###
    <# Sample code
    # Show a menu of choices
    $msg= "Select an Action"
    $actionchoices = @("&Select cert","&Delete cert","Back to &Cert Menu")
    $action=AskForChoice -message $msg -choices $actionchoices -defaultChoice 0
    Write-Host "Action : $($actionchoices[$action].Replace('&',''))"
    if ($action -eq 1)
    { Write-host "Delete" }
    # Show Continue? and Exit
    if ((AskForChoice) -eq 0) {Write-Host "Aborting";Start-Sleep -Seconds 3; exit}
    # Kind of like Pause but with a custom key and msg
    $x=AskForChoice -message "All Done" -choices @("&Done") -defaultChoice 0
    #>
    Param($Message="Continue?", $Choices=$null, $DefaultChoice=0, [Switch]$ChooseDefault=$false)
    $yesno=$false
    if (-not $Choices)
    {
        $Choices=@("&Yes","&No")
        $yesno=$true # We really want No to be 0, but 0 is always the first element (Yes)
    }
    ## If ISE, show prompt, since it's hidden from host, or if it wasn't shown by choosedefault
    If (($Host.Name -ne "ConsoleHost") -or ($ChooseDefault))
    {
        Write-Host "$($message) (" -NoNewline
        For ($i = 0; $i -lt $Choices.Count; $i++)
        {
            If ($i -gt 0) {Write-Host ", " -NoNewline}
            If ($i -eq $DefaultChoice)
            {Write-Host $Choices[$i].Replace("&","") -NoNewline -ForegroundColor Yellow}
            Else
            {Write-Host $Choices[$i].Replace("&","") -NoNewline}
        }
        Write-Host "): " -NoNewline
    }
    if ($ChooseDefault)
    {
        $choice = $DefaultChoice
    }
    Else
    {
        $choice = $host.ui.PromptForChoice("",$message, [System.Management.Automation.Host.ChoiceDescription[]] $choices,$DefaultChoice)
    }
    ## show selection
    If (($Host.Name -ne "ConsoleHost") -or ($ChooseDefault))
    {
        Write-Host $choices[$choice].Replace("&","") -ForegroundColor Green
    }
    ###
    if ($yesno) # flip the result
    {
        If ($choice -eq 0) {$choice=1} else {$choice=0}
    }
    Return $choice
    ###
}
#endregion Functions
### Main
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName}
if ($scriptFullname) {
    $scriptDir      = Split-Path -Path $scriptFullname -Parent
    $scriptName     = Split-Path -Path $scriptFullname -Leaf
    $scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
}
# settiings
$scriptBase = "PC Info"
$folder_common = "$([Environment]::GetFolderPath("ProgramFiles"))\$($scriptBase)"
$files = @()
$files += "PC Info Setup.ps1"
$files += "PC Info.lnk"
if ($mode -eq ""){$mode="menu"}
Write-Host "-----------------------------------------------------------------------------"
Write-Host $scriptName -ForegroundColor Yellow
Write-Host ""
Write-Host "- Installs / Uninstalls PC Into (to Start Menu)"
Write-Host "- "
Write-Host "-          Name: $($scriptBase)"
Write-Host "-          Mode: $($mode)"
Write-Host "-         Admin: $(IsAdmin)"
Write-Host "- folder_common: $($folder_common)"
Write-Host "-         files: $($files -join ", ")"
Write-Host "- "
Write-Host "-----------------------------------------------------------------------------"

ForEach ($file in $files)
{
    if (-not (Test-Path "$($scriptDir)\$($file)" -PathType Leaf))
    {Write-host "File not found: $($file)";Start-Sleep 2;exit 5}
}
$bShowMenu = ($mode -eq "menu")
Do
{ # menu loop
    $intReturn = 0
    if ($bShowMenu)
    { 
        $bShowMenu = $true
        # menu
        Write-Host "-----------------------------------------------------------------------------"
        $choice = AskForChoice "Action" -Choices "E&xit","&Check","Install &System","&Install User","&Uninstall"
        if     ($choice -eq "0") {$mode="Exit"}
        elseif ($choice -eq "1") {$mode="Check"}
        elseif ($choice -eq "2") {$mode="Install_System"}
        elseif ($choice -eq "3") {$mode="Install_User"}
        elseif ($choice -eq "4") {$mode="Uninstall"}
    }
    if ($mode -eq "Exit")
    {
        $bShowMenu = $false
    }
    if ($mode -eq "Check")
        { # Check
            $bCheckOK = $true # Assume it's installed unless proven otherwise
            # regkey        
            $regkeymain = "HKLM:\Software\Microsoft\Active Setup\Installed Components\$($scriptBase)"
            If ($bCheckOK -and (-not (Test-Path -Path $regkeymain)))
            { # regkey
                Write-Host "Couldn't find regkey: $($regkeymain)"
                $intReturn=21
                $bCheckOK=$false
            } # regkey
            # common
            if ($bCheckOK -and (-not (Test-Path $folder_common -PathType Container)))
            { # folder
                Write-Host "Couldn't find folder: $($folder_common)"
                $intReturn=22
                $bCheckOK=$false
            } # folder
            # files
            foreach ($file in $files)
            { # file
                if ($bCheckOK -and (-not (Test-Path "$($folder_common)\$($file)" -PathType Leaf)))
                { # folder
                    Write-Host "Couldn't find file: "$($folder_common)\$($file)""
                    $intReturn=22
                    $bCheckOK=$false
                } # folder
            } # file
            # result
            if ($bCheckOK)
            {
                Write-Host "Check if installed: OK [$($intReturn)]" -ForegroundColor Green
            }
            else
            {
                Write-host "Check if installed: Not installed [$($intReturn)]"
            }
        } # Check
    elseif ($mode -eq "Install_System")
        { # Install_System
            if (IsAdmin)
            { # isadmin
                New-Item -ItemType Directory -Force -Path $folder_common | Out-Null
                if (-not (Test-Path $folder_common -PathType Container))
                { # no target
                    Write-Host "Couldn't create folder: " $folder_common
                } # no target
                else
                { # has target folder
                    # copy files
                    $files | ForEach-Object {Copy-Item -Path "$($scriptDir)\$($_)" -Destination $folder_common -Force}
                    # create reg keys. These will launch the user side installer (on logon of every user)
                    $psexe = (Get-Command powershell.exe).Definition # or powershell.exe
                    $ps1installer = "$($folder_common)\$($files[0])"
                    $regkeymain = "HKLM:\Software\Microsoft\Active Setup\Installed Components\$($scriptBase)"
                    New-Item -Path $regkeymain -ErrorAction SilentlyContinue| Out-Null
                    New-ItemProperty -Path $regkeymain -Name "Version" -Value "1" -ErrorAction SilentlyContinue| Out-Null
                    New-ItemProperty -Path $regkeymain -Name "StubPath" -Value "`"$($psexe)`" -NoProfile -ExecutionPolicy Bypass -file `"$($ps1installer)`" -mode install_user" -ErrorAction SilentlyContinue| Out-Null
                    # done
                    Write-Host "Install System: OK. Users will get the item added to start menu on next logon." -ForegroundColor Green
                    <#
                    # or make a lnk
                    $WshShell = New-Object -comObject WScript.Shell
                    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\ColorPix.lnk")
                    $Shortcut.TargetPath = "C:\Program Files (x86)\ColorPix\ColorPix.exe"
                    $Shortcut.Save()
                    #>
                } # has target folder
            } # is admin
            else
            { # no admin
                Write-Host "Requires admin";$intReturn = 15
            } # no admin
        } # Install_System
        elseif ($mode -eq "Install_User")
        { # Install_User
            if (Test-Path $folder_common -PathType Container)
            { # install_system has happened
                $folder_start =  "$([Environment]::GetFolderPath("StartMenu"))\Programs"
                if (Test-Path $folder_start -PathType Container)
                { # has start menu folder
                    # find .lnk shortcuts in source
                    $scuts = @($files | Where-Object {$_.EndsWith(".lnk")})
                    # copy them to start menu folder and pin
                    foreach ($scut in $scuts)
                    { # each scut lnk
                        $file_src_common = "$($folder_common)\$($scut)"
                        If (Test-Path $file_src_common)
                        { # src lnk exists
                            # copy to start menu folder
                            Copy-Item -Path $file_src_common -Destination $folder_start -Force
                            <#
                            # pin
                            # Unfortunately pinning under program control is no longer allowed by microsoft
                            $i=0
                            $pinned=$false
                            $shell = New-Object -ComObject "Shell.Application"
                            While ($i -le 5)
                            { # waiting for menu
                                # delay a little so menu can appear
                                $i+=1
                                Start-Sleep 1
                                # pin
                                $sh_folder = $shell.Namespace($folder_start)
                                $sh_item = $sh_folder.Parsename($scut)
                                $verb = $sh_item.Verbs() | Where-Object {$_.Name.replace("&","") -like 'pin to start*'}
                                if ($verb) {
                                    $verb.DoIt() # Access is denied. (0x80070005 (E_ACCESSDENIED))
                                    $pinned = $true
                                    Break # out of while
                                } # has menu
                            } # waiting for menu
                            If (-not $pinned)
                            { # pin didn't happen
                                Write-Host "Pin to start didn't happen: $($scut)"
                                $intReturn = 70
                            } # pin didn't happen
                            #>
                        } # src lnk exists
                        else
                        { # src lnk missing
                            Write-Host "Missing file: $($file_src_common)"
                            $intReturn = 73
                        } # src lnk missing
                    } # each scut lnk
                    If ($intReturn -eq 0)
                    {
                        Write-Host "User Install: OK" -ForegroundColor Green
                    }
                } # has start menu folder
            } # install_system has happened
            else
            { # install_system hasn't happened
                Write-Host "Missing folder (Install_System hasn't happend yet, start with that): $($folder_common)"
                $intReturn = 78
            } # install_system hasn't happened 
        } # Install_User
    elseif ($mode -eq "uninstall")
    { # Uninstall
        # erase from user
        $scuts = @($files | Where-Object {$_.EndsWith(".lnk")})
        $folder_start =  "$([Environment]::GetFolderPath("StartMenu"))\Programs"
        foreach ($scut in $scuts)
        { # each scut lnk
            $file_src_start = "$($folder_start)\$($scut)"
            If (Test-Path $file_src_start -PathType Leaf)
            { # src lnk exists
                Remove-Item -Path $file_src_start -Force
                Write-Host "Removed: $($scut)"
            }
        }
        # remove regkey HKCU  
        $regkeymain = "HKCU:\Software\Microsoft\Active Setup\Installed Components\$($scriptBase)"
        If(Test-Path -Path $regkeymain)
        { # regkey exists
            Remove-Item -Path $regkeymain -Recurse
            Write-Host "Removed: $($regkeymain)"
        } # regkey exists
        # remove regkey HKLM    
        $regkeymain = "HKLM:\Software\Microsoft\Active Setup\Installed Components\$($scriptBase)"
        If(Test-Path -Path $regkeymain)
        { # regkey exists
            If (IsAdmin)
            {
                Remove-Item -Path $regkeymain -Recurse
                Write-Host "Removed: $($regkeymain)"
            }
            else
            {
                Write-Host "Must be admin to remove: $($regkeymain)"
                $intReturn=84
            }
        } # regkey exists
        # erase from common
        if (Test-Path $folder_common -PathType Container)
        { # folder exists
            If (IsAdmin)
            {
                Remove-Item $folder_common -Recurse -Force | Out-Null
            }
            else
            {
                Write-Host "Must be admin to remove: $($folder_common)"
                $intReturn=83
            }
        } # folder exists
        Write-Host "Uninstall complete."
    } # Uninstall
} Until (-not $bShowMenu)
Write-Host "Done [$($intReturn)]"
Start-Sleep 2
Exit $intReturn
