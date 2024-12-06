###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main 
Param ## provide a comma separated list of switches
	(
	[switch] $quiet
	)
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

WriteText "-----------------------------------------------------------------------------"
WriteText ("$scriptName        Computer:$env:computername User:$env:username PSver:"+($PSVersionTable.PSVersion.Major))
if ($quiet) {WriteText ("<<-quiet>>")}
WriteText ""
WriteText "IE User Settings"
WriteText ""
WriteText "- Changes the default search provider to Google"
WriteText "- IE Home page to google, Don't warn on close"
WriteText ""
WriteText "-----------------------------------------------------------------------------"

##If (-not(IsAdmin))
##    {
##    $ErrOut=101; WriteText "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
##    }
if ($quiet) {PauseTimed -quiet} else {PauseTimed}

WriteText "- Change the default search provider to Google"
#### is default already google?
$keyroot="HKCU"
$keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes"
$keysetting="DefaultScope"
$DefaultScope=RegGet $keyroot $keypath $keysetting

$keyroot="HKCU"
$keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$DefaultScope"
$keysetting="Displayname"
$displayname=RegGet $keyroot $keypath $keysetting

if ($displayname -eq "Google")
    {
    ## $ErrOut=101; WriteText "Err $ErrOut : Nothing to change. Default is already Google";if ($quiet) {PauseTimed -quiet} else {PauseTimed}; Exit($ErrOut)
	WriteText "Google is already the default search provider."
    }
else
    {
    ### START: Change search scope

    #### is google listed, just not default? (prompts user)
    $keyroot="HKCU"
    $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes"
    # search for Google scopes
    $foundGoogle=$false
    $scopes = Get-ChildItem ($keyroot +":" + $keypath)
    foreach ($scope in $scopes) 
        {
            $displayname=RegGet $keyroot ($keypath+"\"+$scope.PSChildName) "Displayname"
            if ($displayname -eq "Google")
                {
                writetext (($scope.PSChildName) +" Set Default to Google:" + $keypath+"\"+$scope.PSChildName)
                $keysetting="DefaultScope"
                $keyval=$scope.PSChildName
                $keytype="String" #Dword, String, ExpandString
                RegSet $keyroot $keypath $keysetting $keyval $keytype
                $foundGoogle=$true
                }
            else
                {
                writetext (($scope.PSChildName) +" leave $displayname")
                }
        }


    if (!($foundGoogle))
        {
        ### START: Add Google
        #### Add google (prompts user)
        $guid= [Guid]::NewGuid()
        $guid="{"+ $guid.ToString().ToUpper() + "}"
        WriteText "- Internet Explorer\SearchScopes\$guid"

        $keyroot="HKCU"
        $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$guid"
        $keysetting="DisplayName"
        $keyval="Google"
        $keytype="String" #Dword, String, ExpandString
        $x=RegGet $keyroot $keypath $keysetting
        RegSet $keyroot $keypath $keysetting $keyval $keytype
        WriteText "$keysetting=$keyval [$keytype]"
        # WriteText "Old value: $x   New Value: $keyval"

        $keyroot="HKCU"
        $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$guid"
        $keysetting="FaviconURL"
        $keyval="https://www.google.com/favicon.ico"
        $keytype="String" #Dword, String, ExpandString
        $x=RegGet $keyroot $keypath $keysetting
        RegSet $keyroot $keypath $keysetting $keyval $keytype
        WriteText "$keysetting"
        # WriteText "Old value: $x   New Value: $keyval"

        ## Copy favicon.ico from web to local
        $favweb = $keyval
        $favlocal = $env:LOCALAPPDATA+"Low\Microsoft\Internet Explorer\Services"
        if (Test-Path($favlocal))
            {
            Invoke-WebRequest -Uri $favweb -OutFile ($favlocal+"\search_$guid.ico")
            $keyroot="HKCU"
            $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$guid"
            $keysetting="FaviconPath"
            $keyval=($favlocal+"\search_$guid.ico")
            $keytype="String" #Dword, String, ExpandString
            $x=RegGet $keyroot $keypath $keysetting
            RegSet $keyroot $keypath $keysetting $keyval $keytype
            WriteText "$keysetting"
            # WriteText "Old value: $x   New Value: $keyval"
            }

        $keyroot="HKCU"
        $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$guid"
        $keysetting="OSDFileURL"
        $keyval="https://www.microsoft.com/en-us/IEGallery/GoogleAddOns"
        $keytype="String" #Dword, String, ExpandString
        $x=RegGet $keyroot $keypath $keysetting
        RegSet $keyroot $keypath $keysetting $keyval $keytype
        WriteText "$keysetting"
        # WriteText "Old value: $x   New Value: $keyval"

        $keyroot="HKCU"
        $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$guid"
        $keysetting="ShowSearchSuggestions"
        $keyval="1"
        $keytype="Dword" #Dword, String, ExpandString
        $x=RegGet $keyroot $keypath $keysetting
        RegSet $keyroot $keypath $keysetting $keyval $keytype
        WriteText "$keysetting"
        # WriteText "Old value: $x   New Value: $keyval"

        $keyroot="HKCU"
        $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$guid"
        $keysetting="SuggestionsURL"
        $keyval="https://www.google.com/complete/search?q={searchTerms}&client=ie8&mw={ie:maxWidth}&sh={ie:sectionHeight}&rh={ie:rowHeight}&inputencoding={inputEncoding}&outputencoding={outputEncoding}"
        $keytype="String" #Dword, String, ExpandString
        $x=RegGet $keyroot $keypath $keysetting
        RegSet $keyroot $keypath $keysetting $keyval $keytype
        WriteText "$keysetting"
        # WriteText "Old value: $x   New Value: $keyval"

        $keyroot="HKCU"
        $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes\$guid"
        $keysetting="URL"
        $keyval="https://www.google.com/search?q={searchTerms}&sourceid=ie7&rls=com.microsoft:{language}:{referrer:source}&ie={inputEncoding?}&oe={outputEncoding?}"
        $keytype="String" #Dword, String, ExpandString
        $x=RegGet $keyroot $keypath $keysetting
        RegSet $keyroot $keypath $keysetting $keyval $keytype
        WriteText "$keysetting"
        # WriteText "Old value: $x   New Value: $keyval"

        $keyroot="HKCU"
        $keypath="SOFTWARE\Microsoft\Internet Explorer\SearchScopes"
        $keysetting="DefaultScope"
        $keyval=$guid
        $keytype="String" #Dword, String, ExpandString
        $x=RegGet $keyroot $keypath $keysetting
        RegSet $keyroot $keypath $keysetting $keyval $keytype
        WriteText "$keysetting=$keyval [$keytype]"
        # WriteText "Old value: $x   New Value: $keyval"

        ### Now remove any Google scopes that aren't the one we just added
        ## There really shouldn't be any
        $scopes = Get-ChildItem ($keyroot +":" + $keypath)
        foreach ($scope in $scopes) 
            {
            if (!($scope.PSChildName -eq $guid))
                {
                $displayname=RegGet $keyroot ($keypath+"\"+$scope.PSChildName) "Displayname"
                if ($displayname -eq "Google")
                    {
                    writetext (($scope.PSChildName) +" remove old Google:" + $keypath+"\"+$scope.PSChildName)
                    Remove-item ($keyroot + ":\" +$keypath+"\"+$scope.PSChildName) -recurse
                    }
                else
                    {
                    ## writetext (($scope.PSChildName) +" leave $displayname")
                    }
                }
            else
                {
                ## writetext (($scope.PSChildName) +" default we just added")
                }
            }
        ### END: Add Google
	    }
    WriteText "Important: On next launch of IE the user must confirm the change"
    ### END: Change search scope
    }

WriteText "- IE Home page to google, Don't warn on close"
RegSet "HKCU" "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\Main" "Start Page" "https://www.google.com/" "String"
RegSet "HKCU" "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\TabbedBrowsing" "WarnOnClose" "0" "DWord"

#######################
## Main Procedure End
#######################
WriteText "-----------------------------------------------------------------------------"
WriteText "Done"
if ($quiet) {PauseTimed -quiet} else {PauseTimed}
Exit(0)
Return