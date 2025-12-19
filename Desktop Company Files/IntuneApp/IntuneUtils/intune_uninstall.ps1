#################### APPSPUBLISH_TEMPLATE.PS1 FILE
#
# THIS IS THE APPSPUBLISH_TEMPLATE.PS1 FILE. DO NOT EDIT THIS CODE
# THIS CONTAINS THE MASTER COPY OF THE MANAGED CODE THAT GETS INJECTED INTO THE 4 INTUNE PS1 FILES FOR ALL INTUNEAPPS
#
# This code is not intended to be run directly, it is injected into the 4 Intune scripts 
# Use AppsPublish.ps1 to inject the managed region below
# 
# This is because, due to intune requirements, 2 of the scripts* must run stand-alone and can't read values from an external file.
#
# Added by         : IntuneApp\AppsPublish.ps1
#                  : IntuneApp\AppsPublish_Template.ps1 (contains the master copy of injected managed region)
#
# Injected to these 4 files
#                  : intune_install.ps1
#                  : intune_uninstall.ps1
#                  : intune_detection.ps1*
#                  : intune_requirements.ps1*
#
# IntuneApp Logs go here             : C:\IntuneApp\Logs_App-Ver.txt
# IntuneApp CSV file is updated here : C:\IntuneApp\IntuneApp.csv (Install/Uninstall/Detect)
#
# (Search for IntuneAppFunction to find start of debugging region.)
################### Managed Region Info
Param
(
    [switch] $quiet=$false
    ,$LogFnParent= "" #show a calling .ps1 (install,uninstall) prefix when logging (requirements,detection)
)
#region Function Definitions
Function IntuneAppValues
{
    # These values are replaced by AppsPublish.ps1 with matching values from the CSV file
	$IntuneAppValues = @{}
    $IntuneAppValues.Add("AppName","Desktop Company Files-v144")
    $IntuneAppValues.Add("AppInstaller","ps1")
    $IntuneAppValues.Add("AppInstallName","Desktop Company Files.ps1")
    $IntuneAppValues.Add("AppInstallArgs","ARGS:-mode auto")
    $IntuneAppValues.Add("AppUninstallName","")
    $IntuneAppValues.Add("AppUninstallVersion","101")
    $IntuneAppValues.Add("AppUninstallProcess","")
    $IntuneAppValues.Add("SystemOrUser","System")
    $IntuneAppValues.Add("Function","intune_uninstall.ps1")
    $IntuneAppValues.Add("LogFolder","C:\IntuneApp")
    $IntuneAppValues.Add("AppVar1","")
    $IntuneAppValues.Add("AppVar2","")
    $IntuneAppValues.Add("AppVar3","")
    $IntuneAppValues.Add("AppVar4","")
    $IntuneAppValues.Add("AppVar5","")
    Return $IntuneAppValues
}
Function IntuneLog ($line, $quiet=$false,$appname="",$logfolder="",$appfunction="")
{
    if ($IntuneApp.Function -eq "AppsPublish_Template.ps1") {return} # debug mode is active
    $scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
    $scriptName     = Split-Path -Path $scriptFullname -Leaf
    ## Load IntuneApp values if they aren't already loaded
    if ($null -eq $IntuneApp)   {$IntuneApp=IntuneAppValues}
    if ($logfolder -eq "")      {$logfolder=$IntuneApp.LogFolder}
    if ($logfolder -eq "<<IntuneLogFolder>>") {$logfolder="C:\IntuneApp"} # It's still the template value, hardcode this until it gets published to an org-based value
    if ($appname -eq "")        {$IntuneAppNameVer=$IntuneApp.AppName} else {$IntuneAppNameVer=$appName} # $IntuneApp.AppName is of the form AAAA-vVVVV
    if ($appfunction -eq "")    {$IntuneFunction=$IntuneApp.Function} else {$IntuneFunction=$appfunction}
    if ($line -eq "--- Start ---")
    { # Adjust Start line with special contents
        $pshostname = (get-host).Name
        $psversion = $PSVersionTable.PSVersion.tostring()
        $line = "$($line)  [scriptName:$($scriptName) username:$($env:USERNAME) PSversion:$($psversion) PSEdition:$($PSEdition) PSHostname:$($pshostname)]"
    }
    if ($LogFnParent)
    { # Set log function name to a prefix
        $IntuneFunction="$($LogFnParent) ($($IntuneFunction))"
    }
    $logfolder = "$($logfolder)\v2"
    # split IntuneAppNameVer(AAAA-vVVVV) into IntuneAppName (AAAA) and IntuneAppVer VVVV)
    $find = $IntuneAppNameVer.ToLower().LastIndexOf("-v")
    if ($find -eq -1) {
        $IntuneAppName = $IntuneAppNameVer
        $IntuneAppVer = "100"
    }
    else {
        $IntuneAppName = $IntuneAppNameVer.Substring(0,$find)
        $IntuneAppVer  = $IntuneAppNameVer.Substring($find+2)
    }
    # Create a line to output
    $dt=Get-Date -format "yyyy-MM-dd_HH:mm:ss"
    $logline="$($dt) [$($IntuneAppNameVer)] $($IntuneFunction): $($line)"
    # Write to host
    if (-not ($scriptName.endswith("_1.ps1")))
    { # not being called by intune service
        Write-Host $logline -ForegroundColor DarkYellow
    }
    # Create log folder if needed
    try {
        $lf_obj = New-Item -ItemType Directory -Force -Path $logfolder
    }
    catch {
        $lf_obj = $null
    }
    If (-not $lf_obj.FullName -eq "")
    { # logfolder exists
        # delete logfile if over 1MB
        $logfile = "$($logfolder)\Log_$($IntuneAppName).txt"
        if (Test-Path -Path $logfile) {if (((Get-Item $logfile).length) -gt 1MB) {Remove-Item $logfile;Add-Content $logfile "$($dt) [Log file was reset because it grew over 1MB]"}}
        if (-not (Test-Path -Path $logfile)) {Add-Content $logfile "$($dt) [Log file initialized - will reset if it grows over 1MB]"} # 1st line has info about logfile itself
        # append to logfile
        Add-Content $logfile $logline
    } # logfolder exists
}
Function IntuneAppsCSV ($mode="GetStatus",$appnamever="",$setstatus="", $setdescription="",$systemoruser="system",$logfolder="")
{ # Returns and sets information in the IntuneApps.csv file (which keeps track of all the apps on a PC)
    <#
    $approw = IntuneAppsCSV -mode "GetStatus" -appnamever $IntuneApp.AppName -setstatus "" -setdescription "" -systemoruser $IntuneApp.SystemorUser -logfolder $IntuneApp.LogFolder
    -----------------
	mode = GetStatus,SetStatus,setDescription
    -----------------
    GetStatus - Returns status of App (Returns a row object)
    SetStatus - Sets status of App to $setstatus (updates ver to setverupdates the description to include "was v10x Installed")
    SetDescription - Updates the description (setdescription input is ignored by other modes)
    Note: appname is assumed to be in the form: Appname-v100 
    Note: if missing, a row is added with status Missing
    -----------------
    status
    -----------------
    Installed
    Detected
    Missing
    Uninstalled
    Outofdate
    -----------------    
    Intune:install   Setstatus Installed
    Intune:uninstall Setstatus Uninstalled
    Intune:detect    GetStatus ver above or equal minver and Installed or Detected (detec)  below minver OutofDate, missing missing
      SetStatus Detected
    #>
    #if ($null -eq $IntuneApp) {$IntuneApp=IntuneAppValues}
    if ($logfolder -in "","<<IntuneLogFolder>>") {$logfolder="C:\IntuneApp"} # It's still the template value, hardcode this until it gets published to an org-based value
    $csvAppsfile="$($logfolder)\v2\IntuneApps.csv"
    # split IntuneAppNameVer(AAAA-vVVVV) into IntuneAppName (AAAA) and IntuneAppVer VVVV)
    $find = $appnamever.ToLower().LastIndexOf("-v")
    if ($find -eq -1) {
        $AppName = $appnamever
        $AppVer = "1"
    }
    else {
        $AppName = $appnamever.Substring(0,$find)
        $AppVer  = $appnamever.Substring($find+2)
    }
    If ($AppVer -eq "")
        {$AppVer = "1"}
    ## create empty csv if needed with the column headings
    if (-not (Test-Path -Path $csvAppsfile)) {Add-Content $csvAppsfile "AppName,AppVer,Username,Status,Description"}
    ## import from csv
    $csvApps = @(Import-Csv $csvAppsfile)
    $bChangeMade = $false
    $bNewApp = $false
    #Systemoruser
    if ($systemoruser -eq "system") {
        $username = "system"}
    else{
        $username = $env:USERNAME}
    #Retrieve an approw
    $Matchrows = @()
    $Matchrows += $csvApps | Where-Object AppName -eq $AppName | Where-Object Username -eq $username
    if ($Matchrows.Count -gt 1)
    { # remove dupes
        ForEach ($Matchrow in $Matchrows[0..($Matchrows.Length-2)])
        { # mark row for deletion
            $Matchrow.AppName = "TO_DELETE"
            $bChangeMade = $true
        }
        $approw = $Matchrow[$Matchrows.Length-1]
    } # remove dupes
    elseif ($Matchrows.Count -eq 0)
    { # insert a missing row
        $newrowstatus="Missing"
        #region Upgrade from old CSV
        $OldInfo=""
        $csvAppsfileOld="$($logfolder)\IntuneApps.csv"
        if (Test-Path -Path $csvAppsfileOld)
        {## import from old csv
            $csvAppsOld = @(Import-Csv $csvAppsfileOld)
			$csvAppsOld = @($csvAppsOld | Select-Object *,@{Name='App';Expression={($_.AppName -Split "-v")[0]}},@{Name='Ver';Expression={[int]($_.AppName -Split "-v")[1]}})
            $MatchrowsOld = @()
            $MatchrowsOld += $csvAppsOld | Where-Object {$_.App -eq $AppName -and $_.AppValue -eq "Installed"} | Sort-Object Ver -Descending
            if ($MatchrowsOld.Count -gt 0) { # choose highest ver of matches and transfer           
				$newrowstatus="Installed"
				$OldInfo= " [transfer from old CSV:$($MatchrowsOld[0].AppName) $($MatchrowsOld[0].Description)]"
				$Appver =$MatchrowsOld[0].Ver
            } # found old row
        }## import from old csv
        #endregion Upgrade from old CSV
        $approw = [Ordered] @{
            "AppName"     = $AppName
            "AppVer"      = $AppVer
            "Username"    = $Username
            "Status"      = $newrowstatus
            "Description" = "v$($AppVer) Marked $($newrowstatus) on $(Get-Date -format "yyyy-MM-dd") by $($env:USERNAME)$($OldInfo)"
            }
        $csvApps += New-Object -Property $approw -TypeName PSObject
        $approw = $csvApps | Where-Object AppName -eq $AppName # retrieve the newly inserted row
        $bChangeMade = $true
        $bNewApp = $true
    } # insert a missing row
    else
    { # return the match row
        $approw = $Matchrows[0]
    } # return the match row
    # which mode
    If ($mode -eq "GetStatus")
    { # GetStatus
        # $approw.Status
    } # GetStatus
    ElseIf ($mode -eq "SetStatus")
    { # SetStatus
        If ($bNewApp)
        { # new
            $approw.Status = $setstatus
            $approw.Description = "v$($AppVer) $($setstatus) on $(Get-Date -format "yyyy-MM-dd") by $($env:USERNAME)"
            $bChangeMade=$true
        } # new
        Else
        { # not new 
            $Changes = @()
            if ($approw.Username -ne $Username) {
                $Changes+="Username changed from [$($approw.Username)] to [$($Username)]"
                $approw.Username = $Username
                $bChangeMade=$true
            }
            if ($approw.Status -ne $setstatus) {
                # Once it hits these statuses, don't change without an explicit Install or Uninstall
                $StatusFromToProhibit = @()
                $StatusFromToProhibit += "Installed To Detected"
                $StatusFromToProhibit += "Detected To Installed"
                $StatusFromToProhibit += "Uninstalled To Missing"
                $StatusFromToProhibit += "Missing To Uninstalled"
                # if it's not prohibited, change it
                $StatusFromTo = "$($approw.Status) To $($setstatus)"
                if ($StatusFromTo -notin $StatusFromToProhibit) {
                    $Changes+="Status changed from [$($approw.Status)] to [$($setstatus)]"
                    $approw.Status = $setstatus
                    $bChangeMade=$true
                }
            }
            if ($approw.AppVer -ne $AppVer) {
                #$Changes+="AppVer changed from [$($approw.AppVer)] to [$($AppVer)]"
                $approw.AppVer = $AppVer
                $bChangeMade=$true
            }
            if ($Changes.count -gt 0)
            { # summarize changes during SetStatus
                $approw.Description = "v$($AppVer) $($Changes -join ", ") on $(Get-Date -format "yyyy-MM-dd") by $($env:USERNAME)"
            }
        } # not new 
    } # SetStatus
    ElseIf ($mode -eq "SetDescription")
    { # just update description
        if ($approw.Description -ne $setdescription) {
            $approw.Description = $setdescription
            $bChangeMade=$true
        }
    }
    If ($bChangeMade)
    {
        $csvApps | Where-Object AppName -ne "TO_DELETE"| Sort-Object AppName | Export-Csv -Encoding UTF8 -Path $csvAppsfile -NoTypeInformation
    }
    Return $approw
}
Function WriteLog ($Line)
{
    # Injection code converts Write-Host to WriteLog because Intune Management Engine sends write-host to stdout too - which is unexpected
    IntuneLog "WriteLog: $($Line)"
}
Function FindInstall ($installer_path,$installer)
{
    <#
    Usage:
    $intReturnCode,$strReturnMsg,$strInstaller = FindInstall -installer_path (Split-Path -Path $scriptDir -Parent) -installer $IntuneApp.AppInstallName
    #>
    $intReturnCode = 0
    $strReturnMsg = ""
    $strInstaller = ""
    # search for installer
    $installer      = @(Get-ChildItem -Path $installer_path -File -Recurse -Filter $installer)
    if ($installer.Count -eq 0) {
        $intReturnCode = 10
        $strReturnMsg= "Err: Couldn't find installer: $($installer) (check .csv for 'AppInstallName')"
        $strInstaller = ""
    }
    ElseIf ($installer.Count -gt 1) {
        $intReturnCode = 20
        $strReturnMsg= "Err: Multiple installers found for: $($installer) ($($installer.Name -join ", "))"
        $strInstaller = ""
    }
    else {
        $intReturnCode = 0
        $strReturnMsg= "OK: Found installer ($($installer.Name))"
        $strInstaller = $installer[0].FullName
    }
    Return $intReturnCode,$strReturnMsg,$strInstaller
}
Function IntuneAppValuesFromCSV ($intune_settings_csvpath , $IntuneApp)
{
    <# Example usage
    #>
    $iav_csv = Import-Csv $intune_settings_csvpath
    # create object 
    $ia_new = @{}
    foreach ($iav in $iav_csv)
    { # get csv values
        if ($iav.Name -eq "AppName")
        { # AppName requires the version too
            $AppName = $iav.Value
            $AppVer = ($iav_csv | Where-Object Name -EQ AppVersion).Value
            if ($AppVer) {$AppName += "-v$($AppVer)"}
            $ia_new.Add("AppName",$AppName)

        } # AppName requires the version too
        ElseIf ($iav.Name -ne "AppVersion")
        { # Everything else (ignore Appversion)
            $ia_new.Add($iav.Name,$iav.Value)
        }
    } # get csv values
    foreach ($iav in $IntuneApp.GetEnumerator())
    { # get old values
        if ($null -eq $ia_new.($iav.Name))
        { # it was missing, add it
            $ia_new.Add($iav.Name,$iav.Value)
        }
    } # get old values
    Return $ia_new
}
Function IsAdmin() 
{
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    $IsAdmin
}
Function ElevateViaRelaunch()
{
    # Will relaunch Powershell in an elevated session (if needed)
    if (IsAdmin) { Return 0} # not needed - just return
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
    $argumentlist ="-File `"$($scriptFullname)`" $($argsString)"
    # rebuild the argument list
    IntuneLog "Restarting as elevated powershell.exe -File `"$($scriptname)`" $($argsString)"
    Try
    {
        # restart this ps1 elevated (note: if debugging, make sure debugger is running as admin. otherwise this code escapes debugging)
        Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
    }
    Catch {
        $exitcode=110; IntuneLog "Err $exitcode : This script requires Administrator priviledges, re-run with elevation"
        Throw "Failed to start PowerShell elevated"
    }
    Exit
}
function StopProcess ($ProcSpec="")
{ # Stop a running process
    if ($ProcSpec -eq "") {return}
    #Kill any running apps, 1 by 1 until no more (sometimes killing one kills another one automatically)
    While (Get-Process -Name $IntuneApp.AppUninstallProcess -ErrorAction SilentlyContinue)
    {
        $proc=@(Get-Process -Name $IntuneApp.AppUninstallProcess)
        IntuneLog ("Stopping process: $($proc[0].name) [$($proc[0].ID)]")
        Stop-Process -ID $proc.ID -Force
        Start-Sleep -Seconds 1
    }
}
Function GetVersionFromString($Version)
{
    # Safely turns a string into a version
    # If it's already a version return it
    # If it's a string with a whole number append .0 to make it a usable version
    If ($null -eq $Version) {Return [version]"0.0.0.0"}
    If (($Version).GetType().Name -eq "Version")
    {
        Return $Version
    }
    $strVersion = [string]$Version # convert to string
    if ($strVersion -eq "") {$strVersion="0.0.0.0"} # empty so 0.0
    if (-1 -eq $strVersion.IndexOf(".")) {$strVersion+=".0"} # no dot so append a .0
    try {
        $retVersion = [version]$strVersion
    }
    catch {
        $retVersion = [version]"0.0.0.0"
    }
    Return $retVersion
}
Function CommandLineSplit ($line)
{
	## Splits a commandline [1 string] into a exe path and an argument list [2 string].
    # [in] MSIExec.exe sam tom ann  [out] MSIExec.exe , sam tom ann
    # $exeargs = CommandLineSplit "msiexec.exe /I {550E322B-82B7-46E3-863A-14D8DB14AD54}"
    # write-host $exeargs[0] $exeargs[1]
    # Here are the command line types that can be dealt with 
    #
    #$line = 'C:\ProgramFiles\LastPass\lastpass_uninstall.com'
    #$line = 'msiexec /qb /x {3521BDBD-D453-5D9F-AA55-44B75D214629}'
    #$line = 'msiexec.exe /I {550E322B-82B7-46E3-863A-14D8DB14AD54}'
    #$line = '"c:\my path\test.exe'
    #$line = '"c:\my path\test.exe" /arg1 /arg2'
    #
    $return_exe= ""
    $return_args = ""
    $quote = ""
    if ($line.startswith("""")) {$quote=""""}
    if ($line.startswith("'")) {$quote="'"}
    ## did we find a quote of either type
    if ($quote -eq "")  ## not a quoted string
        {
        $exepos=$line.IndexOf(".exe")
        if($exepos -eq -1) 
            #non quoted and no .exe , just find space
            {
            $spacepos=$line.IndexOf(" ")
            if($spacepos -eq -1)
                {#non quoted and no .exe,no space: no args
                #C:\ProgramFiles\LastPass\lastpass_uninstall.com
                $return_exe= $line
                $return_args=""
                }
            else
                {#non quoted and no .exe,with a space: split on space
                #msiexec /qb /x {3521BDBD-D453-5D9F-AA55-44B75D214629}  
                #javaw -jar "C:\Program Files (x86)\Mimo\MimoUninstaller.jar" -f -x 
                $return_exe= $line.Substring(0,$spacepos)
                $return_args=$line.Substring($spacepos+1)
                }
            }
        else
            {#non quoted with .exe , split there
            # C:\Program Files\Realtek\Audio\HDA\RtlUpd64.exe -r -m -nrg2709                                            
            # msiexec.exe /I {550E322B-82B7-46E3-863A-14D8DB14AD54} : 2nd most normal case
            $return_exe= $line.Substring(0,$exepos+4)
            $return_args=$line.Substring($exepos+4)
            }
        }
    else  ## has a quote, find closing quote and strip
        {
        $quote2=$line.IndexOf($quote,1)
        if($quote2 -eq -1)
            { # no close quote, no args: likely a publisher error
            #"c:\my path\test.exe
            $return_exe= $line.Substring(1)
            $return_args=""
            }
        else
            { # strip quotes and the rest are args: most normal case
            #"c:\my path\test.exe" /arg1 /arg2
            $return_exe= $line.Substring(1,$quote2-1)
            # check if args exist and return them
            if ($line.length -gt $quote2+1)
                {
                $return_args=$line.Substring($quote2+2)
                }
            }
        }
    #Return values, removing any spaces in front or at end
    $return_exe.trim()
    $return_args.Trim()
}
Function ArgStringToArgSplat ($strArgs)
{
    <#
    Replaces a string containing ps1 args with a hashtable of named arguments
    If the first char is not a - then it's assumed no named arguments are needed
    (tested with named arguments only)
    Usage:
    $ps1args_unnamed, $ps1args_named = ArgStringToArgSplat $ps1args
    $cmd_out = & $ps1 $ps1args_unnamed @ps1args_named 

    -myname john smith -yourname jones -quiet
    "this is a path to a file.csv"
    -file1 "this is a path.csv" -file2 "another path.csv"
    #>    
    $ps1args_ht = @{}
    if ($null -eq $strArgs) {Return $null, $null}
    # split by -
    if (-not $ps1args.StartsWith("-")) {$ps1args="-UNNAMED_PORTION "+$ps1args}
    $ps1args_arr = $ps1args.Split("-") | ForEach-Object{if ($_){"-$($_)"}}
    #
    ForEach ($ps1arg_arr in $ps1args_arr)
    {
        $argnam = $ps1arg_arr.Substring(1).split(" ")[0]
        $argval = ($ps1arg_arr.Substring(1).split(" ")| Select-Object -Skip 1) -join " "
        ##
        $argval = $argval.Trim()
        if ($argnam -eq "UNNAMED_PORTION")
        {
            $argval = $argval.trim('"')
            $argunnamed=$argval
        }
        else
        {
            # argval adjustments# argval adjustments
            $argval = $argval.trim('"')
            if     ($argval -in ('','true','$true'))        {$argval=$true } # fix switch arg
            elseif ($argval -in ('false','$false'))         {$argval=$false } 
            $ps1args_ht[$argnam]=$argval
        }
    }
    Return $argunnamed, $ps1args_ht
}
Function TranscriptRemoveHeaderFooter ($TsFile)
{
    # Reads transcript file and removes header and footer
    if (-not (Test-Path $TsFile -PathType Leaf)) {Return}
    $TsLines = Get-Content $TsFile
    $header_delim = "**********************"
    $in_body=$true # flips with delim. if true, copy content
    $TsLines_new =@() # new file starts empty
    ForEach ($line in $TsLines)
    {
        if ($line.Startswith($header_delim))
        {$in_body = -not $in_body}  # flip in and out of body/header
        else
        { # not a header
            if ($in_body)
            {$TsLines_new+=$line}
        }
    }
    [System.IO.File]::WriteAllLines($TsFile,$TsLines_new) # writes UTF8 file
}
Function PS1WithLogging ($ps1, $ps1args="")
{
    # calls ps1. logs transcript (write-host)
    # returns output of ps1 (return value)
    #
    # Transcript Start
    $Transcript = [System.IO.Path]::GetTempFileName()
    Start-Transcript -path $Transcript | Out-Null
    # fix up args
    $ps1args_unnamed, $ps1args_named = ArgStringToArgSplat $ps1args
    # call ps1
    $global:LASTEXITCODE = 0 # clear any exit codes
    $ps1_out = & $ps1 $ps1args_unnamed @ps1args_named
    $ps1_exit = $LASTEXITCODE
    # Transcript Stop
    Stop-Transcript | Out-Null
    TranscriptRemoveHeaderFooter $Transcript # trim file
    $log_trn = Get-Content -Path $Transcript
    If (Test-Path $Transcript) {Remove-Item $Transcript -Force}
    # Log results
    $LogFnParentOrig = $LogFnParent
    $LogFnParent = $IntuneApp.Function
    $ps1name = Split-Path $ps1 -Leaf
    If ($log_trn)
    {
        IntuneLog "-------- Transcript from $($ps1name)" -appfunction $ps1name
        $log_trn | ForEach-Object {IntuneLog $_ -appfunction $ps1name}
    }
    If ($ps1_out)
    {
        $ps1_out = $ps1_out | Out-String # force object to string
        If (-not $ps1_out.EndsWith("`n`r")){$ps1_out += "`n`r"} # force a newline cr at the end
        IntuneLog "-------- Output from $($ps1name)" -appfunction $ps1name
        $ps1_out | ForEach-Object {IntuneLog $_ -appfunction $ps1name}
    }
    $LogFnParent = $LogFnParentOrig
    Return $ps1_exit,$ps1_out
}
function StartProcAsJob_Function {
    # not to be called directly: called by StartProc as a ScriptBlock argument
    Param ($xcmd, $xargs)
    & $xcmd $xargs
    Write-Output "LASTEXITCODE:$($LASTEXITCODE)"
}
function StartProcAsJob {
    Param (
        $xcmd,
        $xargs,
        $TimeoutSecs = 300,
        $StopProcOnTimeout = $false,
        $ShowOutputToHost=$true
        )
    <# Usage:
    $retOutput,$retStatus,$retExitCode = StartProcAsJob "winget" "-v" -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 20 
    Write-Host "  retOutput: $($retOutput)"
    Write-Host "  retStatus: $($retStatus)"
    Write-Host "retExitCode: $($retExitCode)"
    Note: $xargs can be a string, or an array of strings expected as arguments (if quotes and spaces are involved)
    $xcmd = "winget"
    $xargs = "list","Workspot Client"
	# To test, break here and run this command:
    & $xcmd $xargs
    #>
    $retStatus = ""
    $retExitCode = 0
    $retOutput = $null
    # show header
    if ($ShowOutputToHost) {Write-Host "--- StartProcAsJob: $($xcmd) $($xargs) [Timeout: $($TimeoutSecs), StopProcOnTimeout: $($StopProcOnTimeout)]"}
    # check that xcmd exists
    if (-not (get-command $xcmd -ErrorAction Ignore))
    {
        $retStatus = "Err [JobState:<none>, Get-Command failed :$($xcmd)]"
        Return $retOutput,$retStatus,$retExitCode
    }
    # Start a job
    $job = Start-Job -Name "Powershell StartProcAsJob Function" -ScriptBlock ${Function:StartProcAsJob_Function} -ArgumentList $xcmd, $xargs
    $outindex = 0
    Do
    { #Loop while running (or timeout)
        if ($job.JobStateInfo.State -eq "Running")
        {
            if (([DateTime]::Now - $job.PSBeginTime).TotalSeconds -gt $TimeoutSecs) {
                break
            }
            Start-Sleep -Milliseconds 200 #breathe
        }
        #region show output
        $outsofar = $job.ChildJobs[0].Output
        if ($ShowOutputToHost) {$outsofar[$outindex..$outsofar.Count] | Out-Host} # show incremental lines of output
        $outindex = $outsofar.Count
        #endregion show output
    } While ($job.JobStateInfo.State -eq "Running")
    # must parse the return object contents before Remove-job deletes the object.
    $retOutput = $job.ChildJobs[0].Output | Where-Object {-not $_.StartsWith("LASTEXITCODE:")} | ForEach-Object {[string]$_}
    $retExitCodeLine = $job.ChildJobs[0].Output | Where-Object {$_.StartsWith("LASTEXITCODE:")} | ForEach-Object {[string]$_}
    # Parse exit code if a line was found
    if ($retExitCodeLine) { # convert to int
        $retExitCode = try {[int]$retExitCodeLine.Replace("LASTEXITCODE:","")} Catch {}
    }
    if ($job.state -notin "Stopped","Completed")
    {
        if ($StopProcOnTimeout)
        {
            $retStatus = "Err [JobState:$($job.state), Timeout:$($TimeoutSecs), Stopped:Yes]"
            $job | Stop-Job
        }
        else
        {
            $retStatus = "Err [JobState:$($job.state), Timeout:$($TimeoutSecs), Stopped:No - job allowed to continue]"
        }
    }
    else
    {
        $retStatus = "OK [Secs:$(([DateTime]::Now - $job.PSBeginTime).TotalSeconds)]"
        $job | Remove-job
    }
    Return $retOutput,$retStatus,$retExitCode
}
Function StartProc($command, $arguments)
{
    <# Usage
    $exitcode,$stdout,$stderr = StartProc "ping.exe" "localhost"
    #>
    IntuneLog "$($command) $($arguments)"
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $command
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false # can't capture stdout if this is true
    $pinfo.CreateNoWindow = $false
    #$pinfo.WindowStyle = ProcessWindowStyle.Normal
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $bDone=$false
    $secs_max = 600 # give it 10 mins to finish
    $secs_progress = 10 # report back every
    $i=0
    Do{
        $i+=1
        Start-Sleep 1
        $bDone=$p.HasExited
        if (-not $bDone)
        {
            if ($i -ge $secs_max) {
                IntuneLog "Gave up. [$($secs_max)s max waiting for processid $($p.id)]"
                $bDone=$true
            }
            elseif ($i % $secs_progress -eq 0) {
                IntuneLog "Waiting $($i)s...[$($secs_max)s max] for processid $($p.id)"
            }
        }
    }
    Until ($bDone)
    if ($p.HasExited)
    {
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $exitcode = $p.ExitCode
    }
    else
    {
        $stdout = ""
        $stderr = "ERR: Gave up. [$($secs_max)s max waiting for processid $($p.id)]"
        $exitcode = 99
    }
    Return $exitcode,$stdout,$stderr
}
Function ChocolateyAction ($MinChocoVer="2.0",$ChocoVerb="list",$ChocoApp="appname", $ChocoArgs="")
{
    <#
    Usage:
    $intReturnCode,$strReturnMsg = ChocolateyAction -MinChocoVer "2.2" -ChocoVerb "list" -ChocoApp "Myapp"
    #>
    $intReturnCode = 0
    $strReturnMsg = ""
    # error check minver
    If ($MinChocoVer -eq "") {$MinChocoVer="1.0"}
	if (!(Get-Command choco.exe -ErrorAction SilentlyContinue))
    { # choco command doesn't exist
        If (IsAdmin)
        {# IsAdmin
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            try {
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }
            catch {
                $intReturnCode=181
                $strReturnMsg="Err $($intReturnCode) : Chocolately is missing.  Install via https://community.chocolatey.org/install.ps1 failed"
            }
            Start-Sleep 3 # pause for a bit
            if ($intReturnCode -eq 0)
            { # check if installed
                if (!(Get-Command choco.exe -ErrorAction SilentlyContinue))
                {
                    $intReturnCode=182
                    $strReturnMsg="Err $($intReturnCode) : Chocolately was installed but the choco.exe command doesn't work"
                }
            } # check if installed
        }# IsAdmin
        else
        {# Not IsAdmin
            $intReturnCode=179;
            $strReturnMsg="Err $($intReturnCode) : Chocolately is missing.  Chocolately couldn't be installed because the process isn't an admin."
        }# Not IsAdmin
    } # choco command doesn't exist
    if ($intReturnCode -eq 0)
    { # check choco ver
        $chocover = (choco)[0].Replace("Chocolatey v","")
        if ((GetVersionFromString $chocover) -lt (GetVersionFromString $MinChocoVer))
        { # version is low
            If (IsAdmin)
            { # try to upgrade
                # upgrade
                $choco_command="upgrade","chocolatey","--yes"
                $proc_return,$retStatus,$exitcode = StartProcAsJob "choco" $choco_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
                #Start-Sleep 2 # wait a bit
                if ($proc_return -like "*is the latest*")
                { # already at the latest
                    $intReturnCode=0
                    $strReturnMsg="OK: Chocolately upgrade requested from v$($chocover) to v$($MinChocoVer). But Chocolately is already at the latest available version so it will allowed."
                } # already at the latest
                else
                { # check version after upgrade
                    $chocoverprior = $chocover
                    $chocover = (choco)[0].Replace("Chocolatey v","")
                    if ((GetVersionFromString $chocover) -lt (GetVersionFromString $MinChocoVer))
                    { # still under
                        $intReturnCode=0
                        $strReturnMsg="OK: Chocolately upgrade attempted from v$($chocoverprior) to v$($chocover), but Chocolately is still less than v$($MinChocoVer). It will be allowed."
                    } # still under
                    else
                    { # ver ok
                        $intReturnCode=0
                        $strReturnMsg="OK: Chocolately upgraded from v$($chocoverprior) to v$($chocover)."
                    } # ver ok 
                } # check version after upgrade
            } # try to upgrade
            else
            { # can't upgrade
                $intReturnCode=178;
                IntuneLog "Err $($intReturnCode) : Chocolately $((choco)[0]) is below required v$($MinChocoVer). Chocolately can't be upgraded because the process isn't an admin."
            } # can't upgrade
        } # version is low
    } # check choco ver
    if ($intReturnCode -eq 0)
    { # chocoverb
        $chocoargs_arr=@($ChocoArgs -split " ")
        if ($chocoverb -eq "list")
        { #verb:list
            $choco_command="list"
            $proc_return,$retStatus,$exitcode = StartProcAsJob "choco" $choco_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            if ($proc_return -like "*$($ChocoApp)*")
            {
                $intReturnCode=0
                $strReturnMsg="OK $($intReturnCode): Chocolately app detected: *$($ChocoApp)* [choco $($choco_command)]"
            }
            else
            {
                $intReturnCode=99
                $strReturnMsg="ERR $($intReturnCode): Chocolately app not detected: *$($ChocoApp)* [choco $($choco_command)]"
            }
        } #verb:list
        elseif ($chocoverb -eq "install")
        {
            $choco_command="install",$ChocoApp,"-y",$chocoargs_arr
            $proc_return,$retStatus,$exitcode = StartProcAsJob "choco" $choco_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            if ($exitcode  -ne 0) {
                $intReturnCode = 185
                $strReturnMsg="ERR $($intReturnCode): Chocolately app [$($ChocoApp)] not installed. Choco err: $($exitcode) [choco $($choco_command)]"
            }
            else {
                $intReturnCode=0
                $strReturnMsg="OK $($intReturnCode): Chocolately [$($ChocoApp)] app installed. [choco $($choco_command)]"
            }
        }
        elseif ($chocoverb -eq "uninstall")
        {
            $choco_command="uninstall",$ChocoApp,"-y","-a","-x",$chocoargs_arr
            $proc_return,$retStatus,$exitcode = StartProcAsJob "choco" $choco_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            if ($exitcode  -ne 0) {
                $intReturnCode = 178
                $strReturnMsg="ERR $($intReturnCode): Chocolately app [$($ChocoApp)] not uninstalled. Choco err: $($exitcode) [choco $($choco_command)]"
            }
            else {
                $intReturnCode=0
                $strReturnMsg="OK $($intReturnCode): Chocolately [$($ChocoApp)] app uninstalled. [choco $($choco_command)]"
            }
        }
        else
        {
            $intReturnCode=182
            $strReturnMsg="Err $($intReturnCode) : Chocolately verb unhandled by this code: $($chocoverb)"
        }
        # choco verb package 
    } # chocverb
    Return $intReturnCode,$strReturnMsg
}
Function GetArchitecture
{
    $architecture = $ENV:PROCESSOR_ARCHITECTURE
    switch ($architecture) {
        "AMD64" { "x64" }
        "ARM64" { "ARM64" }
        "x86"   { "x86" }
        default { "Unknown architecture: $architecture" }
    }
}
function Get-VCRedistVersion
{
    $platform = GetArchitecture # Get OS Arch type (x64 or ARM64)
    # Function to get current VC++ Redistributable version from registry
    $regKeys = @(
        "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$platform",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\$platform"
    )
    foreach ($key in $regKeys) {
        if (Test-Path $key) {
            try {
                $ver = Get-ItemProperty -Path $key | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
                if ($ver) {
                    # Match and remove all non-digit characters at the beginning of the string
                    $cleanVer = $ver -replace '^[^0-9]+', ''
                    return [Version]$cleanVer
                }
            } catch {}
        }
    }
    return $null
}
function winget_lines_clean
{
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline)]
    [String[]]$lines
  )
if ($input.Count -gt 0) { $lines = $PSBoundParameters['Value'] = $input }
  $bInPreamble = $true
  foreach ($line in $lines) {
    if ($bInPreamble){
      if ($line -like "Name*") {
        $bInPreamble = $false
      }
    }
    if (-not $bInPreamble) {
        Write-Output $line
    }
  }
}
function winget_lines_to_obj
{
  # Note:
  #  * Accepts input only via the pipeline, either line by line, 
  #    or as a single, multi-line string.
  #  * The input is assumed to have a header line whose column names
  #    mark the start of each field
  #    * Column names are assumed to be *single words* (must not contain spaces).
  #  * The header line is assumed to be followed by a separator line
  #    (its format doesn't matter).
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)] [string] $InputObject
  )
  begin {
    Set-StrictMode -Version 1
    $lineNdx = 0
  }
  process {
    $lines = 
      if ($InputObject.Contains("`n")) { $InputObject.TrimEnd("`r", "`n") -split '\r?\n' }
      else { $InputObject }
    foreach ($line in $lines) {
      ++$lineNdx
      if ($lineNdx -eq 1) { 
        # header line
        $headerLine = $line 
      }
      elseif ($lineNdx -eq 2) { 
        # separator line
        # Get the indices where the fields start.
        $fieldStartIndices = [regex]::Matches($headerLine, '\b\S').Index
        # Calculate the field lengths.
        $fieldLengths = foreach ($i in 1..($fieldStartIndices.Count-1)) { 
          $fieldStartIndices[$i] - $fieldStartIndices[$i - 1] - 1
        }
        # Get the column names
        $colNames = foreach ($i in 0..($fieldStartIndices.Count-1)) {
          if ($i -eq $fieldStartIndices.Count-1) {
            $headerLine.Substring($fieldStartIndices[$i]).Trim()
          } else {
            $headerLine.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
          }
        } 
      }
      else {
        # data line
        $oht = [ordered] @{} # ordered helper hashtable for object constructions.
        $i = 0
        foreach ($colName in $colNames) {
          $oht[$colName] = 
            if ($fieldStartIndices[$i] -lt $line.Length) {
              if ($fieldLengths[$i] -and $fieldStartIndices[$i] + $fieldLengths[$i] -le $line.Length) {
                $line.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
              }
              else {
                $line.Substring($fieldStartIndices[$i]).Trim()
              }
            }
          ++$i
        }
        # Convert the helper hashable to an object and output it.
        [pscustomobject] $oht
      }
    }
  }
}
Function winget_init
{ # initializes global settings for winget (accepts agreements)
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() # change from IBM437/SingleByte to utf-8/Double-Byte (for global character sets to work)
  winget search dummyapp --accept-source-agreements | Out-Null  # weird way to accept agreements  
}
Function winget_verb_to_obj ($verb="list", $Appid="")
{ # converts winget list and search to powershell object array
    $wgcommand = "winget $($verb)"
    If ($Appid -ne "")
    {
        If ($Appid.contains(".")) { # id is passed
            $wgcommand += " --id $($Appid) --exact"
        }
        else { # name is passed
            $wgcommand += " --name `"$($Appid)`""
        }
    }
    $wglines = Invoke-Expression $wgcommand
    $wgobjs = @()
    $wgobjs += $wglines | winget_lines_clean  | # filter out progress-display lines
        winget_lines_to_obj          | # parse output into objects
        Sort-Object Id               | # sort by the ID property (column)
    Select-Object Name,Id,@{N='Version';E={$_.Version.Replace("> ","")}},Available,Source # Version fixup
    Return $wgobjs
}
Function winget_install
{
	if (IsAdmin)
	{ #isadmin
		# install the Microsoft Visual C++ Redistributable for Visual Studio 2015, 2017, and 2019.
        # https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170
        #
        # Define minimum required version for Visual C++ Redistributable
        $minVersion = [Version]"14.0.0.0"
        # Check current version
        $currentVersion = Get-VCRedistVersion
        if ($currentVersion -and $currentVersion -ge $minVersion) {
            $msg = "Microsoft Visual C++ Redistributable already installed (version $currentVersion)."
            [string]$result="OK - $($msg)"
        } else {
            $platform = GetArchitecture # Get OS Arch type (x64 or ARM64)
            # Set download URL and installer path
            switch ($platform) {
                "ARM64" {
                    $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.arm64.exe"
                }
                "x64" {
                    $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
                }
                default {
                    return "ERR - Unsupported architecture: $platform. Skipping Visual C++ Redistributable install."
                }
            }
            Write-Host "Installing Microsoft Visual C++ Redistributable ($platform) from ($($vcRedistUrl))..."
            # Ensure TLS 1.2 for web downloads
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $installerName = ($vcRedistUrl -split "/")[-1]
            $tempInstaller = "$env:TEMP\$installerName"
            # Download the installer
            Invoke-WebRequest -Uri $vcRedistUrl -OutFile $tempInstaller -UseBasicParsing
            # Silently install
            Start-Process -FilePath $tempInstaller -ArgumentList "/install", "/quiet", "/norestart" -Wait
            # Cleanup
            Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
            # Verify installation
            $newVersion = Get-VCRedistVersion
            if ($newVersion -and $newVersion -ge $minVersion) {
                $msg = "Successfully installed VC++ Redistributable ($platform) version $newVersion."
                [string]$result="OK - $($msg)"
            } else {
                $msg = "Installation of VC++ Redistributable failed. Please check manually."
                [string]$result="ERR - $($msg)"
            }
        }
	} #isadmin
	else
	{ #noadmin
		[string]$result="ERR - Update winget by installing Microsoft Visual C++ Redistributable failed due to non-elevation."
	} #noadmin
    return $result
}
Function winget_core ($WingetMin ="1.6")
{ # verifies existence of winget.  updates if needed.
    # if lt $WingetMin , upgrades winget
    # leave $WingetMin  blank to not upgrade winget
    # [string]$result=winget_core -minver "1.6.2721"
    $strPassInfo=""
    for ($pass = 1; $pass -le 3; $pass++)
    { # loop looking for winget
        $wgc = get-command winget -ErrorAction Ignore
        if ($wgc)
        { # has winget, check if old
            Try { # run winget
                $version = winget -v
            }
            Catch {$version="v0.0.0"} # error means v0
            if ($null -eq $version) {$version="v0.0.0"}
            if ("" -eq $version) {$version="v0.0.0"}
            $version = $version.Replace("v","")
            if (($WingetMin  -ne "") -and ((GetVersionFromString $version) -lt (GetVersionFromString $WingetMin)))
            { # update needed
				[string]$result=winget_install
                $result+="['winget -v' returned v$($version) but v$($WingetMin) or higher is needed]"
			}
            else
            { # no update needed
                [string]$result="OK - no update needed v$($version). Path:$($wgc.source)$($strPassInfo)"
                Break # Done with For loop (no other passes needed)
            } # no update needed
        } # has winget
        else
        { # no winget
            if (IsAdmin)
            { #isadmin, try 1 path fix 2 install
                If ($pass -eq 1)
                { # Pass 1 - try adding a path
                    $strPassInfo=" PassInfo:PathAdjust"
                    $ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*__8wekyb3d8bbwe"
                    if ($ResolveWingetPath)
                    { # change path to include winget.exe (for this session) to try again in for loop pass 2
                        $WingetPath = $ResolveWingetPath[-1].Path
                        $env:Path = $WingetPath + ";" + $env:Path
                    } # change path to include winget.exe (for this session) to try again in for loop pass 2    
                }
                elseif ($pass -eq 2)
                { # Pass 2 - try to install winget (on top of old version)
                    $strPassInfo=" PassInfo:WingetInstallNeeded"
					[string]$result=winget_install
                }
                else
                { # Pass 3 - give up
                    [string]$result="ERR - Needs winget and is elevated, but there's no way to install winget if the OS doesn't include it. Try searching for App Installer in the store. Pass:$($pass) User:$($env:USERNAME) Path:$($env:Path)"
                }
            } #isadmin
            else
            { #no admin
                [string]$result="ERR - Needs winget but isn't elevated. Pass:$($pass)"
                Break 
            } #no admin
        } # no winget
    } # loop twice looking for winget
    Return $result
}
Function WingetList ($WingetMin = "1.6")
{ # Returns winget list (installed apps) as objects
    <#
    Usage:
    $app_objs = WingetList
    #>
    $retObj = $null
    [string]$result=winget_core -minver $WingetMin
    If (-not $result.StartsWith("OK"))
    { # winget itself is err        
        Write-Host "Winget itself had a problem: $($result)"
    } # winget itself is err
    Else
    { # winget is OK
        winget_init # initialize winget (approve)
        $retObj = winget_verb_to_obj "list"
    } # winget is OK
    Return $retObj
}
Function WingetAction ($WingetMin = "1.6",$WingetVerb = "list", $WingetApp="appname", $SystemOrUser="System",$WingetAppMin="")
{ # winget intune actions
    <#
    Usage:
    $intReturnCode,$strReturnMsg = WingetAction -WingetMin "2.2" -WingetVerb "list" -WingetApp "Myapp"
    #>
    $intReturnCode = 0
    $strReturnMsg = ""
    # set winget scope options:--scope user,--scope machine, or nothing
    if ($SystemOrUser -eq "")
    {$strScope = ""}
    Elseif ($SystemOrUser -eq "user")
    {$strScope = " --scope $($SystemOrUser)"}
    Else # translate all else incl system to machine
    {$strScope = " --scope Machine"}
    # get version
    [string]$result=winget_core -minver $WingetMin
    If (-not $result.StartsWith("OK"))
    { # winget itself is err        
        $intReturnCode=301
        $strReturnMsg = "Winget itself had a problem: $($result)"
    } # winget itself is err
    Else
    { # winget is OK
        winget_init
        if ($Wingetverb -eq "list")
        { #verb:list
            if ($WingetApp.Contains(".")){ # exact match (by id)
                $Winget_command = "list","--id",$WingetApp,"--exact"
            }
            else { # name match
                $Winget_command = "list","--name",$WingetApp
            }
            $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            #  (https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md)
            # exitcode: -1978335212=APPINSTALLER_CLI_ERROR_NO_APPLICATIONS_FOUND
            # Any installed package found?
            $detect = $Winget_return -like "*$($WingetApp)*"
            if ($detect) 
            { # winget detected a version
                if ($WingetAppMin -eq "")
                { # detect any version
                    $intReturnCode=0
                    $strReturnMsg="OK $($intReturnCode): Winget app ($($WingetApp)) detected: $($detect) [$winget ($Winget_command)]"
                } # detect any version
                Else
                { # detect at or above min
                    $Winget_return = @(winget_verb_to_obj -verb "list" -Appid $WingetApp)
                    if (-not $Winget_return.Version)
                    { # no version from winget
                        $intReturnCode=99
                        $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) detected, but no version info from winget ($($detect)) to compare with minver ($($WingetAppMin)) [winget $($Winget_command)]"
                    }
                    else
                    { # has version from winget
                        if ($Winget_return.count -ne 1) {
                            $intReturnCode=98
                            $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) detected multiple times [winget $($Winget_command)]"
                        }
                        else {
                            $detect = $Winget_return.Version
                            if ((GetVersionFromString $Winget_return.Version) -lt (GetVersionFromString $WingetAppMin))
                            { # ver too low
                                $intReturnCode=99
                                $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) detected, but version is too low ($($detect)) compared to minver ($($WingetAppMin)) [winget $($Winget_command)]"
                            } # ver too low
                            else
                            { # ver is ok
                                $intReturnCode=0
                                $strReturnMsg="OK $($intReturnCode): Winget app ($($WingetApp)) detected ($($detect)) at or above minver ($($WingetAppMin)) [winget $($Winget_command)]"
                            } # ver is ok
                        }
                    } # has version from winget
                } # detect at or above min
            } # winget detected a version
            else
            { # winget detected nothing
                $intReturnCode=99
                $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) not detected [winget $($Winget_command)]"
            } # winget detected nothing
        } #verb:list
        elseif ($Wingetverb -eq "install")
        { # winget install
            $Winget_command = "install","--id",$WingetApp,"--exact","--accept-package-agreements"
            #$exitcode,$Winget_return,$stderr=StartProc "winget" $Winget_command
            $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            # exitcode: (https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md)
            # exitcode: 0=OK 	-1978335216=APPINSTALLER_CLI_ERROR_NO_APPLICABLE_INSTALLER
            $chkresults = ($Winget_return -like "*Successfully installed*") -or ($Winget_return -like "*Found an existing package already installed*")
            if ($chkresults)
            { # 1st install ok
                $intReturnCode=0
                $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app installed. [$($Winget_command)]"
            } # 1st install ok
            else
            { # 1st install failed
                if ($strScope -eq "")
                { # 2nd install can't be tried
                        $intReturnCode = 385
                        $strReturnMsg="ERR $($intReturnCode): Winget app [$($WingetApp)] not installed. Winget err: $($exitcode) [winget $($Winget_command)]"
                } # 2nd install can't be tried
                else
                { # 2nd install attempt, without scope
                    $Winget_command = "install","--id",$WingetApp,"--exact","--accept-package-agreements"
                    $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
                    $chkresults = (($Winget_return -like "*Successfully installed*") -or ($Winget_return -like "*Found an existing package already installed*"))
                    if (-not $chkresults) {
                        $intReturnCode = 385
                        $strReturnMsg="ERR $($intReturnCode): Winget app [$($WingetApp)] not installed (even with $($strScope) option removed). Winget err: $($exitcode) [winget $($Winget_command)]"
                        $winget_lines = $winget_return |  Where-Object {$_.Trim() -ne ""} | Where-Object { -not ($_ -match '^\s')} # remove blanks
                        $winget_msgs = @("`r`n[winget $($Winget_command -join " ")]") + $winget_lines + @("[winget returned:$($exitcode)]") # header and footer added
                        $strReturnMsg += $winget_msgs -join "`r`n" # append as a long string with crlfs
                    }
                    else {
                        $intReturnCode=0
                        $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app installed (with $($strScope) option removed). [$($Winget_command)]"
                    }
                } #2nd install attempt, without scope
            } # 1st install failed
        } # winget install
        elseif ($Wingetverb -eq "uninstall")
        { # winget uninstall
            $Winget_command = @()
            if ($WingetApp.Contains(".")){ # exact match (by id)
                $Winget_command = "uninstall","--id",$WingetApp,"--disable-interactivity","--silent","--force"
            }
            else { # name match
                $Winget_command = "uninstall","--name",$WingetApp,"--disable-interactivity","--silent","--force"
            }
            if ($SystemOrUser -ne "") {
                $Winget_command += "--scope"
                If ($SystemOrUser -eq "user") {
                    $Winget_command += "user"}
                Else { # translate all else incl system to machine
                    $Winget_command += "machine"}
            }
            # 1603 means elevation needed, -1978335212 means app not found
            $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            # (Successfully uninstalled) or (No installed package found matching input criteria) are OK results
            if ($exitcode  -eq 0) # -or ($exitcode -eq -1978335212)
            { # 1st uninstall ok
                $intReturnCode=0
                $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app uninstalled. [$($Winget_command)]"
            } # 1st uninstall ok
            else
            { # 2nd uninstall attempt, without scope
				$Winget_command = @()
				if ($WingetApp.Contains(".")){ # exact match (by id)
					$Winget_command = "uninstall","--id",$WingetApp,"--disable-interactivity","--silent","--force"
				}
				else { # name match
					$Winget_command = "uninstall","--name",$WingetApp,"--disable-interactivity","--silent","--force"
				}
				# 1603 means elevation needed, -1978335212 means app not found
                $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
                if ($exitcode  -eq 0)
                { # 2nd uninstall ok
                    $intReturnCode=0
                    $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app uninstalled (with $($strScope) option removed). [$($Winget_command)]"
                } # 2nd uninstall ok
                else
                { # 2nd uninstall attempt, without scope
                    $intReturnCode = 378
                    $strReturnMsg="ERR $($intReturnCode): Winget app [$($WingetApp)] not uninstalled (with $($strScope) option removed). Winget err: $($exitcode) [winget $($Winget_command)]"
                } # 2nd uninstall attempt, without scope
            } # 2nd uninstall attempt, without scope
        }  # winget uninstall
        else
        {
            $intReturnCode=182
            $strReturnMsg="Err $($intReturnCode) : Winget verb unhandled by this code: $($Wingetverb)"
        }
        # Winget verb package 
    } # winget is OK
    Return $intReturnCode,$strReturnMsg
}
Function GetTempFolder (
    $Prefix = "Powershell_"
    )
{
    $tempFolderPath = Join-Path $Env:Temp ($Prefix + $(New-Guid))
    New-Item -Type Directory -Path $tempFolderPath | Out-Null
    Return $tempFolderPath
}
Function DownloadFileFromWeb {
    param (
        [string]$WebUrl = "https://download.workspot.com/WorkspotClientSetup64.msi" ,
        [string]$filename = $null, #"WorkspotClientSetup64.msi",
        [string]$hash          = $null, # (Get-FileHash "$TmpFld\$filename" -Algorithm SHA256).Hash
        [boolean]$hideprogress = $false
    )
    $strInfo = ""
    $intErr  = 0
    if ($filename -eq "") {$filename = $null}
    $TmpFld = GetTempFolder -Prefix "webdownload_"
    Write-Host "- Creating temp folder: $(Split-Path $TmpFld -Leaf)"
    if ($hideprogress) {
        $Pp_old=$ProgressPreference;$ProgressPreference = 'SilentlyContinue' # Change from default (Continue). Prevents byte display in Invoke-WebRequest (speeds it up)
    }
    if (-not $filename){
        $filename = Split-Path $WebUrl -Leaf
    }
    Write-Host "Downloading $($filename) ... " -NoNewline
    $startTime = Get-Date
    Invoke-WebRequest -Uri $WebUrl -OutFile "$TmpFld\$filename"
    Write-Host "Done"
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host "Download took (hh:mm:ss): $($duration.ToString("hh\:mm\:ss"))"
    if ($hideprogress) {
        $ProgressPreference = $Pp_old
    }
    Write-Host "Downloaded: " -NoNewline
    Write-Host $filename -ForegroundColor Green
    # Check downloaded hash
    if ($hash){
        Write-Host "- Checking hash ... " -NoNewline
        $hash_dl = (Get-FileHash "$TmpFld\$filename" -Algorithm SHA256).Hash
        if ($hash_dl -ne $hash) {
            $strInfo =  "Err 100: Hash downloaded [$($hash_dl)] didn't match."
            $interr = 100
            Write-Host $strInfo
        }
        else {Write-Host "OK" -ForegroundColor Green}
    }
    # Create and return a custom object
    return [PSCustomObject]@{
        intErr  = $interr
        strFullpath = "$TmpFld\$filename"
        strInfo = "Download took (hh:mm:ss): $($duration.ToString("hh\:mm\:ss"))"
    }
}
Function DownloadFileFromGoogleDrive {
    param (
        [string]$GoogleDriveUrl = "https://drive.google.com/file/d/xxxxxxxxxxx/view?usp=sharing"  ,
        [string]$filename = $null, #"MyFile.zip",
        [string]$hash           = $null, #(Get-FileHash "$TmpFld\$filename" -Algorithm SHA256).Hash
        [boolean]$hideprogress  = $false
    )
    $strInfo = ""
    $intErr  = 0
    if ($filename -eq "") {$filename = $null}
    # create temp folder
    $TmpFld = GetTempFolder -Prefix "googledownload_"
    Write-Host "- Creating temp folder: $(Split-Path $TmpFld -Leaf)"
    if ($hideprogress) {
        $Pp_old=$ProgressPreference;$ProgressPreference = 'SilentlyContinue' # Change from default (Continue). Prevents byte display in Invoke-WebRequest (speeds it up)
    }
    if (-not $filename)
    { # need a filename
        $htmlContent = Invoke-WebRequest -Uri $GoogleDriveUrl -UseBasicParsing -OutFile "$TmpFld\google.txt" -PassThru
        $pattern = '<meta property="og:title" content="(.+?)">'
        if ($htmlContent.RawContent -match $pattern) {
            $filename = $matches[1] # Captured group 1 contains the uuid value
        } else {
            write-host "Err 103: Couldn't find '$($pattern)' in 'google.txt'. Using GoogleDownload.zip"
            $filename = "GoogleDownload.zip"
        }
    } # need a filename
    $FileID=$GoogleDriveUrl.split("/")[5]
    Write-Host "Downloading $($filename) ... " -NoNewline
    $startTime = Get-Date
    Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=$($FileID)&export=download&confirm=t" -OutFile "$TmpFld\$filename"
    Write-Host "Done"
    $endTime = Get-Date
    $duration = $endTime - $startTime
    $strInfo = "Download took (hh:mm:ss): $($duration.ToString("hh\:mm\:ss"))"
    Write-Host $strInfo
    if ($hideprogress) {
        $ProgressPreference = $Pp_old
    }
    Write-Host "Downloaded: " -NoNewline
    Write-Host $filename -ForegroundColor Green
    # Check downloaded hash
    if ($hash){
        Write-Host "- Checking hash ... " -NoNewline
        $hash_dl = (Get-FileHash "$TmpFld\$filename" -Algorithm SHA256).Hash
        if ($hash_dl -ne $hash) {
            $strInfo =  "Err 100: Hash downloaded [$($hash_dl)] didn't match."
            $interr = 100
            Write-Host $strInfo
        }
        else {Write-Host "OK" -ForegroundColor Green}
    }
    # Create and return a custom object
    return [PSCustomObject]@{
        intErr  = $intErr
        strFullpath = "$TmpFld\$filename"
        strInfo = $strInfo
    }
}
Function DownloadFileFromWebOrGoogleDrive {
    param (
        [string]$Url = "https://drive.google.com/file/d/xxxxxxxxxxx/view?usp=sharing"  ,
        [string]$Filename = $null, #"MyFile.zip",
        [string]$hash           = $null, #(Get-FileHash "$TmpFld\$filename" -Algorithm SHA256).Hash
        [boolean]$hideprogress  = $false
    )

    if ($Url -like "*drive.google.com*"){
        $retVal =  DownloadFileFromGoogleDrive -GoogleDriveUrl $url -filename $Filename -hash $hash -hideprogress $hideprogress
    }
    else{
        $retVal =  DownloadFileFromWeb -WebUrl $url -filename $Filename -hash $hash -hideprogress $hideprogress
    }
    $retVal
}
#endregion Function Definitions
#region scriptinfo
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
#endregion scriptinfo
#region Read IntuneApp Values
# load IntuneApp settings - method 1 - injected to this ps1 (not from csv)
$IntuneApp=IntuneAppValues
# load IntuneApp settings - method 2 - override from csv if possible
$intune_settings_csvpath="$(Split-Path -Path $scriptDir -Parent)\intune_settings.csv"
if (Test-Path -Path $intune_settings_csvpath -PathType Leaf)
{$IntuneApp=IntuneAppValuesFromCSV $intune_settings_csvpath $IntuneApp}
# set function (for logging purposes) according to scriptname, in case $IntuneApp.Function is incorrect
if ($scriptName -in ("intune_Uninstall.ps1","intune_Install.ps1","intune_Detection.ps1","intune_Requirements.ps1","AppsPublish_Template.ps1"))
{
    $IntuneApp.Function = $scriptName
}
# intune_requirements.ps1 must operate quietly, others can have output
If ($IntuneApp.Function -eq "intune_requirements.ps1") {$quiet=$true} Else {$quiet=$false}
#endregion Read IntuneApp Values
#region Check Values
if ($IntuneApp.AppName -eq "")        {Write-host "Appname is empty. Aborting."; Start-Sleep 3; Exit}
if ($IntuneApp.AppInstaller -eq "")   {Write-host "AppInstaller is empty. Aborting."; Start-Sleep 3; Exit}
if ($IntuneApp.AppInstallName -eq "") {Write-host "AppInstallName is empty. Aborting."; Start-Sleep 3; Exit}
#endregion Check Values
#region Relaunch as 64 bit Powershell
$argsString = ""
If ($null -ne $ENV:PROCESSOR_ARCHITEW6432) # -eq "AMD64"
{ #32 bit
    #region rebuild the argument list
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
    $argumentlist ="-File `"$($scriptFullname)`" $($argsString)"
    #endregion rebuild the argument list
    #region find correct exe
    $exename = "$env:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe"
    #$exename = "$env:ProgramFiles\PowerShell\7\pwsh.exe" # for now we won't consider v7 until it's windows native
    #endregion
    IntuneLog "PROCESSOR_ARCHITEW6432 is not empty [$($ENV:PROCESSOR_ARCHITEW6432)] - Relaunching as 64-bit PowerShell"
    IntuneLog "Restarting as 64-bit: powershell.exe -File `"$($scriptname)`" $($argsString)"
    Try
    {Start-Process -FilePath $exename -ArgumentList $argumentlist -Wait -NoNewWindow}
    Catch {
        IntuneLog "Failed to start 64-bit PowerShell"
        Throw "Failed to start 64-bit PowerShell"
    }
    Exit
} # 32 bit
#endregion Relaunch as 64 bit Powershell
#region IntuneAppFunction
$exitcode=0
IntuneLog "--- Start ---" -quiet $quiet
if ($exitcode -eq 0)
{ # Check AppInstaller
    if (-not $IntuneApp.AppInstaller)
    { # no installer specified (winget, choco, etc)
        $app_detected=$true
        IntuneLog "ERR: AppInstaller must be specified in the settings.csv file"
        $exitcode=666
    }
} # Check AppInstaller
$app_detected=$false # assume it's not detected
If ($IntuneApp.Function -in ("intune_Detection.ps1"))
{ # intune_Detection.ps1
    if (($exitcode -eq 0) -and (-not $app_detected))
    {# ready for detection method
        if ($IntuneApp.AppUninstallName -ne "")
        { # detect old version (pass1 winget test of AppUninstallName)
            If ($IntuneApp.AppUninstallVersion -ne "")
            { # has additional winget AppUninstallName (to detect)
                # The csv specifies a winget app version to uninstall if found - which in detect is used to detect
                $WingetApp    = $IntuneApp.AppUninstallName
                $WingetAppMin = $IntuneApp.AppUninstallVersion
                $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "list" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser -WingetAppMin $WingetAppMin
                If ($intReturnCode -eq 0)
                { # version ok
                    IntuneLog "Detection OK: $($strReturnMsg)"
                    $app_detected = $true
                } # version ok
                Else
                { # version too low
                    IntuneLog "Detection failed: $($strReturnMsg)"
                    $app_detected = $false
                } # version too low
            } # has additional winget AppUninstallName (to detect)
        } # detect old version (pass1 winget test of AppUninstallName)
        if (-not $app_detected)
        { # not detected yet
            if (($IntuneApp.AppInstaller -in ("msi","exe","ps1","cmd")) -and ($IntuneApp.AppUninstallName -eq ""))
            { # "msi","exe","ps1","cmd" detect and no winget uninstaller specified
                # Just check the CSV file
                $approw = IntuneAppsCSV -mode "GetStatus" -appnamever $IntuneApp.AppName -setstatus "" -setdescription "" -systemoruser $IntuneApp.SystemorUser -logfolder $IntuneApp.LogFolder
                $verthresh = ""
                If ($approw.Status -in "Installed","Detected")
                {
                    if ((GetVersionFromString($approw.AppVer)) -lt (GetVersionFromString($IntuneApp.AppUninstallVersion))) {
                        $app_detected = $false
                        $verthresh = " [Version is lower than $($IntuneApp.AppUninstallVersion)]"
                    }
                    else {
                        $app_detected = $true
                    }
                }
                else {
                    $app_detected = $false
                }
                IntuneLog "Detection Method: CSV check [$($IntuneApp.LogFolder)\IntuneApps.csv] $($IntuneApp.AppName): $($approw.AppVer)=$($approw.Status)$($verthresh) Detected=$($app_detected)"
            } # "msi","exe","ps1","cmd" detect
            elseif (($IntuneApp.AppInstaller) -in ("choco"))
            { # choco detect
                $ChocoApp   = $IntuneApp.AppInstallName.Trim()
                $intReturnCode, $strReturnMsg = ChocolateyAction -ChocoVerb "list" -ChocoApp $ChocoApp
                if ($intReturnCode -eq 0)
                {
                    IntuneLog $strReturnMsg
                    $app_detected = $true
                }
                Else
                {
                    IntuneLog $strReturnMsg
                }
            } # choco detect
            elseif (($IntuneApp.AppInstaller) -eq "winget")
            { # winget detect
                $WingetApp   = $IntuneApp.AppInstallName.Trim()
                if ($LogFnParent -eq "intune_uninstall.ps1") { # if called from uninstall, don't bother with the winget version
                    $WingetAppMin = ""
                }
                else {
                    $WingetAppMin = $IntuneApp.AppUninstallVersion.Trim()
                }
                $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "list" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser -WingetAppMin $WingetAppMin
                If ($intReturnCode -eq 0)
                { # version ok
                    IntuneLog "Detection OK: $($strReturnMsg)"
                    $app_detected = $true
                } # version ok
                Else
                { # version too low
                    IntuneLog "Detection failed: $($strReturnMsg)"
                } # version too low
            } # winget detect
        } # not detected yet
    }# ready for detection method
    # region intune_detection_customcode.ps1
    $customps1 = "$(Split-Path -Path $scriptDir -Parent)\intune_detection_customcode.ps1"
    if (Test-Path $customps1 -PathType Leaf)
    { # found ps1
        # Call a ps1 - log output, log transcript
        IntuneLog "Running found .ps1 file: $(Split-Path -Path $customps1 -leaf)"
        $ps1_exit,$ps1_output = PS1WithLogging -ps1 $customps1
        $app_detected = $ps1_output # apply results of ps1_output
    } # found ps1
    Else
    { # no ps1 found
        # see if $customps1_lines injection happend
        $customps1_injection_lines = @()
        # injection may happen below here
        ### <<intune_detection_customcode.ps1 injection site>> ###
        # injection may happen above here
        if ($customps1_injection_lines.count -gt 0)
        { # code was injected above
            # create a temp file for the injected code
            $tmpfile = New-TemporaryFile
            $customps1_tmp_name = "custom_detection_$($tmpfile.BaseName).ps1"
            Rename-Item -Path $tmpfile.FullName -NewName $customps1_tmp_name
            $customps1_tmp_fullpath = "$($tmpfile.DirectoryName)\$($customps1_tmp_name)"
            # write lines
            [System.IO.File]::WriteAllLines($customps1_tmp_fullpath,$customps1_injection_lines) # writes UTF8 file
            IntuneLog "Running injected .ps1 file: $(Split-Path -Path $customps1_tmp_fullpath -leaf)"
            $ps1_exit,$ps1_output = PS1WithLogging -ps1 $customps1_tmp_fullpath
            $app_detected = $ps1_output # apply results of ps1_output
            # cleanup
            Remove-Item $customps1_tmp_fullpath -Force
        } # code was injected above
    } # no ps1 found
    # endregion intune_detection_customcode.ps1
    IntuneLog "--- End ---" -quiet $quiet
    # detection requires a non-empty stdout (for both cases)
    if ($app_detected)
    {
        $exitcode = 0
        IntuneLog    "Detection: Detected $($IntuneApp.AppName) [$($exitcode)]"
        Write-Output "Detection: Detected $($IntuneApp.AppName) [$($exitcode)]"
        $approw = IntuneAppsCSV -mode "SetStatus" -appnamever $IntuneApp.AppName -setstatus "Detected" -systemoruser $IntuneApp.SystemorUser -logfolder $IntuneApp.LogFolder
    }
    else
    {
        $exitcode = 99
        IntuneLog    "Detection: Didn't detect $($IntuneApp.AppName) [$($exitcode)]"
        Write-Output "Detection: Didn't detect $($IntuneApp.AppName) [$($exitcode)]"
        $approw = IntuneAppsCSV -mode "SetStatus" -appnamever $IntuneApp.AppName -setstatus "Missing" -systemoruser $IntuneApp.SystemorUser -logfolder $IntuneApp.LogFolder
    }
    ###
} # intune_Detection.ps1
If ($IntuneApp.Function -in ("intune_Requirements.ps1"))
{ # intune_Requirements.ps1
    $requirements_met=$true #assume requirements are met
    # if it's winget, check version
    if (($IntuneApp.AppInstaller) -eq "winget")
    { # winget detect
        [string]$result=winget_core -minver "1.6"
        If (-not $result.StartsWith("OK"))
        { # winget itself is err        
            IntuneLog "Winget problem: $($result)"
            $requirements_met=$false
        } # winget itself is err
    } # winget detect
    # region intune_detection_customcode.ps1
    $customps1 = "$(Split-Path -Path $scriptDir -Parent)\intune_requirements_customcode.ps1"
    if (Test-Path $customps1 -PathType Leaf)
    { # found ps1
        # Call a ps1 - log output, log transcript
        IntuneLog "Running found .ps1 file: $(Split-Path -Path $customps1 -leaf)"
        $ps1_exit,$ps1_output = PS1WithLogging -ps1 $customps1
        $requirements_met = $ps1_output # apply results of ps1_output
    } # found ps1
    Else
    { # no ps1 found
        # see if $customps1_lines injection happend
        $customps1_injection_lines = @()
        # injection may happen below here
        ### <<intune_requirements_customcode.ps1 injection site>> ###
        # injection may happen above here
        if ($customps1_injection_lines.count -gt 0)
        { # code was injected above
            # create a temp file for the injected code
            $tmpfile = New-TemporaryFile
            $customps1_tmp_name = "custom_requirements_$($tmpfile.BaseName).ps1"
            Rename-Item -Path $tmpfile.FullName -NewName $customps1_tmp_name
            $customps1_tmp_fullpath = "$($tmpfile.DirectoryName)\$($customps1_tmp_name)"
            # write lines
            [System.IO.File]::WriteAllLines($customps1_tmp_fullpath,$customps1_injection_lines) # writes UTF8 file
            IntuneLog "Running injected .ps1 file: $(Split-Path -Path $customps1_tmp_fullpath -leaf)"
            $ps1_exit,$ps1_output = PS1WithLogging -ps1 $customps1_tmp_fullpath
            $requirements_met = $ps1_output # apply results of ps1_output
            # cleanup
            Remove-Item $customps1_tmp_fullpath -Force
        } # code was injected above
    } # no ps1 found
    # endregion intune_requirements_customcode.ps1
    if ($requirements_met)
    {
        IntuneLog "Requirements: Met" -quiet $quiet
        Write-Output "REQUIREMENTS_MET"
    }
    else
    {
        IntuneLog "Requirements: Not Met" -quiet $quiet
        Write-Output "REQUIREMENTS_NOT_MET" #return value for Intune
    }
    $exitcode=0 #unused by requirements script
} # intune_Requirements.ps1
If ($IntuneApp.Function -in ("intune_Install.ps1"))
{ # intune_Install.ps1
    if ($exitcode -eq 0)
    { # Check Requirements
        [string]$result=&"$($scriptDir)\intune_requirements.ps1" -LogFnParent $($IntuneApp.Function) -quiet $quiet
        if ($result -ne "REQUIREMENTS_MET")
        {
            $exitcode = 20
            IntuneLog "Err: Requirements not met"
        }
    } # Check Requirements
    if ($exitcode -eq 0)
    { # Check Detection
        [string]$result=&"$($scriptDir)\intune_detection.ps1" -LogFnParent $($IntuneApp.Function) -quiet $quiet
        if ($LASTEXITCODE  -eq 0)
        {
            $app_detected=$true
            IntuneLog "OK: App already detected. Skipping installer (Use AppUninstallVersion to upgrade old versions)"
        }
    } # Check Detection
    if ($exitcode -eq 0 -and (-not $app_detected)) 
    { # Check System/User
        If (($IntuneApp.SystemorUser -eq "System") -and (-not(IsAdmin)))
        { # elevate
            ElevateViaRelaunch
        } # elevate
    } # Check System/User
    if (($exitcode -eq 0) -and (-not $app_detected))
    { # ready for install method
        # Pre-downloads
        foreach ($i in 1..2) { # Each URL (csv allows for 2 URLs)
            if ($i -eq 1) {
                $DownloadURL=$intuneapp.AppInstallerDownload1URL
                $DownloadHash=$intuneapp.AppInstallerDownload1Hash
            }
            else {
                $DownloadURL=$intuneapp.AppInstallerDownload2URL
                $DownloadHash=$intuneapp.AppInstallerDownload2Hash
            }
            if ($DownloadURL -eq "") {$DownloadURL = $null}
            if ($DownloadHash -eq "") {$DownloadHash = $null}
            If ($DownloadURL)
            { # download and unzip
                $retVal =  DownloadFileFromWebOrGoogleDrive -Url $DownloadURL -hash $DownloadHash -hideprogress $true
                $strReturnMsg = "$($retval.intErr) $($retval.strInfo) $($retval.strFullpath)"
                IntuneLog "DownloadFileFromWebOrGoogleDrive: $($strReturnMsg)"
                if ($retVal.intErr -ne 0){
                    $exitcode = $retval.intErr
                }
                else { # download ok
                    $folder_target = Split-Path -Path $scriptDir -Parent # the package folder is the parent of the script folder
                    if ($retval.strFullpath.EndsWith(".zip")) {
                        IntuneLog "Extracting Zip: $(Split-Path $retval.strFullpath -Leaf)"
                        Expand-Archive -Path $retval.strFullpath -DestinationPath $folder_target -Force
                    } # zip file
                    else {
                        Move-Item -Path $retval.strFullpath -Destination $folder_target -Force
                    } # non-zip
                } # download ok
                # folder to remove
                if (Test-path ($retVal.strFullpath)){
                    $TmpFolder = (Split-Path $retVal.strFullpath -Parent)
                    if (Test-path ($TmpFolder)){
                        Remove-Item -Path $TmpFolder -Recurse -Force
                    }
                } # found a folder to remove
            } # download and unzip
        } # Each URL
        # Stop running processes
        if ($IntuneApp.AppUninstallProcess) {StopProcess $IntuneApp.AppUninstallProcess}
        if ($IntuneApp.AppUninstallVersion -ne "")
        { # uninstall old version
            If ($IntuneApp.AppUninstallName -ne "")
            { # has additional winget AppUninstallName (installer will uninstall this too)
                IntuneLog "Checking to see if there is an installed app named '$($IntuneApp.AppUninstallName)' below this version: $($IntuneApp.AppUninstallVersion)"
                # The csv specifies a winget app version to uninstall if found
                $WingetApp    = $IntuneApp.AppUninstallName
                $WingetAppMin = $IntuneApp.AppUninstallVersion
                $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "list" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser -WingetAppMin $WingetAppMin
                if ($strReturnMsg -like "*version is too low*")
                { # version too low
                    IntuneLog "AppUninstallVersion uninstall requested: $($strReturnMsg)"
                    $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "uninstall" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser
                    IntuneLog "AppUninstallVersion uninstall result: $($strReturnMsg)"
                } # version too low
            } # has additional winget AppUninstallName
        } # uninstall old version
        if (($IntuneApp.AppInstaller) -in ("msi","exe"))
        { #msi,exe install
            # search for installer
            $exitcode,$strReturnMsg,$strInstaller = FindInstall -installer_path (Split-Path -Path $scriptDir -Parent) -installer $IntuneApp.AppInstallName
            if ($exitcode -ne 0)
            { # FindInstall err
                IntuneLog $strReturnMsg
            } # FindInstall err
            elseif (-not $app_detected)
            { # Found installer, not already_installed
                ## -------- Uninstall
                IntuneLog "Before running installer, run uninstaller"
                [string]$result=&"$($scriptDir)\intune_uninstall.ps1" -LogFnParent $($IntuneApp.Function)
                if ($LASTEXITCODE  -ne 0)
                {
                    $exitcode = 275
                    IntuneLog "Err: Uninstall failed"
                }
                ## -------- Install
                # build command line to installer
                if ($IntuneApp.AppInstaller -eq "msi")
                { # msi
                    $exename = "msiexec.exe"
                    $arglist = "/i ""$($strInstaller)"" "
                    $arglist += $IntuneApp.AppInstallArgs.Replace("ARGS:","")
                } # msi
                else 
                { # exe
                    $exename = $strInstaller
                    $arglist = $IntuneApp.AppInstallArgs.Replace("ARGS:","")
                } # exe
                IntuneLog ("Installing $(split-path (split-path $strinstaller -parent) -leaf)\$(split-path $strinstaller -leaf)" )
                IntuneLog ("via: $($exename) $($arglist)" )
                if ($arglist -eq "") {$arglist = $null}
                # execute installer
                if ($arglist) {
                    $proc = Start-Process $exename -ArgumentList $arglist -PassThru -Wait -NoNewWindow
                } # has args
                else {
                    $proc = Start-Process $exename -PassThru -Wait -NoNewWindow
                } # no args
                if ($proc.ExitCode -ne 0 )
                {
                    $exitcode=105; IntuneLog ("Err $exitcode : Application install failed with error code $($proc.ExitCode)")
                }
            } # Found, not already_installed
        } #msi,exe install
        elseif (($IntuneApp.AppInstaller) -eq "ps1")
        { #ps1 install
            # search for installer
            $exitcode,$strReturnMsg,$strInstaller  = FindInstall -installer_path (Split-Path -Path $scriptDir -Parent) -installer $IntuneApp.AppInstallName
            if ($exitcode -ne 0)
            { # FindInstall err
                IntuneLog $strReturnMsg
            } # FindInstall err
            elseif (-not $app_detected)
            { # Found, not already_installed
                $installargs = $IntuneApp.AppInstallArgs.Replace("ARGS:","")
                IntuneLog "Starting PS1 install: $($IntuneApp.AppInstallName) $($installargs)"
                # Call a ps1 - log output, log transcript
                $ps1_exit,$ps1_output = PS1WithLogging $strInstaller $installargs
                if (($null -ne $ps1_output) -and ($ps1_output.ToLower().StartsWith("err"))) {
                    # ps1 installer signaled a failure via Write-Output ERR
                    $exitcode=98
                } # exit code via output
                else {
                    $exitcode=$ps1_exit
                } # exit code
            } # Found, not already_installed
        } #ps1 install
        elseif (($IntuneApp.AppInstaller) -eq "cmd")
        { #cmd install
            # search for installer
            $exitcode,$strReturnMsg,$strInstaller  = FindInstall -installer_path (Split-Path -Path $scriptDir -Parent) -installer $IntuneApp.AppInstallName
            if ($exitcode -ne 0)
            { # FindInstall err
                IntuneLog $strReturnMsg
            } # FindInstall err
            elseif (-not $app_detected)
            { # Found, not already_installed
                $installargs = $IntuneApp.AppInstallArgs.Replace("ARGS:","")
                IntuneLog "Starting CMD install: $($IntuneApp.AppInstallName) $($installargs)"
                # create a tmp for output
                $tmpfile = New-TemporaryFile
                $tmp_name = "intune_install_cmdoutput_$($tmpfile.BaseName).txt"
                Rename-Item -Path $tmpfile.FullName -NewName $tmp_name
                $tmp_fullpath = "$($tmpfile.DirectoryName)\$($tmp_name)"
                # Call a cmd and return output to tmp file
                Start-Process -FilePath $strInstaller -ArgumentList $installargs -Wait -NoNewWindow -RedirectStandardOutput $tmp_fullpath
                # Log output
                $cmd_out = Get-Content $tmp_fullpath
                $cmd_out | ForEach-Object {IntuneLog $_}
                # Clean up
                Remove-Item $tmp_fullpath -Force
            } # Found, not already_installed
        } #cmd install
        elseif (($IntuneApp.AppInstaller) -eq "choco")
        { #choco install
            $ChocoApp = $IntuneApp.AppInstallName.Trim()
            $arglist = $IntuneApp.AppInstallArgs.Replace("ARGS:","")
            IntuneLog "Starting Choco install --id $($ChocoApp) -y $($arglist)"
            $intReturnCode, $strReturnMsg = ChocolateyAction -ChocoVerb "install" -ChocoApp $ChocoApp -ChocoArgs $arglist
            IntuneLog $strReturnMsg
            $exitcode = $intReturnCode
        } #choco install
        elseif (($IntuneApp.AppInstaller) -eq "winget")
        { #winget install
            $WingetApp   = $IntuneApp.AppInstallName.Trim()
            # uninstall
            if ($IntuneApp.AppUninstallVersion -ne "")
            { # uninstall old version
                [string]$result=&"$($scriptDir)\intune_uninstall.ps1" -LogFnParent $($IntuneApp.Function) -quiet $quiet
            } # uninstall old version
            # install
            IntuneLog "Starting Winget install --id $($WingetApp) --exact"
            $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "install" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser
            IntuneLog $strReturnMsg
            $exitcode = $intReturnCode
        } #winget install
        else
        { #unknown
            IntuneLog ("Unknown AppInstaller: $($IntuneApp.AppInstaller)")
        } #unknown
    } # ready for install method
    if (($exitcode -eq 0)-and (-not $app_detected))
    { # intune_install_followup
        $followup = "$(Split-Path -Path $scriptDir -Parent)\intune_install_followup.ps1"
        if (Test-Path $followup -PathType Leaf)
        { # found ps1
            # Call a ps1 - log output, log transcript
            IntuneLog "Running found .ps1 file: $(Split-Path -Path $followup -leaf)"
            $ps1_exit,$ps1_output = PS1WithLogging -ps1 $followup
            if (($null -ne $ps1_output) -and ($ps1_output.ToLower().StartsWith("err"))) {
                # ps1 installer signaled a failure via Write-Output ERR
                $exitcode=98
            } # exit code via output
            else {
                $exitcode=$ps1_exit
            } # exit code
        } # found ps1
    } # intune_install_followup
    IntuneLog "--- End ---" -quiet $quiet
    if ($exitcode -eq 0)
    {
        IntuneLog "Installed [$($exitcode)]"
        $approw = IntuneAppsCSV -mode "SetStatus" -appnamever $IntuneApp.AppName -setstatus "Installed" -systemoruser $IntuneApp.SystemorUser -logfolder $IntuneApp.LogFolder
    }
    else
    {
        IntuneLog "Install Failed [$($exitcode)]"
    }
} # intune_Install.ps1
If ($IntuneApp.Function -in ("intune_Uninstall.ps1"))
{ # intune_Uninstall.ps1
    IntuneLog "Check if app is detected. (uninstall not needed if it isn't)"
    $app_detected=$false # assume it's not detected
    if ($exitcode -eq 0)
    { # Check Detection
        [string]$result=&"$($scriptDir)\intune_detection.ps1" -LogFnParent $($IntuneApp.Function) -quiet $quiet
        if ($LASTEXITCODE  -eq 0)
        {
            $app_detected=$true
            IntuneLog "App detected. Proceeding with uninstall."
        }
    } # Check Detection
    if (($exitcode -eq 0) -and $app_detected)
    { # App Detected so Uninstall
        # Check System/User
        If (($IntuneApp.SystemorUser -eq "System") -and (-not (IsAdmin)))
        { # elevate
            ElevateViaRelaunch
        } # elevate
        if ($exitcode -eq 0)
        {# ready for uninstall method
            # Stop running processes
            if ($IntuneApp.AppUninstallProcess) {StopProcess $IntuneApp.AppUninstallProcess}
            if ($IntuneApp.AppUninstallVersion -ne "")
            { # uninstall old version
                If ($IntuneApp.AppUninstallName -ne "")
                { # has additional winget AppUninstallName (in uninstall mode - use this to uninstall something else too)
                    IntuneLog "Checking to see if there is an installed app named '$($IntuneApp.AppUninstallName)' below this version: $($IntuneApp.AppUninstallVersion)"
                    # The csv specifies a winget app version to uninstall if found (besides the main winget app itself)
                    $WingetApp    = $IntuneApp.AppUninstallName
                    $WingetAppMin = $IntuneApp.AppUninstallVersion
                    $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "list" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser -WingetAppMin $WingetAppMin
                    if ($strReturnMsg -like "*version is too low*")
                    {
                        IntuneLog "AppUninstallVersion uninstall detected version is too low: $($strReturnMsg)"
                    }
                    else
                    { # version can be uninstalled  - it's above the threshold that shows the package as installed 
                        IntuneLog "AppUninstallVersion uninstall requested: $($strReturnMsg)"
                        $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "uninstall" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser
                        IntuneLog "AppUninstallVersion uninstall result: $($strReturnMsg)"
                    } # version can be uninstalled
                } # has additional winget AppUninstallName
            } # uninstall old version
            if (($IntuneApp.AppInstaller) -in ("ps1","cmd"))
            { #ps1
                # do nothing - use the intune_uninstall_followup.ps1 feature for these
            } #cmd
            elseif (($IntuneApp.AppInstaller) -eq "choco")
            { #choco
                $ChocoApp   = $IntuneApp.AppInstallName.Replace("choco install","").Trim()
                $intReturnCode, $strReturnMsg = ChocolateyAction -ChocoVerb "uninstall" -ChocoApp $ChocoApp
                IntuneLog $strReturnMsg
                $exitcode = $intReturnCode
            } #choco
            elseif (($IntuneApp.AppInstaller) -in ("winget"))
            { #winget
                $WingetApp   = $IntuneApp.AppInstallName.Trim()
                # uninstall
                if ($WingetApp -eq ""){
                    IntuneLog "There is no AppUninstallName in the .CSV settings. Nothing to uninstall so marking as uninstalled."
                    $exitcode = 0
                }
                else { # has winget to uninstall
                    if ($IntuneApp.AppUninstallVersion -ne "")
                    { # uninstall old version
                        # The csv specifies a winget app version to uninstall if found
                        #$WingetApp    = $IntuneApp.AppUninstallName
                        $WingetAppMin = $IntuneApp.AppUninstallVersion
                        $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "list" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser -WingetAppMin $WingetAppMin
                        if ($strReturnMsg -like "*version is too low*")
                        { # version too low
                            IntuneLog "AppUninstallVersion uninstall requested: $($strReturnMsg)"
                            $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "uninstall" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser
                            IntuneLog "AppUninstallVersion uninstall result: $($strReturnMsg)"
                        } # version too low
                    } # uninstall old version
                    # uninstall
                    $intReturnCode, $strReturnMsg = WingetAction -WingetVerb "uninstall" -WingetApp $WingetApp -SystemOrUser $IntuneApp.SystemorUser
                    IntuneLog $strReturnMsg
                    $exitcode = $intReturnCode
                } # has winget to uninstall
            } #winget
            elseif (($IntuneApp.AppInstaller) -in ("msi"))
            { #msi
                if (($IntuneApp.AppUninstallName.Trim() -eq "") -and (-not (Test-Path "$(Split-Path -Path $scriptDir -Parent)\intune_uninstall_followup.ps1" -PathType Leaf))) {
                    IntuneLog ("This msi installer can't be uninstalled but will be marked as uninstalled. There is no AppUninstallName setting (with a winget name or winget id) in intune_settings.csv. Alternatively, intune_uninstall_followup.ps1 can be used.")
                }
            } #msi
            else
            { #unknown
                IntuneLog ("Unknown AppInstaller: $($IntuneApp.AppInstaller)")
            } #unknown
        }# ready for uninstall method
    if ($exitcode -eq 0)
        { # intune_uninstall_followup
            $followup = "$(Split-Path -Path $scriptDir -Parent)\intune_uninstall_followup.ps1"
            if (Test-Path $followup -PathType Leaf)
            { # found ps1
                # Call a ps1 - log output, log transcript
                IntuneLog "Running found .ps1 file: $(Split-Path -Path $followup -leaf)"
                $ps1_exit,$ps1_output = PS1WithLogging -ps1 $followup
                if (($null -ne $ps1_output) -and ($ps1_output.ToLower().StartsWith("err"))) {
                    # ps1 installer signaled a failure via Write-Output ERR
                    $exitcode=98
                } # exit code via output
                else {
                    $exitcode=$ps1_exit
                } # exit code
            } # found ps1
        } # intune_uninstall_followup
    } # App Detected so Uninstall
    IntuneLog "--- End ---" -quiet $quiet
    if ($exitcode -eq 0)
    {
        IntuneLog "Uninstalled [$($exitcode)]" -quiet $quiet
        $approw = IntuneAppsCSV -mode "SetStatus" -appnamever $IntuneApp.AppName -setstatus "Uninstalled" -systemoruser $IntuneApp.SystemorUser -logfolder $IntuneApp.LogFolder
    }
    else
    {
        IntuneLog "Uninstall Failed [$($exitcode)]" -quiet $quiet
    }
} # intune_Uninstall.ps1
#endregion IntuneAppFunction
####################### Managed Region Info Part 2
#
# Basic order of Intune installation is
# [1] intune_detection.ps1
# [2] intune_requirements.ps1 (if not detected)
# [3] intune_install.ps1 (if requirements met)
# [4] intune_uninstall.psq (if required to uninstall or superseded version installs)
#
# Summary of return values expected by .ps1 files
# [1] detection [2] requirements [3] install [4] uninstall
#
# [1] intune_detection.ps1 
#    Detected: STDOOUT="DETECTED" (ignored, can be any non-empty text) and Exit=0
#    Not Detected: STDOOUT="NOT_DETECTED" (ignored, can be any non-empty text) and Exit=99 (or any non-0 #)
#    Note: detection scripts focus on exit codes and ignore STDOUT (but STDOUT can't be empty) so write-output can be used
#    Note: no parameters allowed, must be a stand-alone script with no other package files available
#    Note: at runtime, the IntuneManagementExtension service will rename this script something like: <app_id>_1.ps1
#    Note: if app is detected, it will not be installed
#    Note: if app is not detected, it will be installed
#
# [2] intune_requirements.ps1
#    Required: STDOOUT="REQUIREMENTS_MET" and Exit=(ignored, can be any #)
#    Not Required: STDOOUT="REQUIREMENTS_NOT_MET" and Exit=(ignored, can be any #)
#    Note: no parameters allowed, must be a stand-alone script with no other package files available
#    Note: at runtime, the IntuneManagementExtension service will rename this script something like: <app_id>_1.ps1
#    Note: this script may run as system or user depending on the .csv setting of the app
#    Note: do not pass any output (using write-output or write-host) other than "REQUIREMENTS_MET" or "REQUIREMENTS_NOT_MET"
#    Note: Apps that fail the requirement rule will display as Device Status: Not Applicable in Endpoint Manager
#
# [3] intune_install.ps1 
#    Postinstall: STDOUT="(any text)" and Exit=Success(0,1707), Soft Reboot(3010), Hard Reboot(1641), Retry(1618)
#    Note: at runtime, the IntuneManagementExtension service wil unzip the intunewin package and run the script as-is
#
# [4] intune_uninstall.ps1 
#    Postinstall: No STDOUT or exit value parsing
#    Note: parameters passed (-quiet), other package files available
#    Note: at runtime, the IntuneManagementExtension service wil unzip the intunewin package and run the script as-is
#
####################### Managed Region Info Part 2
Exit $exitcode
#################### APPSPUBLISH_TEMPLATE.PS1 FILE
