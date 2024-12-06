###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main 
Param ## provide a comma separated list of switches
	(
	[switch] $quiet
    ,[switch] $ReturnTranscript
	)

#################### Transcript Open
$Transcript = [System.IO.Path]::GetTempFileName()               
Start-Transcript -path $Transcript | Out-Null
#################### Transcript Open

### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-output "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
$OS= Get-OSVersion

Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 

Write-Output "Teams Settings:Start"
$File_config="$ENV:APPDATA\Microsoft\Teams\desktop-config.json"
if (Test-Path $File_config -PathType Leaf)
{ # File found
    # Get Teams Configuration
    $FileContent=Get-Content -Path "$ENV:APPDATA\Microsoft\Teams\desktop-config.json"
    $Filechanged=$false
    $settings=@()
    ###
    $settings+= [pscustomobject]@{option="openAtLogin"   ;bad="false";good="true"} #open automatically at user login $true or $false
    $settings+= [pscustomobject]@{option="openAsHidden"  ;bad="false";good="true"} #open in the background Hidden $true or $false
    $settings+= [pscustomobject]@{option="runningOnClose";bad="false";good="true"} #running on Taskbar $true or $false
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
            Write-Output "$($setting.option)=$($setting.good): Updated from $($setting.bad)"
            $Filechanged=$true
        }
        else
        {
            Write-Output "$($setting.option)=$($setting.good): Already OK"
        }
    } # Each setting
    if ($Filechanged)
    {
        Write-Output "Exiting Teams and saving settings"
        # Terminate Teams Process in order to save file
        $app = Get-Process Teams -ErrorAction SilentlyContinue
        if ($app) {$app | Stop-Process -Force }
        [System.IO.File]::WriteAllLines($File_config,$FileContent) # writes UTF8 file
        if ($app) {Start-Process -File $env:LOCALAPPDATA\Microsoft\Teams\Update.exe -ArgumentList '--processStart "Teams.exe"'}
    }
}
else
{
    Write-Output "No Teams config file found: $($File_config)"
}
Write-Output "Teams Settings:Done"
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

#################### Transcript Save
Stop-Transcript | Out-Null
$date = get-date -format "yyyy-MM-dd_HH-mm-ss"
$TranscriptTarget="$(Split-Path $Transcript -Parent)\Log $($scriptBase) ps1 $($date).txt"
Move-Item $Transcript $TranscriptTarget -Force #Rename in the temp folder
If($ReturnTranscript) {Get-Content $TranscriptTarget;Remove-Item $TranscriptTarget -Force} #Send transcript to output (includes write-host)
Else {Write-Host "Logged to: $($TranscriptTarget)"}
#################### Transcript Save

if ($quiet) {PauseTimed -quiet} else {PauseTimed}