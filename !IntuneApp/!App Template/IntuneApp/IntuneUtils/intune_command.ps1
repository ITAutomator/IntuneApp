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
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
######################

#######################
## Main Procedure Start
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host ""
$package_path="$($scriptDir)\..\intune_settings.csv"
if (-not (Test-Path $package_path))
{
    Write-Host "Couldn't find intune_settings.csv" -ForegroundColor Yellow
    pause
    Exit 0    
}
# read the intune_settings.csv for this package
$IntuneAppValues_csv = Import-Csv $package_path
$IntuneCSVValues = @{}
$IntuneCSVValues.Add("AppName"              , ($IntuneAppValues_csv | Where-Object Name -EQ AppName).Value)
$IntuneCSVValues.Add("AppVersion"           , ($IntuneAppValues_csv | Where-Object Name -EQ AppVersion).Value)
$IntuneCSVValues.Add("AppNameVer"           , "$($IntuneCSVValues.AppName)$(if ($IntuneCSVValues.AppVersion) {"-v"})$($IntuneCSVValues.AppVersion)")
$IntuneCSVValues.Add("SystemOrUser"         , ($IntuneAppValues_csv | Where-Object Name -EQ SystemOrUser).Value)
$IntuneCSVValues.Add("AppDescription"       , ($IntuneAppValues_csv | Where-Object Name -EQ AppDescription).Value)
$IntuneCSVValues.Add("AppInstaller"         , ($IntuneAppValues_csv | Where-Object Name -EQ AppInstaller).Value)
$IntuneCSVValues.Add("AppInstallName"       , ($IntuneAppValues_csv | Where-Object Name -EQ AppInstallName).Value)
$IntuneCSVValues.Add("AppInstallArgs"       , ($IntuneAppValues_csv | Where-Object Name -EQ AppInstallArgs).Value)
$IntuneCSVValues.Add("AppUninstallNameVer"  , "$($IntuneCSVValues.AppUninstallName)$(if ($IntuneCSVValues.AppUninstallVersion) {"-v"})$($IntuneCSVValues.AppUninstallVersion)")
$IntuneCSVValues.Add("AppUninstallProcess"  , ($IntuneAppValues_csv | Where-Object Name -EQ AppUninstallProcess).Value)
#
$pkg=@([pscustomobject][ordered]@{
    AppName                       = $IntuneCSVValues.AppName
    AppVersion                    = $IntuneCSVValues.AppVersion
    AppType                       = $IntuneCSVValues.SystemOrUser
    AppDescription                = $IntuneCSVValues.AppDescription
    AppInstaller                  = $IntuneCSVValues.AppInstaller
    AppInstallName                = $IntuneCSVValues.AppInstallName
    AppInstallArgs                = $IntuneCSVValues.AppInstallArgs
    AppUninstallNameVer           = $IntuneCSVValues.AppUninstallNameVer
    AppUninstallProcess           = $IntuneCSVValues.AppUninstallProcess
    })
Write-Host "                     intune_settings.csv"
Write-Host ""
Write-Host "            AppName: " -NoNewline
Write-Host $($pkg.AppName) -ForegroundColor Green
Write-Host "     AppDescription: $($pkg.AppDescription)"
Write-Host "         AppVersion: $($pkg.AppVersion)"
Write-Host "       SystemOrUser: $($pkg.AppType)"
Write-Host "       AppInstaller: $($pkg.AppInstaller)"
Write-Host "     AppInstallName: $($pkg.AppInstallName)"
Write-Host "     AppInstallArgs: $($pkg.AppInstallArgs)"
Write-Host "AppUninstallNameVer: $($pkg.AppUninstallNameVer)"
Write-Host "AppUninstallProcess: $($pkg.AppUninstallProcess)"
Write-Host ""
If (($pkg.AppType -eq "System") -and (-not(IsAdmin)))
{ # elevate
    Write-Host "This is a System package and must be run as admin.  Elevating..."
    Start-Sleep 2
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
    $argumentlist ="-ExecutionPolicy Bypass -File `"$($scriptFullname)`" $($argsString)"
    # rebuild the argument list
    Try
    {
        Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
    }
    Catch {
       Write-Host "Failed to start PowerShell Elevated" -ForegroundColor Yellow
       Start-Sleep 3
       Throw "Failed to start PowerShell elevated"
       
    }
    Exit
} # elevate
Do
{ # make choice
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Choices for " -NoNewline
    Write-Host $pkg.AppName -ForegroundColor Green
    Write-Host ""
    Write-Host "I Install.ps1         Installs the app"
    Write-Host "U Uninstall.ps1       Uninstalls the app"
    Write-Host "D Detection.ps1       Detects if the app is already installed"
    Write-Host "R Requirements.ps1    Detects if the machine fulfills the requirements for installing the app"
    Write-Host "X Exit"
    Write-Host ""
    $message="Choice?"; $choices=@("&Install","&Uninstall","&Detection","&Requirements","E&xit"); $defaultChoice=0
    $choices = [System.Management.Automation.Host.ChoiceDescription[]] $choices
    $choice = $host.ui.PromptForChoice("",$message, $choices,$defaultChoice)
    $choiceTxt = $choices[$choice].Label.Replace("&","")
    Write-Host "Choice: " -NoNewline
    Write-Host $choiceTxt -ForegroundColor Green
    Write-Host ""
    if ($choiceTxt -ne "Exit")
    { # chose ps1
        $ps1path = "$($scriptDir)\intune_$($choiceTxt).ps1"
        if (-not (Test-Path $ps1path))
        { # no ps1
            Write-Host "Couldn't find: intune_$($choiceTxt).ps1" -ForegroundColor Yellow
            Start-Sleep 2
        } # no ps1
        else
        { # yes ps1
            if ($choiceTxt -eq "Install") {
                # copy to a temp folder and execute
                $TmpFld = GetTempFolder -Prefix "intuneapp_$($pkg.AppName)"
                Write-Host "- Creating temp folder: $(Split-Path $TmpFld -Leaf)"
                $source = Split-Path $scriptDir -Parent
                xcopy "$($source)" "$($TmpFld)" /E /I /H /Y > $null 2>&1
                $ps1path = "$($TmpFld)\IntuneUtils\intune_$($choiceTxt).ps1"
            } # copy to a temp folder and execute
            & $ps1path
            if ($choiceTxt -eq "Install") {
                Write-Host "- Removing temp folder: $(Split-Path $TmpFld -Leaf)"
                Remove-Item -Path $TmpFld -Recurse -Force
            } # cleanup temp folder
        } # yes ps1
    } # chose ps1
} # make choice
Until ($choiceTxt -eq "Exit")
Write-Host "Done"
Start-Sleep 1