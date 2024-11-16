# Main Procedure
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$($scriptDir)\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
#
Write-Host "-----------------------------------------------------------------------------"
Write-Host $scriptName -ForegroundColor Yellow
Write-Host "Installs and publishes apps using either Intune or manual methods."
Write-Host ""
Write-Host "About Apps" -ForegroundColor Yellow
Write-Host "- Intune enabled (Win32) apps are a package of files that install a product on an endpoint."
Write-Host "- Typically, apps are pulled from the Winget or Choco online repositories."
Write-Host "- Apps can also be custom scripts."
Write-Host "- Most Apps only require an icon (graphic) file and a settings file to indicate the name and Winget ID"
Write-Host "-----------------------------------------------------------------------------"
$bShowmenu=$true
Do
{ # show menu
    Write-Host "-----------------------------------------------------------------------------"
	Write-Host "Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major)"
    Write-Host $scriptName -ForegroundColor Green -nonewline
    Write-Host " Main menu"
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "L - List / Create apps" -ForegroundColor Yellow
    Write-Host "    Shows the current apps. Creates app based on winget template"
    Write-Host "I - Install / Uninstall apps" -ForegroundColor Yellow
    Write-Host "    Installs (or Uninstalls or Detects) apps on the current machine"
    Write-Host "C - Copy apps (to a USB key)" -ForegroundColor Yellow
    Write-Host "    Copies apps to a portable folder for later install"
    Write-Host "P - Publish / Unpublish apps" -ForegroundColor Yellow
    Write-Host "    Publishes apps to an existing org.  Create new org."
    Write-Host "-----------------------------------------------------------------------------"
    $msg= "Select an Action"
    $actionchoices = @("E&xit","&List","&Install","&Copy","&Publish")
    $ps1file = ""
    ##
    $action=AskForChoice -message $msg -choices $actionchoices -defaultChoice 0
    Write-Host "Action [$($action)]: $($actionchoices[$action].Replace('&',''))"
    If ($action -eq 0)
    { # Exit
        $bShowmenu=$false
    } # Exit
    ElseIf ($action -eq 1)
    {
        $ps1file = "$($scriptDir)\AppsCreate.ps1"
    }
    ElseIf ($action -eq 2)
    {
        $ps1file = "$($scriptDir)\AppsInstall.ps1"
    } 
    ElseIf ($action -eq 3)
    {
        $ps1file = "$($scriptDir)\AppsCopy.ps1"
    }
    ElseIf ($action -eq 4)
    {
        $ps1file = "$($scriptDir)\AppsPublish.ps1"
    }
    ##### ps1 launch
    if ($ps1file -ne "")
    {
        if (-not (Test-Path $ps1file -PathType Leaf))
        { # not found
            Write-Host "Aborted, Not found: $($ps1file)" -ForegroundColor Red
        }
        Else
        {
            &$($ps1file)
        }
        Start-Sleep 1
    }
    ##### done with menu actions
    if ($bShowmenu)
    {
        #Write-Host "Action Complete [$($action)]: $($actionchoices[$action].Replace('&',''))"
        Start-Sleep 1
    }
} # show menu
Until (-not $bShowmenu)
Write-Host "Done (exiting in 1s)"
Start-Sleep 1