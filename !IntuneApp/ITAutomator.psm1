########################################################################
# ITAutomator.psm1 copyright(c) ITAutomator
# https://www.itautomator.com
# 
# Library of useful functions for PowerShell Programmers
########################################################################

########################################################################
<###### Sample ps1 Code
####
# Usage: 
# To use these functions in your .ps1 file put this .psm1 in the same folder as your .ps1.
# Then put this sample code at the top of your .ps1 and adjust as needed.
####
######################
### Parameters
######################
Param 
	( 
	 [string] $mode = "manual" #auto       ## -mode auto (Proceed without user input for automation. use 'if ($mode -eq 'auto') {}' in code)
    ,[string] $samplestrparam = "Normal"   ## -samplestrparam Normal
    ,[switch] $sampleswparam  = $false     ## -sampleswparam (use 'if ($sampleswparam) {}' in code)
	)

######################
### Functions
######################

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
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host " This is my script. There are many others, but this one is mine."
Write-Host ""
Write-Host ""
Write-Host "    mode: $($mode)"
Write-Host "-----------------------------------------------------------------------------"

## If script requires admin, include this snippet
If (-not(IsAdmin))
{
    ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
}
#>
<###### Version History
2024-12-19
GetArchitecture
PNPUtiltoObject ($pnpcmd = "pnputil.exe /enum-drivers") 
2024-12-18
GetWhoisData now recognizes the need for eula in double-byte format
2024-12-13
PromptForString
PressEnterToContinue prompt option
AskForChoice ReturnString option
2024-12-12
AskForChoice ShowMenu option
2024-12-08
EncryptString Added KeyAsString to allow for string-based keys
DecryptString Added KeyAsString
2024-12-01
CopyFileIfNeeded ($source, $target, $CompareByHashOrDate="hash")
2024-11-29
DownloadFileFromWeb
DownloadFileFromGoogleDrive
DownloadFileFromWebOrGoogleDrive
2024-11-23
LoadModule - Added suggestion if update is needed
2024-11-20
CopyFilesIfNeeded - added excludeFiles option
2024-11-19
CopyFilesIfNeeded - changed date compare to allow a few seconds of tolerance due to OneDrive
GetHashOfFiles - changed date hash to only include mins (not secs) to help with OneDrive changing by a few secs. Doesn't help with :59 :00 edge cases
2024-11-18
CSVSettingsLoad - Returns a hashtable of settings from a CSV Settings name,value file
CSVSettingsSave - Saves settings to CSV
2024-11-17
CopyFilesIfNeeded -deeply=$true - Added option to not recurse. Also fixed LiteralPath bug to allow filenames with [ chars
2024-05-08
LoadModule - Ask before installing
2024-05-06
PressEnterToContinue
2024-05-03
Forked code into ITAutomator M365.psm1
Updated MainFunctionHeader psm1 load line
2024-04-01
CopyFilesIfNeeded - Removes resulting empty folders if deleteextra is used
2023-12-05
Elevate -  Relaunches powershell.exe elevated
2023-11-19
GetHashOfFiles - Return HashList in addition to final Hash, and fixed sorting so that files are always sorted the same across systems and cultures and powershells
ChooseFromList - better examples
2023-11-08
ContentsHaveChanged - Given an array of strings from 2 files, identifies if they match or not.
CropString - Given a string, crops it below the maxlen and appends ... marks if needed, to indicate cropping
GetHashOfFiles - Give a list of filepaths, creates an MD5 hash of their content (ByContents) or their date time stamps (ByDate)
ParseToken - Given a string with open and close delimeters (can be multi-char), returns the string in between those delimeters (the token).
2023-11-06
LoadModule - added $checkver=false (faster)
2023-10-22
CreateLocalUser2 - Now works with ps 7
2023-09-28
Coalesce - Return first non-null entry in array
2023-09-10
CheckModuleInstalled
2023-09-08
Removed angled quote from file (PS7 didn't like them)
2023-08-11
AddToCommaSeparatedString
AskForChoice - Add write-host if ISE
2023-02-21
Import-Vault comments updated
Export-Vault comments updated
2023-01-30
SystemVersionIncrement ($version="0",$section=0)
2022-12-29
LoadModule PackageProvider feature added
2022-11-02
ChooseFromList $orglist.Org -Showmenu $true
2022-10-27
$x = @(LocalAdmins)
2022-10-26
CreateShortcut -lnk_path $lnk_path -SourceExe $exe_path -exe_args $exe_args
2022-10-04
Format-FileSize (Same as BytesToString but more elegant) 
2022-08-25
GetWhoisData update to use any whois.exe program (nirsoft whoiscl.exe is better than sysinternals whois.exe)
2022-08-23
ToDateOnlyStr ($DateTime, $Format = "yyyy-MM-dd")
2022-07-15
CopyFilesIfNeeded ($source, $target,$CompareMethod = "hash", $delete_extra=$false)
2022-07-12
- CreateLocalUser2
2022-06-26
- SystemVersionStringFromString
2022-06-09
- ChooseFromList
2022-05-06
- Write-Host instead of WriteText
2022-04-26
- LoadModule
2022-01-07
- FolderDelete
2021-10-24
$info = FolderSize $source
CopyFilesIfNeeded ($source, $target,$CompareMethod = "hash")
2020-07-11
- GetWhoisData ($domain, $cache_hrs = 5)
2021-05-08
- FolderCreate
2021-04-29
- CopyFileIfNeeded
2021-04-24
- UpdateXML
2021-04-10
- LeftChars (added -Column)
2021-04-07
- IsOnBlacklist
2021-03-31
- TimeSpanToString
- LogsWithMaxSize
- ErrorMsg
- IPSubnet
- Convert-IPv4AddressToBinaryString
- ConvertIPv4ToInt
- ConvertIntToIPv4
- Add-IntToIPv4Address
- CIDRToNetMask
- NetMaskToCIDR
- Get-IPv4Subnet
2021-03-18
- BytestoString (simplified)
- CopyFilesIfNeeded
- GetMSOfficeInfo
2021-03-07
- BytestoString
- DiskPartitions
- DiskFormat
2021-02-20
- $AzureJoinInfo = AzureJoinInfo
- $computerInfo = computerInfo
2020-11-01
- Import-Vault
- Export-Vault
2020-02-20
- Update Master Location
2020-02-09
- AskForChoice
2020-01-12
- FilenameVersioned
2019-12-22
- Set-CredentialInFile
- Get-CredentialInFile
- VarExists
2019-11-25
- Screenshot
- Get-PublicIPInfo
2019-10-19
- Get-IniFile, Show-IniFile
2019-10-08
- TimeSpanAsText
2019-08-16
- AppVerb error trapping
- GlobalsLoad warning messages
2018-10-21
- LeftChars function added
2018-10-13
- Changed GlobalsLoad Write-host to Write-warning
- Changed PauseTimed to prompt from command line rather than dialog
2018-10-02
- Added Encrypt
2018-09-06
- Fixed bug in GlobalsLoad with init (warning message was inadvertently returned in the stream)
2018-07-17
- Fixed sample code in GlobalsLoad
2017-04-25
- CommandLineSplit fixes
- Get-FileMetaData fixed in case no property name
2017-11-02
- CommandLineSplit
2016-09-24
- AppNameVerb
2016-05-22
- Changed RegSet to create key if doesn't exist
#>
<###### Alphabetical list of functions
Add-IntToIPv4Address
AddToCommaSeparatedString
AppNameVerb ($AppName, $VerbStartsWith)
AppRemove ($Appname)
AppVerb ($PathtoExe, $VerbStartsWith)
ArrayRemoveDupes
AskForChoice
AzureJoinInfo
BytestoString
CheckModuleInstalled
ChooseFromList
CIDRToNetMask
Coalesce - Return first non-null entry in array
CommandLineSplit ($line)
ComputerInfo
Convert-IPv4AddressToBinaryString
ConvertIPv4ToInt
ConvertIntToIPv4
ConvertPSObjectToHashtable
ContentsHaveChanged - Given an array of strings from 2 files, identifies if they match or not.
CopyFileIfNeeded ($source, $target, $CompareByHashOrDate="hash")
CopyFilesIfNeeded ($source, $target,$CompareMethod = "hash", $delete_extra=$false)
CreateLocalUser($username, $password, $desc, $computername, $GroupsList="Administrators")
CreateShortcut -lnk_path $lnk_path -SourceExe $exe_path -exe_args $exe_args
CropString - Given a string, crops it below the maxlen and appends ... marks if needed, to indicate cropping
CSVSettingsLoad - Returns a hashtable of settings from a CSV Settings name,value file
CSVSettingsSave - Saves settings to CSV
DatedFileName ($Logfile)
DecryptString ($StringToDecrypt, $Key)
DecryptStringSecure ($StringToDecrypt)
DiskFormat
DiskPartitions
DownloadFileFromWeb
DownloadFileFromGoogleDrive
DownloadFileFromWebOrGoogleDrive
Elevate -  Relaunches powershell.exe elevated
EncryptString ($StringToEncrypt, $Key)
EncryptStringSecure ($StringToEncrypt)
ErrorMsg
Export-Vault
FilenameVersioned ($MyFile)
FolderCreate -Logfolder "C:\LogFolder"
FolderDelete
FolderSize $source
FromUnixTime 
GetArchitecture
Get-CredentialInFile
Get-FileMetaData
Get-FileMetaData2
Get-FileMetaDataFromFolders 
Get-IPv4Subnet
Get-IniFile
Get-MsiDatabaseProperties
Get-OSVersion
Get-PublicIPInfo
GetHashOfFiles - Give a list of filepaths, creates an MD5 hash of their content (ByContents) or their date time stamps (ByDate)
GetMSOfficeInfo
GetTempFolder
GetWhoisData ($domain, $cache_hrs = 5)
GlobalsLoad ($Globals, $scriptXML, $force=$true)
GlobalsSave ($Globals, $scriptXML)
IPSubnet
Import-Vault
IsAdmin
IsOnBlacklist
LeftChars
LocalAdmins
LogsWithMaxSize
NetMaskToCIDR
ParseToken - Given a string with open and close delimeters (can be multi-char), returns the string in between those delimeters (the token).
PathtoExe ($Exe)
Pause ($Message="Press any key to continue.")
PauseTimed
PNPUtiltoObject ($pnpcmd = "pnputil.exe /enum-drivers") 
PressEnterToContinue
PowershellVerStop ($minver)
PromptForString
RegDel ($keymain, $keypath, $keyname)
RegGet ($keymain, $keypath, $keyname)
RegGetX ($keymain, $keypath, $keyname)
RegSet ($keymain, $keypath, $keyname, $keyvalue, $keytype)
RegSetCheckFirst ($keymain, $keypath, $keyname, $keyvalue, $keytype)
Screenshot($jpg_path)
Set-CredentialInFile
Show-IniFile
$newvalue = SystemVersionIncrement -version $app_found.displayversion
SystemVersionStringFromString
TimeSpanAsText 
TimeSpanToString
ToDateOnlyStr ($DateTime, $Format = "yyyy-MM-dd")
UpdateXML -xmlFilepath $xmlFilepath -xmlPath $xmlPath -xmlAttr $xmlAttr -xmlValu $xmlValu -xmlAttrSubNam $xmlAttrSubNam -xmlAttrSubVal $xmlAttrSubVal
VarExists
WriteText ($line)
#>
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
Function ParseToken ($Stringtosearch, $delim_start = "Hash: [",$delim_end = "]" )
{
    # ParseToken - Given a string with open and close delimeters (can be multi-char), returns the string in between those delimeters (the token).
    # Note: if delimeters aren't found, returns ''
    #                                 ParseToken "0123456789012Hash: [helloworld]12345" 
    #             sssssss**********e
    #0123456789012Hash: [helloworld]12345
    $sReturn = ""
    $sSearch = $Stringtosearch
    $find = $sSearch.IndexOf($delim_start)
    if ($find -ne -1)
    { # found delim_start
        $sSearch = $sSearch.Substring($find+$delim_start.length)
        $find = $sSearch.IndexOf($delim_end)
        if ($find -ne -1)
        { # found delim_start
            $sReturn = $sSearch.Substring(0,$find)
        } # found delim_end
    } # found delim_start
    Return $sReturn
}
Function CropString ($StringtoCrop, $MaxLen = 30)
{
    # CropString - Given a string, crops it below the maxlen and appends ... marks if needed, to indicate cropping
    # helloworld (len=10)
    # maxlen 5
    # 012345678901234
    # he...
    $MaxLen = [math]::Max(3,$MaxLen) # at least 3 (to fit ...)
    $sReturn = ""
    if ($StringtoCrop.length -le $MaxLen)
    {
        $sReturn = $StringtoCrop
    }
    else
    {
        $sReturn = $StringtoCrop.Substring(0,$MaxLen-3)
        $sReturn += "..."      
    }
    Return $sReturn
}
Function GetHashOfFiles ($FilePaths, $ByDateOrByContents="ByContents")
{
    # GetHashOfFiles - Give a list of filepaths, creates an MD5 hash of their content (ByContents) or their date time stamps (ByDate)
    # $sErr,$sHash = GetHashOfFiles $FilePaths ByDateOrByContents "ByDate"
	#
	# Sort so that files are always sorted the same across systems and cultures and powershells. Do this by sorting by the UTF8 byte array of each path.
    #$FilePaths = $FilePaths | Sort-Object {[system.Text.Encoding]::UTF8.GetBytes($_)|ForEach-Object ToString X2}
    $FilePaths = $FilePaths | Sort-Object {[system.Text.Encoding]::UTF8.GetBytes($_)}
    $sErr = "OK"
    $HashList = @()
    ForEach ($FilePath in $FilePaths)
    { # each file
        If (Test-Path $FilePath -PathType Leaf)
        { # file exists
            $Filethis = Get-ChildItem $FilePath
            # create object for results
            $entry_obj=[pscustomobject][ordered]@{
                Name          = $Filethis.Name
                LastWriteTime = $Filethis.LastWriteTime.ToUniversalTime().Tostring('yyyy-MM-dd HH:mm') # was yyyy-MM-dd hh:mm:ss but OneDrive changes ss by 1 as files are copied in out of OneDrive - also hh was 12 not 24
                Length        = $Filethis.Length
                HashType      = $ByDateOrByContents
                Hash          = ""
                Fullpath      = $FilePath
                }
            if ($ByDateOrByContents -eq "ByContents")
            { # ByContents (slower)
                $entry_obj.Hash = (Get-FileHash $FilePath -Algorithm MD5).Hash
            }
            else
            { # ByDate (date can be faked)
                $entry_obj.Hash ="$($entry_obj.name)|$($entry_obj.LastWriteTime)|$($entry_obj.Length)"
            }
            ### append object
            $HashList+=$entry_obj
        } # file exists
        Else
        { # file not found
            $sErr = "ERR: File not found: $($FilePath)"
        } # file not found
    } # each file
    # get a hash of all the strings
    $Hashstring= $HashList.Hash -join ", "
    $sHash= (Get-FileHash  -Algorithm MD5 -InputStream ([IO.MemoryStream]::new([char[]]$Hashstring))).Hash
    Return $sErr,$sHash,$HashList
}
Function ContentsHaveChanged ($filelines1, $filelines2)
{
    #ContentsHaveChanged - Given an array of strings from 2 files, identifies if they match or not.
    $changes_made = $false
    #compare contents
    if ($filelines1.count -eq $filelines2.count)
    { #line counts are same, look at contents for any differences
        $lines_total=$filelines2.count
        for ($line_t = 0 ; $line_t -lt $lines_total; $line_t++)
        {
            if ($filelines1[$line_t] -ne $filelines2[$line_t])
            { #found a difference, stop looking
                $changes_made = $true
                break
            }
        }  
    } #line counts are same, look at contents for any differences
    else {
        $changes_made = $true
    }
    Return $changes_made
}
Function WriteText ($line, $HostOrOutput="Output")
    {  ## Use this if you want to programmatically write to Write-Host or Write-Output.  Write-Output is for capturing output of a function. write-Host is for interactive display.
    if ($HostOrOutput -eq "Output")
	{Write-Output $line}
	else
	{Write-Host $line}
    }
Function Pause ($Message="Press any key to continue.")
    {
    If($psISE)
        {
        $S=New-Object -ComObject "WScript.Shell"
        $B=$S.Popup($Message,0,"Script Paused",0)
        Return
		}
	Else
		{
		Write-Host -NoNewline $Message
		$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183
		While ($Null -Eq $K.VirtualKeyCode -Or $I -Contains $K.VirtualKeyCode)
			{
			$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			}
		Write-Host "(OK)"
		}
    }
Function PauseTimed ()
	# Example:
	# PauseTimed -quiet:$quiet -secs 3
    {
    Param ## provide a comma separated list of switches
	    (
	    [switch]  $quiet  ## continue without input
        ,[int]    $secs=1 ## if quiet, will pause and display a note, use -secs=0 for no display
        ,[string] $prompt ## optional
	    )
    if ($quiet)
        {
        if (!($prompt))
            {
            $prompt = "<< Pausing for "+ $secs + " secs >>"
            }
        if ($secs -gt 0)
            {
            Write-Host $prompt
            Start-Sleep -Seconds $secs
            }
        }
    else
        {
        If($psISE)
            {
            ## IDE mode (development mode doesn't allow ReadKey)
            if (!($prompt)) {$prompt = "<Press Enter to continue>"}
            Read-Host $prompt
            #Write-Host $prompt
            #$S=New-Object -ComObject "WScript.Shell"
            #$B=$S.Popup($prompt,0,"Script Paused",0)
            }
        else
            {
            if (!($prompt)) {$prompt = "Press any key to continue (Ctrl-C to abort)..."}
            Write-Host -NoNewline $prompt
            # $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            # Write-Host
            $I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183
            While ($Null -Eq $K.VirtualKeyCode -Or $I -Contains $K.VirtualKeyCode)
                {
                $K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                ## write-host "keycode " $K.VirtualKeyCode
                }
			Write-Host "(OK)"
            }
        }
    }
Function PressEnterToContinue ($Prompt = "Press <Enter> to continue")
{
    Read-Host $Prompt | Out-Null
}
Function GlobalsSave ($Globals, $scriptXML)
    {
    Export-Clixml -InputObject $Globals -Path $scriptXML
    }

Function GlobalsLoad ($Globals, $scriptXML, $force=$true)
    <#
    .SYNOPSIS
    Reads or Creates an XML settings file
    .DESCRIPTION
    
    .PARAMETER Globals
    Array of variables definded by $Globals = @{} 
    .PARAMETER scriptXML
    File to store globals
    .PARAMETER force
    Create XML with defaults if not found
    .EXAMPLE
    
	########### Method 1 - Manually add and save globals
	## Globals Init with defaults                                            
    $Globals = @{}                                                           
    $Globals.Add("PersistentVar1","Testing")                                 
    $Globals.Add("PersistentVar2",17983)                                     
    $Globals.Add("PersistentVar3",(Get-Date))                                
    ### Reads or Creates an XML settings file
	$Globals = GlobalsLoad $Globals $scriptXML				                                         
    ## Globals used                                                          
    $Globals["PersistentVar1"] = "hello"                                     
    $Globals["PersistentVar2"] = "hello"                                     
    $Globals["PersistentVar3"] = "hello"                                     
    write-host ("PersistentVar1        : " + ($Globals["PersistentVar1"]))   
    write-host ("PersistentVar2        : " + ($Globals["PersistentVar2"]))   
    write-host ("PersistentVar3        : " + ($Globals["PersistentVar3"]))   
    ## Globals Persist to XML                                                
    GlobalsSave  $Globals $scriptXML
	########### Method 2 - Inline create globals and save defaults
	########### Load From XML
	$Globals=@{}
	$Globals=GlobalsLoad $Globals $scriptXML $false
	$GlobalsChng=$false
	# Note: these don't really work for booleans or blanks - if the default is false it's the same as not existing
	if (-not $Globals.last_rundate)       {$GlobalsChng=$true;$Globals.Add("last_rundate","0")}
	if (-not $Globals.last_runtime)       {$GlobalsChng=$true;$Globals.Add("last_runtime","0")}
	if (-not $Globals.admin_username)     {$GlobalsChng=$true;$Globals.Add("admin_username","-")}
	if (-not $Globals.Org_Excludes)       {$GlobalsChng=$true;$Globals.Add("Org_Excludes",("Org to Exclude 1","Org to Exclude 2"))}
	if (-not $Globals.Org_Includes)       {$GlobalsChng=$true;$Globals.Add("Org_Includes",("Org to Include 1","Org to Include 2"))}
	####
	if ($GlobalsChng) {GlobalsSave $Globals $scriptXML}
	########### Load From XML
    #>
    {
    if (-not ($Globals))
        {
        $ErrOut=211; $ErrMsg="No Globals provided" ; Write-Host ("Err "+$ErrOut+" ("+$MyInvocation.MyCommand+"): "+ $ErrMsg);Start-Sleep -Seconds 3; Exit($ErrOut)
        }
    if (-not ($scriptXML))
        {
        $ErrOut=212; $ErrMsg="No scriptXML provided" ; Write-Host ("Err "+$ErrOut+" ("+$MyInvocation.MyCommand+"): "+ $ErrMsg);Start-Sleep -Seconds 3; Exit($ErrOut)
        }
    if (-not(Test-Path($scriptXML)))
        {
        ## Save Globals to XML
        
        if ($force)
            {
            Write-Warning ("Creating a new file with default values: "+$scriptXML)
    	    Export-Clixml -InputObject $Globals -Path $scriptXML
            }
        else
            {
            Write-Warning "Couldn't find settings file. (Use '-force=`$true' option to create one)"
            }
        }
    else
        {
        ## Load Globals from XML
        $Globals = Import-Clixml -Path $scriptXML
        }
    return $Globals
    }
Function PowershellVerStop ($minver)
    {
    if ($PSVersionTable.PSVersion.Major -lt $minver)
        {
        $ErrMsg ="Requires Powershell v$minver"
        $ErrMsg+=" : You have Powershell v"+$PSVersionTable.PSVersion.Major
        $ErrMsg="Requires Powershell v$minver"
        $ErrOut=316;Write-Host ("Err "+$ErrOut+" ("+$MyInvocation.MyCommand+"): "+ $ErrMsg);Start-Sleep -Seconds 3; Exit($ErrOut)
        }
    }

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
Function CreateLocalUser2($username, $password, $desc, $GroupsList="Administrators")
{
    # New version uses new powershell cmdlets
    # Returns lines of informative text
    if ( [version]$PSVersionTable.PSVersion -gt [version]"7.0" )
    { # ps 7 doesn't allow New-LocalUser without this:
        import-module microsoft.powershell.localaccounts -UseWindowsPowerShell
    }
    $return = ""
    $return += "Create account: $($username) [$($desc)]..."
    $usr=Get-LocalUser -Name $username -ErrorAction SilentlyContinue
    if ($usr)
    {
        $return += "[Replacing account that already exists]..."
        $result=Remove-LocalUser -Name $username
    }
    # Create account
    if ($password)
    {
        $pass_secstr = ConvertTo-SecureString $password -AsPlainText -Force
        $result=New-LocalUser -Name $username -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Password $pass_secstr -Description $desc 
    }
    else
    {
        $result=New-LocalUser -Name $username -AccountNeverExpires -UserMayNotChangePassword -NoPassword -Description $desc
    }
    if ($result)
    {# user added
        $Groups=$GroupsList.split(',')
        ForEach ($Group in $Groups)
        { # Each Group
            $Group = $Group.Trim()
	        if ($Group)
		    { # nonblank
                $return += "[Add to group: $($Group)]..."
                $result=Add-LocalGroupMember -Group $Group -Member $username
		    } # nonblank
        } # Each Group
        $return += "OK"
    }# user added
    else
    {# no user added
        $return += "ERR: problem adding user"
    }# no user added
    Return $return
}
Function CreateLocalUser($username, $password, $desc, $computername, $GroupsList="Administrators")
    {
    <#
    .SYNOPSIS
    Creates a local admin user.
    .PARAMETER computername
    Computer where account is to be created, uses $env:computername if none provided.
    .PARAMETER username
    Account name to create
    .PARAMETER desc
    Description max is 48 chars
    .EXAMPLE
    $un="AdminUser"
    $ds="Replacement account for Administrator"
    $pw="ij;wiejn2-38974"
    CreateUser $un $pw $ds $pc "Administrators"
    #>
    if (-not ($computername)) {$computername=$env:computername}
    $adcomputer = [ADSI]"WinNT://$computername,computer"
    Write-Host ("Create:"+$username.PadRight(20)+"["+$desc+"]")
    $localUsers = $adcomputer.Children | Where-Object {$_.SchemaClassName -eq 'user'}  | ForEach-Object {$_.name[0].ToString()}
    if ($localUsers -contains $username)
        {
        Write-Host ("   [Delete existing user]")
        $adcomputer.delete("user", $username)
        }
    $user = $adcomputer.Create("user", $username)
    $user.SetPassword($password)
    $user.SetInfo()
    $user.description = $desc
    $user.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
    $user.SetInfo()
    $GroupsList.split(',') | ForEach-Object  {
        $Group="$_"
		if ($Group -ne "")
			{
			$adgroup = [ADSI]("WinNT://$computername/$Group,group")
			$adgroup.add("WinNT://$username,user")
			Write-Host ("   Add to Group: $Group")
			}
        }
    }
Function EncryptString ($StringToEncrypt, $Key = $null, $KeyAsString = "")
    {
    $EncryptedSS = ConvertTo-SecureString -AsPlainText -Force -String $StringToEncrypt
    if ($KeyAsString -eq "") {
        if (-not ($Key)) { ## default to a simple key
            [Byte[]] $Key = (1..16)
        }
    } # no KeyAsString
    else {  # KeyAsString
        # Input string (could be any length), convert the string to bytes and hash it using SHA256
        $longkey = [System.Text.Encoding]::UTF8.GetBytes($KeyAsString)
        $hashedKey = (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash($longkey)
        # Use the first 16, 24, or 32 bytes, depending on the encryption requirements
        # Use the first 32 bytes for a 256-bit key
        $Key = $hashedKey[0..31]
    } # KeyAsString
    $Encrypted = ConvertFrom-SecureString -key $Key -SecureString $EncryptedSS
    return $Encrypted
}
Function EncryptStringSecure ($StringToEncrypt)
    {
    $EncryptedSS = ConvertTo-SecureString -AsPlainText -Force -String $StringToEncrypt
    $Encrypted = ConvertFrom-SecureString -SecureString $EncryptedSS
    return $Encrypted
}
Function DecryptString ($StringToDecrypt, $Key = $null, $KeyAsString = "")
{
    if ($KeyAsString -eq "") {
        if (-not ($Key)) { ## default to a simple key
            [Byte[]] $Key = (1..16)
        }
    } # no KeyAsString
    else {  # KeyAsString
        # Input string (could be any length), convert the string to bytes and hash it using SHA256
        $longkey = [System.Text.Encoding]::UTF8.GetBytes($KeyAsString)
        $hashedKey = (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash($longkey)
        # Use the first 16, 24, or 32 bytes, depending on the encryption requirements
        # Use the first 32 bytes for a 256-bit key
        $Key = $hashedKey[0..31]
    } # KeyAsString
    $StringToDecryptSS= ConvertTo-SecureString -Key $key -String $StringToDecrypt
    $Decrypted=(New-Object System.Management.Automation.PSCredential 'N/A', $StringToDecryptSS).GetNetworkCredential().Password
    return $Decrypted
}
Function DecryptStringSecure ($StringToDecrypt)
    {
    $StringToDecryptSS= ConvertTo-SecureString -String $StringToDecrypt
    $Decrypted=(New-Object System.Management.Automation.PSCredential 'N/A', $StringToDecryptSS).GetNetworkCredential().Password
    return $Decrypted
}

Function RegGetX ($keymain, $keypath, $keyname)
### DOESN'T WORK - WITH EXPANDABLE ENV VARS - IT PRE-EXPANDS THEM
#########
## $ver=RegGet "HKCR" "Word.Application\CurVer"
#########
    {
    Switch ($keymain)
    {
        "HKCU" {If (-Not (Test-Path -path HKCU:)) {New-PSDrive -Name HKCU -PSProvider registry -Root Hkey_Current_User | Out-Null}}
        "HKCR" {If (-Not (Test-Path -path HKCR:)) {New-PSDrive -Name HKCR -PSProvider registry -Root Hkey_Classes_Root | Out-Null}}
    }
    $keymainpath = $keymain + ":\" + $keypath
    ## check if key even exists
    if (Test-Path $keymainpath)
        {
        ## check if value exists
        if ([string]::IsNullOrEmpty($keyname)) {$keyname="(default)"}
        if (Get-ItemProperty -Path $keymainpath -Name $keyname -ea 0)
            {
            $result=(Get-ItemProperty -Path $keymainpath -Name $keyname).$keyname
            }
	    }
    $result
    }


Function RegGet ($keymain, $keypath, $keyname)
#########
## $ver=RegGet "HKCR" "Word.Application\CurVer"
## $ver=RegGet "HKLM" "System\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections"
#########
    {
    $result = ""
    Switch ($keymain)
        {
            "HKLM" {$RegGetregKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keypath, $false)}
            "HKCU" {$RegGetregKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($keypath, $false)}
            "HKCR" {$RegGetregKey = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($keypath, $false)}
        }
    if ($RegGetregKey)
        {
        $result=$RegGetregKey.GetValue($keyname, $null, "DoNotExpandEnvironmentNames")
        }
    $result
    }

Function RegSet ($keymain, $keypath, $keyname, $keyvalue, $keytype)
#########
## RegSet "HKCU" "Software\Microsoft\Office\15.0\Common\General)" "DisableBootToOfficeStart" 1 "dword"
## RegSet "HKCU" "Software\Microsoft\Office\15.0\Word\Options" "PersonalTemplates" "%appdata%\microsoft\templates" "ExpandString"
#########
{
    ## Convert keytype string to accepted values keytype = String, ExpandString, Binary, DWord, MultiString, QWord, Unknown
    if ($keytype -eq "REG_EXPAND_SZ") {$keytype="ExpandString"}
    if ($keytype -eq "REG_SZ") {$keytype="String"}

    Switch ($keymain)
    {
        "HKCU" {If (-Not (Test-Path -path HKCU:)) {New-PSDrive -Name HKCU -PSProvider registry -Root Hkey_Current_User | Out-Null}}
    }
    $keymainpath = $keymain + ":\" + $keypath
    ## check if key even exists
    if (!(Test-Path $keymainpath))
        {
        ## Create key
        New-Item -Path $keymainpath -Force | Out-Null
        }
    ## check if value exists
    if (Get-ItemProperty -Path $keymainpath -Name $keyname -ea 0)
        ## change it
        {Set-ItemProperty -Path $keymainpath -Name $keyname -Type $keytype -Value $keyvalue}
    else
        ## create it
        {New-ItemProperty -Path $keymainpath -Name $keyname -PropertyType $keytype -Value $keyvalue | out-null }
}

Function RegSetCheckFirst ($keymain, $keypath, $keyname, $keyvalue, $keytype)
#########
## RegSetCheckFirst "HKCU" $Regkey $Regval $Regset $Regtype
#########
{
    $x=RegGet $keymain $keypath $keyname
    if ($x -eq $keyvalue)
        {$ret="[Already set] $keyname=$keyvalue ($keymain\$keypath)"}
    else
        {
        if (($x -eq "") -or ($null -eq $x)) {$x="(null)"}
        RegSet $keymain $keypath $keyname $keyvalue $keytype
        $ret="[Reg Set] $keyname=$keyvalue [was $x] ($keymain\$keypath)"
        }
    $ret
}


Function RegDel ($keymain, $keypath, $keyname)
#########
## RegDel "HKCU" "Software\Microsoft\Office\15.0\Common\General)" "DisableBootToOfficeStart"
#########
{
    Switch ($keymain)
    {
        "HKCU" {If (-Not (Test-Path -path HKCU:)) {New-PSDrive -Name HKCU -PSProvider registry -Root Hkey_Current_User | Out-Null}}
    }
    $keymainpath = $keymain + ":\" + $keypath
    ## check if key even exists
    if (Test-Path $keymainpath)
        {
        ## check if value exists
        if (Get-ItemProperty -Path $keymainpath -Name $keyname -ea 0)
            ## remove it
            {Remove-ItemProperty -Path $keymainpath -Name $keyname}
		}
}

Function PathtoExe ($Exe)
	{
	$ver=RegGet "HKLM" "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$Exe"
	## winword.exe
	## powerpnt.exe
	## excel.exe
	## outlook.exe
	if ($ver)
        {$ver}
    else
        {"(na:$Exe)"}
	}

Function AppVerb ($PathtoExe, $VerbStartsWith)
	#########
	## AppVerb "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE" "Pin"
    ## $PathtoExe = PathtoExe "winword.exe"
    ## Write-Host (AppVerb $PathtoExe "Pin")
	## Verbs: Open Properties Pin Unpin
	#########
	{
	$sa = new-object -c shell.application
	$pn = $sa.namespace("").parsename($PathtoExe)
	##Uncomment to show verbs
	##$pn.Verbs() | Select-Object @{Name="Verb";Expression={$_.Name.replace('&','')}}
	##
	$verb = $pn.Verbs() | where-object {$_.Name.Replace('&','') -like ($VerbStartsWith+'*')}
	if ($verb) 
		{
        Try {
            $verb.DoIt()
            "[OK] (" + $verb.Name.Replace('&','') + ") " + $PathtoExe
            }
        Catch{
            "[ERR] (" + $verb.Name.Replace('&','') + ") " + $PathtoExe +" "+ $_.Exception.Message
            }
		}
	else
		{
		"[APP ACTION NOT FOUND] (" + $VerbStartsWith + ") " + $PathtoExe
		}
	
	}

Function AppNameVerb ($AppName, $VerbStartsWith)
	#########
    ## AppNameVerb APPNAME VERB
    ## AppNameVerb (Shows all apps)
    ## AppNameVerb APPNAME (Shows all verbs)
    ## Ex:
	## AppNameVerb "Word 2016" "Pin to start"
    ## AppNameVerb "Microsoft Edge" "Unpin from Start"
    ## AppNameVerb "Microsoft Edge" "Unpin from taskbar"

    ## Write-Host (AppVerb $PathtoExe "Pin")
	## Verbs: Open Properties "Pin to Start" "Unpin from Start"
	#########
	{
    $Apps =(New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items()
    if (!($AppName))
        { ## Show List of apps
        $Apps | Sort-Object Name | Select-Object Name, Path
        }
    else
        {
        $App= $Apps | Where-Object{$_.Name -eq $AppName}
        if ((!$App))
            {"[APP NOT FOUND] (" + $AppName + ") Call 'AppNameVerb' with no params to show valid apps."}
        else
            {
            if (!($VerbStartsWith))
                { ## Show List of verbs
                $App.Verbs() | Select-Object @{Name="Verb";Expression={$_.Name.replace('&','')}}
                }
            else
                {
                $verb = $App.Verbs() | where-object {$_.Name.Replace('&','') -like ($VerbStartsWith+'*')}
                if (!($verb))
                    {"[APP ACTION NOT FOUND] ("+ $AppName + " > " + $VerbStartsWith + ") Call 'AppNameVerb APPNAME' with no verb to show valid verbs."}
                else
                    {
                    Try {
                        $verb.DoIt()
                        "[OK] (" + $verb.Name.Replace('&','') + ") " + $AppName
                        }
                    Catch{
                        "[ERR] (" + $verb.Name.Replace('&','') + ") " + $AppName +" "+ $_.Exception.Message
                        }
                    }
                }
            }
        }
    $remaining=[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Apps)
    Remove-Variable Apps
    ####

	}

Function AppRemove ($Appname)
	#########
	## Get-AppxPackage -AllUsers | Sort-Object Name  | Select-Object Name  ## Shows packages
    ##     Remove-AppxPackage
	## Get-AppxProvisionedPackage -online| Sort-Object DisplayName | Select-Object DisplayName
    ##     Remove-AppxProvisionedPackage -online -packagename $ProPackageFullName    | where {$_.Displayname -eq $App}).PackageName
    ## $Appname="Microsoft.MicrosoftSolitaireCollection"
    ## Get-AppxPackage -AllUsers "$Appname" | Remove-AppxPackage
    ## Get-AppxProvisionedPackage -online  | where {$_.Displayname -eq $Appname}
    ## $Packagename = "Microsoft.MicrosoftSolitaireCollection_3.7.1041.0_neutral_~_8wekyb3d8bbwe"
    ## Remove-AppxProvisionedPackage -Online -PackageName $Packagename
	## AppRemove "*CandyCrush*"
	## AppRemove "*phone*"
	## AppRemove "*zune*"
	## AppRemove "*SolitaireCollection*"
	## AppRemove "*XboxApp*"
	## AppRemove "*Twitter*"
	#########
	{  ## $Appname="Microsoft.XboxApp"
    If ($null -eq $Appname)
    {
        Get-AppxPackage -AllUsers | Sort-Object Name  | Select-Object Name
        return
    }
	$AppXNames=(Get-AppxPackage -AllUsers "$Appname")
 	If ($AppXNames)
		{
        $AppXName=$AppXNames[0].Name
        Write-Host "[APP REMOVE] $AppXName"
		Get-AppxPackage "$Appname" | Remove-AppXPackage
        $ProvisonedPackages=Get-AppxProvisionedPackage -online  | Where-Object {$_.Displayname -eq $AppXName}
        if ($ProvisonedPackages)
            {
            $PackageName=$ProvisonedPackages[0].PackageName
            Write-Host "[PACKAGE REMOVE] $PackageName"
            Remove-AppXProvisionedPackage -Online -PackageName $PackageName
            }
		}
	else
		{
		Write-Host "[APP NOT FOUND] $Appname"
		}
	}

# ----------------------------------------------------------------------------- 
# Script: Get-FileMetaDataReturnObject.ps1 
# Author: ed wilson, msft 
# Date: 01/24/2014 12:30:18 
# Keywords: Metadata, Storage, Files 
# comments: Uses the Shell.APplication object to get file metadata 
# Gets all the metadata and returns a custom PSObject 
# it is a bit slow right now, because I need to check all 266 fields 
# for each file, and then create a custom object and emit it. 
# If used, use a variable to store the returned objects before attempting 
# to do any sorting, filtering, and formatting of the output. 
# To do a recursive lookup of all metadata on all files, use this type 
# of syntax to call the function: 
# Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName 
# note: this MUST point to a folder, and not to a file. 
# ----------------------------------------------------------------------------- 
Function Get-FileMetaData
{ 
  <# 
   .Synopsis 
    This function gets file metadata and returns it as a custom PS Object  
   .Description 
    This function gets file metadata using the Shell.Application object and 
    returns a custom PSObject object that can be sorted, filtered or otherwise 
    manipulated. 
   .Example 
    Get-FileMetaData -folder "e:\music" 
    Gets file metadata for all files in the e:\music directory 
   .Example 
    Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName 
    This example uses the Get-ChildItem cmdlet to do a recursive lookup of  
    all directories in the e:\music folder and then it goes through and gets 
    all of the file metada for all the files in the directories and in the  
    subdirectories.   
   .Example 
    Get-FileMetaData -folder "c:\fso","E:\music\Big Boi" 
    Gets file metadata from files in both the c:\fso directory and the 
    e:\music\big boi directory. 
   .Example 
    $meta = Get-FileMetaData -folder "E:\music" 
    This example gets file metadata from all files in the root of the 
    e:\music directory and stores the returned custom objects in a $meta  
    variable for later processing and manipulation. 
   .Parameter Folder 
    The folder that is parsed for files  
   .Notes 
    NAME:  Get-FileMetaData 
    AUTHOR: ed wilson, msft 
    LASTEDIT: 01/24/2014 14:08:24 
    KEYWORDS: Storage, Files, Metadata 
    HSG: HSG-2-5-14 
   .Link 
     Http://www.ScriptingGuys.com 
 #Requires -Version 2.0 
 #> 
 Param([string[]]$folder) 
 foreach($sFolder in $folder) 
  { 
   $a = 0 
   $objShell = New-Object -ComObject Shell.Application 
   $objFolder = $objShell.namespace($sFolder) 
 
   foreach ($File in $objFolder.items()) 
    {  
     $FileMetaData = New-Object PSOBJECT 
      for ($a ; $a  -le 266; $a++) 
       {  
         if($objFolder.getDetailsOf($File, $a)) 
           { 
             $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  = 
                        $($objFolder.getDetailsOf($File, $a)) } 
            $FileMetaData | Add-Member $hash 
            $hash.clear()  
           } #end if 
       } #end for  
     $a=0 
     $FileMetaData 
    } #end foreach $file 
  } #end foreach $sfolder 
} #end Get-FileMetaData

Function Get-OSVersion ($method=1)
	{
    # returns
    # $OS[0] 10.0
    # and 
    # $OS[1] Windows 10
    # 
    if ($method -eq 1)
    {
	    $ver=[environment]::OSVersion.Version
	    ##(Get-WmiObject Win32_OperatingSystem).version
	    ##(Get-CimInstance Win32_OperatingSystem).version
        if (($ver.Major -eq 10) -and ($ver.Minor -eq 0) -and ($ver.Build -ge 22000))
        {
            $verbase = "11" + "." + $ver.Minor
        }
        else
        {
	        $verbase = "" + $ver.Major + "." + $ver.Minor
	    }
        $verdesc = switch ($verbase)
		    {
            "11.0" {"Win 11"}
		    "10.0" {"Win 10"}
		    "6.3"  {"Win 8.1"}
		    "6.2"  {"Win 8"}
		    "6.1"  {"Win 7"}
		    "6.0"  {"Win Vista"}
		    "5.1"  {"Win XP"}
		    default {"(Get-OSVersion) Unknown OS " + $verbase}
		    }
    }
    else
    {
        $computerInfo = Get-ComputerInfo
        $verbase= $($computerInfo.OsName)
        $verdesc= "$($computerInfo.OsName) ($($computerInfo.OSDisplayVersion)) v$($computerInfo.OsVersion) $($computerInfo.OsArchitecture)"

    }
	$verbase
	$verdesc
	}

Function ConvertPSObjectToHashtable
{
    ### Example Use:
    # $results = Invoke-WebRequest $url -Body $payload -UseBasicParsing -Method Post | ConvertFrom-Json
    # $LPResults = $results | ConvertPSObjectToHashtable
    # $users = $LPResults.Users.GetEnumerator()
    # foreach ($user in $users)
    ###
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}

Function CommandLineSplit ($line)
    {  ## Splits a commandline [1 string] into a exe path and an argument list [2 string].
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

Function Get-MsiDatabaseProperties () { 
    <# 
    .SYNOPSIS 
    This function retrieves properties from a Windows Installer MSI database. 
    .DESCRIPTION 
    This function uses the WindowInstaller COM object to pull all values from the Property table from a MSI 
    .EXAMPLE 
    Get-MsiDatabaseProperties 'MSI_PATH' 
    .PARAMETER FilePath 
    The path to the MSI you'd like to query 
    #> 
    [CmdletBinding()] 
    param ( 
    [Parameter(Mandatory=$True, 
        ValueFromPipeline=$True, 
        ValueFromPipelineByPropertyName=$True, 
        HelpMessage='What is the path of the MSI you would like to query?')] 
    [IO.FileInfo[]]$FilePath 
    ) 
 
    begin { 
        $com_object = New-Object -com WindowsInstaller.Installer 
    } 
 
    process { 
        try { 
 
            $database = $com_object.GetType().InvokeMember( 
                "OpenDatabase", 
                "InvokeMethod", 
                $Null, 
                $com_object, 
                @($FilePath.FullName, 0) 
            ) 
 
            $query = "SELECT * FROM Property" 
            $View = $database.GetType().InvokeMember( 
                    "OpenView", 
                    "InvokeMethod", 
                    $Null, 
                    $database, 
                    ($query) 
            ) 
 
            $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null) 
 
            $record = $View.GetType().InvokeMember( 
                    "Fetch", 
                    "InvokeMethod", 
                    $Null, 
                    $View, 
                    $Null 
            ) 
 
            $msi_props = @{} 
            while ($null -ne $record) { 
                $prop_name = $record.GetType().InvokeMember("StringData", "GetProperty", $Null, $record, 1) 
                $prop_value = $record.GetType().InvokeMember("StringData", "GetProperty", $Null, $record, 2) 
                $msi_props[$prop_name] = $prop_value 
                $record = $View.GetType().InvokeMember( 
                    "Fetch", 
                    "InvokeMethod", 
                    $Null, 
                    $View, 
                    $Null 
                ) 
            } 
 
            $msi_props 
 
        } catch { 
            throw "Failed to get MSI file version the error was: {0}." -f $_ 
        } 
    } 
}

function Get-FileMetaData2
    {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName","PSPath")]
        [string[]]$Path
        )
 
    begin
        {
        $oShell = New-Object -ComObject Shell.Application
        }
 
    process
        {
        $Path | ForEach-Object
            {
            if (Test-Path -Path $_ -PathType Leaf)
                {
                $FileItem = Get-Item -Path $_
                $oFolder = $oShell.Namespace($FileItem.DirectoryName)
                $oItem = $oFolder.ParseName($FileItem.Name)
                $props = @{}
                0..287 | ForEach-Object
                    {
                    $ExtPropName = $oFolder.GetDetailsOf($oFolder.Items, $_)
                    $ExtValName = $oFolder.GetDetailsOf($oItem, $_)
               
                    if (-not $props.ContainsKey($ExtPropName) -and ($ExtPropName -ne ''))
                        {
                        $props.Add($ExtPropName, $ExtValName)
                        }
                     }
                New-Object PSObject -Property $props
                }
            }
 
        }
 
    end 
        {
        $oShell = $null
        }
    }

Function Get-FileMetaDataFromFolders 
{ 
  <# 
   .Synopsis 
    This function gets file metadata (from an array of folders) and returns it as a custom PS Object  
   .Description 
    This function gets file metadata using the Shell.Application object and 
    returns a custom PSObject object that can be sorted, filtered or otherwise 
    manipulated. 
   .Example 
    Get-FileMetaData -folder "e:\music" 
    Gets file metadata for all files in the e:\music directory 
   .Example 
    Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName 
    This example uses the Get-ChildItem cmdlet to do a recursive lookup of  
    all directories in the e:\music folder and then it goes through and gets 
    all of the file metada for all the files in the directories and in the  
    subdirectories.   
   .Example 
    Get-FileMetaData -folder "c:\fso","E:\music\Big Boi" 
    Gets file metadata from files in both the c:\fso directory and the 
    e:\music\big boi directory. 
   .Example 
    $meta = Get-FileMetaData -folder "E:\music" 
    This example gets file metadata from all files in the root of the 
    e:\music directory and stores the returned custom objects in a $meta  
    variable for later processing and manipulation. 
   .Parameter Folder 
    The folder that is parsed for files  
   .Notes 
    NAME:  Get-FileMetaData 
    AUTHOR: ed wilson, msft 
    LASTEDIT: 01/24/2014 14:08:24 
    KEYWORDS: Storage, Files, Metadata 
    HSG: HSG-2-5-14 
   .Link 
     Http://www.ScriptingGuys.com 
 #Requires -Version 2.0 
 #> 
 Param([string[]]$folder) 
 foreach($sFolder in $folder) 
  { 
   $a = 0 
   $objShell = New-Object -ComObject Shell.Application 
   $objFolder = $objShell.namespace($sFolder) 
 
   foreach ($File in $objFolder.items()) 
    {  
     $FileMetaData = New-Object PSOBJECT 
      for ($a ; $a  -le 266; $a++) 
       {  
         if($objFolder.getDetailsOf($File, $a)) 
           { 
             $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  = 
                   $($objFolder.getDetailsOf($File, $a)) } 
            $FileMetaData | Add-Member $hash 
            $hash.clear()  
           } #end if 
       } #end for  
     $a=0 
     $FileMetaData 
    } #end foreach $file 
  } #end foreach $sfolder 
} #end Get-FileMetaData


Function Get-FileMetaData
{
# Returns meta data of a file
# Example returing ID 0,34,156
# $meta =  Get-FileMetaData $installer[0].Fullname (0,34,156)
# Example showing all IDs (might be slow)
# $meta =  Get-FileMetaData $installer[0].Fullname (0..288) $true
# Write-Host ( $meta.'File description' + " (v"+ $meta.'File version' + ") "  + $meta.Name) 
Param([string] $path, $propnums=(0..255), $showids = $false) 

$shell = New-Object -COMObject Shell.Application
$folder = Split-Path $path
$file = Split-Path $path -Leaf
$shellfolder = $shell.Namespace($folder)
$shellfile = $shellfolder.ParseName($file)
$FileMetaData = New-Object PSOBJECT 
ForEach ($propX In $propnums)
    {  
    $propval = $shellfolder.getDetailsOf($shellfile, $propX)
    if($propval) 
        { 
        $propnam = $shellfolder.getDetailsOf($shellfolder.items, $propX)
        if ($propnam -eq "")
            {
            $propnam = "{none}"
            }									 
        if ($showids) { write-host $propX.tostring() $propnam ":" $propval }
        ##
        $hash += @{ $propnam  =  $propval }
        $FileMetaData | Add-Member $hash
        $hash.clear()
        ##
        } 
    else
        {
        # write-host $propX.tostring()
        }
    }
$FileMetaData 
}

Function LeftChars 
{   #### Return Leftmost N chars (SubString errors are annoying to trap)
    #### Use -Elipses to indicate something was chopped (...)
    Param(
         [string] $Text
        ,[Int]    $Length=100
        ,[switch] $Column
        )
    if ($text.Length -le $Length)
    {#no chopping needed
        
        if ($Column)
        { # Pad with spaces
            $retval = $Text.PadRight($Length)
        }
        else
        { # Leave it
            $retval = $Text
        }
        
    }#no chopping needed
    else
    {#chopping needed
        if ($Column)
        {
            $dots = "..."
            $retval = $text.SubString(0, $Length - $dots.length)+$dots
        }
        else
        {
            $retval = $text.SubString(0, $Length)
        }
    }#chopping needed
    Return $retval
}
Function DatedFileName ($Logfile)
{
    # Ex: $x = DatedFileName ($logfile)
    # In  C:\Logfile\Logfile.txt
    # Out C:\Logfile\Logfile_2019-08-16_v01.txt
    # Out C:\Logfile\Logfile_2019-08-16_v02.txt
    $Return = $Logfile

    #[System.IO.Path] | Get-Member -Static
    #[System.IO.Path]::GetDirectoryName("c:\John\John.txt")
    #[System.IO.Path]::GetFileNameWithoutExtension("c:\John\John.txt")
    #[System.IO.Path]::GetExtension("c:\John\John.txt")
    #[System.IO.Path]::Combine("c:\John" , "John.txt")

    $ext = [System.IO.Path]::GetExtension($Logfile)
    $DatePart=(Get-Date).ToString("yyyy-mm-dd")
    $ver=0

    Do
    { ## keep looking until File 'Logfile_2019-08-16_vNN.txt' doesn't exist
        $ver+=1
        $Thisfile = [System.IO.Path]::GetFileNameWithoutExtension($Logfile) #Logfile
        $Thisfile += "_" + $DatePart #_2019-08-16
        $Thisfile += "_v" + $ver.ToString("##") #_v01
        if ($ext -ne "")
        {
            $Thisfile += $ext  #.csv
        }
        $Return = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($Logfile) , $Thisfile)
    }
    Until (!(Test-Path $Return )) 
    $Return ## Return this path
}
Function FilenameVersioned ($MyFile)
{
    # Ex: $x = FilenameVersioned ($MyFile)
    # In  C:\MyFile\MyFile.txt
	# Out C:\MyFile\MyFile.txt
    # Out C:\MyFile\MyFile_v01.txt
    # Out C:\MyFile\MyFile_v02.txt
    $Return = $MyFile
    #[System.IO.Path] | Get-Member -Static
    #[System.IO.Path]::GetDirectoryName("c:\John\John.txt")
    #[System.IO.Path]::GetFileNameWithoutExtension("c:\John\John.txt")
    #[System.IO.Path]::GetExtension("c:\John\John.txt")
    #[System.IO.Path]::Combine("c:\John" , "John.txt")
    $ext = [System.IO.Path]::GetExtension($MyFile)
    $ver=0
    While (Test-Path $Return)
    { ## keep looking until File 'MyFile_vNN.txt' doesn't exist
        $ver+=1
        $Thisfile = [System.IO.Path]::GetFileNameWithoutExtension($MyFile) #MyFile
        $Thisfile += "_v" + $ver.ToString("##") #_v01
        $Thisfile += $ext  #.csv
        $Return = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($MyFile) , $Thisfile)
    }
    $Return ## Return this path
}
Function FromUnixTime 
{   ### FromUnixTime(1570571081) returns 10/08/2019 @ 9:44pm (UTC)
    Param([Int32] $secsfrom1970) 
    #
    [datetime]$origin = '1970-01-01 00:00:00'
    $result = $origin.AddSeconds($secsfrom1970)
    # Return result
    $result
}
Function Get-IniFile {
    <#
    .SYNOPSIS
    Read an ini file.
    
    .DESCRIPTION
    Reads an ini file into a hash table of sections with keys and values.
    
    .PARAMETER filePath
    The path to the INI file.
    
    .PARAMETER anonymous
    The section name to use for the anonymous section (keys that come before any section declaration).
    
    .PARAMETER comments
    Enables saving of comments to a comment section in the resulting hash table.
    The comments for each section will be stored in a section that has the same name as the section of its origin, but has the comment suffix appended.
    Comments will be keyed with the comment key prefix and a sequence number for the comment. The sequence number is reset for every section.
    
    .PARAMETER commentsSectionsSuffix
    The suffix for comment sections. The default value is an underscore ('_').
    .PARAMETER commentsKeyPrefix
    The prefix for comment keys. The default value is 'Comment'.
    
    .EXAMPLE
    Get-IniFile /path/to/my/inifile.ini
    
    .NOTES
    The resulting hash table has the form [sectionName->sectionContent], where sectionName is a string and sectionContent is a hash table of the form [key->value] where both are strings.
    This function is largely copied from https://stackoverflow.com/a/43697842/1031534. An improved version has since been pulished at https://gist.github.com/beruic/1be71ae570646bca40734280ea357e3c.
    #>
    
    param(
        [parameter(Mandatory = $true)] [string] $filePath,
        [string] $anonymous = 'NoSection',
        [switch] $comments,
        [string] $commentsSectionsSuffix = '_',
        [string] $commentsKeyPrefix = 'Comment'
    )

    $ini = @{}
    switch -regex -file ($filePath) {
        "^\[(.+)\]$" {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
            if ($comments) {
                $commentsSection = $section + $commentsSectionsSuffix
                $ini[$commentsSection] = @{}
            }
            continue
        }
        "^(;.*)$" {
            # Comment
            if ($comments) {
                if (!($section)) {
                    $section = $anonymous
                    $ini[$section] = @{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = $commentsKeyPrefix + $CommentCount
                $commentsSection = $section + $commentsSectionsSuffix
                $ini[$commentsSection][$name] = $value
            }
            continue
        }
        "^(.+?)\s*=\s*(.*)$" {
            # Key
            if (!($section)) {
                $section = $anonymous
                $ini[$section] = @{}
            }
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value
            continue
        }
    }

    return $ini
}
Function Show-IniFile {
        [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline)] [hashtable] $data,
        [string] $anonymous = 'NoSection'
    )
	# $ini | Show-IniFile
    process {
        $iniData = $_

        if ($iniData.Contains($anonymous)) {
            $iniData[$anonymous].GetEnumerator() |  ForEach-Object {
                Write-Output "$($_.Name)=$($_.Value)"
            }
            Write-Output ''
        }

        $iniData.GetEnumerator() | ForEach-Object {
            $sectionData = $_
            if ($sectionData.Name -ne $anonymous) {
                Write-Output "[$($sectionData.Name)]"

                $iniData[$sectionData.Name].GetEnumerator() |  ForEach-Object {
                    Write-Output "$($_.Name)=$($_.Value)"
                }
            }
            Write-Output ''
        }
    }
}
Function Screenshot($jpg_path)
{
    Add-type -AssemblyName System.Drawing
    # Return resolution
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $Width = $Screen.Width
    $Height = $Screen.Height
    $Left = $Screen.Left
    $Top = $Screen.Top
    # Create graphic
    $screenshotImage = New-Object System.Drawing.Bitmap $Width, $Height
    # Create graphic object
    $graphicObject = [System.Drawing.Graphics]::FromImage($screenshotImage)
    # Capture screen
    $graphicObject.CopyFromScreen($Left, $Top, 0, 0, $screenshotImage.Size)
    # Save to file - Saves to c:\temp
    $screenshotImage.Save($jpg_path)
    # Dispose
    $screenshotImage.Dispose()
    $graphicObject.Dispose()
    # Report
    $return="Screenshot: [$($width) x $($height)] '$($jpg_path)'"
    $return
}
Function Get-PublicIPInfo
{
#
# ip       : 22.44.149.82
# hostname : rrcs-22-44-149-82.rr.com
# city     : Peoria
# region   : Chicago
# country  : IL
# loc      : 30.75,-33.9861
# org      : AS12271 Charter Communications Inc
# postal   : 30293
# timezone : America/Pacific
# readme   : https://ipinfo.io/missingauth
#
    $return = Invoke-RestMethod http://ipinfo.io/json
    $return
}
Function Get-CredentialInFile
{
    Param (
         [string] $credentialXML
        ,[String] $service ="smtp" #name of a service (can be anything)
		,[String] $logon ="logon"  #name of a logon (can be any sub-thing)
		,[boolean] $set=$false #true means set the credential (write), false means get the credential (read)
        ,[String] $password ="" 
    )
	<# The conflation with GlobalsSave at the end needs fixing.
	Note: 
	##### Read any existing password
    $smtp_pass = Get-CredentialInFile "$($scriptDir)\Credentials.xml" "SyncPlayerSMTP" "john_smith"
    $smtp_pass = Set-CredentialInFile "$($scriptDir)\Credentials.xml" "SyncPlayerSMTP" "john_smith" $smtp_pass
    #>
    $keyname = "$(${env:COMPUTERNAME})|$(${env:USERNAME})|$($service)|$($logon)"
    $pass_secstringastext = $AllCreds[$keyname]
    if (-not $set)
    {
        Try
        {
            ### ConvertTo-SecureString: SecureString_Plaintext >> SecureString (PSCreds use SecureString, XML stores SecureString_Plaintext)
            ##
            $encrypted = $pass_secstringastext | ConvertTo-SecureString  -ErrorAction Stop
            $credential = New-Object System.Management.Automation.PsCredential($logon, $encrypted) -ErrorAction Stop
            ##
            $return = $credential.GetNetworkCredential().password
            # -------------------------------------------------------
            # Create creds based on saved password using DPAPI.  
            # DPAPI is Microsoft's data protection method to store passwords at rest.  The files are only decryptable on the machine / user that created them.
            # 
            # Decrypt methods below are OK for debugging, as long as the decrypted values aren't saved
            #
            # Decrypt method 1
            # [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($pass_secstr_plaintext))
            #
            # Decrypt method 2
            # $PSCred.GetNetworkCredential().password
            # -------------------------------------------------------
        }
        Catch
        {
            Write-Warning "[Invalid or no password value for [$($keyname)]. Use 'Set-CredentialInFile' and try again."
            $return=$null
        }
        ## Globals Persist to XML
        if ($AllCreds["$($keyname)|Date_LastUsed"])
        {
            $AllCreds.Remove("$($keyname)|Date_LastUsed")
        }
        $AllCreds.Add("$($keyname)|Date_LastUsed",(Get-Date).ToString("yyyy-MM-dd hh:mm:ss"))
        GlobalsSave $AllCreds $credentialXML
    }
    if ($set)
    {
        # Save Cred to file
        if ($password)
        {
            $credential = Get-Credential -Message "Enter Password.  Press CANCEL to keep $("*" * $password.length)" -UserName $logon 
        }
        else
        {
            $credential = Get-Credential -Message "Enter Password" -UserName $logon 
        }
        
        if (-not $credential)
        {
            if ($password) 
            {
                $encrypted = ConvertTo-SecureString $password -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PsCredential($logon, $encrypted)
            }
        }
        if ($credential)
        {
            $pass_secstringastext = $credential.Password | ConvertFrom-SecureString ### saveable
            if ($AllCreds[$keyname])
                {
                    $AllCreds.Remove($keyname)
                }
            $AllCreds.Add($keyname,$pass_secstringastext)
            ###
            if ($AllCreds["$($keyname)|Date_Created"])
                {
                    $AllCreds.Remove("$($keyname)|Date_Created")
                }
            $AllCreds.Add("$($keyname)|Date_Created",(Get-Date).ToString("yyyy-MM-dd hh:mm:ss"))
            GlobalsSave $AllCreds $credentialXML
            #
            $return = $credential.GetNetworkCredential().password
        }
        else
        {
            $return = ""
        }
    }
    $return
}
Function Set-CredentialInFile
{
    Param (
         [string] $credentialXML
        ,[String] $service ="smtp"
		,[String] $logon ="logon"
        ,[String] $password =""
    )
	$return = Get-CredentialInFile $credentialXML $service $logon $true $password
    $return
}
Function VarExists
{
    Param ([String] $variable)
    if (Get-variable -Name $variable -ErrorAction SilentlyContinue)
    {
	    $true
    }
    else
    {
	    $false
    }
}
function PromptForString ($Prompt = "Enter your choice", $defaultValue = "")
{
    if ([string]::IsNullOrWhiteSpace($defaultValue)) {
    }
    else {
        $defaultPrompt = "Press Enter for default: "
        $defaultPrompt = $defaultPrompt.PadLeft($Prompt.Length +2, ' ')  # Line up the 2 prompts
        Write-Host $defaultPrompt -NoNewline
        Write-Host $defaultValue -ForegroundColor Yellow
        $Prompt = $Prompt.PadLeft($defaultPrompt.Length - 2, ' ') # Line up the 2 prompts
    }
    $userInput = Read-Host -Prompt $Prompt
    # Use the default value if the user presses Enter without typing anything
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $userInput = $defaultValue
    }
    Return $userInput
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
    $choices = "E&xit","&List","&Export","&Open"
    $choicen = AskForChoice "Choice:" -Choices ($choices) -DefaultChoice 0 -ShowMenu -ReturnString
    if ($choice -eq "Exit")
    { # Exit
        Exit
    }
    # Kind of like Pause or PressEnterToContinue but with a custom key and msg
    $x = AskForChoice -message "All Done" -choices @("&Done") -defaultChoice 0
    #>
    Param( $Message="Continue?"
        , $Choices=$null                  # an array of strings (choices)
        , $DefaultChoice = 0              # default to 1st entry
        , [Switch] $ChooseDefault=$false  # Don't prompt user, just pick the default
        , [Switch] $ShowMenu=$false       # Show a multi-line menu
        , [Switch] $ReturnString=$false)  # Return the string (instead of 0-n)
    $yesno=$false
    if (-not $Choices)
    {
        $Choices=@("&Yes","&No")
        $yesno=$true # We really want No to be 0, but 0 is always the first element (Yes)
    }
    If ($ShowMenu)
    { # ShowMenu
        Write-Host "$($message)" 
        Write-Host "".PadLeft($Message.Length, '-') # -----------
        For ($i = 0; $i -lt $Choices.Count; $i++)
        {
            if ($Choices[$i].Contains("&")) {
                $bracketchar = $Choices[$i].Split("&")[1][0] # My&Choice becomes C
            }
            else {
                $bracketchar = ""
            }
            $line = "[$($bracketchar)] "
            $line += $Choices[$i].Replace('&','')
            If ($i -eq $DefaultChoice) {
                $line += " (Default)"
            }
            Write-Host $line
        }
    } # ShowMenu
    ## show prompt text: if ISE since it's hidden from text output, or if choosedefault was selected
    If (($Host.Name -eq "Windows PowerShell ISE Host") -or ($ChooseDefault))
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
    if ($ReturnString) {
        Return $choices[$choice].Replace("&","")
    }
    else {
        Return $choice
    }
    ###
}
Function ArrayRemoveDupes {
    ### Removes Dupes from an array of strings, without sorting the array
    Param( $str_arr=@("string3","string1","string2","string3","string2"))  
    $return = @()
    ForEach ($str in $str_arr)
    {
		if (-not ($return.Contains($str))) {
			$return+=$str
		}
	}
    $return
}
Function Import-Vault
{  
	<#
	Import-Vault
	Export-Vault
	These commands securely store (using Windows DAPI encryption) a .csv file containing password columns etc on a machine.

	#Set the vault_folder (any folder you like, but this method keeps the vaults together)
	#They also set the appname which is used to distinguish different vault files.

	$vaultfolder = "PowershellVault"
	$appname = "LastPassAPI"
	$vault_folder = Join-Path (Split-Path -Path $scriptDir -Parent) $vaultfolder # Vault folder is '..\PowershellVault'

	#Create a blank unencrypted file
	$vault = Import-Vault $vault_folder -encrypted $false -vault_name $appname

	# Pause here and edit the unencrypted csv file
	# You can add any columns you like, but 1st col must be name (and unique) and columns called SecureXXX will be the ones that get encrypted

	# Export the Encrypted file (this is a safe file to save - it can only be opened on the computer and by the user that created it, using DAPI)
	Export-Vault $vault $vault_folder -encrypted $true -vault_name $appname

	#Done. You can now delete the unencrypted file

	# To use it in a program.  Note:
	$vaultfolder = "PowershellVault"
	$appname = "LastPassAPI"
	$vault_folder = Join-Path (Split-Path -Path $scriptDir -Parent) $vaultfolder # Vault folder is '..\PowershellVault'
	$vault = Import-Vault $vault_folder -encrypted $true -vault_name $appname

	# To edit / copy vault.  You need to VaultCopy.ps1 if you want to use it on another computer / user.
	Use the utility programs VaultCopy.ps1 and VaultEdit.ps1
	#>
    ##################
    # Usage:
    #
    # load vault values
	# $vaultfolder = "PowershellVault"
	# $appname = "LastPassAPI"
    # $vault_folder = Join-Path (Split-Path -Path $scriptDir -Parent) $vaultfolder # Vault folder is '..\PowershellVault'
	#
    # Create a blank unencrypted file
    # $vault = Import-Vault $vault_folder -encrypted $false -vault_name $appname
    #
    # Export the Encrypted file (this is a safe file to save - it can only be opened on the computer and by the user that created it, using DAPI)
    # Export-Vault $vault $vault_folder -encrypted $true -vault_name $appname
    #
    # Import the encyrpted file (it is unencrypted in memory)
    # $vault = Import-Vault $vault_folder -encrypted $true -vault_name $appname
    #
    # Export the encrypted file (Warning: delete this file when you are done - it contains plaintext passwords)
    # Export-Vault $vault $vault_folder -encrypted $false -vault_name $appname
    #
    # Used in a program
    #$vault_folder = Join-Path (Split-Path -Path $scriptDir -Parent) $vaultfolder # Vault folder is '..\PowershellVault'
    #$vault = Import-Vault $vault_folder -encrypted $true -vault_name $appname
    #
    # To edit the vault
    #$vault_folder = Join-Path (Split-Path -Path $scriptDir -Parent) $vaultfolder # Vault folder is '..\PowershellVault'
    #$vault = Import-Vault $vault_folder -encrypted $true -vault_name $appname
    #Export-Vault $vault $vault_folder -encrypted $false -vault_name $appname
    #
    ###################################################
    ##### Pause here and edit the unencrypted file in the vault folder (Plaintext.csv)
    ##### You can add any columns you like, but 1st col must be name (and unique) and columns called SecureXXX will be the ones that get encrypted
    ###################################################
    #$vault = Import-Vault $vault_folder -encrypted $false -vault_name $appname
    #Export-Vault $vault $vault_folder -encrypted $true -vault_name $appname
    ###################################################
    Param (
         [string]  $vault_folder="C:\VaultFiles"
        ,[boolean] $Encrypted=$true
        ,[string]  $Vault_name = "" # O365 or similar to prepend the vault file with
    )
    if (-Not (Test-Path -Path $vault_folder -PathType Container))
    {
        Throw "Couldn't find vault folder '$($vault_folder)'"
    }
    ##########
    if ($Vault_name -eq "")
    {
        $vault_filepre = "Vault_"
    }
    else
    {
        $vault_filepre = "Vault_$($Vault_name)_"
    }
    if ($encrypted)
    {
        $vault_filepost =""
    }
    else
    {
        $vault_filepost ="_PLAINTEXT"
    }
    $vault_file = "$($vault_folder)\$($vault_filepre)$($env:computername)_$($env:username)$($vault_filepost).csv"
    ############
    if (-Not (Test-Path -Path $vault_file -PathType Leaf))
    { #no vault file
        #Throw "Couldn't find vault file '$($vault_file)'"
        #
        #Encrypt using DAPI
        #$secstr_text = "P@ssword1" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
        #
        #Decrypt using DAPI
        #$str         = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($secstr))
        #
        if ($encrypted)
            { #if encrypted
            $secstr_text = "TestPassword" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
            } #if encrypted
        else
            { #not encrypted
            $secstr_text = "TestPassword"
            } #not encrypted
        $vault = [PSCustomObject]@{
            Name        = "TestName"
            SecureString= $secstr_text
            Description = "TestDescription"
            }
        Write-Warning "Couldn't find vault file, creating a template file: $($vault_file)"
        $vault | Export-Csv -Path $vault_file -Encoding ASCII -NoTypeInformation
        # Flip it back to plaintext
        $vault[0].SecureString = "TestPasssword"
    } #no vault file
    else
    { #found vault file
        $vault  = Import-Csv -Path $vault_file
        if ($encrypted)
        { #if encrypted
            # Decrypt vault
            ForEach ($v in $vault)
            {
                $cols = $v | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
                ## Decrypt on cols that are named 'Secure...'
                foreach ($col in $cols)
                {
                    if ($col -match "secure")
                    {
                        if ($v.$col -ne "")
                        {
                            #$Decrypted= [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($v.SecureString))
                            Try
                            {
                                $Decrypted = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString $v.$col)))
                                $v.$col = $Decrypted
                            }
                            Catch
                            {
                                Write-Warning "Couldn't decrypt"
                                $v | Format-Table | Out-String | Write-Host
                            }
                        } # not empty
                    } #must decrypt
                }# each col
            } #each row
        } #if encrypted
        Write-host "Import-Vault: $($vault_file)"
    } #found vault file
    # Return vault
    Return $vault
}
Function Export-Vault
{
    ### Saves a powershell vault array of names values
    Param (
        $vault
        ,[string]  $vault_folder="C:\VaultFiles"
        ,[boolean] $Encrypted=$true
        ,[string]  $Vault_name = ""   # O365 or similar to prepend the vault file with
    )
    if (-Not(Test-Path -Path $vault_folder -PathType Container))
    {
        Throw "Couldn't find vault folder '$($vault_folder)'"
    }
    ##########
    if ($Vault_name -eq "")
    {
        $vault_filepre = "Vault_"
    }
    else
    {
        $vault_filepre = "Vault_$($Vault_name)_"
    }
    if ($encrypted)
    {
        $vault_filepost =""
    }
    else
    {
        $vault_filepost ="_PLAINTEXT"
    }
    $vault_file = "$($vault_folder)\$($vault_filepre)$($env:computername)_$($env:username)$($vault_filepost).csv"
    ############
    if ($encrypted)
    { #if encrypted
        # copy vault
        $vault2 = $vault | Select-Object *
        # Encrypt vault
        ForEach ($v in $vault2)
        {
            $cols = $v | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
            ## Encrypt cols that are named 'Secure...'
            foreach ($col in $cols)
            {
                if ($col -match "secure")
                {
                    if ($v.$col  -ne "")
                    {
                        $secstr_text = $v.$col | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
                        $v.$col = $secstr_text
                    }
                }
            }
        }
        $vault2 | Export-Csv -Path $vault_file -Encoding ascii -NoTypeInformation
    } #if encrypted
    else
    { #not encrypted
        $vault | Export-Csv -Path $vault_file -Encoding ascii -NoTypeInformation
    } #not encrypted
    Write-host "Export-Vault: $($vault_file)"
    Return $null
}
Function AzureJoinInfo
{
    ############################################### 
    # Get AzureJoin info from registry keys
    $AZDevice_UserEmail = ""
    $AZDevice_TenantDisplayName = ""
    $AZDevice_TenantId = ""
    $AZUser_TenantDomain = ""
    $AZUser_UserId = ""
    ############################
    $subKey = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
    $guids = $subKey.GetSubKeyNames()
    foreach($guid in $guids) {
        $guidSubKey = $subKey.OpenSubKey($guid);
        $AZDevice_TenantId = $guidSubKey.GetValue("TenantId");
        $AZDevice_UserEmail = $guidSubKey.GetValue("UserEmail");
    }
    $subKey = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control\CloudDomainJoin\TenantInfo"
    $guids = $subKey.GetSubKeyNames()
    foreach($guid in $guids) {
        $guidSubKey = $subKey.OpenSubKey($guid);
        $AZDevice_TenantDisplayName = $guidSubKey.GetValue("DisplayName");
    }
    $subKey = Get-Item "HKCU:/SOFTWARE/Microsoft/Windows NT/CurrentVersion/WorkplaceJoin/AADNGC"
    $guids = $subKey.GetSubKeyNames()
    foreach($guid in $guids) {
        $guidSubKey = $subKey.OpenSubKey($guid);
        $AZUser_TenantDomain = $guidSubKey.GetValue("TenantDomain")
        $AZUser_UserId = $guidSubKey.GetValue("UserId")
    }
    $objProps = [ordered]@{ 
        AZDevice_UserEmail         = $AZDevice_UserEmail
        AZDevice_TenantDisplayName = $AZDevice_TenantDisplayName
        AZDevice_TenantID          = $AZDevice_TenantID
        AZUser_TenantDomain        = $AZUser_TenantDomain
        AZUser_UserId              = $AZUser_UserId
    } 
    $AZInfo = New-Object -TypeName psobject -Property $objProps 
    $AZInfo
    ###############################################
}
Function ComputerInfo
{
    ###############################################
    $computerInfo = Get-ComputerInfo
    $objProps = [ordered]@{ 
        Username              = $env:username
        Userdomain            = $env:userdomain
        CsName                = $computerInfo.CsName
        CsUserName            = $computerInfo.CsUserName
        LogonServer           = $computerInfo.LogonServer
        BiosManufacturer      = $computerInfo.BiosManufacturer
        BiosSeralNumber       = $computerInfo.BiosSeralNumber
        CsManufacturer        = $computerInfo.CsManufacturer
        CsModel               = $computerInfo.CsModel
        PowerPlatformRole     = $computerInfo.PowerPlatformRole
        CsPCSystemType        = $computerInfo.CsPCSystemType
        WindowsProductName    = $computerInfo.WindowsProductName
        } 
    $ComputerInfo = New-Object -TypeName psobject -Property $objProps 
    $ComputerInfo 
    ############################################### 
}
Function DiskFormat (
    $DiskNum = 3     
    ,$Letter = "G:"
    ,$Label = "Offsite (g:)"
    ,$AskFirst = "no"  #Note: yes doesn't really work because can't figure out how to detect user-cancel of Clear-Disk
    )
{
    $Letter = $Letter.Substring(0,1)
    $disk = Get-Disk $DiskNum
    if (-not ($disk))
        {$retval = "Err: No disk $($DiskNum)"}
    else
        {
        Try
        {
            Clear-Disk $DiskNum -RemoveData -Confirm:($AskFirst -eq "yes") -ErrorAction Stop
            $retval = "OK"
        }
        Catch
        {
            if ($_.Exception.Message -match "The disk has not been initialized")
            {$retval = "OK"}
            else
            {$retval = "Err: "+ $_.Exception.Message}
        }
        if ($retval -eq "OK")
        {
            Try
            {
                Initialize-Disk -Number $DiskNum -ErrorAction Stop
                New-Partition -DiskNumber $DiskNum -UseMaximumSize -DriveLetter $Letter -ErrorAction Stop| Out-Null
                Format-Volume -DriveLetter $Letter -FileSystem NTFS -NewFileSystemLabel $Label -ErrorAction Stop | Out-Null
                $retval = "OK: Disk $($DiskNum) formatted as $($Letter): [$($Label)]"
            }
            Catch
            {
                $retval = "Err: "+ $_.Exception.Message
            }
        }
    }
    $retval
}
Function DiskPartitions
{
    <#
    Usage:
    $DiskParts=DiskPartitions
    Write-Host $DiskParts.TextChart

    Info:
    $DiskPartitions is a table of Disks, Partitions (Volumes), Drive Letters
    $DiskChart is a text-based chart for printing

    Reference:
    Get-Partition
    Get-Disk
    Get-Volume
    #>
    $DiskPartitions= @() #Initialize an empty array
    #
    $disks=Get-Disk
    ForEach ($disk in $disks)
    {# Each Disk
        $parts = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue
        If (-not ($parts))
        { # No Parts
            # Create an object with defaults
                $ObjProps=[ordered]@{
                    DiskNum    = $disk.Number
                    DiskModel  = $disk.FriendlyName
                    DiskSize   = $disk.Size
                    Partition     = '-'
                    PartitionSize = 0
                    PartitionBoot = '-'
                    DiskVolLetter   = '-'
                    DiskVolName     = '-'
                    DiskVolSize     = 0
                    DiskVolFreeSpace= 0
                }
                $DiskPartitions +=$(New-Object psobject -Property $ObjProps)
        } # No Parts
        Else
        { # Has Parts
            ForEach ($part in $parts)
            { # Each Part
                # Create an object with defaults
                $ObjProps=[ordered]@{
                    DiskNum    = $disk.Number
                    DiskModel  = $disk.FriendlyName
                    DiskSize   = $disk.Size
                    Partition     = $part.PartitionNumber
                    PartitionSize = $part.Size
                    PartitionBoot = $part.IsBoot
                    DiskVolLetter   = '-'
                    DiskVolName     = '-'
                    DiskVolSize     = 0
                    DiskVolFreeSpace= 0
                }
        
                if ($part.DriveLetter)
                { # has logdisks ## We are assuming there's just 1 here, even though we pretend to loop
                    $vol = Get-Volume $part.DriveLetter
                    if ($vol)
                    { # Each logdisk
                        $ObjProps.DiskVolLetter     = $vol.DriveLetter+":"
                        $ObjProps.DiskVolName       = $vol.FileSystemLabel
                        $ObjProps.DiskVolSize       = $vol.Size
                        $ObjProps.DiskVolFreeSpace  = $vol.SizeRemaining
                    } # Each logdisk
                } # has logdisks
                $DiskPartitions +=$(New-Object psobject -Property $ObjProps)
            } # Each Part
        } # Has Parts
    }# Each Disk
    $DiskPartitions = $DiskPartitions | Sort-Object DiskNum, Partition
    ########### Text-based chart
    $col1 = 50
    $col2 = 18
    $col3 = 30
    $CurrDisk = ""
    $chart=@()
    $chart+= ("{0,-$($col1)} {1,-$($col2)} {2,-$($col3)}" -f "Disk","Partition","Letter")
    $chart+= ("{0,-$($col1)} {1,-$($col2)} {2,-$($col3)}" -f "----","---------","------")
    ForEach ($DiskPart in $DiskPartitions)
    {
        If ($CurrDisk -eq $DiskPart.DiskNum)
        {$DispDisk = "-"} #Same disk as last time
        else
        {
            $CurrDisk= $DiskPart.DiskNum
            $DispDisk = "[Disk $($DiskPart.DiskNum)] "
            $DispDisk += LeftChars $DiskPart.DiskModel ($col1-23)
            $DispDisk += " ($(BytestoString $DiskPart.DiskSize))"
        }
        $DispPart = "[P$($DiskPart.Partition)]"
        $DispPart += " ($(BytestoString $DiskPart.PartitionSize))"
        $DispDrive = $DiskPart.DiskVolLetter
        if (-not("-" -eq $DiskPart.DiskVolLetter))
        {
            $DispDrive += " $($DiskPart.DiskVolName)"
            $DispDrive += " ($(BytestoString $DiskPart.DiskVolSize))"
        }
        $chart+= ("{0,-$($col1)} {1,-$($col2)} {2,-$($col3)}" -f $DispDisk,$DispPart,$DispDrive)
    }
    $Diskchart=$chart -join "`r`n"
    ########### Text-based chart

    $retvals = "" | Select-Object -Property PartTable,TextChart
    $retvals.PartTable = $DiskPartitions
    $retvals.TextChart = $DiskChart
    return $retvals
}
Function Format-FileSize() {
    Param ([int64]$size)
    If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
    Else                   {"0B"}
}
Function BytestoString {
    Param
    (
        [Parameter(
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [long]$number
    )
    Begin{
        $sizes = 'B','KB','MB','GB','TB','PB'
    }
    Process {
        #
        if ($number -eq 0) {return '0 B'}
        $size = [math]::Log($number,1024)
        $size = [math]::Floor($size)
        $num = $number / [math]::Pow(1024,$size)
        $num = "{0:N2}" -f $num
        return "$num $($sizes[$size])"
        #
    }
    End{}
}
Function GetTempFolder (
    $Prefix = "Powershell_"     
    )
    <#
    Usage:
    $TmpFld=GetTempFolder -Prefix "MyCode_"
    Write-Host $TmpFld
    Explorer $TmpFld

    Info:
    Creates a temp folder.
    #>
{
    $tempFolderPath = Join-Path $Env:Temp ($Prefix + $(New-Guid))
    New-Item -Type Directory -Path $tempFolderPath | Out-Null
    Return $tempFolderPath
}
Function CopyFileIfNeeded ($source, $target, $CompareByHashOrDate="hash", $TargetIsFolder = $false)
# Copies a source file to a target file or folder
{
    # Only copies files that need copying (based on hash)
    # Returns status of copy
    # Usage: 
    #        $retcode, $retmsg= CopyFileIfNeeded $src $trg
    #        $retmsg | Write-Host
    $retcode=0 # 0 no files needed copying, 10 files needed copying but OK, 20 Error copying files
    $retmsg=@()
    if (-not (Test-Path -LiteralPath $source -PathType Leaf))
    { # no source file
        $retcode=20
        $retmsg+="ERR:20 Couldn't find source file '$($source)'"
    }
    else 
    { # has source file
        if (Test-Path -LiteralPath $target -PathType Leaf)
        { # target was passed as a file path (filename might be different)
            If ($TargetIsFolder) {
                $retcode=20
                $retmsg+="ERR:21 There is a conflict. Target is a file, but TargetIsFolder True expects a folder: $($target)"
            }
        }
        if ($retcode -eq 0)
        { # no target error
            If ($TargetIsFolder) { # target is a folder (might not even exist yet) so use the source filename
                $target_path = Join-Path $target (Split-Path $source -Leaf)
            }
            else { # target is apath
                $target_path = $target
            }
            # check target
            if (Test-Path -LiteralPath $target_path -PathType Leaf)
            { # File exists on both sides
                $File = Get-ChildItem -LiteralPath $source -File
                if ($CompareByHashOrDate -eq "hash")
                { #compare by hash
                    $source_check=Get-FileHash $File.FullName
                    $target_check=Get-FileHash $target_path
                    $compareresult = ($source_check.Hash -eq $target_check.Hash)
                } #compare by hash
                else
                { #compare by date,size
                    $tolerance_secs = 3 # allow for a few seconds of date diff due to OneDrive
                    $target_file = Get-ChildItem -LiteralPath $target_path -File
                    $compareresult = ($File.Length -eq $target_file.Length) `
                    -and ([Math]::Abs(($File.LastWriteTimeUtc - $target_file.LastWriteTimeUtc).TotalSeconds) -lt $tolerance_secs)
                } #compare by date,size
                if ($compareresult)
                {
                    $files_same=$true
                }
                else
                {
                    $files_same=$false
                    $copy_reason="Updated"
                }
            } # File exists on both sides
            else
            { # No Target file (or folder)
                $files_same=$false
                $copy_reason="Missing"
            } # No Target file (or folder)
            #########
            if ($files_same)
            { #files_same!
                $retmsg+= "OK:00 $($source) [already same file]"
            } #files_same!
            else
            { #not files_same
                New-Item -Type Dir (Split-Path $target_path -Parent) -Force | Out-Null #create folder if needed
                $result = Copy-Item -LiteralPath $source -destination $target_path -Force -PassThru
                if (-not($result)) {
                    $retmsg+= "CP:90 $($source) [$($copy_reason) but copy failed]"
                    if ($retcode -eq 0) {$retcode=90} #adjust return
                }
                Else {
                    $retmsg+= "CP:10 $($source) [$($copy_reason)]"
                    if ($retcode -eq 0) {$retcode=10} #adjust return
                }
            } #not files_same
        } # no target error
    } # has source file
    Return $retcode, $retmsg
}
Function CopyFilesIfNeeded ($source, $target,$CompareMethod="hash", $delete_extra=$false, $deeply=$true, $excludeFiles=@())
# Copies the contents of a source folder into a target folder (which must exist)
{
    # Only copies files that need copying, based on date or hash of contents.
    # Source can be a directory, a file, or a file spec.
    # Target must be a directory (will be created if missing)
    <# Usage:
        $src = "C:\Downloads\src"
        $trg = "C:\Downloads\trg"
        $retcode, $retmsg= CopyFilesIfNeeded $src $trg -CompareMethod "date"
        $retmsg | Write-Host
        Write-Host "Return code: $($retcode)"
    #>
    # $comparemethod
    # hash : based on hash (hash computation my take a long time for large files)
    # date : based on date,size
    #
    # $retcode
    # 0    : No files copied
    # 10   : Some files copied
    # 90   : Some files failed
    #
    # $delete_extra
    # false : extra files in target are left alone (default)
    # true  : extra files in target are deleted. resulting empty folders also deleted. Careful with this.
    #
    # $deeply
    # true  : subdirs are included (default)
    # false : no subdirs are traversed
    #
    # $retmsg
    # Returns a list of files with status of each (an array of strings)
    #
    $retcode=0 # 0 no files needed copying, 10 files needed copying but OK, 20 Error copying files
    $retmsg=@()
    ##
    
    if (Test-Path -LiteralPath $target -PathType Leaf)
    {
        $retcode=20
        $retmsg+="ERR:20 Couldn't find target '$($target)'"
    }
    else
    { # Target folder exists
        # Figure out what the 'root' of the source is
        if (Test-Path -LiteralPath $source -PathType Container) #C:\Source (a folder)
        {
            $sourceroot = $source
        }
        else # C:\Source\*.txt  (a wildcard)
        {
            $sourceroot = Split-Path $source -Parent
        }

        $retcode=0 #Assume OK
        if ($deeply){
            $Files = Get-ChildItem -LiteralPath $source -File -Recurse
        }
        else {
            $Files = Get-ChildItem -LiteralPath $source -File
        }
        if ($null -ne $excludeFiles)
        { # exclude?
            if ($excludeFiles -is [string]){ # force it to be an array of strings
                $excludeFiles = @($excludeFiles)
            }
            If ($excludeFiles.Count -gt 0){
                $Files = $Files  | Where-Object {-not ($excludeFiles -contains $_.Name)}
            }
        } # exclude?
        ForEach ($File in $Files)
        { # Each file
            $files_same=$false
            #############
            #$source
            #C:\Source\MSOffice Templates\MS Office Templates\Office2016_Themes
            #$file.FullName
            #C:\Source\MSOffice Templates\MS Office Templates\Office2016_Themes\MyTheme.thmx
            #$target
            #C:\Target\Microsoft\Templates\Document Themes
            #$target_path
            #C:\Target\Microsoft\Templates\Document Themes\MyTheme.thmx
            #
            $target_path = $file.FullName.Replace($sourceroot,$target)
            if (Test-Path -LiteralPath $target_path -PathType Leaf)
            { # File exists on both sides
                Write-Verbose "$($file.name) Bytes: $($file.length)"
                if ($CompareMethod -eq "hash")
                { #compare by hash
                    $source_check=Get-FileHash $File.FullName
                    $target_check=Get-FileHash $target_path
                    $compareresult = ($source_check.Hash -eq $target_check.Hash)
                } #compare by hash
                else
                { #compare by date,size
                    $tolerance_secs = 3 # allow for a few seconds of date diff due to OneDrive
                    $target_file = Get-ChildItem -LiteralPath $target_path -File
                    $compareresult = ($File.Name -eq $target_file.Name) `
                     -and ($File.Length -eq $target_file.Length) `
                     -and ([Math]::Abs(($File.LastWriteTimeUtc - $target_file.LastWriteTimeUtc).TotalSeconds) -lt $tolerance_secs)
                } #compare by date,size
                if ($compareresult)
                {
                    $files_same=$true
                }
                else
                {
                    $files_same=$false
                    $copy_reason="Updated"
                }
            } # File exists on both sides
            else
            { # No Target file (or folder)
                $files_same=$false
                $copy_reason="Missing"
            } # No Target file (or folder)
            #########
            if ($files_same)
            { #files_same!
                $retmsg+= "OK:00 $($file.FullName.Replace($sourceroot,'')) [already same file]"
            } #files_same!
            else
            { #not files_same
                New-Item -Type Dir (Split-Path $target_path -Parent) -Force | Out-Null #create folder if needed
                $result = Copy-Item -LiteralPath $File.FullName -destination $target_path -Force -PassThru
                if (-not($result)) {
                    $retmsg+= "CP:90 $($file.FullName.Replace($sourceroot,'')) [$($copy_reason) but copy failed]"
                    if ($retcode -eq 0) {$retcode=90} #adjust return
                }
                Else {
                    $retmsg+= "CP:10 $($file.FullName.Replace($sourceroot,'')) [$($copy_reason)]"
                    if ($retcode -eq 0) {$retcode=10} #adjust return
                }
            } #not files_same
        } # Each file
        if ($delete_extra)
        { # Delete extra files from target
            #$retcode=0 #Assume OK
            if ($deeply){
                $Files = Get-ChildItem -LiteralPath $target -File -Recurse
            }
            else {
                $Files = Get-ChildItem -LiteralPath $target -File
            }
            if ($null -ne $excludeFiles)
            { # exclude?
                if ($excludeFiles -is [string]){ # force it to be an array of strings
                    $excludeFiles = @($excludeFiles)
                }
                If ($excludeFiles.Count -gt 0){
                    $Files = $Files  | Where-Object {-not ($excludeFiles -contains $_.Name)}
                }
            } # exclude?
            ForEach ($File in $Files)
            { # Each file in target
                $source_path = $file.FullName.Replace($target,$source)
                if (-not(Test-Path -LiteralPath $source_path -PathType Leaf))
                { # No Source file, delete target
                    Remove-Item -LiteralPath $File.FullName -Force | Out-Null
                    $retmsg+= "DL:20 $($file.FullName.Replace($target,'')) [extra file removed]"
                    if (($file.DirectoryName -ne $target) -and (-not (Test-Path -Path "$($file.DirectoryName)\*")))
                    { # is parent an empty folder, remove it
                        Remove-Item -LiteralPath $File.DirectoryName -Force | Out-Null
                        $retmsg+= "DL:30 $($file.DirectoryName.Replace($target,'')) [empty folder removed]"
                    }
                } # No Source file, delete target
            } # Each file
        } # Delete extra files from target
    } # Target folder exists
    Return $retcode, $retmsg
}
Function GetMSOfficeInfo
#########
## Gets Office information from Registry: HKCR\Word.Application\CurVer
## Usage:
## $OfficeDescription, $OfficeName, $OfficeID=GetMSOfficeInfo
## write-host $OfficeDescription, $OfficeName, $OfficeID
#########
{
$ver=RegGet "HKCR" "Word.Application\CurVer"
Switch ($ver)
    {
        "Word.application.11" {$OfficeName="2003"; $OfficeID="11" ;$OfficeDescription=$OfficeName; break}
        "Word.application.12" {$OfficeName="2007"; $OfficeID="12" ;$OfficeDescription=$OfficeName; break}
        "Word.application.14" {$OfficeName="2010"; $OfficeID="14" ;$OfficeDescription=$OfficeName; break}
        "Word.application.15" {$OfficeName="2013"; $OfficeID="15" ;$OfficeDescription=$OfficeName; break}
        "Word.application.16" {$OfficeName="2016"; $OfficeID="16" ;$OfficeDescription="Office 365, 2019, 2016"; break}
        default {$OfficeName=""; $OfficeID="";$OfficeDescription=""; break}
    }
return $OfficeDescription, $OfficeName, $OfficeID
}
Function TimeSpanAsText 
{   ### TimeSpanAsText([timespan]::fromseconds(50000)
    Param([timespan] $ts) 
    #
    $result = ""
    if ($ts.Days -gt 0) {$result+=" $($ts.Days)d"}
    if ($ts.Hours -gt 0) {$result+=" $($ts.Hours)h"}
    if ($ts.Minutes -gt 0) {$result+=" $($ts.Minutes)m"}
    if ($ts.Seconds -gt 0) {$result+=" $($ts.Seconds)s"}
    $result = $result.Trim()
    # Return result
    $result
}
Function TimeSpanToString
{
    ## Returns a timespan in '6d 3h 2m 13s' format.
    ## TimeSpanToString -totalminutes 1440
    ## TimeSpanToString ((Get-Date) - $starttime)
    Param (
        [TimeSpan] $e
        ,[int] $totalminutes
        ,[string] $txt_d="d"
        ,[string] $txt_h="h"
        ,[string] $txt_m="m"
        ,[string] $txt_s="s"
    )
    if (-not ($e))
    {
        $e = New-TimeSpan -Minutes $totalminutes
    }
    $retval = ""
    if ($e.Days -gt 0)
    {
        $retval += " {0:d1}$($txt_d)" -f $e.Days
    }
    if ($e.Hours -gt 0)
    {
        $retval += " {0:d1}$($txt_h)" -f $e.Hours
    }
    if ($e.Minutes -gt 0)
    {
        $retval += " {0:d1}$($txt_m)" -f $e.Minutes
    }
    if ($e.Seconds -gt 0)
    {
        $retval += " {0:d2}$($txt_s)" -f $e.Seconds
    }
    Return $retval.Trim()
}
Function LogsWithMaxSize
{
    <#
    ### Generates a log file name for a folder, with the files totaling up to a certain size, grooming the oldest to make room.
    ### Note: grooming happens before file is saved, so folder size will go over by last file size
    Usage:
    $logfile = LogsWithMaxSize -Logfolder "C:\LogFolder" -MaxMB 5 -Prefix "Logs" -Ext "txt"
    #>
    Param (
        [string]  $LogFolder="C:\LogFolder"
        ,[int]     $MaxMB=5
        ,[string]  $Prefix = "Logs" ## C:\LogFolder\Logs_2021-03-21_hh-mm-ss.txt (will groom Logs_Vectors*.*)
        ,[string]  $Ext = "txt"
    )
    # Try to create folder if it doesn't exist
    if (-not (Test-Path -Path $LogFolder -PathType Container))
    {
        New-Item -ItemType Directory -Force -Path $LogFolder | Out-Null
        if (-Not(Test-Path -Path $LogFolder -PathType Container))
        {
            Throw "Could not create vault folder '$($LogFolder)'"
        }
    }
    # Prune old files up to MaxMB
    $MaxBytes = $MaxMB * 1MB
    $FilesBytes = 0
    $Logfiles = Get-ChildItem $LogFolder -Filter "$($Prefix)_*.$($Ext)"
    ForEach ($Logfile in ($Logfiles | Sort-Object LastWriteTime -Descending))
    {
        $fileinfo = "$($Logfile.Name) $($Logfile.LastWritetime) $(BytestoString $Logfile.Length)"
        $FilesBytes +=$Logfile.Length
        if ($FilesBytes -gt $MaxBytes)
        {
            #Write-Host "$($fileinfo) [Deleted]"
            $Logfile.Delete()
        }
        else
        {
            #Write-Host "$($fileinfo)"
        }
    }
    # Get a file name
    $datestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $retval = "$($LogFolder)\$($Prefix)_$($datestamp).$($Ext)"
    # Create 0 byte file to avoid collisions (but it's just a 'nice to have')
    New-Item -Path $retval -Type File -Force -ErrorAction SilentlyContinue |Out-Null
    # 
    Return $retval
}
Function ErrorMsg
{
    <#Usage:
    ## For Fatal errors the function never returns
    ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
    ## For Non-Fatal erros tt's useful to capture results back to the script
    $ErrCode,$ErrMsg=ErrorMsg -ErrCode 101 -ErrMsg "This is a warning"
    #>
    Param (
        [switch]   $Fatal = $false     ## Fatal exits the script immediately, otherwise just a warning with a pause
        ,[int]     $ErrCode = 0        ## A number related to the error
        ,[string]  $ErrMsg  = "There was a problem"
        ,[string]  $SemFileToDelete = ""  ## User can provide a semaphore (lock) file to delete if there's a fatal error
    )
    Write-Warning "($($ErrCode)) $($ErrMsg)"
    if ($Fatal)
        {
            If ($SemFileToDelete -ne "")
            { # Check SemFile
                If (Test-Path $SemFileToDelete)
                { # Found SemFile
                    Remove-Item $SemFileToDelete
                    If (Test-Path $SemFileToDelete)
                        { # Remove Fail
                            Write-Host "[Exiting] (failed to remove lock file $(Split-Path -Path $SemFileToDelete -Leaf))"
                        }
                    else
                        { # Remove OK
                            Write-Host "[Exiting]  (removed lock file $(Split-Path -Path $SemFileToDelete -Leaf))"
                        }
                } # Found SemFile
                else
                { # No Found SemFile
                    Write-Host "[Exiting] (no lock file to remove)"
                } # No Found SemFile
            } # Check SemFile
            else
            { # NoCheck SemFile
                Write-Host "[Exiting]"
            }
        }
    Start-Sleep -Seconds 3
    if ($Fatal)
    {
        Exit($ErrCode)
    }
    Return $ErrCode, $ErrMsg
}
Function IPSubnet {
    <#Usage:
    IPSubnet $_.IPAddress 24
    #>
    Param (
        [string]  $ipaddress  = "1.2.3.4"
        ,[int]     $subnet  = 24
    )
    $testipv4 = $ipaddress.Split(".")
    if ($testipv4.count -ne 4)
    {
        Write-Warning "IPSubnet - malformed IP: $($ipaddress)"
        $retval=$ipaddress
    }
    else
    {
        $retval=(Get-IPv4Subnet -IPAddress $ipaddress -PrefixLength $subnet).CidrID
    }
    Return $retval
}
Function Convert-IPv4AddressToBinaryString {
  Param(
    [IPAddress]$IPAddress='0.0.0.0'
  )
  $addressBytes=$IPAddress.GetAddressBytes()

  $strBuilder=New-Object -TypeName Text.StringBuilder
  foreach($byte in $addressBytes){
    $8bitString=[Convert]::ToString($byte,2).PadRight(8,'0')
    [void]$strBuilder.Append($8bitString)
  }
  Write-Output $strBuilder.ToString()
}
Function ConvertIPv4ToInt {
  [CmdletBinding()]
  Param(
    [String]$IPv4Address
  )
  Try{
    $ipAddress=[IPAddress]::Parse($IPv4Address)

    $bytes=$ipAddress.GetAddressBytes()
    [Array]::Reverse($bytes)

    [System.BitConverter]::ToUInt32($bytes,0)
  }Catch{
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}
Function ConvertIntToIPv4 {
  [CmdletBinding()]
  Param(
    [uint32]$Integer
  )
  Try{
    $bytes=[System.BitConverter]::GetBytes($Integer)
    [Array]::Reverse($bytes)
    ([IPAddress]($bytes)).ToString()
  }Catch{
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}

<#
.SYNOPSIS
Add an integer to an IP Address and get the new IP Address.
.DESCRIPTION
Add an integer to an IP Address and get the new IP Address.
.PARAMETER IPv4Address
The IP Address to add an integer to.
.PARAMETER Integer
An integer to add to the IP Address. Can be a positive or negative number.
.EXAMPLE
Add-IntToIPv4Address -IPv4Address 10.10.0.252 -Integer 10
10.10.1.6
Description
-----------
This command will add 10 to the IP Address 10.10.0.1 and return the new IP Address.
.EXAMPLE
Add-IntToIPv4Address -IPv4Address 192.168.1.28 -Integer -100
192.168.0.184
Description
-----------
This command will subtract 100 from the IP Address 192.168.1.28 and return the new IP Address.
#>
Function Add-IntToIPv4Address {
  Param(
    [String]$IPv4Address,

    [int64]$Integer
  )
  Try{
    $ipInt=ConvertIPv4ToInt -IPv4Address $IPv4Address `
      -ErrorAction Stop
    $ipInt+=$Integer

    ConvertIntToIPv4 -Integer $ipInt
  }Catch{
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}
Function CIDRToNetMask {
  [CmdletBinding()]
  Param(
    [ValidateRange(0,32)]
    [int16]$PrefixLength=0
  )
  $bitString=('1' * $PrefixLength).PadRight(32,'0')

  $strBuilder=New-Object -TypeName Text.StringBuilder

  for($i=0;$i -lt 32;$i+=8){
    $8bitString=$bitString.Substring($i,8)
    [void]$strBuilder.Append("$([Convert]::ToInt32($8bitString,2)).")
  }

  $strBuilder.ToString().TrimEnd('.')
}
Function NetMaskToCIDR {
  [CmdletBinding()]
  Param(
    [String]$SubnetMask='255.255.255.0'
  )
  $byteRegex='^(0|128|192|224|240|248|252|254|255)$'
  $invalidMaskMsg="Invalid SubnetMask specified [$SubnetMask]"
  Try{
    $netMaskIP=[IPAddress]$SubnetMask
    $addressBytes=$netMaskIP.GetAddressBytes()

    $strBuilder=New-Object -TypeName Text.StringBuilder

    $lastByte=255
    foreach($byte in $addressBytes){

      # Validate byte matches net mask value
      if($byte -notmatch $byteRegex){
        Write-Error -Message $invalidMaskMsg `
          -Category InvalidArgument `
          -ErrorAction Stop
      }elseif($lastByte -ne 255 -and $byte -gt 0){
        Write-Error -Message $invalidMaskMsg `
          -Category InvalidArgument `
          -ErrorAction Stop
      }

      [void]$strBuilder.Append([Convert]::ToString($byte,2))
      $lastByte=$byte
    }

    ($strBuilder.ToString().TrimEnd('0')).Length
  }Catch{
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}
<#
.SYNOPSIS
Get information about an IPv4 subnet based on an IP Address and a subnet mask or prefix length
.DESCRIPTION
Get information about an IPv4 subnet based on an IP Address and a subnet mask or prefix length
.PARAMETER IPAddress
The IP Address to use for determining subnet information. 
.PARAMETER PrefixLength
The prefix length of the subnet.
.PARAMETER SubnetMask
The subnet mask of the subnet.
.EXAMPLE
Get-IPv4Subnet -IPAddress 192.168.34.76 -SubnetMask 255.255.128.0
CidrID       : 192.168.0.0/17
NetworkID    : 192.168.0.0
SubnetMask   : 255.255.128.0
PrefixLength : 17
HostCount    : 32766
FirstHostIP  : 192.168.0.1
LastHostIP   : 192.168.127.254
Broadcast    : 192.168.127.255
Description
-----------
This command will get the subnet information about the IPAddress 192.168.34.76, with the subnet mask of 255.255.128.0
.EXAMPLE
Get-IPv4Subnet -IPAddress 10.3.40.54 -PrefixLength 25
CidrID       : 10.3.40.0/25
NetworkID    : 10.3.40.0
SubnetMask   : 255.255.255.128
PrefixLength : 25
HostCount    : 126
FirstHostIP  : 10.3.40.1
LastHostIP   : 10.3.40.126
Broadcast    : 10.3.40.127
Description
-----------
This command will get the subnet information about the IPAddress 10.3.40.54, with the subnet prefix length of 25.
#>
Function Get-IPv4Subnet {
  [CmdletBinding(DefaultParameterSetName='PrefixLength')]
  Param(
    [Parameter(Mandatory=$true,Position=0)]
    [IPAddress]$IPAddress,

    [Parameter(Position=1,ParameterSetName='PrefixLength')]
    [Int16]$PrefixLength=24,

    [Parameter(Position=1,ParameterSetName='SubnetMask')]
    [IPAddress]$SubnetMask
  )
  Begin{}
  Process{
    Try{
      if($PSCmdlet.ParameterSetName -eq 'SubnetMask'){
        $PrefixLength=NetMaskToCidr -SubnetMask $SubnetMask `
          -ErrorAction Stop
      }else{
        $SubnetMask=CIDRToNetMask -PrefixLength $PrefixLength `
          -ErrorAction Stop
      }
      
      $netMaskInt=ConvertIPv4ToInt -IPv4Address $SubnetMask     
      $ipInt=ConvertIPv4ToInt -IPv4Address $IPAddress
      
      $networkID=ConvertIntToIPv4 -Integer ($netMaskInt -band $ipInt)

      $maxHosts=[math]::Pow(2,(32-$PrefixLength)) - 2
      $broadcast=Add-IntToIPv4Address -IPv4Address $networkID `
        -Integer ($maxHosts+1)

      $firstIP=Add-IntToIPv4Address -IPv4Address $networkID -Integer 1
      $lastIP=Add-IntToIPv4Address -IPv4Address $broadcast -Integer -1

      if($PrefixLength -eq 32){
        $broadcast=$networkID
        $firstIP=$null
        $lastIP=$null
        $maxHosts=0
      }

      $outputObject=New-Object -TypeName PSObject 

      $memberParam=@{
        InputObject=$outputObject;
        MemberType='NoteProperty';
        Force=$true;
      }
      Add-Member @memberParam -Name CidrID -Value "$networkID/$PrefixLength"
      Add-Member @memberParam -Name NetworkID -Value $networkID
      Add-Member @memberParam -Name SubnetMask -Value $SubnetMask
      Add-Member @memberParam -Name PrefixLength -Value $PrefixLength
      Add-Member @memberParam -Name HostCount -Value $maxHosts
      Add-Member @memberParam -Name FirstHostIP -Value $firstIP
      Add-Member @memberParam -Name LastHostIP -Value $lastIP
      Add-Member @memberParam -Name Broadcast -Value $broadcast

      Write-Output $outputObject
    }Catch{
      Write-Error -Exception $_.Exception `
           }
  }
  End{}
}
Function IsOnBlacklist
{
<#
Checks if the IP is on a blacklist website
$ErrCode, $ErrMsg = IsOnBlacklist "1.2.3.4" "abuseipdb.com"
#>
    Param (
      [string]  $ip = "1.2.3.4"
      ,[string] $site = "abuseipdb.com"
    )
    $url = ""
    If ($site -eq "abuseipdb.com")
    {
        $url ="https://www.abuseipdb.com/check/$($ip)"
        $blackif = "was found in our database!"
    }
    Else
    {
        $retval = $false
        $retmsg = "Unknown blacklist site '$($site)'"
    }
    
    If ($url -ne "")
    {
        Try
        {
            $txt1 = Invoke-WebRequest $url -UseBasicParsing
            Start-Sleep -Milliseconds 500
            $txt2 = $txt1 | Select-Object -ExpandProperty RawContent
            $txt3 = $txt2 | Select-string $blackif
            ###
            If ($txt3)
            {
                $retval = $true
                $retmsg = "ERR Found IP on blacklist $($url)"
            }
            Else
            {
                $retval = $false
                $retmsg = "OK Not on blacklist $($IP)"
            }
        }
        Catch
        {
            $retval=$false
            $retmsg = "Warning $($IP), Couldn't lookup at $($url)"
        }
    }
    Return $retval, $retmsg
}
Function  UpdateXML
{
    Param (
        $xmlFilepath = "myfile.xml"
        ,$xmlPath = "NotepadPlus/GUIConfigs/GUIConfig"
        ,$xmlAttr = "auto-completion"
        ,$xmlValu = "<attrib>" # Set this to the value you want or <attrib> to set attribs
        ,$xmlAttrSubNam = 'autoCAction'  #ignored if xmlValu is not <attrib>
        ,$xmlAttrSubVal = '0'            #ignored if xmlValu is not <attrib>
    )
    [xml]$nppXML = Get-Content $xmlFilepath
    ###
    $xmlNode = $nppXML.SelectNodes($xmlPath) | Where-Object {$_.name -eq $xmlAttr}
    if (!($xmlNode))
    { #no node
        $msg = "[$($xmlPath)] $($xmlAttr) [NOT FOUND]"
    }
    else
    { #node found
        # which kind
        if ($xmlValu -eq "<attrib>")
            { # Setting an attrib
            if ($xmlNode.GetAttribute($xmlAttrSubNam) -eq $xmlAttrSubVal)
                {
                    $msg="[$($xmlPath)] $($xmlAttrSubNam)=$($xmlAttrSubVal) [Already Set]"
                }
                else
                {
                    $xmlValuOld = $xmlNode.GetAttribute($xmlAttrSubNam)
                    $xmlNode.SetAttribute($xmlAttrSubNam,$xmlAttrSubVal)            
                    $msg="[$($xmlPath)] $($xmlAttrSubNam)=$($xmlAttrSubVal) [Updated from '$($xmlValuOld)']"
                    $nppXML.Save($xmlFilepath)
                }
            } # Setting an attrib
        else
            { # Setting the text value
                if ($xmlNode.'#text' -eq $xmlValu)
                {
                    $msg="[$($xmlPath)] $($xmlAttr)=$($xmlValu) [Already Set]"
                }
                else
                {
                    $xmlValuOld = $xmlNode.'#text'
                    $xmlNode.'#text' = $xmlValu
                    $msg="[$($xmlPath)] $($xmlAttr)=$($xmlValu) [Updated from '$($xmlValuOld)']"
                    $nppXML.Save($xmlFilepath)
                }
            } # Setting the text value
        # which kind
    }  #node found
    Return $msg
}
Function FolderCreate
{
    <#
    ### Creates a Folder if it doesn't exist 
    Usage:
    FolderCreate -Folder "C:\LogFolder"
    #>
    Param (
        [string]  $Folder="C:\LogFolder"
        
    )
    if (-not (Test-Path -Path $Folder -PathType Container))
    {
        New-Item -ItemType Directory -Force -Path $Folder | Out-Null
        if (-Not(Test-Path -Path $Folder -PathType Container))
        {
            Throw "Could not create folder '$($Folder)'"
        }
    }
}
Function FolderSize
{
    <#
    ### Gets easily readable folder size info 
    Usage:
    $info = FolderSize $source
    #>
    Param (
        [string]  $Folder="C:\LogFolder"
    )

    if (-Not(Test-Path -Path $Folder -PathType Container))
    {
        Throw "No folder '$($Folder)'"
    }

    $foldersize = Get-ChildItem -Path $Folder -File -Recurse | 
    Measure-Object -Property Length -Sum | 
    Select-Object Sum, Count
    if ($foldersize)
    {
    # Return the properties in a custom object
    [PsCustomObject]@{
        Folder= $Folder
        Count = $foldersize.Count
        Bytes = $foldersize.Sum
        Size  = BytestoString $foldersize.Sum
        }
    }
    else
    {
    [PsCustomObject]@{
        Folder= $Folder
        Count = 0
        Bytes = 0
        Size  = "0 B"
        }
    }
}
Function FolderDelete {
    <#
    .SYNOPSIS
    Removes all files and folders within given path, recursively removing files first.
    .DESCRIPTION
    Satisfies OneDrive files on demand, where you can't remove non-empty folders (Remove-Item -Recurse -Force doesn't work)
    .PARAMETER Path
    Path to file/folder
    .PARAMETER SkipFolder
    Supply this switch if you do not want to delete top level folder
    .EXAMPLE
    FolderDelete -Path "C:\Support\GitHub\GpoZaurr\Docs"
    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        [alias('LiteralPath')][string] $Path,
        [switch] $SkipFolder
    )
    if ($Path -and (Test-Path -LiteralPath $Path)) {
        #### 1st Pass: Delete all files
        $Items = Get-ChildItem -LiteralPath $Path -Recurse -File
        foreach ($Item in $Items) {
            try {
                $Item.Delete()
            } catch {
                Write-Warning "Remove-ItemAlternative - Couldn't delete $($Item.FullName), error: $($_.Exception.Message)"
            }
        }
        #### Next Passes: Delete all folders (each pass will succeed only on deepest / empty folders)
        Do
        {
            $delete_count=0
            $Items = Get-ChildItem -LiteralPath $Path -Recurse -Directory
            foreach ($Item in $Items) {
                try {
                    $Item.Delete()
                    $delete_count +=1
                } catch {
                    #Write-Warning "Remove-ItemAlternative - Couldn't delete $($Item.FullName), error: $($_.Exception.Message)"
                }
            }
        } Until ($delete_count -eq 0) ## If something was deleted, try again
        #### Now delete top folder
        if (-not $SkipFolder) {
            $Item = Get-Item -LiteralPath $Path
            try {
                $Item.Delete($true)
            } catch {
                Write-Warning "Remove-ItemAlternative - Couldn't delete $($Item.FullName), error: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Warning "Remove-ItemAlternative - Path $Path doesn't exists. Skipping. "
    }
}
Function ChooseFromList ($package_paths, $title="Choose", $showmenu=$true)
{
    <### Examples
	# Built-in menu
    $menu = @()
    $menu += "Choice 1"
    $menu += "Choice 2"
    $choice=ChooseFromList $menu -Showmenu $true
    if ($choice -eq -1) {Write-Host "Exiting";Exit 0} Else {$choice +=1}
	# Custom Menu
	$i=0
	Write-Host ($orglist | Select-object @{N="ID";E={(++([ref]$i).Value)}},Org,Packages | Format-Table | Out-String)
	$choice=ChooseFromList $orglist.Org "Choose an Org (1 to $($i)" -showmenu $false
    #>
    ### prompt
    if ($showmenu) {Write-Host $title}
    $i=0
    $uichoice=@()
    $choice_list=@()
    $uichoice+=@("E&xit")
    if ($showmenu) {Write-Host "  X) Exit"}
    ForEach ($package_path in $package_paths)
    {
        $i++
        $uichoice += "&$($i)" #add to choices for menu
        $choice_obj=@(
            [pscustomobject][ordered]@{
            number=$i
            choiceval=$package_path
            }
        )
        if ($showmenu) {Write-Host "  $($i)) $($choice_obj.choiceval)"}
        ### append object
        $choice_list +=$choice_obj
    }
    if ($showmenu) {Write-Host "-----------------"}
    Write-Host "Enter a number from the list [X to Cancel]"
    #### Get input
    $message="Which one?"
    $choices = [System.Management.Automation.Host.ChoiceDescription[]] @($uichoice)
    [int]$defaultChoice = 0
    $choice = $host.ui.PromptForChoice("Choice",$title,$choices,$defaultChoice)
    if (($choice -eq 0) -or ($choice -eq -1)) #chose exit or clicked X
    {
        Write-Host "   Exiting." -ForegroundColor Yellow
        $return=-1
    }
    if ($return -ne -1)
    {
        $pkg = @($choice_list | Where-Object {($_.number -eq $choice)})
        if (!($pkg))
        { ## invalid number
            Write-Host "   Invalid choice." -ForegroundColor Yellow
            $return=-1
        }
        else
        {
            $return=$pkg.number-1
        }
    }
    ### prompt for package
    Return $return
}
Function SystemVersionIncrement ($version="0",$section=0)
{
    #system strings are of the format '2.20.1' (major,minor,rev) 
    #this increments section
    # 1: major (3.20.1)
    # 2: minor (2.21.1)
    # 3: rev (2.20.2)
    # 0: last section (2.20.2)
	# $newvalue = SystemVersionIncrement -version $app_found.displayversion -section 0
    ###############
    $return ="1"
    if ($Version)
    {
        ### convert to valid System.Version string
        $version = [string]$version #convert a possible number to a string
        $appver_arr=$Version.Split(".")
        if ($section -eq 0)
        { # last section
            $section=$appver_arr.count
        } # last section
        else
        { # section
            if ($section -gt $appver_arr.Count)
            { # add missing sections
                for ($i = $appver_arr.Count; $i -lt $section; $i++)
                {
                    $appver_arr+="0"
                }
            } # add missing sections
        } # section
        # increment section 1.2.3.4
        [int]$appver_arr[$section-1]+=1
        $return= $appver_arr -join(".")
    }
    Return $return
}
Function SystemVersionStringFromString ($Version)
{
    #system strings are of the format '2.20.001' (major,minor,rev) 
    #and must have at least major minor values, which this function enforces
    $return ="0.0"
    if ($Version)
    {
        ### convert to valid System.Version string
        $version = [string]$version #convert a possible number to a string
        $appver_arr=$Version.Split(".")
        if ($appver_arr.count -eq 0)
        { # nothing -> 0.0
            $appver_arr="0","0"
        }
        elseif ($appver_arr.count -eq 1)
        { # no minor -> x.0
            $appver_arr+="0"
        }
        $return= $appver_arr -join(".")
        ### convert to valid System.Version string
    }
    Return $return
}
Function ToDateOnlyStr ($DateTime, $Format = "yyyy-MM-dd")
{
    #Converts a date to a date-only string with the universal sorting format 2022-08-23
    $return =""
    if ($DateTime)
    {
        $DateTime = $DateTime -as [DateTime] #force convert to DateTime (if e.g. it's a string)
        $return = $DateTime.ToString($Format)
    }
    Return $return
}
Function GetWhoisData ($domain, $cache_hrs = 5, $exename = "whois.exe", $whoisexeargs = "-nobanner")
{
    #$ErrorActionPreference = 'Stop'
    $scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
    $scriptDir      = Split-Path -Path $scriptFullname -Parent
    ##
    $whoisexe = $scriptDir + "\" + $exename
    if (-not (Test-Path($whoisexe))) {write-host "Err 99: Couldn't find '$($whoisexe)'";Start-Sleep -Seconds 5;Exit(99)}
    ##

    <## whois values
    $whoisvars = New-Object System.Collections.Generic.List[System.Object]
    $whoistxt = $scriptDir + "\whois.txt"
    if (Test-Path($whoistxt))
    { # read potential variable names from whois.txt file
        [string[]]$arrWhois = Get-Content -Path $whoistxt
        foreach ($whoistxt_ln in $arrwhois)
        {
            $whoisvars.Add($whoistxt_ln.Split(":")[0]+":")
        }
    } # read potential variable names from whois.txt file
    else
    { # just use this list
        $whoisvars.Add("Domain name:")
        $whoisvars.Add("Registrar:")
        $whoisvars.Add("Registrar IANA ID:")
        $whoisvars.Add("Registrar WHOIS Server:")
        $whoisvars.Add("Name Server:")
        $whoisvars.Add("Creation Date:")
        $whoisvars.Add("Registered on:")
        $whoisvars.Add("Updated Date:")
        $whoisvars.Add("Last updated:")
        $whoisvars.Add("Registry Expiry Date:")
        $whoisvars.Add("Expiry date:")
    } # just use this list
    ## whoisvlues
    ##>

    ## set up a whois cache folder
    $path = $scriptDir + "\whois_cache"
    If(!(test-path $path))
    {
          New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
    $usecache = $false
    ## cache file name
    $whoistxt = $scriptDir + "\whois_cache\whois_" + $domain + ".txt"
    If(!(test-path $whoistxt))
    {
        $usecache = $false
        $whoisexe_output_cache = ""
    }
    else
    {
        ##
        $whoisexe_output_cache = Get-Content $whoistxt
        ##
        $lastWrite = (get-item $whoistxt).LastWriteTime
        $timespan = new-timespan -days 0 -hours $cache_hrs -minutes 0  #older than x hours
        if (((get-date) - $lastWrite) -gt $timespan) {
            $usecache = $false
        } else {
            $usecache = $true
        }
    }
    # runs the whoisexe program
    if ($usecache)
    {
        $whoisexe_output = $whoisexe_output_cache
    }
    else
    { # dont use cache
        $whoistries = 0
        $Keeptrying = $true
        Do
        {
            $whoistries += 1
            if ($whoistries -eq 2)
            {
                $Keeptrying = $false
            }
			$error.Clear()
			$EAC = $ErrorActionPreference #save existing
			$ErrorActionPreference = 'SilentlyContinue'
			###### Run an exernal whois.exe command (and capture output)
			$whoisexe_output = & $whoisexe -v $domain $whoisexeargs
			######
			if ($error[0])
			{
				# Write-Host "DEBUG: $($domain) Error $($error[0].ToString())"
			}
			$ErrorActionPreference = $EAC #restore existing
            $eula = "You must accept EULA"
            $whoisexe_output_ascii = -join ($whoisexe_output.ToCharArray() | Where-Object { $_ -ne "`0" }) # utf8? eliminate blank bytes
			if (($whoisexe_output -match $eula) -or ($whoisexe_output_ascii -match $eula))
			{
				Write-Host "Must accept EULA. Pausing 5s..." -ForegroundColor Green
				Start-Sleep 5
				$whoisexe_output = & $whoisexe -accepteula
				$Keeptrying = $true
			}
			elseif ($whoisexe_output -match "Rate limit exceeded")
			{
				Write-Host "Try $($whoistries): Rate limit exceeded. Pausing 5s..." -ForegroundColor Green
				Start-Sleep 5
				$Keeptrying = $true
			}
			else
			{
				$whoisexe_output = $whoisexe_output.where{$_ -ne ""}
				$whoisexe_output | Set-Content -path $whoistxt  # save to cache
				$Keeptrying = $false
			}

            if ($false)
            {
                # Write-Host "whois.exe -v domain $($domain): failed try # $($whoistries)"
            }
            
        } #do 
        Until ($Keeptrying -eq $false)
        ###
        if ($whoisexe_output -eq "")
        { # no output
            if ($whoisexe_output_cache -eq "")
            { # no cache
                Return $null
            } # no cache
            else
            { # cache
                $whoisexe_output = $whoisexe_output_cache
            } # cache
        } # no output
    } # dont use cache
    ###
    # create $whoisvars based on whoisexe_output
    ## whois values pass 1
    $whoisvars = New-Object System.Collections.Generic.List[System.Object]
    foreach ($line in $whoisexe_output|Where-Object{$_ -match ":"})
    { # look for lines with a :
        $line= $line.Trim()
        $delim_pos = $line.IndexOf(":")
        if ($delim_pos -ne -1)
        {
            $whoisvars.Add($line.Substring(0,$delim_pos+1).trim())
        }
    } # look for lines with:
    ## whoisvlues pass 2
    # create $whoisvars based on file
    ###
    $whoishash = @{}
    foreach ($line in $whoisexe_output|Where-Object{$_ -match ":"})
    { #loop through lines
        $line= $line.Trim()
        if (($whoisvars | ForEach-Object{$line.startswith($_)}) -contains $true)
        { #line is of interest
            # Write-Host $line
            $linehash = $line.split(":")
            $line_name = $linehash[0].Trim()
            $line_value = $line.Substring($line_name.Length+1,$line.Length - $line_name.Length - 1) #rest of line
            $line_value = $line_value.Trim()
            if ($line_value -eq "")
            {
                # write-host "DEBUG"
            }
            else
            { #line has value
                if (-not ($whoishash[$line_name]))
                { #hash add
                    if ($line_name -like "*date*")
                    {
                        $whoishash.Add($line_name,$line_value.Substring(0,10))
                    } #date
                    else
                    {
                        # DEBUG
                        # Write-Host "DEBUG Domain: $($domain) name:$($line_name) value:$($line_value)"
                        $whoishash.Add($line_name,$line_value)
                    } #not date
                } #hash add
            } #line has value
        } #line is of interest
    } #loop through lines
    Return $whoishash, $whoisexe_output
}
Function CreateShortcut ()
{
	# Example:
	# CreateShortcut -lnk_path $lnk_path -SourceExe $exe_path -exe_args $exe_args
	Param
	(
		[string]$lnk_path,
		[string]$exe_path,
		[string]$exe_args
	)
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($lnk_path)
	$Shortcut.TargetPath = $exe_path
	$Shortcut.Arguments = $exe_args
	$Shortcut.Save()
}
Function LocalAdmins
{
    #Usage $x = @(LocalAdmins)
    $administratorsAccount = Get-WmiObject Win32_Group -filter "LocalAccount=True AND SID='S-1-5-32-544'" 
    $administratorQuery = "GroupComponent = `"Win32_Group.Domain='" + $administratorsAccount.Domain + "',NAME='" + $administratorsAccount.Name + "'`"" 
    $locadmins_wmi = Get-WmiObject Win32_GroupUser -filter $administratorQuery | Select-Object PartComponent
    $locadmins = @()
    $count = 0
    $account_warnings = 0
    $msg_accounts =""
    foreach ($locadmin_wmi in $locadmins_wmi)
    {
        $user1 = $locadmin_wmi.PartComponent.Split(".")[1]
        $user1 = $user1.Replace('"',"")
        $user1 = $user1.Replace('Domain=',"")
        $user1 = $user1.Replace(',Name=',"\")
        $Status = ""
        $accountname = $user1.Split("\")[1]
        $locadmin_info = Get-LocalUser $accountname -ErrorAction SilentlyContinue
        if ($locadmin_info)
        {
            if (-not ($locadmin_info.Enabled))
            {
                $Status = " [Disabled]"
            }
        }
        if ($Status -eq "")
        {
            $count +=1
            $locadmins+="$($user1)$($Status)"
            Write-Output "$($user1)"
        }
    }
}
Function AddToCommaSeparatedString (
     $sElement = "pluto"
    ,$sList ="venus,mars,earth"
    ,$AddMethod="sort"            # Addmethod
    ,$delim_in=","                # separates inputs by this
    ,$delim_out=", ")             # returns output with this delim
{
    # Adds an element to a comma separated string
    # Dupes are removed
    # elements are sorted
    #
    # AddMethod
    # first      : adds as first element
    # last       : adds as last element
    # sort       : (default) resorts list and adds in sorted order - dupes removed, 
    # sortDupesOK: same but dupes allowed
    # remove     : removes element
    # removesort : removes element and sorts and removes dupes
    #
    <# Usage:
    $sListNew = AddToCommaSeparatedString "pluto" "venus ,mars, earth (our home)"
    $sListNew = AddToCommaSeparatedString "pluto" "venus ,mars, earth (our home)" -AddMethod="first"
    $sListNew = AddToCommaSeparatedString "pluto" "venus ,mars, earth (our home)" -AddMethod="last"

    $sList = "venus ,mars, earth (our home)"
    $sListNew = AddToCommaSeparatedString "pluto" $sList
    Write-Host "sList   :$($sList)"
    Write-Host "sListNew:$($sListNew)"
    exit
    #>
    ##
    $sReturn = ""
    if ($AddMethod -in @("first"))
    { # add to beginning
        $sList = "$($sElement),$($sList)"
    }
    if ($AddMethod -in @("last","sort","sortDupesOK"))
    { # add to end (or sorted since it doesn't matter where it's added)
        $sList = "$($sList),$($sElement)"
    }
    # convert to a list of trimmed items (omitting blanks)
    $arrList = ($sList -Split $delim_in)|ForEach-Object{$x=$_.Trim();if ($x -ne "") {$x}}
    ### sort list?
    if ($AddMethod -in @("sort","sortDupesOK","removesort"))
    { # sort
        if ($AddMethod -in @("sort","removesort"))
        { #sort and remove dupes (only works if sorted)
            $arrList = @($arrList | Sort-Object | Get-Unique)
        } 
        else
        { #just sort
            $arrList = @($arrList | Sort-Object)
        }
    }
    ### remove elements
    if ($AddMethod -in @("remove","removesort"))
    {
        $arrList = @($arrList | Where-Object { $_ -ne $sElement })
    }
    ### Return
    $sReturn = $arrList -join $delim_out
    Return $sReturn
}
Function CheckModuleInstalled($modulename)
{
    <#### Usage
    ####
    $module = "PSZoom"
    Write-Host "Module: $($module)..." -NoNewline
    $result = CheckModuleInstalled $module
    Write-Host $result -ForegroundColor Yellow
    If ($result.startswith("ERR"))
    { Pause; Exit}
    Import-Module $module
    ####
    #> 
    $retval = "OK"
    $x = Get-InstalledModule $modulename -ErrorAction SilentlyContinue
    if ($x)
    {
        $retval="OK: v$($x.Version)"
    }
    Else
    {
        $retval="ERR: Get-InstalledModule $($modulename) returned nothing. Try this: Install-Module $($modulename) -Scope AllUsers"
    }
    Return $retval
}
Function Coalesce ($list=@()){ 
    # Return first non-null entry in array
    <#
    Coalesce "a","b","c"
    Coalesce $null,"b","c"
    Coalesce $null,$null,"c"
    #>
    ForEach ($list_i in $list){
        if ($null -ne $list_i) {Return $list_i}
    }
}
Function Elevate
{ # elevate
    # Relaunches powershell.exe elevated
    # Usage:
    # Elevate $PSBoundParameters
    [CmdletBinding()]
    param($paramspassed)
    Write-Host "Elevating..."
    Start-Sleep 1
    # rebuild params
    foreach($k in $paramspassed.keys)
    {
        switch($paramspassed[$k].GetType().Name)
        {
            "SwitchParameter" {if($paramspassed[$k].IsPresent) { $argsString += "-$k " } }
            "String"          { $argsString += "-$k `"$($paramspassed[$k])`" " }
            "Int32"           { $argsString += "-$k $($paramspassed[$k]) " }
            "Boolean"         { $argsString += "-$k `$$($paramspassed[$k]) " }
        }
    }
    # script name
    $scriptFullname = $PSCmdlet.MyInvocation.PSCommandPath
    # rebuild the argument list
    $argumentlist ="-ExecutionPolicy Bypass -File `"$($scriptFullname)`" $($argsString)"
    # pspath
    $pspath = "$($PSHOME)\powershell.exe"
    if (-not (Test-Path $pspath -PathType Leaf)){
    $pspath = "$($PSHOME)\pwsh.exe"}
    if (-not (Test-Path $pspath -PathType Leaf)){
    $pspath = "powershell.exe"}
    # show command
    Write-Host "Command:" $pspath $argumentlist
    # launch elevated
    Try
    {
        Start-Process -FilePath $pspath -ArgumentList $argumentlist -Wait -verb RunAs
        Exit # stop current process since Start-Process 'took over'
    }
    Catch {
       Write-Host "Failed to start PowerShell elevated (raising error)" -ForegroundColor Yellow
       Start-Sleep 1
       Throw "Failed to start PowerShell elevated"
    }
} # elevate
Function LoadModule ($m, $providercheck = "", $checkver = $true) #nuget
{
    <#
    Example:
    # Load the module and show results
    $module= "ExchangeOnlineManagement" ; Write-Host "Loadmodule $($module)..." -NoNewline ; $lm_result=LoadModule $module ; Write-Host $lm_result
    # Misc commands
    Get-Module $module #shows modules available in this powershell session
    Get-InstalledModule $module | Format-List Name,Version,InstalledLocation #shows installed modules available on this machine
    Import-Module $module #brings module commands into powershell session (whatever module is installed on this machine)
    Remove-Module $module #removes module from this powershell session (doesn't uninstall module)
    # To Install/Update/Uninstall
    Get-InstalledModule $module | Format-List Name,Version,InstalledLocation #shows installed modules available on this machine
    Find-Module $module #Shows what is available online
    Install-Module -Name $module (run as admin)
    Install-Module -Name $module -RequiredVersion <PreviewVersion>  (run as admin)
    Install-Module -Name $module -AllowClobber -AllowPrerelease -SkipPublisherCheck (run as admin)
    Update-Module -Name $module #updates to latest (run as admin)
    Uninstall-Module -Name $module #Uninstalls module on this machine (run as admin)
    #>
    $strReturn = @()
    $bErr=$false
    If ($providercheck -ne "")
    { #install provider if needed
        write-verbose "Checking for PackageProvider $($providercheck)..."
        $prv = Get-PackageProvider|where-object{$_.name -eq $providercheck}
        if (-not $prv)
        {
            Install-PackageProvider -Name $providercheck -Force
            $strReturn +="(PackageProvider $($providercheck) installed)"
        }
    } #install provider if needed
    write-verbose "Checking for Module $($m)..."
    # If module is imported say that and do nothing
    $minfo = @(Get-Module | Where-Object {$_.Name -eq $m})
    If ($minfo)
    { # has Get-Module
        write-verbose "Module $($m) is already imported."
        # see what the latest version online is
        if ($checkver)
        { # checkver
            $mod_avail = Find-Module -Name $m -ErrorAction SilentlyContinue
            if ($mod_avail) { # found module online
                if ($minfo[0].Version.ToString() -eq $mod_avail[0].Version.ToString()) {
                    $strReturn+="v$($minfo[0].Version.ToString()) [Current version]"
                }
                else {
                    $strReturn+="v$($minfo[0].Version.ToString()) [Update available to v$($mod_avail[0].Version.ToString()). Suggestion: Open Powershell (as admin) and run Update-Module $($m)]"
                }
            } # found module online
            else { # no found module online
                $strReturn+="v$($minfo[0].Version.ToString()) (no online version found)"
            } # no found module online
        } # checkver
        Else { # not checkver
            $strReturn+="v$($minfo[0].Version.ToString()) (not checked for updates)"
        } # not checkver
    } # has Get-Module
    Else
    { # no Get-Module
        # If module is not imported, but available on disk then import
        $minfo = @(Get-Module -ListAvailable -Name $m| Where-Object {$_.Name -eq $m})
        if ($minfo)
        { # ListAvailable
            write-verbose "Module $($m) is available on disk, importing..."
            Import-Module $m
            $strReturn+="Imported v$($minfo[0].Version.ToString())"
            if ($checkver)
            { # checkver
                # see what the latest version online is
                $mod_avail = Find-Module -Name $m -ErrorAction SilentlyContinue
                if ($mod_avail)
                {
                    if ($minfo[0].Version.ToString() -eq $mod_avail[0].Version.ToString())
                    {
                        $strReturn+="Imported v$($minfo[0].Version.ToString()) [Current version]"
                    }
                    else
                    {
                        $strReturn+="Imported v$($minfo[0].Version.ToString()) [Update available to v$($mod_avail[0].Version.ToString()). Suggestion: Open Powershell (as admin) and run Update-Module $($m)]"
                    }
                }
                else {
                    $strReturn+="Imported v$($minfo[0].Version.ToString())"
                }
            } # checkver
            Else { # not checkver
                $strReturn+="v$($minfo[0].Version.ToString()) (not checked for updates)"
            } # not checkver   
        } # ListAvailable
        else
        { # No ListAvailable
            if ($checkver)
            { # checkver
                if (Find-Module -Name $m -ErrorAction SilentlyContinue)
                { # If module is not imported, not available on disk, but is in online gallery then install and import
                    If (IsAdmin)
                    { # admin
                        $msg = "About to run Install-Module $($m). You are an admin, is that OK?"
                        if (AskForChoice -Message $msg) {
                            write-verbose "Module $($m) is available online, downloading to disk (as admin to all users)..."
                            Install-Module -Name $m -Force -Scope AllUsers
                        }
                        else {
                            write-verbose "Module $($m) not installed (user aborted)"
                            $strReturn +="NOT_INSTALLED_ABORT"
                            $bErr=$true
                        }
                    } # admin
                    Else
                    { # no admin
                        $msg = "About to run Install-Module $($m). You are not an admin, is that OK? (not recommended)"
                        if (AskForChoice -Message $msg) {
                            write-verbose "Module $($m) is available online, downloading to disk (not an admin so as user)..."
                            Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                        }
                        else {
                            write-verbose "Module $($m) not installed (user aborted)"
                            $strReturn +="NOT_INSTALLED_ABORT"
                            $bErr=$true
                        }
                    } # no admin
                    if (-not $bErr) {
                        write-verbose "Module $($m) is available on disk, importing..."
                        Import-Module $m
                        $minfo = @(Get-Module -ListAvailable | Where-Object {$_.Name -eq $m})
                        $strReturn+="INSTALL v$($minfo[0].Version.ToString())"
                    }
                }
                else 
                { # If the module is not imported, not available and not in the online gallery then abort
                    write-verbose "Module $($m) not imported, not available and not in an online gallery, exiting."
                    $strReturn +="NOT_FOUND"
                    $bErr=$true
                }
            } # checkver
            Else
            { # not checkver
                $strReturn +="NOT_FOUND (online version not checked)"
                $bErr=$true
            } # not checkver
        } # No ListAvailable
    } # no Get-Module
    if ($bErr) {
        Return "ERR: "+ ($strReturn -join ", ")
    }
    Else {
        Return "OK: "+ ($strReturn -join ", ")
    }
} # Load Module
function CSVSettingsLoad ($csvFile="")
{
    # Returns a hashtable of settings from a CSV Settings file
    # Usage: 
    <# 
    # Load settings
    $csvFile = "$($scriptDir )\$($scriptBase) Settings.csv"
    $settings = CSVSettingsLoad $csvFile
    # Defaults
    $settings_updated = $false
    if ($null -eq $settings.Username) {$settings.Username = "MyName"; $settings_updated = $true}
    if ($null -eq $settings.Fullname) {$settings.Fullname = "My Full Name"; $settings_updated = $true}
    if ($settings_updated) {$retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"}
    # Use Settings
    Write-Host "Username: $($settings.Username)"
    Write-Host "Fullname: $($settings.Fullname)"
    $settings.Fullname = "George Washington"
    # Save Settings
    $retVal = CSVSettingsSave $settings $csvFile
    Write-Host $retVal
    #>
    $settings = @{} # empty hashtable
    If (Test-Path $csvFile) {
        $csvData = Import-Csv -Path $csvFile
        # Hashtable from a CSV with Name,Value entries
        foreach ($entry in $csvData) {$settings[$entry.Name] = $entry.Value}
    }
    else {
        CSVSettingsSave $settings $csvFile | Out-Null
    }
    $settings
}
function CSVSettingsSave ($settings, $csvFile="")
{
    # Saves settings to CSV
    # Usage: $retValue = CSVSettingsSave $settings $csvFile
    $init_needed = $true
    if ($settings){
        if ($settings.GetType().Name -eq "Hashtable"){
            if ($settings.Count -ne 0){
                $init_needed = $false
            }
        }
    }
    if ($init_needed){
        $settings["SettingsFileCreatedDate"] = Get-Date -format "yyyy-MM-dd"
        $settings["SettingsFileCreatedBy"] = "$($env:computername)\$($env:username)"
    }
    # Convert to a PSCustomObject and export to a CSV file
    $exportObject = $settings.GetEnumerator() | ForEach-Object {[PSCustomObject] @{Name=$_.Name;Value=$_.Value}}
    try {
        $exportObject | Sort-Object Name | Export-Csv -Path $csvFile
        $retValue = "$($settings.count) settings saved to $(Split-Path $csvFile -Leaf)"
    }
    catch {
        $retValue = "Problem saving $(Split-Path $csvFile -Leaf). (Is it open?)"
    }
    Return $retValue
}

function DownloadFileFromWeb {
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
function DownloadFileFromGoogleDrive {
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
function DownloadFileFromWebOrGoogleDrive {
    param (
        [string]$Url = "https://drive.google.com/file/d/xxxxxxxxxxx/view?usp=sharing"  ,
        [string]$Filename = $null, #"MyFile.zip",
        [string]$hash           = $null, #(Get-FileHash "$TmpFld\$filename" -Algorithm SHA256).Hash
        [boolean]$hideprogress  = $false
    )

    if ($Url -like "*drive.google.com*"){
        $retVal =  DownloadFileFromGoogleDrive -GoogleDriveUrl $url -filename $Filename -hash $hash -hideprogress $false
    }
    else{
        $retVal =  DownloadFileFromWeb -WebUrl $url -filename $Filename -hash $hash -hideprogress $false
    }
    $retVal
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
Function PNPUtiltoObject($pnpcmd = "pnputil.exe /enum-drivers") 
{ # PNPUtiltoObject
    ### Converts the output of pnputil command into a powershell object
    #$pnpcmd = "pnputil.exe /enum-drivers"
    #$pnpcmd = "pnputil.exe -e"
    $pnpout= Invoke-Expression $pnpcmd
    $pnp_objs=@()
    $cols=@()
    foreach ($line in $pnpout)
        { ## foreach line
        if ($line -ne "Microsoft PnP Utility")
            { #not file header
            if (-not $line.Contains(":"))
                {   #### line feed - save row
                if ($cols)
                    {$pnp_obj=@([pscustomobject][ordered]@{})
                    foreach ($col in $cols) {
                        $pnp_obj | Add-Member -MemberType NoteProperty -Name $col.Name -Value $col.Data
                    }
                    $pnp_objs += $pnp_obj
                    }
                $cols=@()
                }   #### line feed - save row
            else
                {   #### collect this row's columns
                $col_obj=@([pscustomobject][ordered]@{
                    Name=$line.Substring(0,$line.Indexof(":")).Trim()
                    Data=$line.Substring($line.Indexof(":")+1).Trim()
                })
                $cols+=$col_obj
                }   #### collect this row's columns
            } #not file header
        } ## foreach line
    $pnp_objs
} # PNPUtiltoObject

# END OF FILE