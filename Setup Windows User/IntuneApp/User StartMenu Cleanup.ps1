###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
Param ## provide a comma separated list of switches
	(
	[string] $mode = "manual" #auto
	)
$mode_auto = ($mode -eq "auto")
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
##$Globals=@{}
##$Globals.Add("Var1","Default")
##$Globals.Add("Var2","Default")
##$Globals=GlobalsLoad $Globals $scriptXML $false

$OS= Get-OSVersion

Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host "Windows Start Menu cleanup"
Write-Host ""
Write-Host "- Pin/Unpin Apps"
Write-Host ""
Write-Host "-----------------------------------------------------------------------------"

##If (-not(IsAdmin))
##    {
##    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
##    }
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}

#####
Write-Host "- (Win 10) Pin/Unpin Apps"
if ($os[1] -eq "Win 10")
    {
    ############### Useful commands
    ## Get a list of all apps
    ## AppNameVerb 

    ## AppNameVerb "Word 2016"
    ## AppNameVerb "Word 2016" "Unpin from Start"
    ##Write-Host (AppNameVerb "Word 2016" "Pin to Start")  ## Stuff above is better b/c it is version independent
    ##Write-Host (AppNameVerb "Excel 2016" "Pin to Start")
    ##Write-Host (AppNameVerb "Outlook 2016" "Pin to Start")
    ##Write-Host (AppNameVerb "Powerpoint 2016" "Pin to Start")

    # 6f22b67c-228d-89de-29a5-5ab1fbec5718US
    # {"ProductId":"9WZDNCRFHX52","SkuId":"0010","PackageFamilyName":
    # "Microsoft.NetworkSpeedTest_8wekyb3d8bbwe","ProductTitle":"Network Speed Test","WuCategoryId":"700659b6-f843-4878-ae6e-5e9f72d4eb58"}

    ################################# Unpin things: START
    Write-Host "- UnPin Apps"
    Write-Host (AppNameVerb "Adobe Photoshop Express" "Unpin from Start")
    Write-Host (AppNameVerb "Age of Empires:Castle Seige" "Unpin from Start")
    Write-Host (AppNameVerb "Alarms & Clock" "Unpin from Start")
    Write-Host (AppNameVerb "Calculator" "Unpin from Start")
    Write-Host (AppNameVerb "Calendar" "Unpin from Start")
    Write-Host (AppNameVerb "Code Writer" "Unpin from Start")
    Write-Host (AppNameVerb "Cortana" "Unpin from Start")
    Write-Host (AppNameVerb "Create USB Recovery" "Unpin from Start")
    Write-Host (AppNameVerb "Duolingo" "Unpin from Start")
    Write-Host (AppNameVerb "Eclipse Manager" "Unpin from Start")
    Write-Host (AppNameVerb "FarmVille 2 : Country Escape" "Unpin from Start")
    Write-Host (AppNameVerb "Flipboard" "Unpin from Start")
    Write-Host (AppNameVerb "Fresh Paint" "Unpin from Start")
    Write-Host (AppNameVerb "Get Office" "Unpin from Start")
    Write-Host (AppNameVerb "Groove Music" "Unpin from Start")
    Write-Host (AppNameVerb "Mail" "Unpin from Start")
    Write-Host (AppNameVerb "Maps" "Unpin from Start")
    Write-Host (AppNameVerb "Microsoft Power BI" "Unpin from Start")
    Write-Host (AppNameVerb "Microsoft Solitaire Collection" "Unpin from Start")
	Write-Host (AppNameVerb "Microsoft Store" "Unpin from Start")
    Write-Host (AppNameVerb "Movies & TV" "Unpin from Start")
    Write-Host (AppNameVerb "Netflix" "Unpin from Start")
    Write-Host (AppNameVerb "Network Speed Test" "Unpin from Start")
    Write-Host (AppNameVerb "OneNote" "Unpin from Start")
    Write-Host (AppNameVerb "Pandora" "Unpin from Start")
	Write-Host (AppNameVerb "Paint 3D" "Unpin from Start")
    Write-Host (AppNameVerb "People" "Unpin from Start")
    Write-Host (AppNameVerb "Phone Companion" "Unpin from Start")
    Write-Host (AppNameVerb "Photos" "Unpin from Start")
    Write-Host (AppNameVerb "PicsArt" "Unpin from Start")
    Write-Host (AppNameVerb "Remote Desktop" "Unpin from Start")
    Write-Host (AppNameVerb "Skype Preview" "Unpin from Start")
    Write-Host (AppNameVerb "Skype video" "Unpin from Start")
    Write-Host (AppNameVerb "Store" "Unpin from Start")
    Write-Host (AppNameVerb "Store" "Unpin from taskbar")
    Write-Host (AppNameVerb "SupportAssist" "Unpin from Start")
    Write-Host (AppNameVerb "Sway" "Unpin from Start")
    Write-Host (AppNameVerb "Translator" "Unpin from Start")
    Write-Host (AppNameVerb "Twitter" "Unpin from Start")
    Write-Host (AppNameVerb "Wunderlist" "Unpin from Start")
    Write-Host (AppNameVerb "Xbox" "Unpin from Start")
    ################################# Unpin things: END
    
    
    ################################# Pin things: START
    Write-Host "- Pin Apps"
    ## Office Apps
    $PathtoExe = PathtoExe "winword.exe"
    If (Test-Path $PathtoExe){Write-Host (AppVerb $PathtoExe "Pin")} else {Write-Host "[EXE NOT FOUND] $PathtoExe" }
    $PathtoExe = PathtoExe "excel.exe"
    If (Test-Path $PathtoExe){Write-Host (AppVerb $PathtoExe "Pin")} else {Write-Host "[EXE NOT FOUND] $PathtoExe" }
    $PathtoExe = PathtoExe "outlook.exe"
    If (Test-Path $PathtoExe){Write-Host (AppVerb $PathtoExe "Pin")} else {Write-Host "[EXE NOT FOUND] $PathtoExe" }
    $PathtoExe = PathtoExe "powerpnt.exe"
    If (Test-Path $PathtoExe){Write-Host (AppVerb $PathtoExe "Pin")} else {Write-Host "[EXE NOT FOUND] $PathtoExe" }

    ## IE
    $PathtoExe = PathtoExe "IEXPLORE.EXE"
    If (Test-Path $PathtoExe){Write-Host (AppVerb $PathtoExe "Pin")} else {Write-Host "[EXE NOT FOUND] $PathtoExe" }
    $PathtoExe = PathtoExe "Chrome.exe"
    If (Test-Path $PathtoExe){Write-Host (AppVerb $PathtoExe "Pin")} else {Write-Host "[EXE NOT FOUND] $PathtoExe" }

    ## Misc
    $PathtoExe="C:\Program Files (x86)\Spark\Spark.exe"
    If (Test-Path $PathtoExe){Write-Host (AppVerb $PathtoExe "Pin")} else {Write-Host "[EXE NOT FOUND] $PathtoExe" }
    ##Write-Host (AppNameVerb "Money" "Pin to Start")
    ##Write-Host (AppNameVerb "Sports" "Pin to Start")
    Write-Host (AppNameVerb "News" "Pin to Start")
    Write-Host (AppNameVerb "Weather" "Pin to Start")
    Write-Host (AppNameVerb "This PC" "Pin to Start")
    Write-Host (AppNameVerb "This PC" "Pin to Taskbar")
    ################################# Pin things: END
    }
if ($os[1] -eq "Win 11")
    {
    ############### Useful commands
    ## Get a list of all apps
    ## AppNameVerb 

    ## AppNameVerb "Word 2016"
    ## AppNameVerb "Word 2016" "Unpin from Start"
    ##Write-Host (AppNameVerb "Word 2016" "Pin to Start")  ## Stuff above is better b/c it is version independent
    ##Write-Host (AppNameVerb "Excel 2016" "Pin to Start")
    ##Write-Host (AppNameVerb "Outlook 2016" "Pin to Start")
    ##Write-Host (AppNameVerb "Powerpoint 2016" "Pin to Start")

    # 6f22b67c-228d-89de-29a5-5ab1fbec5718US
    # {"ProductId":"9WZDNCRFHX52","SkuId":"0010","PackageFamilyName":
    # "Microsoft.NetworkSpeedTest_8wekyb3d8bbwe","ProductTitle":"Network Speed Test","WuCategoryId":"700659b6-f843-4878-ae6e-5e9f72d4eb58"}

    ################################# Unpin things: START
    Write-Host "- UnPin Apps"
    Write-Host (AppNameVerb "Microsoft Store" "Unpin from Taskbar")
    ################################# Unpin things: END
    }

#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"

if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}