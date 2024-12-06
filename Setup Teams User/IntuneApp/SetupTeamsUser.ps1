###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")
Write-host "Mode: $($mode)"
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
$OS= Get-OSVersion

Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}

$TeamsConfigFiles = @()
$TeamsConfigFiles +="$env:USERPROFILE\AppData\Roaming\Microsoft\Teams\desktop-config.json"
$TeamsConfigFiles +="$env:USERPROFILE\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\app_settings.json"

$i=0
ForEach ($TeamsConfigFile in $TeamsConfigFiles)
{ # Each config (teams ver)
    $i+=1
    Write-Host "Teams Config v$($i): $($TeamsConfigFile)"
    if (Test-Path $TeamsConfigFile -PathType Leaf)
    { # File found
        # Get Teams Configuration
        $FileContent=Get-Content -Path $TeamsConfigFile
        $Filechanged=$false
        $settings=@()
        ###
        if ($i -eq 1)
        {
            $procname = "Teams"
            $settings+= [pscustomobject]@{option="openAtLogin"   ;bad="false";good="true"} #open automatically at user login $true or $false
            $settings+= [pscustomobject]@{option="openAsHidden"  ;bad="false";good="true"} #open in the background Hidden $true or $false
            $settings+= [pscustomobject]@{option="runningOnClose";bad="false";good="true"} #running on Taskbar $true or $false
        }
        elseif ($i -eq 2)
        {
            $procname = "ms-teams"
            $settings+= [pscustomobject]@{option="open_app_in_background"   ;bad="false";good="true"} #open in the background Hidden $true or $false
        }
        ###
        ForEach ($setting in $settings)
        { # Each setting
            #
            $vbad = """$($setting.option)"":$($setting.bad)"
            $vgood = """$($setting.option)"":$($setting.good)"
            #[boolean]$OpenAsHidden=$True
            $foundbad = $FileContent -like "*" + $vbad +"*"
            if ($foundbad)
            {
                $FileContent=$FileContent.Replace($vbad,$vgood)
                write-host "Teams config v$($i): $($setting.option)=$($setting.good): Updated from $($setting.bad)"
                $Filechanged=$true
            }
            else
            {
                write-host "Teams config v$($i): $($setting.option)=$($setting.good): Already OK"
            }
        } # Each setting
        if ($Filechanged)
        { # file changed
            write-host "Teams config v$($i): Exiting Teams, Saving settings, Restarting Teams"
            # Terminate Teams Process in order to save file
            $app = @(Get-Process $procname -ErrorAction SilentlyContinue)
            if ($app)
            { # app is running
                $app_path = $app | Select-Object -ExpandProperty Path
                $app | Stop-Process -Force 
            } # app is running
            [System.IO.File]::WriteAllLines($TeamsConfigFile,$FileContent) # writes UTF8 file
            if ($app)
            { # restart
                if ($i -eq 1)
                { # v1
                    Start-Process -File $env:LOCALAPPDATA\Microsoft\Teams\Update.exe -ArgumentList '--processStart "Teams.exe"'
                }
                else
                { # velse
                    $app_path | ForEach-Object {Start-Process -FilePath $_}
                }
            } # restart 
        } # file changed
    } # File found
    else
    { # File not found
        write-host "Teams config v$($i): no file found"
    } # File not found
} # Each config (teams ver)
write-host "Teams Settings:Done"
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}