# To enable scrips, Run powershell 'as admin' then type Set-ExecutionPolicy Unrestricted
#
<# Readme
# https://github.com/ITAutomator/IntuneApp
#
# IntuneWin32App module
# https://github.com/MSEndpointMgr/IntuneWin32App
# https://github.com/MSEndpointMgr/IntuneWin32App/tree/master/Public
# https://github.com/MSEndpointMgr/IntuneWin32App/blob/master/Public/Add-IntuneWin32App.ps1
#
# Endpoint manager
# https://endpoint.microsoft.com/?ref=AdminCenter#blade/Microsoft_Intune_DeviceSettings/AppsWindowsMenu/windowsApps
#
# Detection rules MSI listing
# Get-WMIObject Win32_Product | Sort-Object -Property Name | Format-Table IdentifyingNumber, Name, Version, LocalPackage -AutoSize
#
# Folder structure
# \7ZipInstaller\           installer.exe
# \7zipInstaller\IntuneApp\   intune_settings.csv
#                             intune_install
#>
function Get-TokenDetailsFromHeader {
    param (
        [Parameter(Mandatory)]
        $AuthToken
    )

    $tokenHeader = $AuthToken.Authorization
    if (-not $tokenHeader) {
        Write-Warning "Authorization header not found."
        return
    }

    $rawToken = $tokenHeader -replace '^Bearer\s+', ''
    $parts = $rawToken -split '\.'
    if ($parts.Count -lt 2) {
        Write-Warning "Invalid JWT format."
        return
    }

    # Base64 decode payload
    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) {
        2 { $payload += '==' }
        3 { $payload += '=' }
    }

    try {
        $bytes = [Convert]::FromBase64String($payload)
        $json = [Text.Encoding]::UTF8.GetString($bytes)
        $claims = $json | ConvertFrom-Json

        return [pscustomobject]@{
            TenantId = $claims.tid
            User     = $claims.upn
            Issuer   = $claims.iss
            Expires  = $claims.exp | ForEach-Object { [DateTimeOffset]::FromUnixTimeSeconds($_).UtcDateTime }
            Scopes   = $claims.scp
            Audience = $claims.aud
        }
    } catch {
        Write-Warning "Failed to decode token: $_"
    }
}
Function InitializeOrgList ($orglistcsv)
# Creates an empty OrgList
{
    if (-not (Test-Path ($orglistcsv)))
    {
        ######### Template
        '"Org","Packages","Last Publish Count","Last Publish Date","PublishToGroupIncluded","PublishToGroupExcluded","AppPublisherClientID"' | Add-Content $orglistcsv
    }
}
Function CreatePublishingApp ($OrgDomain, $AppName)
# Connects to an org and creates the required Registered App to publish Windows Apps
{ # CreatePublishingApp
    $sResult = ""
    $connected = $false
    Do
    { #Loop until connected
        Try
        {
            # These are the scopes required for the user to connect and create a registered app
            $scopes = @() 
            $scopes += "Domain.Read.All"                        # Read domain properties
            $scopes += "User.ReadWrite.All"                     # Read and update user properties
            $scopes += "Directory.Read.All"                     # Allows the app to read data in your organization's directory.
            #$scopes += "Application.Read.All"                   # Allows the app to read all applications and service principals without a signed-in user
            $scopes += "Application.ReadWrite.All"              # Allows the app to create, read, update and delete applications and service principals without a signed-in user. Does not allow management of consent grants.
            $scopes += "RoleManagement.ReadWrite.Directory"     # Allows the app to read and manage the role-based access control (RBAC) settings for your company's directory, without a signed-in user.
            $scopes += "DelegatedPermissionGrant.ReadWrite.All" # Manage app permission grants and app role assignments 
            $retval=""
            $context = Get-MgContext
            if ($context)
            { # already connected
                Write-Host "Connect-MgGraph is already connected as: " -NoNewline
                Write-Host $context.Account -ForegroundColor Yellow
                if (-not (AskForChoice "Use this connection?"))
                {
                    Disconnect-MgGraph -ErrorAction Ignore | Out-Null
                    Write-Host "Connecting ... There may be a popup logon window in the background"
                    PressEnterToContinue "Press Enter to try connecting"
                    Connect-MgGraph -Scopes $scopes -TenantId $OrgDomain -erroraction Stop | Out-Null
                }
            } # already connected
            else {
                Write-Host "Connecting ... There may be a popup logon window in the background"
                Connect-MgGraph -Scopes $scopes -TenantId $OrgDomain -erroraction Stop | Out-Null
            }
            $connected = $true
        }
        Catch
        {
            $retval="ERR: Connect-MgGraph returned $($_.ToString())"
            Write-Host $retval
        }      
        if ($connected)
        { # connected
            $retval="OK"
            $context = Get-MgContext
            if ($null -eq $context.TenantId)
            {
                $connected=$false
            }
            if ($connected)
            { #connected witn context
                # see if we are in the correct domain
                Try
                {
                    $orgdomains = (Get-MgDomain | Sort-Object IsDefault -Descending | Select-Object Id).Id
                    Write-Host "Connected to Domain: " -NoNewline
                    Write-Host ($orgdomains -join ", ") -ForegroundColor Yellow
                }
                Catch
                {
                    $orgdomains = "Error running Get-MgDomain"
                }
                if (-not ($OrgDomain -in $orgdomains))
                {
                    Write-Host "Couldn't find domain [$($OrgDomain)] in orgdmains[$($orgdomains -join ",")]"
                    $connected = $false
                    Pause
                    Disconnect-MgGraph -ErrorAction Ignore | Out-Null
                }
                # see if we are in the correct domain
            } #connected witn context
        } # connected
        If (-not $connected)
        { # not connected
            Write-Host "Not Connected (Showing connection options again...)"
        } # not connected
        #Pause
    } #Loop until connected
    Until ($connected)
    # Show Mgcontext for access to tenant ID
    $context = Get-MgContext
    $tenantid = $context.TenantId
    Write-Host "Connected via account: " -NoNewline
    Write-Host $context.Account $tenantid -ForegroundColor Yellow
    # Check for application
    $appidtoremove = $null
    $orgapps = @(Get-MgApplication)
    $orgapp = $orgapps | Where-Object DisplayName -EQ $AppName
    If ($orgapp)
    {# App with same name found
        Write-host "Warning: Existing app was found in tenant:" -NoNewline
        Write-Host $AppName -ForegroundColor Yellow
        Write-Host "Would you like to replace it?"
        if ((AskForChoice -message "Replace existing app: $($AppName)" -ChooseDefault:$AutoCreate) -eq 0)
        {#user didn't want to replace
            $retval="ERR: Existing app found, user chose not to replace: $($AppName)"
            Write-Verbose $retval
            Return $retval
        }#user didn't want to replace
        $appidstoremove = @($orgapp.id)
    }# App with same name found
    #region CreateApp
    ######## Create API Permission Object $ReqResAccess (https://aad.portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
    $ReqResAccess = New-Object -TypeName System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]
    $ResourceName = "Microsoft Graph"
    $ReqResAppIDAccesses = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
    $ResourceApp = Get-MgServicePrincipal -Filter "DisplayName eq '$($ResourceName)'"
    $ReqResAppIDAccesses.ResourceAppId = $ResourceApp.AppId
    $ResourceRoles = @()
    $ResourceRoles += "DeviceManagementManagedDevices.ReadWrite.All" # read and write the properties of devices managed by Microsoft Intune
    $ResourceRoles += "DeviceManagementApps.ReadWrite.All"           # read and write the properties, group assignments and status of apps
    $ResourceRoles += "Group.Read.All"                               # read group properties and memberships
    $ResourceRoles += "User.Read.All"                                # read user properties
    Foreach ($Role in $ResourceRoles)
    { # each resourcerole 
        $sp_property = "Oauth2PermissionScopes" #sp_property: 'AppRoles' for Application, 'Oauth2PermissionScopes' for Delegated
        $ra_type = "Scope"                      #Type       : 'Role' for Application, 'Scope' for Delegated
        ##
        $ResourceAppRole = Get-MgServicePrincipal -Filter "DisplayName eq '$($ResourceName)'" -Property $sp_property | Select-Object -ExpandProperty $sp_property | Where-Object Value -EQ $Role
        $ReqResAppIDAccesses.ResourceAccess+=@{ Id = $ResourceAppRole.id ; Type = $ra_type } 
        Write-Host "Staging access to resource: " -NoNewline
        Write-Host $ResourceApp.DisplayName -ForegroundColor Yellow -NoNewline
        Write-Host " with role: " -NoNewline
        Write-Host $ResourceAppRole.Value -ForegroundColor Yellow
    } # each resourcerole
    # Add the list to the ReqResAccess
    $ReqResAccess.Add($ReqResAppIDAccesses)
    ####### Create MgApplication (Registered App)
    ####### https://aad.portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps
    $params = @{
        DisplayName = $AppName
        SignInAudience = "AzureADMyOrg"
        PublicClient = @{ RedirectUris="https://login.microsoftonline.com/common/oauth2/nativeclient"; } 
        IsFallbackPublicClient = $true # Allow public client flows (needed for DeviceCode option)
        RequiredResourceAccess = $ReqResAccess
        AdditionalProperties = @{}
    }
    try {
        ########### CREATE APP! This is the purpose of this function
        $appRegistration = New-MgApplication @params 
    }
    catch {
        $_  
        Pause
    }
    #endregion CreateApp
    #region GrantApp
    ####### Create service principal (svc_princ) for the App (SPs are AD object ids, kind of like user ids, but for apps and resources)
    $AppClient = New-MgServicePrincipal -AppId $appRegistration.AppId | Out-Null # was $svc_princ=  
    $AppClient = Get-MgServicePrincipal -Filter "appId eq '$($appRegistration.AppId)'"
    # Retrieve the RequiredResourceAccess for the app (the APIs)
    $rras = $appRegistration.RequiredResourceAccess
    # Each requiredResourceAccess identifies an API (the resource app) and a list of required
    # delegated permissions and app roles.
    foreach ($rra in $rras)
    { # each api (Microsoft Graph)
        $resource = Get-MgServicePrincipal -Filter "appId eq '$($rra.resourceAppId)'"
        $requiredScopeIds = $rra.resourceAccess | Where-Object { $_.Type -eq "Scope" } | ForEach-Object { $_.id }
        if ($requiredScopeIds)
        { # each api permission
            #$grantedScopeValues = @()
            $finalScopeValues = {@()}.Invoke()  # not really sure what this does - create an empty object?
            foreach ($requiredScopeId in $requiredScopeIds) {
                $requiredScope = $resource.Oauth2PermissionScopes | Where-Object { $_.Id -eq $requiredScopeId }
                $finalScopeValues.Add($requiredScope.Value) 
            }
            #Write-Host "  Creating delegated permissions grant for '$($finalScopeValues -join " ")'"
            New-MgOauth2PermissionGrant -ConsentType "AllPrincipals" -ClientId $AppClient.Id -ResourceId $resource.Id -Scope ($finalScopeValues -join " ") | Out-Null
        } # each api permission
    } # each api
    #endregion GrantApp
    ####### Remove old App?
    if ($appidstoremove)
    { # Some cookie to remove?
        ForEach ($appidtoremove in $appidstoremove)
        {
            Remove-MgApplication -ApplicationId $appidtoremove
        }
    } # Some cookie to remove?
    ####### Create MgApplication: Done
    # Disconnect-MgGraph | Out-Null
    ####
    $retval="OK"
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Package-publishing Application setup complete"
    Write-Host "                  AppName: " -NoNewline
    Write-Host                             $AppName -ForegroundColor Yellow
    Write-Host "                    AppId: " -NoNewline
    Write-Host                             $appRegistration.AppId -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Find it here: Entra Admin > Apps > App Registrations > All apps"
    Write-Host "              https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM" -ForegroundColor Green
    Write-Host "    and here: Entra Admin > Apps > App Registrations > $($AppName)"
    Write-Host "              https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($appRegistration.AppId )/isMSAApp~/false" -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------------------"
    Start-Sleep 3 # pause
    $sResult = $appRegistration.AppId
    Return $sResult
} # CreatePublishingApp
Function CreatePublishTemplatePs1Files ($rootpath)
# Copies the template lines into the 4 ps1files
{
    $sReturn="OK"
    $ps1template = "$($rootpath)\AppsPublish_Template.ps1"
    $ps1path = "$($rootpath)\!App Template\IntuneApp\IntuneUtils"
    $ps1files = @()
    $ps1files += "intune_requirements.ps1"
    $ps1files += "intune_detection.ps1"
    $ps1files += "intune_install.ps1"
    $ps1files += "intune_uninstall.ps1"
    if (-not (Test-Path $ps1template -PathType Leaf)){
        Return "ERR: couldn't find $($ps1template)"
    }
    if (-not (Test-Path $ps1path -PathType Container)){
        Return "ERR: couldn't find $($ps1path)"
    }
    $iUpdateCount=0
    $sUpdateList=@()
    $ps1source = Get-Content $ps1template
    ForEach ($ps1file in $ps1files)
    { # replace each ps1file
        $ps1targetfile = "$($ps1path)\$($ps1file)"
        if (Test-Path $ps1targetfile -PathType Leaf) {
            $ps1target = Get-Content $ps1targetfile
        } 
        Else{ # target doesn't exist
            $ps1target = $null
        }
        if (($null -eq $ps1target) -or (ContentsHaveChanged $ps1source $ps1target))
        { # target doesn't exist or is different
            [System.IO.File]::WriteAllLines($ps1targetfile,$ps1source) # writes UTF8 file
            $iUpdateCount+=1
            $sUpdateList+=$ps1file
        } # files are different
    } # replace each ps1file
    If ($iUpdateCount -gt 0){
        $sReturn = "OK: template files updated: $($sUpdateList -join ", ")"
    }
    Else{
        $sReturn = "OK: no template files updated"
    }
    Return $sReturn
}
Function UpdatePS1File ($ps1template, $ps1file, $pkgobj, $injection_site, $injection_file, $fnvalues)
# Splices in the template lines (from the ps1template .ps1 file) into the ps1file
{
    # Also updates the appvalues in the ps1file from the csv file
    $return="OK"
    $ps1source = Get-Content $ps1template  # template file
    $ps1target_new =@()                    # package file (new) starts empty
    ForEach ($linesource in $ps1source)
    { # each line in ps1source
        # within the template section, see if this line is an iav intuneappvalue that needs special adjustment
        $line_repl=$linesource
        $iav_line = "`$IntuneAppValues.Add("
        $iav_line_start = $line_repl.IndexOf($iav_line)
        If ($iav_line_start -ne -1)
        { # line has $IntuneAppValues.Add(
            # get iav_name, given s start and e end
            # .....................sVVVVVVVVVVVVe----------------
            # $IntuneAppValues.Add("AppInstaller"       ,"choco")
            $iav_line_start += $iav_line.Length+1 # start 1 past the 1st quote
            $iav_line_end = $line_repl.IndexOf("`"",$iav_line_start) # look for close quote
            $iav_name = $line_repl.Substring($iav_line_start,$iav_line_end-$iav_line_start) # name is between the quotes
            # look for this variable (iav_name) in fnvalues and pkobj (function info and package info)
            If     ($iav_name -eq "AppName") {$val_repl = $pkgobj.AppNameVer}  # use the versioned name
            Elseif ($fnvalues.$iav_name)     {$val_repl = $fnvalues.$iav_name} # found in fnvalues
            Elseif ($pkgobj.$iav_name)       {$val_repl = $pkgobj.$iav_name}   # found in pkgobj values
            Else {$val_repl = ""}
            If ($val_repl -eq "")
            { # replace this line w blank
                $line_repl = "    `$IntuneAppValues.Add(`"$($iav_name)`",`"`")"
            } # replace this line w blank
            Else
            { # replace this line w var
                $lineswithvars+=1
                $line_repl = "    `$IntuneAppValues.Add(`"$($iav_name)`",`"$($val_repl)`")"
            } # replace this line w var
        } # line has $IntuneAppValues.Add(
        # check for injection site
        if (($injection_site -ne "") -and ($line_repl.IndexOf($injection_site) -gt 0))
        { # found injection site
            If (test-path $injection_file -pathtype leaf)
            { # found injection file
                # inject the file
                $ps1target_new+="#region INJECTION SITE for $(Split-Path $injection_file -Leaf)"
                $ps1target_new+="##########################################################"
                $inject_lines = Get-Content $injection_file
                ForEach ($inject_line in $inject_lines)
                {
                    # change the line a bit to a staging line
                    $staged_line = $inject_line
                    $staged_line = $staged_line.Replace("'","''")  # replace any single quotes with two single quotes
                    $staged_line = ($staged_line -ireplace [regex]::Escape("write-host"), "WriteLog")  # replace write-host with a trapping fn since intune seems to send it to STDOUT (ireplace is non case sensitive)
                    # inject staged line
                    $inject_line_new = "`$customps1_injection_lines +='" # pre-amble for each line
                    $inject_line_new+= $staged_line
                    $inject_line_new+="'"  # post-amble for each line
                    # append this inject_line
                    $ps1target_new+=$inject_line_new
                }
                $ps1target_new+="##########################################################"
                $line_repl =   "#endregion INJECTION SITE for $(Split-Path $injection_file -Leaf)"
            } # found injection file
        } # found injection site
        # append template line
        $ps1target_new+=$line_repl
    } # each line in ps1source
    # Done creating lines for new file
    # check old file
    if (Test-Path $ps1file -PathType Leaf) {
        $ps1target = Get-Content $ps1file      # package file (old)
    } 
    Else{ # target doesn't exist
        $ps1target = $null
    }
    # write file if needed
    if (($null -eq $ps1target) -or (ContentsHaveChanged $ps1target_new $ps1target))
    { # target doesn't exist of is different
        [System.IO.File]::WriteAllLines($ps1file,$ps1target_new) # writes UTF8 file
        $return ="Updated. Intune vars found: $($lineswithvars)"
    }
    else
    { # template ok,no change
        $return ="OK. No change"
    }
    Return $return
}
Function Ps1FileCheckUpdate ($ps1template, $file_checks, $pkgobj)
{
    $LogFolder = "C:\IntuneApp"
    $sResult = "OK"
    $i=0
    $updated_count=0
    ForEach ($file_check in $file_checks)
    { #Each file
        $i++
        $filebase = Split-Path $file_check -Leaf
        # certain package files have to pre-exist, not the ps1s
        if ($filebase -in ("intune_settings.csv","intune_icon.png")) 
        {
            If (-not (Test-Path $file_check -PathType Leaf))
            { #file not found
                $sResult= "ERR: Required file missing: $($file_check)"
            }
        }
        elseif ($filebase -in ("intune_install.ps1","intune_uninstall.ps1","intune_detection.ps1","intune_requirements.ps1")) 
        { #ps1 file, check/replace contents
            #$ps1name = Split-Path $file_check -Leaf
            # create object to pass to UpdatePS1File
            # Note: Not all vars are needed.  Only include vars that are needed for intune_requirements.ps1, intune_detection.ps1 scripts.  
            # Note: Those 2 scripts are self-contained so they can't read vars from the .csv.
            $fnvalues = @{}
            $fnvalues.Add("Function"           ,$filebase)
            $fnvalues.Add("LogFolder"          ,$LogFolder)
            # check/replace contents in file (initialize empty)
            $injection_site = ""
            $injection_file = ""
            if ($filebase -in ("intune_detection.ps1","intune_requirements.ps1"))
            { # intune_detection.ps1 or intune_requirements.ps1
                $inject_file_name = $filebase.Replace(".ps1","_customcode.ps1")
                $inject_file_path = Join-path (Split-Path (Split-path $file_check -Parent) -Parent) $inject_file_name
                If (Test-path $inject_file_path -PathType Leaf)
                { # found _customcode.ps1
                    $injection_site = "### <<$($inject_file_name) injection site>> ###"
                    $injection_file = $inject_file_path
                } # found _customcode.ps1
            } # intune_detection.ps1 or intune_requirements.ps1
            # rewrite ps1 - update with template / inject code
            $update_result = UpdatePS1File $ps1template $file_check $pkgobj $injection_site $injection_file $fnvalues
            if ($update_result.StartsWith("Updated"))
            { #contents replaced
                $updated_count +=1
            } #contents replaced
            elseif ($update_result.StartsWith("OK"))
            { #contents already OK
            } #contents already OK
            else
            { #contents have an issue
                $sResult= "ERR: Required file $($i): ($($update_result)) $($filebase)"
            } #contents have an issue
        } #ps1 file, check/replace contents
        else
        { # other files just copy
            $src = "$(Split-path $ps1template -Parent)\!App Template\IntuneApp\IntuneUtils\$(Split-path $file_check -Leaf)"
            $retcode, $retmsg = CopyFileIfNeeded -source $src -target $file_check -TargetIsFolder $false -CompareByHashOrDate "date"
        } # other files just copy
    } #Each file
    If ($sResult.StartsWith("OK"))
    {
        If ($updated_count -gt 0) {$sResult += ": $($updated_count) files updated"}
    }
    Return $sResult
}
Function AppVersionIncrementInCSV ($intune_settings_csvpath)
{
    $IntuneAppValues_csv = Import-Csv $intune_settings_csvpath
    $versionstr_old = ($IntuneAppValues_csv | Where-Object Name -EQ AppVersion).Value
    if ($versionstr_old-eq "")
        {$versionstr_old= "100"} # Default to 100 if none provided
    # read existing version and increment
    [string]$versionstr_new = [int]$versionstr_old + 1
    # Update CSV file
    ($IntuneAppValues_csv | Where-Object Name -EQ AppVersion).Value = $versionstr_new
    $IntuneAppValues_csv | Export-Csv $intune_settings_csvpath -NoTypeInformation
    Return $versionstr_new
}
Function PackagesLocalChecks($search_root="C:\Users\Public\Documents\IntuneApps", $GetHash = $true)
{
    $LogFolder = "C:\IntuneApp"
    #region Search for packages (files named intune_settings.csv)
    If (-not (Test-Path $search_root -PathType Container)) {Return "search_root not found: $($search_root)"}
    $package_files= Get-ChildItem -Path $search_root -File -Recurse -Filter "intune_settings.csv"
    $package_paths = @()
    ForEach ($package_file in $package_files)
    { # each csv file
        $package_path=$package_file.FullName
        if (-not (Split-Path (Split-path (Split-Path $package_path -Parent) -Parent) -Leaf).StartsWith("!"))
        { #not a disabled package (grandparent folder has a ! in front)
            $package_path = $package_path.Replace("$($search_root)\","")
            $package_paths += $package_path
        }
    } # each csv file
    if ($package_paths.count -eq 0) {Return "Couldn't find any package files (intune_settings.csv): $($search_root)"}
    #endregion Search for packages (files named intune_settings.csv)
    #region CheckUpdateHashes
    # create object for hash results
    $hash_obj=[pscustomobject][ordered]@{
        Hash          = ""
        HashList      = $null
        }
    $bHashUpdateAllOK = $false
    $pkgobjs = @()
    $pkgupdated = @()
    $warningsallpkgs = @()
    $i = 0
    $i_count = $package_paths.count
    if ($i_count -ge 10)
    { # more than 10 packages
        Write-Host "Found $($i_count) packages to check"
        if (AskForChoice "Auto-update hash values [No to stop and ask for any updated packages]"){
            $bHashUpdateAllOK = $true
        }
    } # more than 10 packages
    Write-Progress -Activity "Checking Packages" -Status "Starting" -PercentComplete 0
    ForEach ($pkg in $package_paths)
    { # Each pkg (csv) file
        $i+=1
        $PercentComplete = (($i / $i_count) * 100)
        $Status = "Checking $($i) of $($i_count) : $(($pkg -split "\\")[0])"
        Write-Progress -Activity "Checking Packages" -Status $Status -PercentComplete $PercentComplete
        $IntuneAppFolder = Split-Path "$($search_root)\$($pkg)" -Parent
        #region check required files
        $intune_settings_csvpath=Join-Path $IntuneAppFolder "intune_settings.csv"
        $file_checks = @(
            # required (2 package files)
            (Join-Path $IntuneAppFolder "intune_settings.csv"),
            (Join-Path $IntuneAppFolder "intune_icon.png"),
            # injected (4 IntuneUtils files)
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_install.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_uninstall.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_detection.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_requirements.ps1"),
            # overwritten (8 IntuneUtils files)
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_command.cmd"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_command.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_detection_customcode_template.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_install_customcode_template.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_install_followup_template.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_requirements_customcode_template.ps1"),
            (Join-Path $IntuneAppFolder "IntuneUtils\intune_uninstall_followup_template.ps1")
            (Join-Path $IntuneAppFolder "IntuneUtils\Readme.txt")
            )
        #Write-Host "Checking \IntuneApp folder for required files..."
        $IntuneAppValues_csv = Import-Csv $intune_settings_csvpath
        # create object out of csv values
        $pkgobj = [Ordered]@{}
        ForEach ($IntuneAppValue_csv in $IntuneAppValues_csv)
        {
            $pkgobj.Add( $IntuneAppValue_csv.Name , $IntuneAppValue_csv.Value )
        }
        $pkgobj.Add("AppNameVer"           , "$($pkgobj.AppName)$(if ($pkgobj.AppVersion) {"-v"})$($pkgobj.AppVersion)")
        # other info
        $pkgobj.Add("Fullpath"            , $IntuneAppFolder)
        $pkgobj.Add("Relpath"             , $pkg)
        $pkgobj.Add("PackageFolder"       , (Split-Path (Split-path (Split-Path $pkg -Parent) -Parent) -Leaf))
        $pkgobj.Add("Hash"                , "") # Calculated hash (later)
        $pkgobj.Add("PublishedAppId"      , "")
        $pkgobj.Add("PublishedDate"       , "")
        $pkgobj.Add("PublicationStatus"   , "Unpublished") #Unpublished, Published, Needs Update, Package Missing
        $pkgobj.Add("Warnings"            , "")
        # convert to booleans
        $pkgobj.PublishToOrgGroup       = [System.Convert]::ToBoolean($pkgobj.PublishToOrgGroup)
        $pkgobj.CompanyPortalFeaturedApp= [System.Convert]::ToBoolean($pkgobj.CompanyPortalFeaturedApp)
        $pkgobj.AvailableInCompanyPortal= [System.Convert]::ToBoolean($pkgobj.AvailableInCompanyPortal)
        $pkgobj.CreateExcludeGroup      = [System.Convert]::ToBoolean($pkgobj.CreateExcludeGroup)
        # other info part ii
        if ($pkgobj.PublishToOrgGroup) {$Required_Pkg = "Yes"} else {$Required_Pkg = ""}
        $pkgobj.Add("Required_Pkg"            , $Required_Pkg)
        $pkgobj.Add("Required_Org"            , "")
        # checks that all files exist, and injects them with updated variables and custom code (for detection and requirements files)
        $ps1template = "$($search_root)\!IntuneApp\AppsPublish_Template.ps1"
        $sResultps1 = Ps1FileCheckUpdate $ps1template $file_checks $pkgobj
        if ($sResultps1.StartsWith("ERR"))
        {Return $sResultps1, $null}

        if ($GetHash)
        { # GetHash is true (default)
            # update hash for this package (if needed)
            $HashFileExcludes = @()
            $HashFileExcludes += "IntuneUtils" # Ignore changes in the utils folder
            $HashFileExcludes += "intune_packagehash.xml" # Ignore intune_packagehash
            # build a list of the files to hash
            $HashFilePaths = @()
            #files in root that are non-excluded (Note: GCI -Exclude is not reliable)
            $HashFilePaths += (Get-ChildItem -Path $IntuneAppFolder -File | Where-Object Name -NotIn $HashFileExcludes).Fullname
            #files in non-excluded subfolders
            $HashFilePaths += ((Get-ChildItem -Path $IntuneAppFolder -Directory | Where-Object Name -NotIn $HashFileExcludes) | Get-ChildItem -Recurse -File).FullName
            #core package files (probably don't need these)
            $HashFilePaths += $file_checks 
            # get hash of these files
            $HashFilePaths = $HashFilePaths | Sort-Object | Select-Object -Unique
            # hash calc
            #$HashMethod = "ByContents"
            $HashMethod = "ByDate"
            $sErr,$sHash,$HashList = GetHashOfFiles $HashFilePaths -ByDateOrByContents $HashMethod
            $pkgobj.Hash = $sHash
            $HashFilePath = Join-Path $IntuneAppFolder "intune_packagehash.xml"
            If (Test-Path $HashFilePath -PathType Leaf)
            {
                $hash_obj = Import-Clixml -Path $HashFilePath
                $sHash_old = $hash_obj.Hash
            }
            Else {$sHash_old = "<none>"}
            If ($sHash_old -ne $sHash)
            { # hashes don't match - package was updated
                Write-Host ""
                Write-Host ""
                Write-host "Hash for this app will be updated: " -NoNewline
                Write-host $pkgobj.AppName -ForegroundColor Green
                if ($sHash_old -ne "<none>")
                { # show the hash diff
                    Write-Host "------------------------------------------------------------"
                    Write-Host "These files changed since the last hash was computed."
                    Write-Host "A hash update will cause 'needs update' indicators wherever the app was previously published."
                    Write-Host "<= means file was removed"
                    Write-Host "=> means file was added"
                    Write-Host "(if the same file has both indicators it has been modified from <= old to => new )"
                    Write-Host (Compare-Object $hash_obj.HashList $HashList -Property Hash | Format-Table | Out-String)
                    Write-Host "------------------------------------------------------------"
                } # show the hash diff
                if (-not $bHashUpdateAllOK) { # ask for hash update
                    $choice = (AskForChoice "Update hash value for this app?" -choices "&No","&Yes","Yes to &all" -DefaultChoice 1)
                    if ($choice -eq 0)   {$bHashUpdateOK = $false}
                    if ($choice -in 1,2) {$bHashUpdateOK = $true}
                    if ($choice -eq 2)   {$bHashUpdateAllOK = $true}
                } # ask for hash update
                else {$bHashUpdateOK = $true} # auto-update
                if (-not $bHashUpdateOK)
                { # skip update package
                    Write-Host "Aborting hash update of [$($pkgobj.AppName)]"
                    Continue
                } # skip update package
                else
                { # update package
                    # update version number in csv
                    $versionstr_new=AppVersionIncrementInCSV $intune_settings_csvpath
                    # Update Values
                    $pkgobj.AppVersion=$versionstr_new
                    $pkgobj.AppNameVer="$($pkgobj.AppName)-v$($versionstr_new)"
                    $sResultps1 = Ps1FileCheckUpdate $ps1template $file_checks $pkgobj
                    # recalc hash (because of csv change)
                    $sErr,$sHash,$HashList = GetHashOfFiles $HashFilePaths -ByDateOrByContents $HashMethod
                    $pkgobj.Hash = $sHash
                    # save hash
                    $hash_obj.Hash          = $sHash
                    $hash_obj.HashList      = $HashList
                    Export-Clixml -InputObject $hash_obj -Path $HashFilePath
                    # keep a list of updated packages
                    $pkgupdated += $pkgobj.AppNameVer
                } # update package
            } # hashes don't match - package was updated
        } # GetHash is true (default)
        #region warnings
        $warnings=@()
        if ($pkgobj.PackageFolder -ne $pkgobj.AppName)
        {
            $warnings+="Name mismatch: Folder is [$($pkgobj.PackageFolder)] but App name from csv is [$($pkgobj.AppName)]. Generally it's one app per folder, and the folder should match the app."
        }
        $pkgdupes = @($pkgobjs | Where-Object AppName -eq $pkgobj.AppName)
        if ($pkgdupes)
        {
            $warnings+="This AppName [$($pkgobj.AppName)] is found at this path [$($pkgobj.Relpath)] and also this path [$($pkgdupes[0].Relpath)]. Delete or rename one of them."
        }
        $pkgobj.warnings = $warnings -join ", "
        $warningsallpkgs += $warnings
        #endregion warnings
        # append object of this package (the comma in front forces the values to be added as an additional array object in the parent list, vs within the same list)
        $pkgobjs += ,$pkgobj
    } #  # Each pkg (csv) file
    #endregion CheckUpdateHashes
    Write-Progress -Activity "Checking Packages" -Status "Complete" -PercentComplete 100 -Completed
    #region sResult
    $sResult = "OK: $($pkgobjs.count) Packages"
    if ($pkgupdated.count -gt 0)
    { # Updated
        $sResult += ". Updated: $($pkgupdated.count) [$($pkgupdated -join ', ')]"
    }
    If ($warningsallpkgs.count -gt 0)
    {
        $sResult += ". Warnings: $($warningsallpkgs.count) [$($warningsallpkgs -join ', ')]"
    }
    #endregion sResult
    Return $sResult,$pkgobjs
}
Function PackagesLocalUpdateandCheck ($GetHash = $true)
{
        #region update !App Template\IntuneApp\IntuneUtils
        $ps1template = "$($scriptdir)\AppsPublish_Template.ps1"
        If (-not (Test-Path $ps1template)) {write-host "Err: Couldn't find $($ps1template)";return}
        # Update the 4 key ps1 files in !App Template\IntuneApp\IntuneUtils
        Write-Host "Checking / updating the 4 key template ps1 files... " -NoNewline
        $sReturn = CreatePublishTemplatePs1Files -rootpath $scriptdir
        if ($sReturn -eq "OK: no template files updated") {Write-Host $sReturn}
        else {Write-Host $sReturn;Write-host "Note: Template files were changed. This updates all packages, and hashes will be updated too." -ForegroundColor Yellow;PressEnterToContinue}
        if (-not $sReturn.Startswith("OK")) {Write-host $sReturn -ForegroundColor Yellow ;return}
        #endregion update !App Template\IntuneApp\IntuneUtils
        #region package hashes
        Write-Host "Checking / updating package files (takes a few secs)... " -NoNewline
        $search_root  = Split-Path -Path $scriptdir -Parent
        $sReturn,$pkgs = PackagesLocalChecks $search_root -GetHash $GetHash
        Write-Host $sReturn
        if (-not $sReturn.Startswith("OK")) {Write-host $sReturn -ForegroundColor Yellow; PressEnterToContinue ;return}
        #endregion package hashes
        Return $pkgs
}
# Main Procedure
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
#
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
$psm1="$($scriptDir)\ITAutomator M365.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
#
#region Transcript Open
$Transcript = [System.IO.Path]::GetTempFileName()               
Start-Transcript -path $Transcript | Out-Null
#endregion Transcript Open
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host $scriptName -ForegroundColor Yellow
Write-Host "This script publishes Apps to M365 Orgs via Intune."
Write-Host ""
Write-Host "Published Apps (named IntuneApps...) can be found in the Intune Windows Apps list here:"
Write-Host "https://intune.microsoft.com/?ref=AdminCenter#view/Microsoft_Intune_DeviceSettings/AppsWindowsMenu/~/windowsApps" -ForegroundColor Green
Write-Host "-----------------------------------------------------------------------------"
$bShowmenu=$true
Do
{ # show menu
    if ($pkgs)
    {
        $chkInfo = " (Checked: $($pkgs.count))"
    }
    else
    {
        $chkInfo = ""
    }
    Write-Host "-----------------------------------------------------------------------------"
	Write-Host "Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major)"
    Write-Host $scriptName -ForegroundColor Yellow -nonewline
    Write-Host " Publish menu"
    Write-Host "IntuneApps are published here: " -NoNewline
    Write-Host "https://intune.microsoft.com/?ref=AdminCenter#view/Microsoft_Intune_DeviceSettings/AppsWindowsMenu/~/windowsApps" -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "C - Check local apps prior to publication$($chkInfo)" -ForegroundColor Yellow
    Write-Host "    Checks local apps for changes / updates hash (recommended for Publish option)"
    Write-Host "P - Publish apps" -ForegroundColor Yellow
    Write-Host "    Publishes apps to an og"
    Write-Host "O - Prep a new Org for publishing apps" -ForegroundColor Yellow
    Write-Host "    Creates an entry in AppsPublish_Orgs.csv and creates an App publishing app used by this program in Entra."
    Write-Host "M - Install / upgrade modules" -ForegroundColor Yellow
    Write-Host "    Installs the PowerShell modules (required for Publish option)"
    Write-Host "-----------------------------------------------------------------------------"
    $msg= "Select an Action"
    $actionchoices = @("E&xit","&Check","&Publish","&Org prep","&Modules")
    $ps1file = ""
    ##
    $action=AskForChoice -message $msg -choices $actionchoices -defaultChoice 0
    Write-Host "Action [$($action)]: $($actionchoices[$action].Replace('&',''))"
    If ($action -eq 0)
    { # Menu Choice: Exit
        $bShowmenu=$false
    } # Menu Choice: Exit
    ElseIf ($action -eq 1)
    { # Menu Choice: Check
        if ($pkgs)
        {
            if (0 -eq (AskForChoice "$($pkgs.count) packages have already been checked. Check again?"))
            {
                Write-Host "Skipping."
                Start-sleep 1
                Continue
            }
        }
        $pkgs=PackagesLocalUpdateandCheck
    } # Menu Choice: Check
    ElseIf ($action -eq 2)
    { # Menu Choice: Publish
        $showmenu_publish=$true
        $verbosepackager=$false
        # if ($PSVersionTable.PSVersion.Major -eq 7) {
        #     Write-Host "Note: " -ForegroundColor Green -NoNewline
        #     Write-Host "Powershell version 7 detected."
        #     Write-Host "You may run into MFA-related connection issues. Consider using Powershell 5 for publishing." -ForegroundColor Green
        #     PressEnterToContinue
        # }
        #region choose tenant
        # Get Org info
        $orglistcsv = "$($scriptdir)\AppsPublish_OrgList.csv"
        If (-not (Test-Path $orglistcsv)) {InitializeOrgList $orglistcsv}
        $orglist=@(Import-Csv $orglistcsv)
        If ($orglist.count -eq 0) {
            Write-Host "No orgs have been prepped yet.  Use the [O]rg prep option."; PressEnterToContinue ;Continue 
        } 
        Write-host "[AppsPublish_OrgList.csv]" -ForegroundColor Yellow
        $i=0
        Write-Host ($orglist | Select-object @{N="ID";E={(++([ref]$i).Value)}},Org,Packages,"Last Publish Count","Last Publish Date"| Format-Table | Out-String)
        $choice_OK =$false
        Do {
            $prompt = PromptForString "Publish to Org (1-$($orglist.count), 0 to Exit)"
            Try {
                $choice = [int]$prompt
                if ($choice -le $orglist.count) {
                    $choice_OK =$true
                }
                else {
                    write-host "ERR: Invalid choice. Please enter a number between 1 and $($orglist.count) or 0 to exit."
                }
            }
            Catch {Write-Host "ERR: Invalid choice."}
        } Until ($choice_OK)
        if ($choice -eq 0) {Write-Host "Aborted.";Continue}
        $choice--
        Write-Host "You chose Org: " -NoNewline
        Write-Host $orglist[$choice].Org -ForegroundColor Yellow
        if (-not $pkgs)
        { # no local package list yet
            if (0 -eq (AskForChoice "No local packages checked yet. Use [C]heck before publishing (otherwise package update status will be unknowable). Check now?"))
            { # No, don't check now (Note: this is kind of dumb because the hash checking isn't the slow part)
                Write-Host "Skipping."
                $pkgs=PackagesLocalUpdateandCheck -GetHash $false
                Start-sleep 1
            } # Yes, check now
            else {
                $pkgs=PackagesLocalUpdateandCheck -GetHash $true
            }
        } # no local package list yet
        $OrgValues = @{} #hashtable
        $OrgValues.Add("TenantName"             , $Orglist[$choice].Org)
        $OrgValues.Add("AppPublisherClientID"   , $orglist[$choice].AppPublisherClientID)
        $OrgValues.Add("PublishToGroupIncluded" , $orglist[$choice].PublishToGroupIncluded)
        $OrgValues.Add("PublishToGroupExcluded" , $orglist[$choice].PublishToGroupExcluded)
        Write-Host "               TenantName : $($OrgValues.TenantName)" -ForegroundColor Yellow
        #Write-Host "      AgentLocalLogFolder : $($OrgValues.LogFolder)"
        Write-Host "   PublishToGroupIncluded : $($OrgValues.PublishToGroupIncluded)"
        Write-Host "   PublishToGroupExcluded : $($OrgValues.PublishToGroupExcluded)"
        Write-Host "     AppPublisherClientID : $($OrgValues.AppPublisherClientID)"
        if ($OrgValues."AppPublisherClientID" -eq "")
        {
            Write-Host "ERR: AppPublisherClientID is missing for this Org. Suggestion: Use menu option [O]rg prep to fix up this TenantName." -ForegroundColor Red;Start-sleep  3; continue
        }
        #endregion choose tenant
        #region modules
        $checkver=$true
        $modules=@()
        $modules+="IntuneWin32App"
        $modules+="Microsoft.Graph.Devices.CorporateManagement"
        $modules+="Microsoft.Graph.Groups"
        $modules+="Microsoft.Graph.Users"
        $modules+="Microsoft.Graph.Authentication"
        # $modules+="Microsoft.PowerShell.ConsoleGuiTools" # for Out-ConsoleGridView (PS7 only)
        ForEach ($module in $modules)
        { 
            Write-Host "Loadmodule $($module)..." -NoNewline ; $lm_result=LoadModule $module -checkver $checkver; Write-Host $lm_result
            if ($lm_result.startswith("ERR")) {
                Write-Host "ERR: Load-Module $($module) failed. Suggestion: Open PowerShell $($PSVersionTable.PSVersion.Major) as admin and run: Install-Module $($module)";Start-sleep  3; Return $false
            }
        }
        #endregion modules
        #region Connect-MgGraph
        Write-Host "[Connect-MgGraph] Connecting to Tenant: $($OrgValues.TenantName) [You may see a sign-on popup]" -ForegroundColor Yellow
        PressEnterToContinue "Press Enter to try connecting"
        $connected=$false
        $done = $false
        # Method 1 (no scopes - hides consent window if not set up yet)
        #$connected_ok = ConnectMgGraph -domain $OrgValues.TenantName
        # Method 2 (w scopes - asks for consent if needed)
        $RequiredScopes = @()
        $RequiredScopes += "Group.ReadWrite.All"
        $RequiredScopes += "GroupMember.ReadWrite.All"
        $RequiredScopes += "User.ReadWrite.All"
        #$RequiredScopes += "DeviceManagementApps.Read.All" # not sure about this one
        $RequiredScopes += "DeviceManagementApps.ReadWrite.All"
        Do {
            Write-Host "Connecting ... There may be a popup logon window in the background"
            $connected_ok = Connect-MgGraph -TenantId $OrgValues.TenantName -Scopes $RequiredScopes
            #
            if (!($connected_ok)) 
            { # connect failed
                Write-Host "[connection failed]"
                if (AskforChoice -Message "Try again?")
                { # yes, try again
                    Write-Host "Retrying connection..."
                    Start-Sleep -Seconds 2
                } # yes, try again
                else
                { # no, exit
                    Write-Host "Exiting."
                    Start-Sleep -Seconds 2
                    Exit
                } # no, exit
            }
            else
            { # connect ok
                Write-Host "Connected  ... OK"
                Write-Host "--------------------"
                break # exit connect loop
            }
        } while ($true) # connect loop
        Do { # menu loop
            # Get Required group ID
            Write-Host "Required org group: " -NoNewline
            Write-Host $OrgValues.PublishToGroupIncluded -NoNewline -ForegroundColor Yellow
            Write-Host " ...  (there may be a popup in the background) ... " -NoNewline
            $group = Get-MgGroup -Filter "displayName eq '$($OrgValues.PublishToGroupIncluded)'"
            $Required_OrgGroupId = $group.Id
            if ($Required_OrgGroupId) {
                Write-host "Found" -ForegroundColor Green
            } else {
                Write-Host "NOT FOUND" -ForegroundColor Red
                Write-Host "If you have never published to this Org, this is OK, it will be created during publishing process."
                Write-host "If you have published and the group has been renamed, rename them back to these values, then press [N] to check again."
                Write-Host $OrgValues.PublishToGroupIncluded -ForegroundColor Yellow
                Write-Host $OrgValues.PublishToGroupExcluded -ForegroundColor Yellow
                if (-not (AskForChoice))
                {Continue} # skip processConnect-MSIntuneGraph
            }
            #region Check published apps
            Write-Host "Checking published apps in: " -nonewline; Write-host $OrgValues.TenantName -ForegroundColor Yellow
            # Get List of apps
            $IntuneApps = Get-MgDeviceAppManagementMobileApp -All -ErrorAction Ignore
            $IntuneApps = $IntuneApps | Where-Object {$_.AdditionalProperties."@odata.type" -in ("#microsoft.graph.win32LobApp")}
            Write-Host "$($IntuneApps.Count) Apps"
            # clear entries (in case we've looped around after unpublishing)
            $pkgs = $pkgs | Where-Object PublicationStatus -ne "Package Missing" # remove any intune-only apps, they will be added by discovery
            ForEach ($pkg in $pkgs) # set the remainder to unpublished
            { # each pkg
                $pkg.PublishedAppId = ""
                $pkg.PublishedDate = ""
                $pkg.PublicationStatus = "Unpublished"
                $pkg.Required_Org = ""
                $pkg.Required_Pkg = ""
            } # each pkg
            $i = 0
            $i_count = $IntuneApps.count
            Write-Progress -Activity "Checking Published Packages" -Status "Starting" -PercentComplete 0
            ForEach ($IntuneApp in $IntuneApps)
            { # each published intuneapp
                $i+=1
                $PercentComplete = (($i / $i_count) * 100)
                $Status = "Checking $($i) of $($i_count) : $($IntuneApp.DisplayName)"
                Write-Progress -Activity "Checking Published Packages" -Status $Status -PercentComplete $PercentComplete
                # check for dupes within intune
                $IntuneDupes = @($IntuneApps | Where-Object DisplayName -eq $IntuneApp.DisplayName)
                if ($IntuneDupes.count -gt 1)
                { # dupes exist
                    Write-host "Warning: Duplicate Intune apps found for: " -NoNewline
                    Write-host $IntuneApp.DisplayName -ForegroundColor Green
                    Write-host ($IntuneDupes | Select-Object DisplayName,CreatedDateTime,Id | Format-Table | Out-String)
                    Write-host "Publishing can't proceed when there are duplicates."
                    $choice = AskForChoice -Message "Remove ALL versions of this app? (N=Skip this app)" -Choices "&Remove","&Skip","&Cancel" -DefaultChoice 0
                    if ($choice -eq 1)
                    {Continue} # skip
                    elseif ($choice -eq 2)
                    {Break} # cancel
                    else
                    { # removedupes
                        ForEach ($IntuneDupe in $IntuneDupes)
                        { # each dupe
                            Remove-MgDeviceAppManagementMobileApp -MobileAppId $IntuneDupe.Id -ErrorAction Ignore
                            Write-Host "App Removed: " -nonewline
                            Write-Host "$($IntuneDupe.DisplayName) [$($IntuneDupe.Id)]" -ForegroundColor Yellow
                            # now remove them from the in-memory list so we don't have to read the whole thing again
                            $IntuneDupe.DisplayName = "$($IntuneDupe.DisplayName) [$($IntuneDupe.Id)] Deleted" 
                        } # each dupe
                    } # removedupes
                } # dupes exist
                #region: check group assignments for the app
                $Required_Org_YesNo = "" # assume group isn't in org
                if ($Required_OrgGroupId)
                { # org has a Required group
                    # get Required Group Assignments that match the publication group (Required_OrgGroupId)
                    $AppAssignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $IntuneApp.Id -all -ErrorAction Ignore
                    $AppAssignments = $AppAssignments | Where-Object {($_.Intent -eq "required") `
                            -and ($_.target.AdditionalProperties."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") `
                            -and ($_.target.AdditionalProperties.groupId -eq $Required_OrgGroupId)}
                    if ($AppAssignments) {
                        $Required_Org_YesNo = "Yes"
                    } # $AppAssignments.target.AdditionalProperties.groupId | % {Get-MgGroup -GroupId $_} 
                } # org has a Required group
                #endregion: check group assignments for the app
                #region: check for matching local pkg
                $pkg = $pkgs | Where-Object AppName -eq $IntuneApp.DisplayName
                if ($pkg)
                { # matching local app found
                    if ($pkg.Fullpath.count -gt 1)
                    { # there are duplicate apps with same name
                        Write-Host "Warning: There are duplicate apps with the same name in the CSV file: " -ForegroundColor Yellow
                        Write-Host "AppName: $($IntuneApp.DisplayName)"
                        $pkg.Fullpath | Write-Host
                        PressEnterToContinue "These will be ignored. Correct this problem before the next publication. Press Enter to Continue"
                        Continue
                    } # there are duplicate apps with same name
                    $pkg.PublishedAppId = $IntuneApp.Id
                    $pkg.PublishedDate  = $IntuneApp.CreatedDateTime.ToString("yyyy-MM-dd")
                    $pub_hash = ParseToken $IntuneApp.Description "Hash: [" "]"
                    if (($pub_hash -ne "") -and ($pub_hash -eq $pkg.Hash))
                    { # hash match
                        $pkg.PublicationStatus = "Published"
                    } # hash match
                    else
                    { # no match
                        $pkg.PublicationStatus = "Needs Update"
                        $pkg.PublishedAppId = $IntuneApp.Id
                    } # no match
                    $pkg.Required_Org = $Required_Org_YesNo
                } # matching local app found
                else
                { # no matching local app, add a new row 
                    $pkgobj_new = [Ordered]@{}
                    $pkgobj_new.Add("AppName"           ,$IntuneApp.DisplayName)
                    $pkgobj_new.Add("PublicationStatus" ,"Package Missing")
                    $pkgobj_new.Add("PublishedDate"     ,$IntuneApp.CreatedDateTime.ToString("yyyy-MM-dd"))
                    $pkgobj_new.Add("AppDescription"    ,$IntuneApp.Description)
                    $pkgobj_new.Add("PublishedAppId"    ,$IntuneApp.Id)
                    $pkgobj_new.Add("Required_Org"      ,$Required_Org_YesNo)
                    $pkgobj_new.Add("Required_Pkg"      ,"")
                    $pkgs+=$pkgobj_new
                } # no matching local app, add a new row
                #endregion: check for matching local pkg
            } # each published intuneapp
            Write-Progress -Activity "Checking Published Packages" -Status "Complete" -PercentComplete 100 -Completed
            #endregion Check published apps
            #region app selections
            $pkgchoices = $pkgs | Select-Object `
            @{Name = 'AppName'           ; Expression = {$_.AppName}} `
            ,@{Name = 'PublicationStatus'; Expression = {$_.PublicationStatus}} `
            ,@{Name = 'PublishedDate'    ; Expression = {$_.PublishedDate}} `
            ,@{Name = 'Required_Pkg'    ; Expression = {if ($_.PublishToOrgGroup) {"Yes"} else {""}}} `
            ,@{Name = 'Required_Org'    ; Expression = {$_.Required_Org}} `
            ,@{Name = 'AppInstaller'     ; Expression = {$_.AppInstaller}} `
            ,@{Name = 'AppDescription'   ; Expression = {CropString $_.AppDescription.Replace("`n","").Replace("`r","")}} | Sort-object AppName
            Write-Host "Choose apps from the popup list (may be behind this window - check taskbar): " -NoNewline
            $msg= "Select rows and click OK (Use Ctrl and Shift and Filter features to multi-select)"
            # Note: Out-GridView filtering doesn't work in PS7. So we can use Out-ConsoleGridView instead, but it's probably not worth it because it's not as good.
            #ps5 
            $pkgselects =  @($pkgchoices | Out-GridView -PassThru -Title $msg) 
            #ps7 only Install-Module Microsoft.PowerShell.ConsoleGuiTools for Out-ConsoleGridView
            #$pkgselects =  @($pkgchoices | Out-ConsoleGridView -OutputMode Multiple -Title "Select Packages") 
            #endregion app selections
            if ($pkgselects.Count -eq 0)
            { # apps canceled
                Write-Host "Canceled"
                $showmenu_publish = $false
            } # apps canceled
            else
            { # apps selected
                # convert selects to a bunch of objects (with all the properties)
                $pkgselect_objs = $pkgs | Where-Object AppName -in $pkgselects.AppName
                $pkgwarnings_objs = $pkgselects | Where-Object {$_.Required_Pkg -ne $_.Required_Org}
                $pkgwarnings_msg = ""
                $pkgwarnings_msg = $pkgwarnings_objs.AppName -Join ", "
                # Show a menu of choices
                Write-Host "$($pkgselects.Count) apps selected"
                Write-Host "---------------------------------------------------------------"
                Write-Host ($pkgselects | Format-Table | Out-string)
                Write-Host "---------------------------------------------------------------"
                Write-Host "[P]ublish       - Publish using package settings (Recommended)"
                Write-Host "[R]equired      - Publish as Required to group: " -NoNewline
                Write-host $OrgValues.PublishToGroupIncluded -NoNewline -ForegroundColor Yellow 
                Write-host " (ignores package settings for PublishToOrgGroup)"
                Write-Host "[N]ot Required  - Publish as Not Required (ignores package settings for PublishToOrgGroup)"
                Write-Host "[U]npublish     - Remove app from the org"
                Write-Host "---------------------------------------------------------------"
                $msg= "Select an action for these $($pkgselects.count) apps"
                $actionchoices = @("E&xit","&Publish","&Required","&Not Required","&Unpublish")
                $action=AskForChoice -message $msg -choices $actionchoices -defaultChoice 1 -showmenu:$false
                Write-Host "Action : $($actionchoices[$action].Replace('&',''))"
                if ($action -eq 0)
                { Write-host "Aborting" }
                elseif (($action -ge 1) -and ($action -le 3))
                { # action publish, Required, notrequired
                    # warn of requirement diffs
                    if ($pkgwarnings_msg -ne "") {
                        Write-Host "Warning, package(s) with Require_Pkg and Required_Org difference: " -NoNewline
                        Write-Host $pkgwarnings_msg -ForegroundColor Red
                        Write-Host "   Publishing may immediately add packages to users in the Group: " -NoNewline
                        Write-Host $($OrgValues.PublishToGroupIncluded) -ForegroundColor Yellow
                    }
                    if (-not (AskForChoice))
                    {
                        Write-Host "Aborted"
                        Continue
                    }
                    # description of publish_option
                    $publish_option_msg = ""
                    if ($action -eq 2) {$publish_option_msg = "[R]equired"}
                    if ($action -eq 3) {$publish_option_msg = "[N]ot Required"}
                    $apps_touched_count=0
                    #region Remove unpackaged rows
                    $pkg_missing = @($pkgselects | Where-Object PublicationStatus -eq "Package Missing")
                    if ($pkg_missing.count -gt 0)
                    {
                        Write-Host "Skipping unpackaged apps: ($($pkg_missing.Count)) " -NoNewline
                        Write-Host ($pkg_missing.AppName -join ", ") -ForegroundColor Green -NoNewline
                        Write-Host " (PublicationStatus=Package Missing)"
                        $pkgselects = $pkgselects | Where-Object PublicationStatus -ne "Package Missing"
                        # convert selects to a bunch of objects (with all the properties)
                        $pkgselect_objs = $pkgs | Where-Object AppName -in $pkgselects.AppName
                    }
                    #endregion Remove unpackaged rows
                    #region Remove published
                    $pkg_published = @($pkgselects | Where-Object PublicationStatus -eq "Published")
                    if ($pkg_published.count -gt 0)
                    {
                        Write-Host "Skipping published apps that are already up to date: ($($pkg_published.Count)) "
                        Write-Host ($pkg_published | Format-Table | Out-String)
                        if ((AskForChoice "Skip $($pkg_published.Count) apps that are already up to date? Yes=Skip, No=Re-publish") -eq 1)
                        {
                            $pkgselects = $pkgselects | Where-Object PublicationStatus -ne "Published"
                            # convert selects to a bunch of objects (with all the properties)
                            $pkgselect_objs = $pkgs | Where-Object AppName -in $pkgselects.AppName
                        }
                    }
                    #endregion Remove published
                    If ($pkgselects.count -eq 0)
                    {Continue}
                    Write-host "Publishing $($pkgselects.count) apps"
                    #region Connect to MSIntuneGraph
                    $connected=$false
                    $done = $false
                    $DeviceCode = $false
                    Do {# Until Connect-MSIntuneGraph
                        #  Test-AccessToken -RenewalThresholdMinutes 10
                        if ($DeviceCode) {
                            Write-host "[-DeviceCode option] To sign in... information is about to be shown. Open the URL (as an org admin) and copy / paste the code. The process will continue (or timeout)." -ForegroundColor Yellow
                            Write-host "Note: if this isn't working you may make a one-time adjustment to the IntuneApp Publisher app"
                            Write-host "      Entra > Applications > App registrations > All applications > [IntuneApp Publisher] > Authentication > Allow public client flows: Yes"
                            Write-host "      https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Authentication/appId/$($OrgValues.AppPublisherClientID)"
                            PressEnterToContinue
                        }
                        # This can fail in PS7 (without the DeviceCode option): The embedded WebView2 browser cannot be started because a runtime component cannot be loaded. For troubleshooting details, see https://aka.ms/msal-net-webview2 
                        # Download and install from Microsoft (Look for the Evergreen Standalone Installer (x64)): https://developer.microsoft.com/en-us/microsoft-edge/webview2/
                        $connect_try = $true # assume we need to connect
                        if ($AuthToken) { # existing token found
                            Write-Host "Connect-MSIntuneGraph: Token AuthToken found." -ForegroundColor Yellow
                            if (($AuthToken.ExpiresOn-(Get-Date)).TotalHours -gt 0) {
                                $token_claims = Get-TokenDetailsFromHeader $AuthToken
                                if ($token_claims.TenantId -eq (Get-MgContext).TenantId) {
                                    Write-Host "Connect-MSIntuneGraph: Token is valid for this Org. Using existing token." -ForegroundColor Yellow
                                    $connect_try = $false
                                } else {
                                    Write-Host "Connect-MSIntuneGraph: Token ($($token_claims.User)) is NOT valid for this Org ($($OrgValues.TenantName)). Reconnecting." -ForegroundColor Yellow
                                    $connect_try = $true
                                }
                            }
                        } # existing token found
                        if ($connect_try) {
                            Write-Host "[Connect-MSIntuneGraph] Connecting to Tenant: $($OrgValues.TenantName) [You may see a sign-on popup <OR> subsequent directions for web sign-on]" -ForegroundColor Yellow
                            $AuthToken = Connect-MSIntuneGraph -TenantID $OrgValues.TenantName -ClientID $OrgValues.AppPublisherClientID -RedirectUri "https://login.microsoftonline.com/common/oauth2/nativeclient" -DeviceCode:$DeviceCode
                        }
                        if ($AuthToken)
                        {
                            Write-Host "Connected OK for: $(($AuthToken.ExpiresOn-(Get-Date)).TotalHours.toString("0.#")) hrs"
                            $connected=$true
                            $done=$true
                        }
                        else
                        {
                            $msg = "Connect-MSIntuneGraph failed. Try again?"
                            #Write-Host $msg -ForegroundColor Yellow
                            $connected=$false
                            $result = AskForChoice $msg -Choices @("&Yes","Yes using the &Device code option","&No") -ReturnString
                            if ($result -eq "No") {
                                $done=$true
                            }
                            elseif ($result -eq "Yes") {
                                $done=$false
                            }
                            elseif ($result -eq "Yes using the Device code option") {
                                $DeviceCode = $true
                            }
                        }
                    } Until ($done) # Until Connect-MSIntuneGraph
                    if (-not $connected) {
                        Write-Host "Connect-MSIntuneGraph: Not connected, exiting"
                        Pause;Break
                    }
                    #endregion Connect to MSIntuneGraph
                    # Force Yes to All (ignore this portion of the code that asks per app)
                    $pubchoice = 1
                    ForEach ($pkg in $pkgselect_objs)
                    { # Each package
                        #region display
                        Write-Host "App to publish : " -nonewline
                        Write-Host $pkg.AppName -ForegroundColor green
                        Write-Host "              TenantName : $($OrgValues.TenantName)" -ForegroundColor Yellow
                        if ($pkg.AvailableInCompanyPortal)
                        {
                            Write-Host "AvailableInCompanyPortal : $($pkg.AvailableInCompanyPortal)" -ForegroundColor Yellow
                        }
                        else
                        {
                            Write-Host "AvailableInCompanyPortal : $($pkg.AvailableInCompanyPortal)"
                        }
                        # Determine Publishing group option
                        $publish_option_msg = ""
                        if ($action -eq 2) {$publish_option_msg = "[R]equired"}
                        if ($action -eq 3) {$publish_option_msg = "[N]ot Required"}
                        $publish_option_boolean = $false # assume not Required
                        if ($publish_option_msg -eq "") { # override is off: use package option
                            $publish_option_boolean = $pkg.PublishToOrgGroup
                        }
                        else { # override is on: Required or not
                            $publish_option_boolean = ($publish_option_msg -eq "[R]equired")
                        }
                        ###
                        if ($publish_option_boolean)
                        {
                            Write-Host "  PublishToGroupIncluded : $($OrgValues.PublishToGroupIncluded) $($publish_option_msg)"
                            Write-Host "  PublishToGroupExcluded : $($OrgValues.PublishToGroupExcluded)"
                        }
                        else
                        {
                            Write-Host "  PublishToGroupIncluded : None $($publish_option_msg)" -ForegroundColor DarkGray
                            Write-Host "  PublishToGroupExcluded : None" -ForegroundColor DarkGray
                        }
                        Write-Host "            AppName      : $($pkg.AppNameVer)" -ForegroundColor Yellow
                        Write-Host "            SystemOrUser : $($pkg.SystemOrUser)" -ForegroundColor Yellow
                        Write-Host "            AppDesc      : $($pkg.AppDescription)" -ForegroundColor Yellow
                        #endregion display
                        if ($pubchoice -ne 1)
                        {
                            Write-Host "Proceed to create and publish $($pkg.AppNameVer)?"
                            $pubchoices = @("&Yes","Yes to &All","&No") 
                            $pubchoice=AskForChoice -message "Publish $($pkg.AppNameVer)?" -choices $pubchoices -defaultChoice 0
                            Write-Host "Proceed to create and publish app: $($pubchoices[$pubchoice].Replace('&',''))"
                            if ($pubchoice -eq 2)
                            {Write-Host "Aborting";Start-Sleep -Seconds 0; Continue}
                        }
                        #region delete apps that conflict
                        Write-Host "Checking for existing app: $($pkg.AppName)..." -ForegroundColor Yellow
                        $apps_todel = $null
                        $apps_todel = @($pkgs | Where-Object AppName -eq $pkg.AppName | Where-Object PublishedAppId -ne "")
                        if ($apps_todel.Count -eq 0)
                        {
                            Write-Host "OK: No existing app found"
                        }
                        else
                        { # apps_todel
                            $i=0
                            ForEach ($app_todel in $apps_todel)
                            { # each package
                                $i+=1
                                Write-Host "Deleting old app $($app_todel.AppName): " -NoNewline
                                if ($app_todel.PublishedAppId -eq "")
                                { # no appid
                                    Write-Host "App not found" -ForegroundColor Yellow
                                } # no appid
                                else
                                { # has appid
                                    Remove-MgDeviceAppManagementMobileApp -MobileAppId $app_todel.PublishedAppId
                                    Write-Host "App deleted" -ForegroundColor Yellow
                                } # has appd
                            } # each package
                        } # apps_todel
                        #endregion delete apps that conflict
                        # Create intunewin zip file in temp folder along with in-mem script files for intune: start
                        $IntuneTempFolder = GetTempFolder -Prefix "IntuneWinApp"
                        Write-Host "Creating Win32App zip file (.intunewin) ..." -ForegroundColor Yellow
                        #Write-Host "Temp Folder: $($IntuneTempFolder)"
                        #install/uninstall cmds
                        $intune_install_cmd     ="IntuneUtils\intune_install.ps1"
                        $intune_uninstall_cmd   ="IntuneUtils\intune_uninstall.ps1"
                        #create zip
                        $IntuneWinFile = $null
                        while (-not $IntuneWinFile)
                        { # keep trying to build
                            #Location of IntuneWinAppUtil.exe
                            $IntuneWinAppUtilPath = "$($scriptDir)\Utils\IntuneWinAppUtil.exe"
                            # try from \Utils\IntuneWinAppUtil.exe otherwise TEMP
                            If (Test-Path $IntuneWinAppUtilPath -PathType Leaf){
                                $ver = . $IntuneWinAppUtilPath -v
                                $daysold = ((Get-Date)-(Get-Item $IntuneWinAppUtilPath).LastWriteTime).Days
                                Write-Host "Use IntuneWinAppUtil.exe v$($ver) [Days old: $($daysold)] (from \Utils\IntuneWinAppUtil.exe instead of automatic download)"
                            }
                            else {
                                $daysoldmax = 90
                                $IntuneWinAppUtilPath =Join-Path -Path $env:TEMP -ChildPath "IntuneWinAppUtil.exe" 
                                If (Test-Path $IntuneWinAppUtilPath -PathType Leaf){
                                    $ver = . $IntuneWinAppUtilPath -v
                                    $daysold = ((Get-Date)-(Get-Item $IntuneWinAppUtilPath).LastWriteTime).Days
                                    if ($daysold -gt $daysoldmax) {
                                        $ver="not downloaded yet"
                                        Write-Host "Use IntuneWinAppUtil.exe (will be downloaded automatically by New-IntuneWin32AppPackage)"
                                        Write-Host "Found IntuneWinAppUtil.exe v$($ver) [Days old: $($daysold)] (from $($env:TEMP)\IntuneWinAppUtil.exe will be deleted and re-downloaded since it is older than $($daysoldmax) days)"
                                        Remove-Item $IntuneWinAppUtilPath -Force | Out-Null
                                    }
                                    else {
                                        Write-Host "Use IntuneWinAppUtil.exe v$($ver) [Days old: $($daysold)] (from $($env:TEMP)\IntuneWinAppUtil.exe instead of automatic download at $($daysoldmax) days)"
                                    }
                                }
                                else {
                                    $ver="not downloaded yet"
                                    Write-Host "Use IntuneWinAppUtil.exe (will be downloaded automatically by New-IntuneWin32AppPackage)"
                                }
                                $IntuneWinAppUtilPath = $null # when this is null New-IntuneWin32AppPackage checks Temp, if not found it downloads to Temp
                            }
                            # Splat the Required arguments
                            $SplatArgs = @{
                                SourceFolder         = $pkg.Fullpath 
                                SetupFile            = $intune_install_cmd 
                                OutputFolder         = $IntuneTempFolder
                                Verbose              = $verbosepackager
                            }
                            # Optional args
                            if($IntuneWinAppUtilPath) {$SplatArgs.IntuneWinAppUtilPath = $IntuneWinAppUtilPath}
                            # Create intunewin
                            $IntuneWinFile = New-IntuneWin32AppPackage @SplatArgs
                            #$IntuneWinFile = New-IntuneWin32AppPackage -SourceFolder $pkg.Fullpath -SetupFile $intune_install_cmd -OutputFolder $IntuneTempFolder -Verbose:$verbosepackager -IntuneWinAppUtilPath $IntuneWinAppUtilPath
                            if (-not ($IntuneWinFile))
                            {
                                Write-Host "Intunewin file not created (is a file open?): $($IntuneTempFolder)"
                                if ((AskForChoice "Intunewin file not created. Possible causes: (1) .csv or other file is locked, (2) Package creation tool is crashing (check this file \Utils\IntuneWinAppUtil.exe) . Try again?") -eq 0) {Write-Host "Aborting";Start-Sleep -Seconds 3; exit}
                            }
                        } # keep trying to build
                        #intune_detection.ps1 (see above for return values)
                        $DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile "$($pkg.Fullpath)\IntuneUtils\intune_detection.ps1"
                        # intune_requirements.ps1 (see above for return values)
                        $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "W10_1809"
                        $AdditionalRequirementRule = New-IntuneWin32AppRequirementRuleScript -ScriptFile "$($pkg.Fullpath)\IntuneUtils\intune_requirements.ps1" -StringOutputDataType -StringComparisonOperator equal -StringValue "REQUIREMENTS_MET" -ScriptContext $pkg.SystemOrUser
                        # Convert image file to icon
                        $IntuneIcon = New-IntuneWin32AppIcon -FilePath "$($pkg.Fullpath)\intune_icon.png"
                        # Install and Uninstall commands
                        $InstallCommandLine   = "Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $($intune_install_cmd) -quiet"
                        $UninstallCommandLine = "Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $($intune_uninstall_cmd) -quiet"
                        # Create intunewin zip file in temp folder along with in-mem script files for intune: end
                        #### AppDescription
                        if ($pkg.AppDescription) {
                            $AppDescription=$pkg.AppDescription
                        }
                        else {
                            $AppDescription="(None)"
                        }
                        $AppDescription+="`r`n* " #Markdown. See Endpoint Manager>App>Edit description for Markdown help/visual editor. (Newline starting with: > block quote, * list, # header, ## header2, ### header3)
                        $AppDescription+="$($pkg.AppNameVer)"
                        # AppInstaller:ps1 (Setup.ps1 -ARGS:test)
                        $AppDescription+="`r`n* AppInstaller: $($pkg.AppInstaller) ($($pkg.AppInstallName)"
                        if ($pkg.AppInstallArgs -ne "") {$AppDescription+=" $($pkg.AppInstallArgs)"}
                        $AppDescription+=")"
                        # ps1 AppUninstallVersion (upgrade if below): 129
                        if (($pkg.AppInstaller -eq "ps1") -and ($pkg.AppUninstallVersion -ne "")) {
                            $AppDescription+="`r`n* ps1 AppUninstallVersion (upgrade if below): $($pkg.AppUninstallVersion)"
                        }
                        # AvailableInCompanyPortal: True
                        if ($pkg.AvailableInCompanyPortal) {
                            $AppDescription+="`r`n* AvailableInCompanyPortal: $($pkg.AvailableInCompanyPortal)"
                        }
                        # Pushed to group: IntuneApp Appname
                        if (($pkg.PublishToOrgGroup) -and ($OrgValues.PublishToGroupIncluded)) {
                            $AppDescription+="`r`n* Pushed to group: IntuneApp $($pkg.AppName), $($OrgValues.PublishToGroupIncluded)"
                        }
                        else {
                            $AppDescription+="`r`n* Pushed to group: IntuneApp $($pkg.AppName)"
                        }
                        # Exclude group: IntuneApp Appname Exclude
                        if ($pkg.CreateExcludeGroup -eq "true") {
                            $AppDescription+="`r`n* Excluded from group: IntuneApp $($pkg.AppName) Exclude"
                        }
                        # Updated by and Hash value (used to check for package content changes in later publish requests)
                        $AppDescription+="`r`n* Updated: $(Get-Date -format "yyyy-MM-dd") by $($env:USERNAME) on $($env:COMPUTERNAME)"
                        $AppDescription+="`r`n* Hash: [$($pkg.Hash)]"
                        #### AppDescription
                        # Splat the Required arguments
                        $SplatArgs = @{
                            FilePath         = $IntuneWinFile.Path
                            DisplayName      = $pkg.AppName
                            Description      = $AppDescription
                            InstallExperience= $pkg.SystemOrUser 
                            RestartBehavior  = $pkg.RestartBehavior # allow, basedOnReturnCode, suppress or force
                            DetectionRule    = $DetectionRule
                            RequirementRule  = $RequirementRule
                            AdditionalRequirementRule = $AdditionalRequirementRule
                            InstallCommandLine        = $InstallCommandLine
                            UninstallCommandLine      = $UninstallCommandLine
                            Icon                      = $IntuneIcon
                            CompanyPortalFeaturedApp  = ($pkg.CompanyPortalFeaturedApp -eq "True")
                            AllowAvailableUninstall   = $true
                            Publisher                 = $pkg.Publisher
                            }
                        # Error checking
                        $pattern="(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)"
                        if (($pkg.InformationURL -ne $null) -and (-not ($pkg.InformationURL -match $pattern))) {
                            Write-Host "Warning: Removing InformationURL '$($pkg.InformationURL)' due to failed match pattern '$($pattern)'" -ForegroundColor Yellow
                            Write-Host "(Does it start with https:// ?)" -ForegroundColor Yellow
                            $pkg.InformationURL=$null
                            PressEnterToContinue
                        }
                        # Optional args
                        if($pkg.InformationURL) {$SplatArgs.InformationURL = $pkg.InformationURL}
                        if($pkg.PrivacyURL)     {$SplatArgs.PrivacyURL     = $pkg.PrivacyURL}
                        if($pkg.Notes)          {$SplatArgs.Notes          = $pkg.Notes}
                        if($pkg.Owner)          {$SplatArgs.Owner          = $pkg.Owner}
                        if($pkg.Developer)      {$SplatArgs.Developer      = $pkg.Developer}
                        if($pkg.AppVersion)     {$SplatArgs.AppVersion     = $pkg.AppVersion}
                        if($pkg.Publisher)      {$SplatArgs.Publisher      = $pkg.Publisher} else {$SplatArgs.Publisher = "<none>"} # Publisher is required
                        # Adding
                        Write-Host "Adding $($pkg.AppName) to $($OrgValues.TenantName) ... "
                        $AutoRetries=2
                        Do
                        { #### FINALLY, ADD THE APP TO INTUNE
                            $added_app=Add-IntuneWin32App @SplatArgs -Verbose:$verbosepackager
                            #### FINALLY, ADD THE APP TO INTUNE
                            if ($null -eq $added_app.id)
                            { # Publish didn't work
                                # This usually means the app was added but no id was returned and it may be in an incosistent state. Search for name and delete it.
                                #
                                Write-host "There was a problem uploading Add-IntuneWin32App -DisplayName '$($pkg.AppName)'" -ForegroundColor Yellow
                                Write-host "It may be in an inconsistent state, so all found instances will be removed."
                                #region delete apps that conflict
                                Write-Host "Checking for existing app: $($pkg.AppName)..." -ForegroundColor Yellow
                                $apps_todel  = @()
                                $apps_todel += Get-MgDeviceAppManagementMobileApp -All -ErrorAction Ignore
                                $apps_todel = @($apps_todel | Where-Object {$_.AdditionalProperties."@odata.type" -in ("#microsoft.graph.win32LobApp")})
                                $apps_todel = @($apps_todel | Where-Object DisplayName -eq $pkg.AppName)
                                if ($apps_todel.Count -eq 0) {
                                    Write-Host "OK: No existing app found to delete"
                                }
                                else
                                { # apps_todel
                                    $i=0
                                    ForEach ($app_todel in $apps_todel)
                                    { # each package
                                        $i+=1
                                        Write-Host "Deleting old app $($app_todel.DisplayName) [$($app_todel.Id)]: " -NoNewline
                                        if ($app_todel.PublishedAppId -ne "")
                                        { # has appid
                                            Remove-MgDeviceAppManagementMobileApp -MobileAppId $app_todel.Id
                                            Write-Host "App deleted" -ForegroundColor Yellow
                                        } # has appd
                                    } # each package
                                } # apps_todel
                                #endregion delete apps that conflict
                                $msg = "There was a problem uploading Add-IntuneWin32App -DisplayName '$($pkg.AppName)'."
                                # Something didn't work
                                If ($AutoRetries -gt 0)
                                { # some auto retries left
                                    $msg += " Retrying. Auto-retries left: $($AutoRetries)"
                                    Write-host $msg
                                    $AutoRetries-=1
                                    Start-Sleep 3
                                } # some auto retries left
                                else
                                { # no auto retries left
                                    $msg += " Try again?"
                                    if (0 -eq (AskforChoice $msg))
                                    { # try again = no, forget this one
                                        Write-Host "The app was deleted. It is recommended to re-publish this app in another session, since its state can't be guaranteed." -ForegroundColor Green
                                        Pause
                                        Break
                                    } # forget this one
                                }# no auto retries left
                            } # Publish didn't work
                        } While ($null -eq $added_app.id) # Loop until publish works
                        if ($null -eq $added_app.id) 
                        {continue} # step next
                        #region AvailableInCompanyPortal
                        if ($pkg.AvailableInCompanyPortal)
                        {
                            Write-Host "AvailableInCompanyPortal: $($pkg.AvailableInCompanyPortal) (Visible in portal)" -ForegroundColor Yellow
                            Add-IntuneWin32AppAssignmentAllUsers -ID $added_app.id -Intent "available" -Notification "showAll" -Verbose:$verbosepackager | Out-Null
                        }
                        else
                        {
                            Write-Host "AvailableInCompanyPortal: $($pkg.AvailableInCompanyPortal) (Not visible in portal)" -ForegroundColor Gray
                        }
                        #endregion AvailableInCompanyPortal
                        #region include_exclude groups
                        if (-not $publish_option_boolean)
                        {
                            Write-Host "PublishToOrgGroup: " -NoNewline; Write-Host "FALSE " -NoNewline -ForegroundColor Yellow
                            Write-Host "Group '$($OrgValues.PublishToGroupIncluded)' will NOT be added to this app. $($publish_option_msg)"
                        }
                        elseif ($OrgValues.PublishToGroupIncluded)
                        {  #has include group
                            #region group PublishToGroupIncluded
                            $groupname = $OrgValues.PublishToGroupIncluded
                            Write-Host "Including via Group: $($groupname) ... " -NoNewline
                            $strReturn,$MgGroup=MgGroupCreate $groupname
                            Write-Host $strReturn
                            if (-not $MgGroup)
                            {Write-Host "Couldn't find group with that name. App will be available, but will not reference the group." -ForegroundColor Red}
                            else
                            { 
                                Add-IntuneWin32AppAssignmentGroup -ID $added_app.id -GroupID $MgGroup.Id -Include -Intent "required" -Notification "showAll" -Verbose:$verbosepackager| Out-Null
                                Write-Host "OK: App references Group: $($groupname)" -ForegroundColor Yellow
                            }
                            #endregion group PublishToGroupIncluded
                            if ($OrgValues.PublishToGroupExcluded)
                            { #has exclude group    
                                #region group PublishToGroupExcluded
                                $groupname = $OrgValues.PublishToGroupExcluded
                                Write-Host "Excluding via Group: $($groupname) ... " -NoNewline
                                $strReturn,$MgGroup=MgGroupCreate $groupname
                                Write-Host $strReturn
                                if (-not $MgGroup)
                                {Write-Host "Couldn't find group with that name. App will be available, but will not reference the group." -ForegroundColor Red}
                                else
                                { 
                                    Add-IntuneWin32AppAssignmentGroup -ID $added_app.id -GroupID $MgGroup.Id -Exclude -Intent "required" -Verbose:$verbosepackager | Out-Null
                                    Write-Host "OK: App references Group: $($groupname)" -ForegroundColor Yellow
                                }
                            } #has exclude group
                            #endregion group PublishToGroupExcluded
                        } #has include group
                        #endregion include_exclude groups
                        #region add app group include
                        $groupname = "IntuneApp $($pkg.AppName)"
                        Write-Host "Including via this-app-only Group: $($groupname) ... " -NoNewline
                        $strReturn,$MgGroup=MgGroupCreate $groupname
                        Write-Host $strReturn
                        if (-not $MgGroup)
                        {Write-Host "Couldn't find group with that name. App will be available, but will not reference the group." -ForegroundColor Red}
                        else
                        { 
                            Add-IntuneWin32AppAssignmentGroup -ID $added_app.id -GroupID $MgGroup.Id -Include -Intent "required" -Notification "showAll" -Verbose:$verbosepackager| Out-Null
                            Write-Host "OK: App references Group: $($groupname)" -ForegroundColor Yellow
                        }
                        #endregion add app group include
                        if ($pkg.CreateExcludeGroup -eq "true")
                        { # add app group exclude
                            $groupname = "IntuneApp $($pkg.AppName) Exclude"
                            Write-Host "Excluding via this-app-only Group: $($groupname) ... " -NoNewline
                            $strReturn,$MgGroup=MgGroupCreate $groupname
                            Write-Host $strReturn
                            if (-not $MgGroup)
                            {Write-Host "Couldn't find group with that name. App will be available, but will not reference the group." -ForegroundColor Red}
                            else
                            { 
                                Add-IntuneWin32AppAssignmentGroup -ID $added_app.id -GroupID $MgGroup.Id -Exclude -Intent "required" -Verbose:$verbosepackager| Out-Null
                                Write-Host "OK: App references Group: $($groupname)" -ForegroundColor Yellow
                            }
                        } # add app group exclude
                        # Delete temp folder
                        Remove-Item $IntuneTempFolder -Recurse
                        Write-Host "Done adding app: " -NoNewline
                        Write-Host $pkg.AppNameVer -ForegroundColor Green
                        Write-Host "Endpoint Manager URL (to check app, etc):"
                        $app_url = "https://endpoint.microsoft.com/?ref=AdminCenter#blade/Microsoft_Intune_Apps/SettingsMenu/0/appId/$($added_app.id)"
                        Write-Host "$($app_url)" -ForegroundColor Green
                        Write-Host "--------------------------------------------"
                        $apps_touched_count += 1
                    } # Each package
                } # action publish, Required, notrequired
                elseif ($action -eq 4)
                { # action delete
                    Write-host "Unpublishing $($pkgselects.count) apps"
                    $i=0
                    ForEach ($pkgselect in $pkgselect_objs)
                    { # each package
                        $i+=1
                        Write-Host "$($i)) $($pkgselect.AppName): " -NoNewline
                        if ($pkgselect.PublishedAppId -eq "")
                        { # no appid
                            Write-Host "App not found" -ForegroundColor Yellow
                        } # no appid
                        else
                        { # has appid
                            $bDelete = $True
                            if ($pkgselect.PublicationStatus -eq "Package Missing")
                            {
                                Write-host ""
                                Write-host "Warning: No offline package" -ForegroundColor Yellow
                                $bDelete = ((AskforChoice "There is no offline package for $($pkgselect.AppName). Once deleted from the org, it can not be re-published. Continue?") -eq 1)
                            }
                            If ($bDelete)
                            { #asked 
                                Remove-MgDeviceAppManagementMobileApp -MobileAppId $pkgselect.PublishedAppId -ErrorAction Ignore
                                Write-Host "App unpublished" -ForegroundColor Yellow
                                # remove orphaned groups        
                                $groupname = "IntuneApp $($pkgselect.AppName)"
                                $MgGroup = Get-MgGroup -All | Where-Object {$_.DisplayName -eq $groupname}
                                if ($mgGroup)
                                { # has group
                                    Write-Host "   Remove associated group (if empty): $($groupname)... " -NoNewline
                                    $Children = Get-MgGroupMember -GroupId $MgGroup.id -ErrorAction Ignore
                                    if ($Children) {
                                        Write-Host "Left group alone (not empty)"
                                    } # non-empty
                                    else {
                                        Remove-MgGroup -GroupId $MgGroup.id
                                        Write-Host "Removed" -ForegroundColor Yellow
                                    } # empty (orphan)
                                } # has group
                                $apps_touched_count += 1
                            } #asked
                            else
                            {
                                Write-Host "App skipped" -ForegroundColor Yellow
                            }
                        } # has appid
                    } # each package
                } # action delete
                #region update orgcsv
                $pkgscount =$pkgchoices | Where-Object PublicationStatus -in ("Published","Needs Update","Package Missing")
                $Orglist[$choice].Packages = $pkgscount.count
                $Orglist[$choice]."Last Publish Date" = get-date -format "yyyy-MM-dd_HH:mm:ss"
                if ($apps_touched_count -gt 0)
                { # something changed
                    $Orglist[$choice]."Last Publish Count" = $apps_touched_count
                } # something changed
                Do
                { # try exporting
                    Try {
                        $orglist | Export-Csv $orglistcsv -NoTypeInformation
                        Break
                    }
                    Catch {
                        Write-Host "Couldn't export to CSV, make sure it's not open/locked: $(Split-Path $orglistcsv -Leaf)"
                        PressEnterToContinue
                    }
                } # try exporting
                Until ($true)
            } # apps selected
            #endregion update orgcsv
            Write-Host "Check apps at the Intune Windows Apps (Admin center):"
            Write-Host "https://intune.microsoft.com/?ref=AdminCenter#view/Microsoft_Intune_DeviceSettings/AppsWindowsMenu/~/windowsApps" -ForegroundColor Green
            # Kind of like Pause but with a custom key and msg
            $retVal=AskForChoice -message "Done. Publish something else?"
            if ($retVal -eq 0) {
                $showmenu_publish =$false
                $bShowmenu=$false
            }
        } until (-not $showmenu_publish)
    } # Menu Choice: Publish
    ElseIf ($action -eq 3)
    { # Menu Choice: Org Create
        $AppName = "IntuneApp Publisher"
        $orglistcsv = "$($scriptdir)\AppsPublish_OrgList.csv"
        If (-not (Test-Path $orglistcsv)) {InitializeOrgList $orglistcsv}
        $orglist=Import-Csv $orglistcsv
        #
        Write-Host "-----------------------------------------------------------------------------"
        Write-Host "Package-publishing Application Creation"
        Write-Host "                  AppName: " -NoNewline
        Write-Host                             $AppName -ForegroundColor Yellow
        Write-Host "-----------------------------------------------------------------------------"
        Write-Host "This will create an Entra registered app." -ForegroundColor Yellow
        Write-Host "In order to publish IntuneApp packages, a registered app will be created in the Entra registered App list."
        Write-Host "This registered app will have delegated permission (vs application permission)."
        Write-host ""
        Write-host "A note about security:"
        Write-Host "Apps with delegated permission are safer, because they require a user to logon, and can only do things that the user can already do."
        Write-Host "(as opposed to application permission, which allows the app to operate independently from users.)"
        Write-Host ""
        Write-Host "What this means:"
        Write-Host "When IntuneApps are published, this package-publishing app will prompt the user to logon, and verify they have required access before proceeding with publication."
        Write-Host "-----------------------------------------------------------------------------"
        Write-Host "To see existing registered Apps: Entra Admin > Apps > App Registrations > All apps"
        Write-Host "                                 https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM" -ForegroundColor Green
        Write-Host "-----------------------------------------------------------------------------"
        $OrgDomain = Read-Host "Enter Org domain to connect to as admin (eg mydomain.com, blank to cancel)"
        if ($OrgDomain -eq "") {
            Write-Host "Canceled" -ForegroundColor Yellow;Start-Sleep 2;Continue}
        #region modules
        $checkver=$true
        $modules=@()
        #$modules+="IntuneWin32App"
        $modules+="Microsoft.Graph.Identity.SignIns"
        $modules+="Microsoft.Graph.Identity.DirectoryManagement"
        $modules+="Microsoft.Graph.Users"
        $modules+="Microsoft.Graph.Authentication"
        $modules+="Microsoft.Graph.Applications"
        ForEach ($module in $modules)
        { 
            Write-Host "Loadmodule $($module)..." -NoNewline ; $lm_result=LoadModule $module -checkver $checkver; Write-Host $lm_result
            if ($lm_result.startswith("ERR")) {
                Write-Host "ERR: Load-Module $($module) failed. Suggestion: Open PowerShell $($PSVersionTable.PSVersion.Major) as admin and run: Install-Module $($module)";Start-sleep  3; Return $false
            }
        }
        #endregion modules
        #region: Create the app in the org
        Write-Host "Modules loaded." -ForegroundColor Green
        $OrgAppPublisherClientID = CreatePublishingApp $OrgDomain $AppName
        if ($OrgAppPublisherClientID.StartsWith("ERR"))
        { # auto didn't work
            If (-not(AskForChoice "Org connection didn't work out. Would you like directions to add the app manually?"))
            {
                Write-Host "Canceled" -ForegroundColor Yellow;Start-Sleep 2;Continue
            }
            else
            { # Manual
                Write-Host "---------------------------------"
                Write-Host "Manual steps for: " -NoNewline
                Write-Host $OrgDomain -ForegroundColor Yellow
                Write-Host "---------------------------------"
                Write-Host ""
                Write-Host "Open Entra Applications (as Org admin)"
                Write-Host " Entra Admin > Applications > App registrations > All applications"
                Write-Host " https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM" -ForegroundColor Green
                Write-Host ""
                Write-Host "New registration"
                Write-Host " Name: " -nonewline
                Write-host $AppName -ForegroundColor Yellow
                Write-Host " Redirect Uri / public client/native: https://login.microsoftonline.com/common/oauth2/nativeclient"
                Write-Host " Click Register"
                Write-Host ""
                Write-Host "API permisssions (Repeat search and tick box to accumulate all selections at once, then click Grant admin consent)"
                Write-Host " API permisssions > Add a permission > Microsoft graph > Delegated permissions,"
                Write-Host "  DeviceManagementManagedDevices.ReadWrite.All"
                Write-Host "  DeviceManagementApps.ReadWrite.All"
                Write-Host "  Group.Read.All"
                Write-Host " Click Grant admin consent"
                Write-Host ""
                Write-Host "App ID"
                Write-Host " Click Overview > Application (client) ID > Copy ID"
                Write-Host "---------------------------------"
                $OrgAppPublisherClientID = Read-Host "Paste Application (client) ID (from final step above, blank to cancel)"
                if ($OrgAppPublisherClientID -eq ""){
                    Write-Host "Canceled" -ForegroundColor Yellow;Start-Sleep 2;Continue}
            } # manual
        } # auto didn't work
        #endregion: Create the app in the org
        # At this point we have a valid OrgAppPublisherClientID either automatically or manually
        $rows_existing = @($orglist | Where-Object Org -eq $OrgDomain)
        if ($rows_existing.count -ne 0)
        { # Update existing row(s)
            foreach ($row_existing in $rows_existing)
            { # each row
                $row_existing.AppPublisherClientID = $OrgAppPublisherClientID
            } # each row
        } # Update existing row(s)
        else
        { # create a new row
            $newrow=[pscustomobject][ordered]@{
                Org                    = $OrgDomain
                Packages               = "0"
                "Last Publish Count"   = ""
                "Last Publish Date"    = ""
                PublishToGroupIncluded = "IntuneApp Windows Users"
                PublishToGroupExcluded = "IntuneApp Windows Users Excluded"
                AppPublisherClientID = $OrgAppPublisherClientID
            }
            #$newrow = $orglist[-1].PSObject.Copy() # copy the last added row?
            $orglist += $newRow
        } # create a new row
        # Save
        $orglist | Export-Csv $orglistcsv -NoTypeInformation
        Write-host "New org added: " -NoNewline
        Write-Host $OrgDomain -ForegroundColor Yellow
        PressEnterToContinue
    } # Menu Choice: Org Create
    ElseIf ($action -eq 4)
    { # Menu Choice: Modules
        $ps1file = "$($scriptDir)\ModuleManager.ps1"
        if (-not (Test-Path $ps1file -PathType Leaf))
        { # not found
            Write-Host "Aborted, Not found: $($ps1file)" -ForegroundColor Red
        }
        Else
        {
            & $($ps1file)
        }
        Start-Sleep 1
    } # Menu Choice: Modules
    ##### done with menu actions
    if ($bShowmenu) {
        Start-Sleep 1
    }
} # show menu
Until (-not $bShowmenu)
#region Transcript Save
Stop-Transcript | Out-Null
$logdir  = New-Item -ItemType Directory -Force -Path "$(Split-Path $scriptDir -Parent)\!IntuneApp_Logs"
if ($logdir)
{ # found logdir
    $TranscriptTarget = "$($logdir.Fullname)\$($scriptBase)_$(Get-Date -format "yyyy-MM-dd HH-mm-ss")_transcript.txt"
    Move-Item $Transcript $TranscriptTarget -Force
}
else
{ Write-Host "ERR: Couldn't find / create logdir: $($logdir)";Pause}
#endregion Transcript Save
Write-Host "Done (exiting in 1s)"
Start-Sleep 1
Exit
