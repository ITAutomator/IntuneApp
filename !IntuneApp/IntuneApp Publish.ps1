#######################################
# IntuneApp Publish.ps1
# Use this to publish Win32 apps to Intune
# 
# Prequisites (From a user-based command prompt)
#
# Powershell 7
# winget install --id Microsoft.Powershell --source winget
#
# Modules (From a user-based pwsh.exe prompt)
# Install-Module Microsoft.Graph
# Install-Module IntuneWin32App
#
# VSCode (Optional)
# winget install --id Microsoft.VisualStudioCode --source winget
#
#######################################
#region: Functions
Function MgGroupCreate ($groupname)
{
    #MgGroupCreate - Creates a group in Azure/Entra (if necessary)
    #Usage: $strReturn,$group=MgGroupCreate "TestGroup"
    $strReturn = ""
    $MgGroup = @()
    $MgGroup += Get-MgGroup -All | Where-Object {$_.DisplayName -eq $groupname}
    If ($MgGroup)
    {
        $strReturn= "OK: found group id $($MgGroup[-1].Id)"
    } # group already exists
    Else
    {
        $groupname_mail = $groupname.Replace(" ","_")
        $groupname_mail = $groupname_mail.Replace("(","_")
        $groupname_mail = $groupname_mail.Replace(")","_")
        Write-Host "New-MgGroup -DisplayName $($groupname) ... " -NoNewline
        $MgGroup = New-MgGroup -DisplayName $groupname -SecurityEnabled:$true -MailEnabled:$False -MailNickName $groupname_mail -ErrorAction Ignore
        # wait for group creation
        $try_count = 20
        $try_ok = $false
        do {
            $try_count --
            $MgGroup = @()
            $MgGroup += Get-MgGroup -All | Where-Object {$_.DisplayName -eq $groupname}
            If ($MgGroup) {
                $try_ok = $true
            } else {
                Write-Host "trying again [$($try_count)] .. " -NoNewline
                Start-Sleep -Seconds 2
            }
        } # try again
        until ($try_count -le 0 -or $try_ok)
        if ($try_ok) {
            Write-Host "OK"
            $strReturn= "OK: created group $($MgGroup[-1].Id)"
        } else {
            Write-Host "ERR: couldn't find group after creation"
            $strReturn= "ERR: couldn't create group $($groupname)"
        }
    } # group doesn't already exist
    Return $strReturn,$MgGroup[-1]
}
Function Get-TokenDetailsFromHeader
{ # Get-TokenDetailsFromHeader
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
} # Get-TokenDetailsFromHeader
Function InitializeOrgList ($orglistcsv)
{ # InitializeOrgList
    # Creates an empty OrgList
    if (-not (Test-Path ($orglistcsv)))
    {
        ######### Template
        '"Org","Packages","Last Publish Count","Last Publish Date","PublishToGroupIncluded","PublishToGroupExcluded","AppPublisherClientID"' | Add-Content $orglistcsv
    }
} # InitializeOrgList
Function CreatePublishingApp ($OrgDomain, $AppName)
{ # CreatePublishingApp
    # Connects to an org and creates the required Registered App to publish Windows Apps
    $sResult = ""
    $connected = $false
    Do
    { #Loop until connected
        Try
        {
            # Roles for Entra registered app management
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
    $ResourceRoles += "Group.ReadWrite.All"                               # read group properties and memberships
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
Function CreatePublishingAppWithClientSecret ($OrgDomain, $AppName)
{ # CreatePublishingAppWithClientSecret
    # Connects to an org and creates a Registered App using Application permissions + Client Secret
    # for non-interactive (unattended) authentication. Returns a hashtable with ClientID and ClientSecret.
    $sResult = @{ ClientID = "ERR"; ClientSecret = "ERR" }
    $connected = $false
    Do
    { #Loop until connected
        Try
        {
            # Roles for Entra registered app management
            $scopes = @()
            $scopes += "Domain.Read.All"                        # Read domain properties
            $scopes += "Application.ReadWrite.All"              # Create/update app registrations
            $scopes += "AppRoleAssignment.ReadWrite.All"        # Grant app role assignments (admin consent)
            $scopes += "RoleManagement.ReadWrite.Directory"     # Role management
            $retval = ""
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
                    Connect-MgGraph -Scopes $scopes -TenantId $OrgDomain -ErrorAction Stop | Out-Null
                }
            } # already connected
            else
            {
                Write-Host "Connecting ... There may be a popup logon window in the background"
                Connect-MgGraph -Scopes $scopes -TenantId $OrgDomain -ErrorAction Stop | Out-Null
            }
            $connected = $true
        }
        Catch
        {
            $retval = "ERR: Connect-MgGraph returned $($_.ToString())"
            Write-Host $retval
        }
        if ($connected)
        { # connected
            $retval = "OK"
            $context = Get-MgContext
            if ($null -eq $context.TenantId)
            {
                $connected = $false
            }
            if ($connected)
            { # connected with context
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
                    Write-Host "Couldn't find domain [$($OrgDomain)] in orgdomains[$($orgdomains -join ",")]"
                    $connected = $false
                    Pause
                    Disconnect-MgGraph -ErrorAction Ignore | Out-Null
                }
            } # connected with context
        } # connected
        If (-not $connected)
        { # not connected
            Write-Host "Not Connected (Showing connection options again...)"
        } # not connected
    } #Loop until connected
    Until ($connected)
    $context = Get-MgContext
    $tenantid = $context.TenantId
    Write-Host "Connected via account: " -NoNewline
    Write-Host $context.Account $tenantid -ForegroundColor Yellow
    # Check for existing application with same name
    $appidstoremove = $null
    $orgapps = @(Get-MgApplication)
    $orgapp = $orgapps | Where-Object DisplayName -EQ $AppName
    If ($orgapp)
    { # App with same name found
        Write-Host "Warning: Existing app was found in tenant:" -NoNewline
        Write-Host $AppName -ForegroundColor Yellow
        if ((AskForChoice -message "Replace existing app: $($AppName)" -ChooseDefault:$AutoCreate) -eq 0)
        { # user didn't want to replace
            $retval = "ERR: Existing app found, user chose not to replace: $($AppName)"
            Write-Verbose $retval
            Return $retval
        } # user didn't want to replace
        $appidstoremove = @($orgapp.id)
    } # App with same name found
    #region CreateApp
    # Build Application permission (Role type) objects - these work with client credential flow
    $ReqResAccess = New-Object -TypeName System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]
    $ResourceName = "Microsoft Graph"
    $ReqResAppIDAccesses = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
    $ResourceApp = Get-MgServicePrincipal -Filter "DisplayName eq '$($ResourceName)'"
    $ReqResAppIDAccesses.ResourceAppId = $ResourceApp.AppId
    # Roles for Intune App management
    $ResourceRoles = @()
    $ResourceRoles += "DeviceManagementManagedDevices.ReadWrite.All" # devices managed by Microsoft Intune
    $ResourceRoles += "DeviceManagementApps.ReadWrite.All"           # group assignments and status of apps
    $ResourceRoles += "Group.ReadWrite.All"                          # group properties and memberships
    $ResourceRoles += "User.Read.All"                                # user properties
    $ResourceRoles += "Domain.Read.All"                              # domain properties
    Foreach ($Role in $ResourceRoles)
    { # each resourcerole
        $sp_property = "AppRoles"  # Application permissions use AppRoles (not Oauth2PermissionScopes)
        $ra_type = "Role"          # Application permissions use Role (not Scope)
        $ResourceAppRole = Get-MgServicePrincipal -Filter "DisplayName eq '$($ResourceName)'" -Property $sp_property | Select-Object -ExpandProperty $sp_property | Where-Object Value -EQ $Role
        $ReqResAppIDAccesses.ResourceAccess += @{ Id = $ResourceAppRole.id; Type = $ra_type }
        Write-Host "Staging access to resource: " -NoNewline
        Write-Host $ResourceApp.DisplayName -ForegroundColor Yellow -NoNewline
        Write-Host " with role: " -NoNewline
        Write-Host $ResourceAppRole.Value -ForegroundColor Yellow
    } # each resourcerole
    $ReqResAccess.Add($ReqResAppIDAccesses)
    # No RedirectUri or PublicClient needed for client credentials flow
    $params = @{
        DisplayName            = $AppName
        SignInAudience         = "AzureADMyOrg"
        RequiredResourceAccess = $ReqResAccess
        AdditionalProperties   = @{}
    }
    try
    {
        ########### CREATE APP
        $appRegistration = New-MgApplication @params
    }
    catch
    {
        $_
        Pause
    }
    #endregion CreateApp
    #region AddClientSecret
    # Azure generates the secret value; it is only readable once at creation time
    $passwordCredential = @{
        DisplayName = "AutoGenerated-$(Get-Date -Format 'yyyyMMdd')"
        EndDateTime = (Get-Date).AddYears(1)
    }
    try
    {
        $secretResult = Add-MgApplicationPassword -ApplicationId $appRegistration.Id -PasswordCredential $passwordCredential
    }
    catch
    {
        $_
        Pause
    }
    #endregion AddClientSecret
    #region GrantApp
    # Create service principal for the new app, then grant each application role (admin consent)
    New-MgServicePrincipal -AppId $appRegistration.AppId | Out-Null
    $AppClient = Get-MgServicePrincipal -Filter "appId eq '$($appRegistration.AppId)'"
    $rras = $appRegistration.RequiredResourceAccess
    foreach ($rra in $rras)
    { # each api (Microsoft Graph)
        $resource = Get-MgServicePrincipal -Filter "appId eq '$($rra.resourceAppId)'"
        $requiredRoleIds = $rra.resourceAccess | Where-Object { $_.Type -eq "Role" } | ForEach-Object { $_.id }
        foreach ($requiredRoleId in $requiredRoleIds)
        {
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $AppClient.Id -PrincipalId $AppClient.Id -ResourceId $resource.Id -AppRoleId $requiredRoleId | Out-Null
        }
    } # each api
    #endregion GrantApp
    # Remove old app if it was replaced
    if ($appidstoremove)
    {
        ForEach ($appidtoremove in $appidstoremove)
        {
            Remove-MgApplication -ApplicationId $appidtoremove
        }
    }
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Package-publishing Application (Client Secret) setup complete"
    Write-Host "                  AppName: " -NoNewline
    Write-Host                             $AppName -ForegroundColor Yellow
    Write-Host "         AppId (ClientID): " -NoNewline
    Write-Host                             $appRegistration.AppId -ForegroundColor Yellow
    Write-Host "             ClientSecret: " -NoNewline
    Write-Host                             $secretResult.SecretText -ForegroundColor Yellow
    Write-Host "      Secret Expires On : " -NoNewline
    Write-Host                             $secretResult.EndDateTime -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "WARNING: Save the ClientSecret now - it cannot be retrieved again!" -ForegroundColor Red
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Find it here: Entra Admin > Apps > App Registrations > All apps"
    Write-Host "              https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM" -ForegroundColor Green
    Start-Sleep 3
    $sResult = @{
        ClientID     = $appRegistration.AppId
        ClientSecret = $secretResult.SecretText
    }
    Return $sResult
} # CreatePublishingAppWithClientSecret
Function CreatePublishTemplatePs1Files ($rootpath)
{ # CreatePublishTemplatePs1Files
    # Copies the template lines into the 4 ps1files
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
    $ps1source = Get-Content $ps1template -Encoding UTF8
    ForEach ($ps1file in $ps1files)
    { # replace each ps1file
        $ps1targetfile = "$($ps1path)\$($ps1file)"
        if (Test-Path $ps1targetfile -PathType Leaf) {
            $ps1target = Get-Content $ps1targetfile -Encoding UTF8
        } 
        Else{ # target doesn't exist
            $ps1target = $null
        }
        if (($null -eq $ps1target) -or (ContentsHaveChanged $ps1source $ps1target))
        { # target doesn't exist or is different
            $utf8Encoding = [System.Text.UTF8Encoding]::new($true) # with BOM
            [System.IO.File]::WriteAllLines($ps1targetfile,$ps1source,$utf8Encoding) # writes UTF8 file
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
} # CreatePublishTemplatePs1Files
Function UpdatePS1File ($ps1template, $ps1file, $pkgobj, $injection_site, $injection_file, $fnvalues)
{ # UpdatePS1File
    # Splices in the template lines (from the ps1template .ps1 file) into the ps1file
    # Also updates the appvalues in the ps1file from the csv file
    $return="OK"
    $ps1source = Get-Content $ps1template -Encoding UTF8 # template file
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
                $inject_lines = Get-Content $injection_file -Encoding UTF8
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
        $ps1target = Get-Content $ps1file -Encoding UTF8  # package file (old)
    } 
    Else{ # target doesn't exist
        $ps1target = $null
    }
    # write file if needed
    if (($null -eq $ps1target) -or (ContentsHaveChanged $ps1target_new $ps1target))
    { # target doesn't exist of is different
        $filebase = Split-Path $ps1file -Leaf
        if ($filebase -in ("intune_detection.ps1","intune_requirements.ps1")) {
            $encoding = "UTF8"
            $utf8Encoding = [System.Text.UTF8Encoding]::new($false) # with no BOM
        }
        else { # "intune_install.ps1","intune_uninstall.ps1",
            $encoding = "UTF8NoBOM"
            $utf8Encoding = [System.Text.UTF8Encoding]::new($true) # with BOM
        }
        [System.IO.File]::WriteAllLines($ps1file,$ps1target_new,$utf8Encoding) # writes UTF8 file
        $return ="Updated [$($encoding)]. Intune vars found: $($lineswithvars)"
    }
    else
    { # template ok,no change
        $return ="OK. No change"
    }
    Return $return
} # UpdatePS1File
Function Ps1FileCheckUpdate ($ps1template, $file_checks, $pkgobj)
{ # Ps1FileCheckUpdate
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
} # Ps1FileCheckUpdate
Function AppVersionIncrementInCSV ($intune_settings_csvpath)
{ # AppVersionIncrementInCSV
    # for exporting to CSV.  Example: Export-Csv -Path $csvFile -NoTypeInformation -Force -Encoding $utf8Encoding
    $utf8Encoding = if ($PSVersionTable.PSEdition -eq 'Core') { 'utf8BOM' } else { 'utf8' } # UTF8-with-BOM string based on PowerShell Edition
    $IntuneAppValues_csv = Import-Csv $intune_settings_csvpath
    $versionstr_old = ($IntuneAppValues_csv | Where-Object Name -EQ AppVersion).Value
    if ($versionstr_old-eq "")
        {$versionstr_old= "100"} # Default to 100 if none provided
    # read existing version and increment
    [string]$versionstr_new = [int]$versionstr_old + 1
    # Update CSV file
    ($IntuneAppValues_csv | Where-Object Name -EQ AppVersion).Value = $versionstr_new
    $IntuneAppValues_csv | Export-Csv $intune_settings_csvpath -NoTypeInformation -Encoding $utf8Encoding
    Return $versionstr_new
} # AppVersionIncrementInCSV
Function PackagesLocalChecks($search_root="C:\Users\Public\Documents\IntuneApps", $GetHash = $true)
{ # PackagesLocalChecks
    $LogFolder = "C:\IntuneApp"
    #region Search for packages (files named intune_settings.csv)
    If (-not (Test-Path $search_root -PathType Container)) {Return "search_root not found: $($search_root)"}
    $package_files= Get-ChildItem -Path $search_root -File -Recurse -Filter "intune_settings.csv"
    $package_paths = @()
    ForEach ($package_file in $package_files)
    { # each csv file
        #$package_path=$package_file.FullName
        $package_foldername = Split-Path (Split-path (Split-Path $package_file.FullName -Parent) -Parent) -Leaf
        if (-not ($package_foldername).StartsWith("!"))
        { # not a disabled package (grandparent folder has a ! in front)
            #$package_path = $package_file.FullName.Replace("$($search_root)\","")
            #$package_paths += $package_path

            $objThis = [pscustomobject][ordered]@{
                RelPath        = $package_file.FullName.Replace("$($search_root)\","")
                FolderName     = $package_foldername
                IntuneSettingsCSVDate   = $package_file.LastWriteTime.ToString("yyyy-MM-dd")
                }
            $package_paths += $objThis

        } # not a disabled package
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
    $bCheckAllPackages = $true
    if ($i_count -ge 10)
    { # more than 10 packages
        Write-Host "Found $($i_count) packages to check"
        # consider all packages or a subset
        if (-not (AskForChoice "Check all packages? [No to select packages (faster)]")){
            $bCheckAllPackages = $false
            Write-Host "Choose apps from the popup list (may be behind this window - check taskbar): " -NoNewline
            $msg= "Select rows and click OK (Use Ctrl and Shift and Filter features to multi-select)"
            # Select
            $package_paths =  @($package_paths | Out-GridView -PassThru -Title $msg) 
            $i_count = $package_paths.count
            Write-Host "Selected packages to check: " -NoNewline
            Write-host $i_count -ForegroundColor Yellow
        } # select packages
    } # more than 10 packages
    Write-Progress -Activity "Checking Packages" -Status "Starting" -PercentComplete 0
    ForEach ($pkg in $package_paths.RelPath)
    { # Each pkg (csv) file
        $i+=1
        $PercentComplete = (($i / $i_count) * 100)
        $Status = "Checking $($i) of $($i_count) : $(($pkg -split "\\")[0])"
        Write-Progress -Activity "Checking Packages" -Status $Status -PercentComplete $PercentComplete
        $IntuneAppFolder = Split-Path "$($search_root)\$($pkg)" -Parent
        #check required files
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
        if ($sResultps1.StartsWith("ERR")) {Return $sResultps1, $null}
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
                    $choice = (AskForChoice "Update hash value for this app?" -choices "&No","&Yes","Yes to &all" -DefaultChoice 2)
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
    Return $sResult,$bCheckAllPackages,$pkgobjs
} # PackagesLocalChecks
Function PackagesLocalUpdateandCheck ($GetHash = $true)
{ # PackagesLocalUpdateandCheck
        #region update !App Template\IntuneApp\IntuneUtils
        # $root  = Split-Path -Path $scriptdir -Parent
        $root  = $scriptdir
        $ps1template = "$($root)\AppsPublish_Template.ps1"
        If (-not (Test-Path $ps1template)) {write-host "Err: Couldn't find $($ps1template)";return}
        # Update the 4 key ps1 files in !App Template\IntuneApp\IntuneUtils
        Write-Host "Checking / updating the 4 key template ps1 files... " -NoNewline
        $sReturn = CreatePublishTemplatePs1Files -rootpath $root
        if ($sReturn -eq "OK: no template files updated") {Write-Host $sReturn}
        else {Write-Host $sReturn;Write-host "Note: Template files were changed. This updates all packages, and hashes will be updated too." -ForegroundColor Yellow;PressEnterToContinue}
        if (-not $sReturn.Startswith("OK")) {Write-host $sReturn -ForegroundColor Yellow ;return}
        #endregion update !App Template\IntuneApp\IntuneUtils
        #region package hashes
        Write-Host "Checking / updating package files (takes a few secs)... " -NoNewline
        $search_root  = Split-Path -Path $root -Parent
        $sReturn,$bCheckAllPackages,$pkgs = PackagesLocalChecks $search_root -GetHash $GetHash
        Write-Host $sReturn
        if (-not $sReturn.StartsWith("OK")) {Write-host $sReturn -ForegroundColor Yellow; PressEnterToContinue ;return}
        #endregion package hashes
        Return $bCheckAllPackages,$pkgs
} # PackagesLocalUpdateandCheck
Function Get-MgCommandRoles
{ # Get-MgCommandRoles
    # Returns the Microsoft Graph API permissions (roles) required to run a specified Microsoft Graph PowerShell command or set of commands, based on the permissions defined in the Microsoft Graph PowerShell SDK metadata. 
    # You can specify whether you want application permissions or delegated permissions, and whether you want to return all permissions or just the least privileged permissions for each command.
    Param (
        [string[]]$MgCommands = @("Get-MgContext")
        ,[string]$PermissionType = "Application" # or "DelegatedWork"
        ,[string]$PrivLeastOrPrivAll = "PrivLeast" # or "PrivAll" PrivLeast only picks the 1st entry (Include ".Raad" might be better)
        ,[string]$PrivInclude = "" # "" for include all or ".Read." for just strings with 
        ,[string]$PrivExclude = "" # "" for exclude none or ".Admin." for example to exclude admin roles
    )
    $RolesAll = @()
    ForEach ($MgCommand in $MgCommands)
    { # Each CommandName
        #Write-Host "Roles for $MgCommand ($PermissionType permissions) ($($PrivLeastOrPrivAll)):"
        $MgCommandRoles = Find-MgGraphCommand -Command $MgCommand | 
            Select-Object -ExpandProperty Permissions | 
            Select-Object Name, IsAdmin, PermissionType | 
            Sort-Object PermissionType, Name | 
            Select-Object -Unique * | 
            Where-Object PermissionType -eq $PermissionType
        ForEach ($MgCommandRole in $MgCommandRoles) {
            #Write-Host "- $($MgCommandRole.Name) (Admin consent required: $($MgCommandRole.IsAdmin))"
            $RolesAll += $MgCommandRole
            If ($PrivLeastOrPrivAll -eq "PrivLeast") {break}
        }
    } # Each CommandName
    # Apply unique
    $RolesAll = $RolesAll | Sort-Object PermissionType, Name | Select-Object -Unique * 
    # Apply include and exclude filters
    If ($PrivInclude) {
        $RolesAll = $RolesAll | Where-Object { $_.Name -like "*$PrivInclude*" }
    }
    If ($PrivExclude) {
        $RolesAll = $RolesAll | Where-Object { $_.Name -notlike "*$PrivExclude*" }
    }
    return $RolesAll
} # Get-MgCommandRoles
Function ConnectMgGraph
{ # ConnectMgGraph
    # If already connected to Microsoft Graph, will detect existing connection and offer to reuse it or disconnect and reconnect
    # If AdminAppID is specified, will attempt to connect using the app registration / certificate credentials rather than interactive user login
    Param (
        [string[]]$mgScopes = @()
        ,[string]$TenantID = "contoso.com"
        ,[string]$SystemOrUser = "User"
        ,[string]$AdminAppID = ""
        ,[string]$AdminAppCertThumbprint = ""
        ,[string]$AdminAppCertFriendlyName = ""
    )
    $ReturnObj = [PSCustomObject]@{
        ConnectOK      = $false
        Message        = ""
        TenantID       = ""
        Account        = ""
        AdminAppID     = ""
        AdminAppCertThumbprint = ""
        AdminAppCertFriendlyName = ""
    }
    If (-not (Get-Command -Name Connect-MgGraph -ErrorAction SilentlyContinue)) {
        Write-Host "Connect-MgGraph is NOT available. You may need to install the Microsoft Graph module:"
        Write-Host 'Install-Module Microsoft.Graph -Scope CurrentUser'
        PressEnterToContinue
        $ReturnObj.Message = "Connect-MgGraph is NOT available. Install-Module Microsoft.Graph -Scope CurrentUser"
        $ReturnObj.ConnectOK = $false
        Return $ReturnObj
    }
    Write-Host "Connect-MgGraph is being requested with these paramenters"
    Write-Host "        Tenant: " -NoNewline
    Write-Host          $TenantID -ForegroundColor Cyan
    Write-Host "        Scopes: " -NoNewline
    Write-Host          ($mgScopes -join ", ") -ForegroundColor Cyan
    Write-Host "  AdminAppCert: " -NoNewline
    Write-Host          "AdminAppID=$($AdminAppID), AdminAppCertFriendlyName=$($AdminAppCertFriendlyName), AdminAppID=$($AdminAppCertThumbprint)" -ForegroundColor Cyan
    # Check If we are already connected
    Do {
        # Check If already connected to Microsoft Graph
        $mgContext = Get-MgContext
        If ($mgContext -and $mgContext.TenantId)
        { # has connection info
            If ($mgContext.CertificateThumbprint) {
                Write-Host "Connect-MgGraph is connected via cert thumbprint $(CropString $mgContext.CertificateThumbprint 8)... Tenant Domain: " -NoNewline
            }
            elseif ($mgContext.Account) {
                Write-Host "Connect-MgGraph is connected via Account $($mgContext.Account) Tenant Domain: " -NoNewline
            }
            # domain info
            #$tenantDomain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
            #Write-Host "Now connected to Microsoft Graph. " -NoNewline 
            Try {
                $tenantDomain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
                Write-Host "Connected to tenant Domain: $tenantDomain" -ForegroundColor Green
            }
            Catch {
                Write-Host "Connected to tenant Account: $mgContext.Account" -ForegroundColor Green
            }
            Write-Host $tenantDomain -ForegroundColor Green
            $response = AskForChoice "Choice: " -Choices @("&Use this connection","&Disconnect and try again","E&xit") -ReturnString
            # If the user types 'exit', break out of the loop
            If ($response -eq 'Disconnect and try again') {
                Write-Host "Disconnect-MgGraph..."
                Disconnect-MgGraph | Out-Null
                PressEnterToContinue "Done. Press <Enter> to connect again"
            }
            elseif ($response -eq 'exit') {
                $ReturnObj.Message = "User chose not to connect"
                $ReturnObj.ConnectOK = $false
                Break
            }
            Else { # Use this connection
                $ReturnObj.Message = "User selected existing connection"
                $ReturnObj.ConnectOK = $true
                $ReturnObj.Account = $mgContext.Account
                $ReturnObj.TenantID = $mgContext.TenantId
                $ReturnObj.AdminAppID               = $AdminAppID
                $ReturnObj.AdminAppCertFriendlyName = $AdminAppCertFriendlyName
                $ReturnObj.AdminAppCertThumbprint   = $AdminAppCertThumbprint
            } # Use this connection
        } # has connection info
        Else
        { # no connection 
            Write-Host "Connect-MgGraph not connected to: " -NoNewLine ; Write-Host $TenantId -ForegroundColor Yellow
            If ($AdminAppID -and $AdminAppCertThumbprint)
            { # AdminAppID provided, try to connect with it
                Write-Host "Trying to connect with AdminAppID: Connect-MgGraph -TenantId $TenantId -ClientId  " -NoNewLine
                Write-Host (CropString $AdminAppID 8) -ForegroundColor Yellow -NoNewline
                Write-Host " -CertificateThumbprint  " -NoNewLine
                Write-Host (CropString $AdminAppCertThumbprint 8) -ForegroundColor Yellow
                Try {
                    Connect-MgGraph -TenantId $TenantId -ClientId $AdminAppID -CertificateThumbprint $AdminAppCertThumbprint -NoWelcome -ErrorAction Stop
                    $ReturnObj.Message = "Connected with AdminAppID"
                    $ReturnObj.ConnectOK = $true
                    $ReturnObj.AdminAppID               = $AdminAppID
                    $ReturnObj.AdminAppCertFriendlyName = $AdminAppCertFriendlyName
                    $ReturnObj.AdminAppCertThumbprint   = $AdminAppCertThumbprint
                }
                catch {
                    Write-Host "Error connecting to Microsoft Graph with AdminAppID" -ForegroundColor Yellow
                    Write-Host "AdminAppID: $AdminAppID" 
                    Write-Host "Error details: $_" -ForegroundColor Red
                    PressEnterToContinue "Press Enter to continue"
                }
            } # AdminAppID provided, try it
            If (-not $ReturnObj.ConnectOK)
            { # not connected yet, try cert selection
                $ConnChoice = AskForChoice "How would you like to connect?" -Choices @("&Interactive login", "&Certificate-based login","&Device code login","E&xit") -ReturnString
                If ($ConnChoice -eq "Exit")
                { # chose exit
                    $ReturnObj.Message = "User canceled connection"
                    Return $ReturnObj
                } # chose exit
                elseif ($ConnChoice -eq "Device code login")
                { # device code
                    PressEnterToContinue "Device Code Login. Open an admin browser to this tenant, and use the directions that follow. <Press Enter>"
                    Write-Host Connect-MgGraph -TenantId $TenantId -Scopes $mgScopes -NoWelcome -UseDeviceCode -ErrorAction Stop
                    Connect-MgGraph -TenantId $TenantId -Scopes $mgScopes -UseDeviceCode | Out-Host
                    Try {
                        $ReturnObj.Message = "User entered creds"
                        $ReturnObj.ConnectOK = $true
                    }
                    catch {
                        Write-Host "Error connecting to Microsoft Graph with scopes" -ForegroundColor Yellow
                        Write-Host "Scopes: $($mgScopes -join ", ")" 
                        Write-Host "Error details: $_" -ForegroundColor Red
                    }
                    If (-not $ReturnObj.ConnectOK) {
                        If (AskForChoice "Failed to connect. Try Again?") {
                            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
                        } # said yes
                        Else {
                            $ReturnObj.ConnectOK = $false
                            $ReturnObj.Message = "User gave up trying to connect."
                            Return $ReturnObj
                        } # said no
                    } # connect failed
                } # device code
                elseif ($ConnChoice -eq "Certificate-based login")
                { # chose cert based
                    Write-Host "The AdminApp must have the scopes listed above (with Application grants)" -ForegroundColor yellow
                    $certSelectResult = SelectAppCertificate -SystemOrUser $SystemOrUser -DefaultFriendlyName $AdminAppCertFriendlyName
                    If ($certSelectResult.CertOK)
                    { # user selected a cert, try to connect with it
                        Write-host "      CertFriendlyName: " -NoNewline
                        Write-Host $certSelectResult.CertFriendlyName -ForegroundColor Green
                        Write-host "AdminAppCertThumbprint: " -NoNewline
                        Write-Host $certSelectResult.CertThumbprint -ForegroundColor Green
                        $AdminAppID = PromptForString "Enter the Admin App ID to use with the selected certificate (or press Enter to skip)" -defaultValue $AdminAppID
                        If (-not $AdminAppID) {
                            Write-Host "No Admin App ID provided. Skipping certificate-based connection attempt." -ForegroundColor Yellow
                        }
                        Else
                        { # Admin App ID provided
                            Write-Host "Trying to connect with selected certificate: " -NoNewLine
                            Write-Host $certSelectResult.CertFriendlyName -ForegroundColor Yellow
                            Try {
                                Connect-MgGraph -TenantId $TenantId -ClientId $AdminAppID -CertificateThumbprint $certSelectResult.CertThumbprint -NoWelcome -ErrorAction Stop
                                $ReturnObj.Message = "Connected with selected certificate"
                                $ReturnObj.ConnectOK = $true
                                $ReturnObj.AdminAppID = $AdminAppID
                                $ReturnObj.AdminAppCertFriendlyName = $certSelectResult.CertFriendlyName
                                $ReturnObj.AdminAppCertThumbprint = $certSelectResult.CertThumbprint
                            }
                            catch {
                                Write-Host "Error connecting to Microsoft Graph with selected certificate" -ForegroundColor Yellow
                                Write-Host "Certificate Friendly Name: $($certSelectResult.CertFriendlyName)" 
                                Write-Host "Certificate Thumbprint: $(CropString $certSelectResult.CertThumbprint 8)..." 
                                Write-Host "Error details: $_" -ForegroundColor Red
                                PressEnterToContinue "Press Enter to continue"
                            }
                        } # Admin App ID provided
                    } # user selected a cert, try to connect with it
                } # chose cert based
                Else
                { # chose interactive
                    PressEnterToContinue "Next use an Admin logon (might be in a hidden window). <Press Enter>"
                    Write-Host Connect-MgGraph -TenantId $TenantId -Scopes $mgScopes -NoWelcome -ErrorAction Stop
                    Try {
                        Connect-MgGraph -TenantId $TenantId -Scopes $mgScopes -NoWelcome -ErrorAction Stop
                        $ReturnObj.Message = "User entered creds"
                        $ReturnObj.ConnectOK = $true
                    }
                    catch {
                        Write-Host "Error connecting to Microsoft Graph with scopes" -ForegroundColor Yellow
                        Write-Host "Scopes: $($mgScopes -join ", ")" 
                        Write-Host "Error details: $_" -ForegroundColor Red
                    }
                    If (-not $ReturnObj.ConnectOK) {
                        If (AskForChoice "Failed to connect. Try Again?") {
                            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
                        } # said yes
                        Else {
                            $ReturnObj.ConnectOK = $false
                            $ReturnObj.Message = "User gave up trying to connect."
                            Return $ReturnObj
                        } # said no
                    } # connect failed
                } # chose interactive
            } # not connected yet, try cert selection
            # Confirm connection
            $mgContext = Get-MgContext
            If ($mgContext) {
                $mgContext = Get-MgContext
                $ReturnObj.Account = $mgContext.Account
                $ReturnObj.TenantID = $mgContext.TenantId
                Write-Host "Now connected to Microsoft Graph. " -NoNewline 
                Try {
                    $tenantDomain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
                    Write-Host "Tenant Domain: $tenantDomain" -ForegroundColor Green
                }
                Catch {
                    Write-Host "Tenant Account: $mgContext.Account" -ForegroundColor Green
                }
                
            } Else {
                Write-Host "Connect-MgGraph: Failed" -ForegroundColor Yellow
            }
        } # no connection
    } Until ($ReturnObj.ConnectOK) # until connected or break
    Return $ReturnObj
} # ConnectMgGraph
Function RemoveRegisteredApp
{ # RemoveRegisteredApp
    # Connects to an org and removes Registered App
    Param (
        [string]$TenantId ="contoso.com" 
        ,[string]$AppName = "MyCustomApp" 
        ,[string]$SystemOrUser = "User"
        ,[string]$AdminAppID = ""
        ,[string]$AdminAppCertThumbprint = ""
        ,[string]$AdminAppCertFriendlyName = ""
    )
    # Define the Microsoft Graph commands needed for app registration and permission grants
    $CreateAppMgCommands = @()
    $CreateAppMgCommands += "Get-MgContext"
    $CreateAppMgCommands += "Get-MgApplication"
    $CreateAppMgCommands += "Get-MgServicePrincipal"
    $CreateAppMgCommands += "New-MgApplication"
    $CreateAppMgCommands += "New-MgServicePrincipal"
    $CreateAppMgCommands += "New-MgOauth2PermissionGrant"
    $CreateAppMgCommands += "Remove-MgApplication"
    # Get the required roles for the specified Microsoft Graph commands, permission type, and max privilege level
    $MgCommandRoles = Get-MgCommandRoles -MgCommands $CreateAppMgCommands -PermissionType $PermissionType -PrivLeastOrPrivAll "PrivAll" -PrivInclude ".ReadWrite.All"
    $mgScopes = @($MgCommandRoles.Name)
    $returnObj = ConnectMgGraph -TenantID $TenantId -mgScopes $mgScopes -AdminAppID $AdminAppID -AdminAppCertThumbprint $AdminAppCertThumbprint -AdminAppCertFriendlyName $AdminAppCertFriendlyName -SystemOrUser $SystemOrUser
    If (-not $returnObj.ConnectOK) {
        Write-Host $returnObj.Message -ForegroundColor Yellow
        PressEnterToContinue
        Return $null
    }
    # Check for application
    $appidtoremove = $null
    $orgapps = @(Get-MgApplication)
    $orgapp = $orgapps | Where-Object DisplayName -EQ $AppName | Select-Object -First 1
    If ($orgapp)
    {# App with same name found
        Write-Host "   Existing App Found: " -NoNewline
        Write-Host $AppName -ForegroundColor Green
        Write-Host "               App Id: " -NoNewline
        Write-Host $orgapp.AppId -ForegroundColor Yellow
        If (AskForChoice -message "Remove this app [No to leave it]" )
        { # user wants to delete
            Write-Host "About to delete the existing app." -ForegroundColor Yellow
            Write-Host "[Click the green link below to check the app and certs before deleting] " -ForegroundColor Yellow
            Write-Host "  Entra Admin > Apps > App Registrations > "
            Write-Host $AppName -ForegroundColor Yellow
            Write-Host "  https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($orgapp.AppId )/isMSAApp~/false" -ForegroundColor Green
            PressEnterToContinue "Press Enter to continue."
            $appidstoremove = $orgapp.Id
        } # user wants to delete
    }# App with same name found
    If ($appidstoremove)
    { # Old AppId(s) to remove
        ForEach ($appidtoremove in $appidstoremove)
        {
            Remove-MgApplication -ApplicationId $appidtoremove
        }
    }
    Disconnect-MgGraph | Out-Null
    Start-Sleep 3 # pause
} # RemoveRegisteredApp
Function CreateRegisteredApp
{ # CreateRegisteredApp
    # Connects to an org and creates (or returns the existing) Registered App
    Param (
        [string]    $TenantId ="contoso.com" 
        ,[string]   $AppName = "MyCustomApp" 
        ,[string[]] $PermissionNames = @("User.Read.All","Group.Read.All")# @("User.Read.All","Group.Read.All")
        ,[string]   $PermissionType = "Application" # or "DelegatedWork"
        ,[string]   $AdminAppId = "" 
        ,[string]   $AdminAppCertThumbprint = "" 
        ,[string]   $AdminAppCertFriendlyName = ""
        ,[string]   $SystemOrUser = "User"
        ,[bool]     $AlwaysUseExisting = $true
    )
    $ReturnObj = [PSCustomObject]@{
        ConnectOK      = $false
        AppId        = ""
        Message        = ""
        AdminAppID   = ""
        AdminAppCertThumbprint = ""
        AdminAppCertFriendlyName = ""
    }
    # Define the Microsoft Graph commands needed for app registration and permission grants
    $CreateAppMgCommands = @()
    $CreateAppMgCommands += "Get-MgContext"
    $CreateAppMgCommands += "Get-MgDomain"
    $CreateAppMgCommands += "Get-MgApplication"
    $CreateAppMgCommands += "Get-MgServicePrincipal"
    $CreateAppMgCommands += "New-MgApplication"
    $CreateAppMgCommands += "New-MgServicePrincipal"
    $CreateAppMgCommands += "New-MgOauth2PermissionGrant"
    $CreateAppMgCommands += "Remove-MgApplication"
    # Get the required roles for the specified Microsoft Graph commands, permission type, and max privilege level
    $MgCommandRoles = Get-MgCommandRoles -MgCommands $CreateAppMgCommands -PermissionType $PermissionType -PrivLeastOrPrivAll "PrivAll" -PrivInclude ".ReadWrite.All"
    $mgScopes = @($MgCommandRoles.Name)
    $ConnReturnObj = ConnectMgGraph -TenantID $TenantId -mgScopes $mgScopes -AdminAppId $AdminAppId -AdminAppCertThumbprint $AdminAppCertThumbprint -SystemOrUser $SystemOrUser -AdminAppCertFriendlyName $AdminAppCertFriendlyName
    $ReturnObj.AdminAppID             = $ConnReturnObj.AdminAppID
    $ReturnObj.AdminAppCertThumbprint = $ConnReturnObj.AdminAppCertThumbprint
    $ReturnObj.AdminAppCertFriendlyName   = $ConnReturnObj.AdminAppCertFriendlyName
    If (-not $ConnReturnObj.ConnectOK) {
        Write-Host $ConnReturnObj.Message -ForegroundColor Yellow
        PressEnterToContinue
        $ReturnObj.Message = $ConnReturnObj.Message
        Return $ReturnObj
    }
    # Check for application
    $appidtoremove = $null
    $orgapps = @(Get-MgApplication)
    $orgapp = $orgapps | Where-Object DisplayName -EQ $AppName | Select-Object -First 1
    If ($orgapp)
    {# App with same name found
        $ExistingAppOK = $true
        Write-Host "   Existing App Found: " -NoNewline
        Write-Host $AppName -ForegroundColor Green
        Write-Host "               App Id: " -NoNewline
        Write-Host $orgapp.AppId -ForegroundColor Green
        #region: Certs
        $orgappCerts = @((Get-MgApplication -ApplicationId $orgapp.Id).KeyCredentials)
        Write-Host "     Registered Certs: " -NoNewline
        If ($orgappCerts.Count -eq 0) {
            Write-Host "(none)" -ForegroundColor Gray
        } Else {
            Write-Host ""
            $cert_n = 0
            ForEach ($kc in $orgappCerts) {
                $cert_n++
                $thumb = If ($kc.CustomKeyIdentifier) { [System.BitConverter]::ToString($kc.CustomKeyIdentifier).Replace("-","") } Else { "(n/a)" }
                Write-Host "Cert $($cert_n). $(CropString $thumb 8)... exp $($kc.EndDateTime.ToString('yyyy-MM')) | $($kc.DisplayName)"
            }
        }
        #endregion: Certs
        #region: Permissions
        $graphSP = Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'" -Property "AppRoles","Oauth2PermissionScopes","AppId"
        $graphResAccess = $orgapp.RequiredResourceAccess | Where-Object ResourceAppId -EQ $graphSP.AppId
        $existingPermNames = @()
        If ($graphResAccess) {
            $existingPermNames = @($graphResAccess.ResourceAccess | ForEach-Object {
                $id = $_.Id
                (@($graphSP.AppRoles) + @($graphSP.Oauth2PermissionScopes) | Where-Object Id -EQ $id).Value
            } | Where-Object { $_ })
        }
        Write-Host "          Permissions: " -NoNewline
        If ($existingPermNames.Count -gt 0) {
            Write-Host ($existingPermNames -join ", ") -ForegroundColor Green
        } Else {
            Write-Host "(none)" -ForegroundColor Gray
        }
        $missingPerms = @($PermissionNames | Where-Object { $existingPermNames -notcontains $_ })
        If ($missingPerms.Count -gt 0) {
            Write-Host "  Missing Permissions: " -NoNewline
            Write-Host ($missingPerms -join ", ") -ForegroundColor Yellow
            $ExistingAppOK = $false
        }
        #endregion: Permissions
        If (($AlwaysUseExisting -and $ExistingAppOK) -or (AskForChoice -message "Use existing app [No to delete it and replace it]" ))
        { # user didn't want to replace
            $ReturnObj.ConnectOK = $true
            $ReturnObj.Message = "User chose to use existing App"
            $ReturnObj.AppId = $orgapp.AppId
            Return $ReturnObj
        } # user didn't want to replace
        Else
        { # user wants to replace
            Write-Host "About to delete the existing app(s) and create a new one. Any existing certs will be disassociated. " -ForegroundColor Yellow
            Write-Host "[Click the green link below to check the app and certs before deleting] " -ForegroundColor Yellow
            Write-Host "  Entra Admin > Apps > App Registrations > "
            Write-Host $AppName -ForegroundColor Yellow
            Write-Host "  https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($orgapp.AppId )/isMSAApp~/false" -ForegroundColor Green
            $appidstoremove = @($orgapps | Where-Object DisplayName -EQ $AppName | Select-Object)
            if (-not (AskForChoice)) {
                $ReturnObj.ConnectOK = $true
                $ReturnObj.Message = "User chose to keep existing App"
                $ReturnObj.AppId = $orgapp.AppId
                Return $ReturnObj
            }
        } # user wants to replace
    }# App with same name found
    #region CreateApp
    ######## Create API Permission Object $ReqResAccess (https://aad.portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
    $ReqResAccess = New-Object -TypeName System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]
    $ResourceName = "Microsoft Graph"
    $ReqResAppIDAccesses = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
    $ResourceApp = Get-MgServicePrincipal -Filter "DisplayName eq '$($ResourceName)'"
    $ReqResAppIDAccesses.ResourceAppId = $ResourceApp.AppId
    Foreach ($Role in $PermissionNames)
    { # each resourcerole 
        If ($PermissionType -eq "Application")
        { # Application permissions
            $sp_property = "AppRoles"              #sp_property: 'AppRoles' for Application, 'Oauth2PermissionScopes' for Delegated
            $ra_type = "Role"                      #Type       : 'Role' for Application, 'Scope' for Delegated
        } # Application permissions
        Else
        { # Delegated permissions 
            $sp_property = "Oauth2PermissionScopes" #sp_property: 'AppRoles' for Application, 'Oauth2PermissionScopes' for Delegated
            $ra_type = "Scope"                      #Type       : 'Role' for Application, 'Scope' for Delegated
        } # Delegated permissions
        $ResourceAppRole = Get-MgServicePrincipal -Filter "DisplayName eq '$($ResourceName)'" -Property $sp_property | Select-Object -ExpandProperty $sp_property | Where-Object Value -EQ $Role
        $ReqResAppIDAccesses.ResourceAccess+=@{ Id = $ResourceAppRole.id ; Type = $ra_type } 
        Write-Host "Adding API Permission: " -NoNewline
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
        PressEnterToContinue "Error creating app registration. Press Enter to continue."
        $ReturnObj.Message = "Error creating app registration"
        Return $ReturnObj
    }
    #endregion CreateApp
    #region GrantApp
    # Get / Create service principal (svc_princ) for the App (SPs are AD object ids, kind of like user ids, but for apps and resources)
    Write-Host "Getting or creating service principal for the app .. " -NoNewline
    $try_count = 10
    $try_ok = $false
    Do #While (-not $AppClient -and $try_count -gt 0)
    {
        Start-Sleep -Seconds 2
        $try_count--
        $AppClient = Get-MgServicePrincipal -Filter "appId eq '$($appRegistration.AppId)'"
        if (-not $AppClient) {
            try {
                $AppClient = New-MgServicePrincipal -AppId $appRegistration.AppId -ErrorAction Stop
                $try_ok = $true
            }
            catch {
                Write-Host "trying again [$($try_count)] .. " -NoNewline
            }
        } # not found
    } # try again
    until ($try_count -le 0 -or $try_ok)
    if (-not $AppClient) {
        Write-Host "Failed to get or create service principal for the app." -ForegroundColor Yellow
        $ReturnObj.Message = "Failed to get or create service principal for the app"
        Return $ReturnObj
    }
    else {
        Write-Host "OK" -ForegroundColor Green
    }
    # Retrieve the RequiredResourceAccess for the app (the APIs)
    $rras = $appRegistration.RequiredResourceAccess
    # Each requiredResourceAccess identifies an API (the resource app) and a list of required
    # delegated permissions and app roles.
    ForEach ($rra in $rras)
    { # each api (Microsoft Graph)
        $resource = Get-MgServicePrincipal -Filter "appId eq '$($rra.resourceAppId)'"
        If ($resource)
        { # each api permission
            If ($PermissionType -eq "Application")
            { # Application permissions
                $requiredScopeIds = $rra.resourceAccess | Where-Object { $_.Type -eq "Role" } | ForEach-Object { $_.id }
                $finalScopeValues = {@()}.Invoke()  # not really sure what this does - create an empty object?
                ForEach ($requiredScopeId in $requiredScopeIds) {
                    Write-Host "New-MgServicePrincipalAppRoleAssignment AppRoleId " -NoNewline
                    Write-Host $requiredScopeId -foregroundcolor Yellow -NoNewline
                    Write-Host " .. " -NoNewline
                    $try_count = 10
                    $try_ok = $false
                    do {
                        $try_count --
                        try {
                            $x = New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $AppClient.Id -PrincipalId $AppClient.Id -ResourceId $resource.Id -AppRoleId $requiredScopeId -ErrorAction Stop
                            $try_ok = $true
                        }
                        catch {
                            if ($_ -like "*Permission being assigned already exists*") {
                                $try_ok = $true
                                Write-Host "already assigned. " -NoNewline
                            } else {
                                Write-Host "trying again [$($try_count)] .. " -NoNewline
                                Start-Sleep -Seconds 2
                            }
                        }
                    } # try again
                    until ($try_count -le 0 -or $try_ok)
                    if ($try_ok) {
                        Write-Host "OK" -ForegroundColor Green
                    } 
                    else {
                        Write-Host "Failed New-MgServicePrincipalAppRoleAssignment." -ForegroundColor Yellow
                        $ReturnObj.Message = "Failed New-MgServicePrincipalAppRoleAssignment"
                        Return $ReturnObj
                    }
                } # Each requiredScopeId
            } # Application permissions
            Else
            { # Delegated permissions 
                $requiredScopeIds = $rra.resourceAccess | Where-Object { $_.Type -eq "Scope" } | ForEach-Object { $_.id }
                $finalScopeValues = {@()}.Invoke()  # not really sure what this does - create an empty object?
                ForEach ($requiredScopeId in $requiredScopeIds) {
                    $requiredScope = $resource.Oauth2PermissionScopes | Where-Object { $_.Id -eq $requiredScopeId }
                    $finalScopeValues.Add($requiredScope.Value) 
                }
                New-MgOauth2PermissionGrant -ConsentType "AllPrincipals" -ClientId $AppClient.Id -ResourceId $resource.Id -Scope ($finalScopeValues -join " ") | Out-Null
            } # Delegated permissions
        } # each api permission
    } # each api
    #endregion GrantApp
    If ($appidstoremove)
    { # Old AppId(s) to remove
        ForEach ($appidtoremove in $appidstoremove)
        {
            Write-Host "Removing old $($appidtoremove.DisplayName) with AppId: " -NoNewline
            Write-Host $appidtoremove.AppId -ForegroundColor Yellow
            Remove-MgApplication -ApplicationId $appidtoremove.Id
        }
    } # Old AppId(s) to remove
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Package-publishing Application setup complete"
    Write-Host "     AppName: " -NoNewline
    Write-Host                $AppName -ForegroundColor Yellow
    Write-Host "       AppId: " -NoNewline
    Write-Host                $appRegistration.AppId -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Find it here: Entra Admin > Apps > App Registrations > All apps"
    Write-Host "              https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade" -ForegroundColor Green
    Write-Host "    and here: Entra Admin > Apps > App Registrations > $($AppName)"
    Write-Host "              https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($appRegistration.AppId )/isMSAApp~/false" -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------------------"
    Start-Sleep 3 # pause
    $ReturnObj.Message = "App created succesfully"
    $ReturnObj.AppId = $appRegistration.AppId
    $ReturnObj.ConnectOK = $true
    Return $ReturnObj
} # CreateRegisteredApp
Function SelectAppCertificate
{ # SelectAppCertificate
    # Shows certs in the machine and allows selection. Returns the cert object.
    Param (
        [string] $SystemOrUser = "User" # or "System"
        ,[string] $DefaultFriendlyName = ""
    )
    # Return object defined
    $returnObj = [PSCustomObject]@{
        Cert              = "" # Certificate
        CertFriendlyName  = "" 
        CertThumbprint    = "" 
        Message           = ""
        CertOK            = $false
    }
    # CertStoreLocation
    If ($SystemOrUser -eq "System") { # System
        $CertStoreLocation = "Cert:\LocalMachine\My"
    } Else { # User
        $CertStoreLocation = "Cert:\CurrentUser\My"
    } # SytemOrUser
    # System check
    If (($SystemOrUser -eq "System") -and (-not(IsAdmin))){
         $returnObj.Message = "You must run this script as an administrator to access system certificates."
        Return $returnObj
    }
    # Show certs with the friendly name and allow selection, return the selected cert object
    $LocalAppCerts = @(Get-ChildItem $CertStoreLocation -Recurse | Where-Object FriendlyName -ne "" | Sort-Object NotAfter -Descending)
    If ($LocalAppCerts.Count -eq 0) {
        $returnObj.Message = "No certificates found."
        Return $returnObj
    }
    Write-Host "Select a certificate for the app:" 
    $DefaultSelect = ""
    ForEach ($i in 0..($LocalAppCerts.Count - 1)) {
        $cert = $LocalAppCerts[$i]
        Write-Host "$($i+1)) $($cert.FriendlyName) Thumbprint: $(CropString $cert.Thumbprint 8)... Exp: $($cert.NotAfter.ToString('yyyy-MM-dd'))" 
        If ($DefaultFriendlyName -eq $Cert.FriendlyName) {
            $DefaultSelect = [string]($i+1)
        }
    }
    $selection = PromptForString "Enter the number of the certificate to use (or press Enter to cancel)" -defaultValue $DefaultSelect
    $num = 0
    If ([int]::TryParse($selection, [ref]$num) -and $num -ge 1 -and $num -le $LocalAppCerts.Count){
        $returnObj.Cert = $LocalAppCerts[$selection - 1]
        $returnObj.CertFriendlyName = $LocalAppCerts[$selection - 1].FriendlyName
        $returnObj.CertThumbprint = $LocalAppCerts[$selection - 1].Thumbprint
        $returnObj.CertOK = $true ; $returnObj.Message = "User selected from local cert list"
        Return $returnObj
    } Else {
        $returnObj.Message = "Invalid selection or canceled."
        Return $returnObj
    }
} # SelectAppCertificate
Function CreateAppCertificate
{ # CreateAppCertificate 
    # Looks for an existing certificate for the app in the local cert store and will create a new one if needed and attach it to the app registration in Azure AD
    # Assumes Connect-Mgraph has been run and is permitted.
    Param (
        [string]  $AppName = "MyCustomApp"
        ,[string] $AppId = "29302-22187983-example-app-id-12345" # If you have an existing app registration, set the AppId here to reuse it; otherwise, a new app will be created
        ,[string] $TenantId = "contoso.com"
        ,[string] $SystemOrUser = "User" # or "system"
        ,[Int16]  $AppCertMonths = 120 # number of months for cert expiration
    )
    # Return object defined
    $returnObj = [PSCustomObject]@{
        AppCert           = "" # Certificate that will be used / created for the app
        CertFriendlyName  = "" # Friendly name of the certificate that will be used / created for the app
        Message           = ""
        CertOK            = $false
    }
    # CertFriendlyName
    If ($SystemOrUser -eq "System") { # System
        $CertFriendlyName = "$AppName [System]"
        $CertStoreLocation = "Cert:\LocalMachine\My"
    } Else { # User
        $CertFriendlyName = "$AppName [User $($env:USERNAME)]"
        $CertStoreLocation = "Cert:\CurrentUser\My"
    } # SytemOrUser
    $returnObj.CertFriendlyName = $CertFriendlyName
    # System check
    If (($SystemOrUser -eq "System") -and (-not(IsAdmin))){
        $returnObj.Message = "You must run this script as an administrator to access system certificates."
        Return $returnObj
    }
    #region LocalAppCerts
    $AppCert = $null # this will be the one we use (either existing or new)
    $DeletedThumbprints = @() # extras will be deleted and tracked here to remove from app registration If needed
    $i = 0
    $LocalAppCerts = @(Get-ChildItem $CertStoreLocation -Recurse | Where-Object { $_.FriendlyName -eq $CertFriendlyName } |  Sort-Object NotAfter -Descending)
    Foreach ($LocalAppCert in $LocalAppCerts)
    { # each local cert with the friendly name
        $i++
        # Warning If expiration is soon
        $DaysRemaining = [Math]::Round(($LocalAppCert.NotAfter - (Get-Date)).TotalDays)
        If ($DaysRemaining -lt 1)
        { # Expired
            Write-Host "Expired: Deleting certificate with thumbprint $(CropString $LocalAppCert.Thumbprint 8)... and subject $($LocalAppCert.Subject)..." -ForegroundColor Yellow
            $DeletedThumbprints += @($LocalAppCert.Thumbprint)
            Remove-Item -Path $LocalAppCert.PSPath -Force
        } # Expired
        Else
        { # NotExpired
            If ($DaysRemaining -lt 30)
            { # 30 days
                Write-Host "Warning: Certificate expires in only $($DaysRemaining) days!" -ForegroundColor Yellow
            } # 30 days
            If ($AppCert)
            { # delete extras
                Write-Host "Extra: Deleting duplicate cert with thumbprint $(CropString $LocalAppCert.Thumbprint 8) and subject $($LocalAppCert.Subject)..." -ForegroundColor Yellow
                $DeletedThumbprints += @($LocalAppCert.Thumbprint)
                Remove-Item -Path $LocalAppCert.PSPath -Force
            } # delete extras
            Else
            { # keep the first one we find that isn't expired
                $AppCert = $LocalAppCert
            } # keep the first one we find that isn't expired
        } # NotExpired
    } # each local cert with the friendly name
    If ($AppCert)
    { # Found an existing cert to use
        $returnObj.Message = "Using existing cert $($AppCert.FriendlyName) [thumbprint $(CropString $AppCert.Thumbprint 8)...] exp $($AppCert.NotAfter.ToString('yyyy-MM'))"
    }
    Else
    { # No cert found, create a new one
        $CertSubject = "CN=$($CertFriendlyName)"
        $AppCert = New-SelfSignedCertificate -Subject $CertSubject -FriendlyName $CertFriendlyName -CertStoreLocation $CertStoreLocation -NotAfter (Get-Date).AddMonths($AppCertMonths)
        $returnObj.Message = "Created cert $($AppCert.FriendlyName) [thumbprint $(CropString $AppCert.Thumbprint 8)...] exp $($AppCert.NotAfter.ToString('yyyy-MM'))"
    }
    #endregion LocalAppCerts
    #region MgAppCerts
    # Look up by client/app ID and get the KeyCredentials(certs)
    $FoundAppCert = $false
    $MgUpdateNeeded = $false # need to replace KeyCredentials? Update-MgApplication -ApplicationId $MgApp.Id -KeyCredentials $KeyCredentials
    $MgApp = Get-MgApplication -Filter "AppId eq '$($AppId)'"
    if (-not $MgApp) {
        Throw "Application with AppId '$AppId' not found"
    }
    $MgAppKeyCredsOld = (Get-MgApplication -ApplicationId $MgApp.Id).KeyCredentials
    $MgAppKeyCredsNew = @()
    $cert_i = 0
    ForEach ($MgAppKeyCredOld in $MgAppKeyCredsOld)
    { # each cert found in the app registration with this machine
        $cert_i++
        $MgAppCertThumbprint = If ($MgAppKeyCredOld.CustomKeyIdentifier) { [System.BitConverter]::ToString($MgAppKeyCredOld.CustomKeyIdentifier).Replace("-", "") } Else { "(not available)" }
        Write-Host "  $($cert_i) Cert thumbprint $(CropString $MgAppCertThumbprint 8) ... " -NoNewline
        If ($MgAppCertThumbprint -eq $AppCert.Thumbprint)
        { # cert already associated
            Write-Host "OK: found on this machine" -ForegroundColor Green
            #Write-Host "Certificate with thumbprint $(CropString $MgAppCertThumbprint 5)... already associated with the app registration." -ForegroundColor Green
            $MgAppKeyCredsNew += @($MgAppKeyCredOld) # Copy it over
            $FoundAppCert = $true
        } # cert already associated with this machine
        Else
        { # cert not associated with this machine
            If ($DeletedThumbprints -contains $MgAppCertThumbprint)
            { # it was deleted locally above, dont keep it
                Write-Host "Stale: removed from App and Machine" -ForegroundColor Green
                Write-Host "Certificate with thumbprint $(CropString $MgAppCertThumbprint 8)... was deleted locally above and will be removed from the app registration." -ForegroundColor Yellow
                $DeletedThumbprints += @($MgAppCertThumbprint)
                $MgUpdateNeeded = $true
            } # it was deleted locally above, dont keep it
            Else
            { # not deleted, keep it for another machine
                Write-Host "OK: from another machine" -ForegroundColor Green
                $MgAppKeyCredsNew += @($MgAppKeyCredOld) # Copy it over for now, but it is not on this machine
            } ## not deleted, keep it for another machine
        } # cert not associated with this machine
    } # each cert found in the app registration
    If (-not $FoundAppCert)
    { # not found, need to add it
        Write-Host "  * Adding Machine cert $(CropString $AppCert.Thumbprint 8) to App ..." -ForegroundColor Green
        # Build the key credential using the certificate's raw data
        $KeyCredential = @{
            DisplayName = "$($SystemOrUser) cert on [$($env:COMPUTERNAME)\$($env:USERNAME)] via [$($scriptName)] created $(Get-Date -Format "yyyy-MM-dd")"
            Type        = "AsymmetricX509Cert"
            Usage       = "Verify"
            Key         = $AppCert.RawData
            StartDateTime = $AppCert.NotBefore
            EndDateTime   = $AppCert.NotAfter
            KeyId         = [Guid]::NewGuid().ToString()
            CustomKeyIdentifier  = $AppCert.GetCertHash()   # SHA1 bytes = thumbprint bytes
        }
        # Add the new cert alongside any existing ones
        $MgUpdateNeeded = $true
        $MgAppKeyCredsNew += @($KeyCredential) # Add the new cert
    } # not found, need to add it
    If ($MgUpdateNeeded) {
        Update-MgApplication -ApplicationId $MgApp.Id -KeyCredentials $MgAppKeyCredsNew | Out-Null
        # Confirm the cert was added
        Write-Host "It may take a few moments to appear in the portal and be usable."
        #Start-Sleep -Seconds 5
        $returnObj.Message = "App updated with this cert. $($returnObj.Message)"
    }
    Else {
        $returnObj.Message = "App already had this cert. $($returnObj.Message)"
    }
    #endregion MgAppCerts
    $returnObj.AppCert = $AppCert
    $returnObj.CertOK = $true
    return $returnObj
} # CreateAppCertificate
Function GetAppCertificate
{ # GetAppCertificate
    # Gets Cert for the App by looking locally for the friendly name in the right format
    Param (
        [string]  $AppName = "MyCustomApp"
        ,[string] $SystemOrUser = "User" # or "System"
    )
    # Return object defined
    $returnObj = [PSCustomObject]@{
        AppCert           = "" # Certificate
        CertFriendlyName  = "" # Friendly name of the certificate
        Message           = ""
        CertOK            = $false
    }
    # CertFriendlyName
    If ($SystemOrUser -eq "System") { # System
        $CertFriendlyName = "$AppName [System]"
        $CertStoreLocation = "Cert:\LocalMachine\My"
    } Else { # User
        $CertFriendlyName = "$AppName [User $($env:USERNAME)]"
        $CertStoreLocation = "Cert:\CurrentUser\My"
    } # SytemOrUser
    $returnObj.CertFriendlyName = $CertFriendlyName
    # System check
    If (($SystemOrUser -eq "System") -and (-not(IsAdmin))){
        $returnObj.Message = "You must run this script as an administrator to access system-based certificates."
        PressEnterToContinue $returnObj.Message  
        Return $returnObj
    }
    # Find certs
    $AppCerts = @(Get-ChildItem $CertStoreLocation -Recurse | Where-Object { $_.FriendlyName -eq $CertFriendlyName })
    If ($AppCerts.Count -eq 1)
    { # Found exactly 1 cert
        $AppCert = $AppCerts[0]
        # Warning If expiration is soon
        $DaysRemaining = [Math]::Round(($AppCert.NotAfter - (Get-Date)).TotalDays)
        If ($DaysRemaining -lt 90)
        { # 90 days
            Write-Host "Warning: Certificate expires in only $($DaysRemaining) days!" -ForegroundColor Yellow
            Write-Host "At 30 days you will be asked to delete the expiring certificate and create a new one."
            $returnObj.Message = "Certificate expires in only $($DaysRemaining) days."
            $returnObj.AppCert = $AppCert
            $returnObj.CertOK = $true
        } # 90 days
        Elseif ($DaysRemaining -lt 30)
        { # 30 days
            Write-Host "Warning: Certificate expires in only $($DaysRemaining) days!" -ForegroundColor Yellow
            If (AskForChoice "Cancel using the expiring certificate (You will need to re-run the script to create a new one)?") {
                Write-Host "Ignoring use of certificate with thumbprint $($AppCert.Thumbprint) and subject $($AppCert.Subject)..." -ForegroundColor Yellow
                $returnObj.Message = "Certificate ignored because it expires in only $($DaysRemaining) days. You will be asked to create one."
                $returnObj.CertOK = $false
            }
        } # 30 days
        Else { # OK
            $returnObj.AppCert = $AppCert
            $returnObj.CertOK = $true
        } # OK
    } # Found exactly 1 cert
    Elseif ($AppCerts.Count -gt 0)
    { # Found more than 1 cert
        $returnObj.Message = "Too many [$($AppCerts.Count) Certs found with friendly name [$($CertFriendlyName))]. Canceling, press Enter to continue."
        PressEnterToContinue $returnObj.Message  
        $returnObj.CertOK = $false
    } # Found more than 1 cert
    Else
    { # Found no certs
        $returnObj.Message = "No certificate found with friendly name: $($CertFriendlyName)"
        # Write-Host $returnObj.Message -ForegroundColor Yellow
        $returnObj.CertOK = $false
    } # Found no certs
    # Return a custom object with the cert details (Thumbprint, Subject, NotAfter) If needed
    return $returnObj 
} # GetAppCertificate
Function CheckAppAndCert
{ # CheckAppAndCert
    # Connects to an org and creates (or returns the existing) Registered App
    Param (
        [string]    $TenantId ="contoso.com" 
        ,[string]   $AppName = "MyCustomApp" 
        ,[string]   $AppId = "20930022" 
        ,[string[]] $AppRoles = @("User.Read.All","Group.Read.All")# @("User.Read.All","Group.Read.All")
        ,[string]   $PermissionType = "Application" # or "DelegatedWork"
        ,[string]   $AdminAppId = "" 
        ,[string]   $AdminAppCertThumbprint = ""
        ,[string]   $AdminAppCertFriendlyName = ""
        ,[string]   $SystemOrUser = "User"
        ,[bool]     $AlwaysUseExisting = $false
    )
    $CheckReturnObj = [PSCustomObject]@{
        AppId             = $AppId
        Message           = ""
        AppOK             = $false
        AdminAppId             = ""
        AdminAppCertThumbprint = ""
        AdminAppCertFriendlyName   = ""
    }
    # CreateRegiredApp
    Write-Host "Checking Tenant for Registered App and Certificate [Use Tenant admin for Connection]..." -ForegroundColor Green
    $CreateReturnObj = CreateRegisteredApp -TenantId $TenantId -AppName $AppName -PermissionType $PermissionType -PermissionNames $AppRoles -AdminAppId $AdminAppId -AdminAppCertThumbprint $AdminAppCertThumbprint -AdminAppCertFriendlyName $AdminAppCertFriendlyName -SystemOrUser $SystemOrUser -AlwaysUseExisting $AlwaysUseExisting
    If (-not $CreateReturnObj.ConnectOK) {
        #Write-Host "Error creating app registration. Cannot continue without an app registration." -ForegroundColor Red
        $CheckReturnObj.Message = "Error creating app registration. Cannot continue without an app registration."
        $CheckReturnObj.AppOK = $false
    } # No AppId
    Else
    { # Got AppId
        $CheckReturnObj.AppOK = $true
        $CheckReturnObj.AppId = $CreateReturnObj.AppId
        $CheckReturnObj.Message = "App registration successful with AppId: $($CreateReturnObj.AppId)"
        $CheckReturnObj.AdminAppId = $CreateReturnObj.AdminAppId
        $CheckReturnObj.AdminAppCertThumbprint = $CreateReturnObj.AdminAppCertThumbprint
        $CheckReturnObj.AdminAppCertFriendlyName  = $CreateReturnObj.AdminAppCertFriendlyName
        Write-Host "App registration returned AppId: " -NoNewline
        Write-Host $CreateReturnObj.AppId -ForegroundColor Green
        $AppCertObj = CreateAppCertificate -AppName $AppName -TenantId $TenantId -SystemOrUser $SystemOrUser -AppId $CreateReturnObj.AppId
        If ($AppCertObj.CertOK) {
            Write-Host $AppCertObj.Message -ForegroundColor Yellow
            $CheckReturnObj.AppOK = $true
            $CheckReturnObj.Message += ", Cert: $(CropString $AppCertObj.AppCert.Thumbprint 8)..."
        } Else {
            Write-Host $AppCertObj.Message -ForegroundColor Yellow
            PressEnterToContinue
            $CheckReturnObj.AppOK = $false
            $CheckReturnObj.Message += " Cert failed: $($AppCertObj.Message)"
        }
        Disconnect-MgGraph | Out-Null
        Start-Sleep -Seconds 3 # pause
    } # Got AppId
    Return $CheckReturnObj 
} # CheckAppAndCert
# Functions End here
#endregion: Functions
# Main Code Starts here
#region Main Code Header
#region    --- Transcript Open
$TranscriptTemp = [System.IO.Path]::GetTempFileName()               
Start-Transcript -path $TranscriptTemp | Out-Null
#endregion --- Transcript Open
$scriptFullname = $PSCommandPath ; If (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v$((Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd"))"
$psm1="$($scriptDir)\ITAutomator.psm1";If ((Test-Path $psm1)) {Import-Module $psm1 -Force} Else {Write-Host "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
#$psm1="$($scriptDir)\ITAutomator M365.psm1";If ((Test-Path $psm1)) {Import-Module $psm1 -Force} Else {Write-Host "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
Write-Host "+---------------------------------------------------------------------------------------------------------+"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "IntuneApp Publish"
Write-Host "This script will publish Win32 applications to Intune."
Write-Host ""
# Load settings
Write-Host "Loading Settings ... " -NoNewline
$csvFile = "$($scriptDir )\$($scriptBase) Settings.csv"
$settings = CSVSettingsLoad $csvFile
# Defaults
$settings_updated = $false
If ($null -eq $settings.TenantId)    {$settings.TenantId = "contoso.com"       ; $settings_updated = $true} # can be domain or id number
If ($null -eq $settings.AppName)     {$settings.AppName = "IntuneApp Publish"   ; $settings_updated = $true}
If ($null -eq $settings.AppId)       {$settings.AppId = "(none)"               ; $settings_updated = $true} # retrieved from tenant
If ($null -eq $settings.AdminAppId)   {$settings.AdminAppId = ""               ; $settings_updated = $true} # retrieved from tenant
If ($null -eq $settings.AdminAppCertFriendlyName) {$settings.AdminAppCertFriendlyName = ""  ; $settings_updated = $true} # 
If ($null -eq $settings.AdminAppCertThumbprint) {$settings.AdminAppCertThumbprint = ""      ; $settings_updated = $true} # 
If ($null -eq $settings.LastChecked) {$settings.LastChecked = "(never)"        ; $settings_updated = $true} # default to never
#If ($null -eq $settings.Hrs1stCheck) {$settings.Hrs1stCheck = "24"             ; $settings_updated = $true} # check x hrs of logs on first run
If ($null -eq $settings.LogSizeWarnMB) {$settings.LogSizeWarnMB = "100"        ; $settings_updated = $true} # If log folder is beyond this size warn
If ($null -eq $settings.LogSizeAutoPruneMB) {$settings.LogSizeAutoPruneMB = "110"        ; $settings_updated = $true} # If log folder is beyond this size auto prune (blank for never)
If ($null -eq $settings.MaxTranscripts) {$settings.MaxTranscripts = "1000"        ; $settings_updated = $true} # Maximum number of transcript files to keep (blank for 1000)
If ($null -eq $settings.EmailTo)       {$settings.EmailTo = ""                 ; $settings_updated = $true} # default to blank (no email)
#If ($null -eq $settings.EmailEmptyReport) {$settings.EmailEmptyReport = "no"   ; $settings_updated = $true} # yes to send email every time even If nothing happened
If ($settings_updated) {$retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"}
# Tenants List
$Tenants = @()
$TenantsCSV = "$($scriptDir )\$($scriptBase) Tenants.csv"
If (Test-Path $TenantsCSV) {
    $Tenants += Import-Csv -Path $TenantsCSV
} Else {  # Create Tenants.csv If not exists
    $Tenant = [PSCustomObject]@{
        TenantId     = $settings.TenantId
        AppId        = $settings.AppId
        LastChecked  = $settings.LastChecked
        AdminAppId               = "" # Set to AppId of an admin app-adding App that can add Apps. Requires Type: Application Roles: Application.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All, Directory.ReadWrite.All
        AdminAppCertFriendlyName = "" #
        AdminAppCertThumbprint   = "" # Set to Cert thumbprint of the AdminAppId
    }
    $Tenants += $Tenant
    $Tenants | Sort-Object TenantId | Export-Csv -Path $TenantsCSV -Encoding UTF8 -NoTypeInformation -Force 
} # Create Tenants.csv If not exists
#region Module command checks
Write-Host "Checking for Modules ... " -NoNewline
$ModuleCommands=@()
$ModuleCommand = [PSCustomObject]@{ 
    Module = "Microsoft.Graph"
    Commands = @("Connect-MgGraph","Get-MgOrganization","Get-MgAuditLogDirectoryAudit","Find-MgGraphCommand")
}
$ModuleCommands += $ModuleCommand
$ModuleCommand = [PSCustomObject]@{
    Module = "IntuneWin32App"
    Commands = @("Add-IntuneWin32App","New-IntuneWin32AppPackage","New-IntuneWin32AppDetectionRuleScript","New-IntuneWin32AppRequirementRule")
}
$ModuleCommands += $ModuleCommand
ForEach ($ModuleCommand in $ModuleCommands)
{ # each Module
    ForEach ($Command in $ModuleCommand.Commands)
    { # each command
        Write-Host "*" -NoNewline
        $cmd_result=Get-Command -Name $Command -ErrorAction SilentlyContinue
        If (-not $cmd_result) {
            Write-Host "A required command is missing:"
            Write-Host "  $($Command)" -ForegroundColor Yellow
            Write-Host "Suggestion: Open PowerShell $($PSVersionTable.PSVersion.Major) as and run:"
            Write-Host "  Install-Module $($ModuleCommand.Module) -Scope CurrentUser" -ForegroundColor Green
            Write-Host "     Or, to install for all users (requires admin):"
            Write-Host "  Install-Module $($ModuleCommand.Module) -Scope AllUsers"-ForegroundColor Green
            PressEnterToContinue "Press Enter to exit."
            Exit
        } # not found
    } # each command
} # each Module
#endregion Module command checks
Write-Host " ... OK " -NoNewline
# Log Folder size
$LogFolder = "$($scriptDir)\Logs"
if (-not (Test-Path -Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder | Out-Null
}
$scriptDirSizeinMB = [math]::Round((Get-ChildItem -Path $LogFolder -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
Write-Host "Logs Folder is $($scriptDirSizeinMB) MB [Warns If over $($settings.LogSizeWarnMB) MB]"
If ($scriptDirSizeinMB -gt ([System.Int32]$settings.LogSizeWarnMB)) {
    Write-Host "Warning: Logs folder is $($scriptDirSizeinMB) MB, which exceeds the $($settings.LogSizeWarnMB) MB threshold. Consider archiving or deleting old logs." -ForegroundColor Yellow
    if ($settings.LogSizeAutoPruneMB -eq "") {
        Write-Host "Note: Auto-prune is blank. To enable it, set LogSizeAutoPruneMB in settings to a value above $($settings.LogSizeWarnMB) MB." -ForegroundColor Yellow
    } Else {
        Write-Host "Note: Auto-prune is enabled with a threshold of $($settings.LogSizeAutoPruneMB) MB. At that point old files will be deleted to get to $($settings.LogSizeWarnMB) MB." -ForegroundColor Yellow
    } # auto-prune info
    # Start-sleep 3
    if (($settings.LogSizeAutoPruneMB -ne "") -and ($scriptDirSizeinMB -gt ([System.Int32]$settings.LogSizeAutoPruneMB))){
        Write-Host "Auto-pruning threshold reached ($($settings.LogSizeAutoPruneMB) MB.). Deleting old logs get to $($settings.LogSizeWarnMB) MB ..." -ForegroundColor Yellow
        $retObj = FolderPruneToSize -Folder $LogFolder -MaxMB ([System.Int32]$settings.LogSizeWarnMB) -Filter "*.csv"
        if ($retObj.CountPruned -gt 0) {
            Write-Host "Pruned $($retObj.CountPruned) old log(s) ($($retObj.PrunedMsg)) to keep only the most recent $($settings.LogSizeWarnMB) MB of logs." -ForegroundColor Green
            $retObj.Messages | ForEach-Object { Write-Host $_ }
        } # auto-prune happened
    } # possible auto-prune situation
} # Log Folder size
# check for Powershell 7
If ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "------------------------------------"
    Write-Host "Warning: You are running PowerShell version $($PSVersionTable.PSVersion.Major)."
    Write-Host "Some features only work in PowerShell 7 or later." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install PowerShell 7, run this command prompt (elevation not required) and re-run this script."
    Write-Host "winget install --id Microsoft.PowerShell --source winget" -ForegroundColor Green
    Write-Host "------------------------------------"
    PressEnterToContinue "Press Enter to continue anyway."
} # check for Powershell 7
# check for first run
If (($settings.TenantId -eq "(none)") -or ($settings.TenantId -eq "contoso.com")) {
    Write-Host "| First Start" -ForegroundColor Yellow
    Write-Host "| It looks like this is the first time you're running the script, or you haven't configured a tenant yet." -ForegroundColor Yellow
    Write-Host "| As a first step, use the [T] Manage Tenants List to add your tenant information." -ForegroundColor Yellow
    PressEnterToContinue "Press Enter to see the Main Menu"
} # check for first run
#endregion Main Code Header
# main menu
Do { # Main Menu Loop
    #region Show Settings
    $SytemOrUser = If (IsAdmin) {"System"} Else {"User"}
    # check for certificate for this AppName and TenantId
    $AppCert = $null
    $AppCertObj = GetAppCertificate -AppName $settings.AppName -SystemOrUser $SytemOrUser
    If ($AppCertObj.CertOK) {
        $AppCert = $AppCertObj.AppCert
        $AppCertInfo = "$($AppCertObj.CertFriendlyName) thumbprint $(CropString $AppCert.Thumbprint 8)... exp $($AppCert.NotAfter.ToString("yyyy-MM"))"
    } Else {
        $AppCertInfo = "(none)"
    }
    # hours ago
    $lastChecked = [DateTime]::MinValue # set $lastChecked default value If parsing fails
    If ([DateTime]::TryParse($settings.LastChecked, [ref]$lastChecked)) {
        $hrsAgo = "[$(((Get-Date).Subtract($lastChecked).TotalHours.ToString("0.0"))) hrs ago]"
    } Else { $hrsAgo = "[never]"}
    Write-Host "+---------------------------------------------------------------------------------------------------------+"
    Write-Host "      AppName: " -NoNewline
    Write-Host                 $settings.AppName -ForegroundColor Green
    # Write-Host "      EmailTo: " -NoNewline
    # Write-Host                 $settings.EmailTo -ForegroundColor Green
    # Write-Host " SystemOrUser: " -NoNewline
    # Write-Host                 $SytemOrUser -ForegroundColor Green
    Write-Host "      AppCert: " -NoNewline
    Write-Host                 $AppCertInfo -ForegroundColor Green
    Write-Host "      Tenants: " -NoNewline
    Write-Host                 $Tenants.count -ForegroundColor Green
    # Write-Host "       Tenant: " -NoNewline
    # Write-Host                 $settings.TenantId -ForegroundColor Yellow -NoNewline
    # Write-Host " LastChecked: " -NoNewline
    # Write-Host                 $settings.LastChecked $hrsAgo -ForegroundColor Green
    Write-Host "------------------------------------------------ Tenants (Orgs) -----------------------------------"
    Write-Host "[P] Publish to Tenant(s)                         [T] Manage Tenants List                           "
    Write-Host "--------------- Settings --------------------------------------------------------------------------"
    Write-Host "[B] Browse the log folder                                                                          "
    Write-Host "[S] Edit the Settings.csv file                   [E] Setup / test email alerts (SMTP)              "
    Write-Host "[X] Exit                                                                                           "
    Write-Host "---------------------------------------------------------------------------------------------------"
    #endregion Show Settings
    #If ($AutoMenuChoice -eq '') {
        $choice = PromptForString "Choice [X to exit]"
    #} # ask for choice
    #Else {
    #    Write-Host "Choice: [$($AutoMenuChoice)]  (-AutoMenuChoice $($AutoMenuChoice))"
    #    $choice = $AutoMenuChoice 
    #} # don't ask (auto)
    If (($choice -eq "") -or ($choice -eq "X")) {
        #Break
    } # Exit
    If ($choice -eq "T")
    { # Tenants List
        Do { # Tenant Loop
            # Display current tenants list
            Write-Host "+---------------------------------------------------------------------------------------------------------+"
            Write-Host "Current Tenants List:" -ForegroundColor Green
            If ($Tenants.Count -eq 0) {
                Write-Host "(empty)" -ForegroundColor Yellow
            } # No tenants list
            Else 
            { # Has tenants list
                $TenantCount = 0
                $TenantHash = @{}
                ForEach ($Tenant in $Tenants | Sort-Object TenantId) {
                    $TenantCount++
                    # is current
                    If ($Tenant.TenantId -eq $settings.TenantId) {
                        $highlighted = "Green"
                    } Else {
                        $highlighted = "White"
                    }
                    # add a hash lookup
                    $TenantHash[[string]$TenantCount] = $Tenant.TenantId
                    # display the tenant info
                    Write-Host "[$($TenantCount)] " -ForegroundColor $highlighted -NoNewline
                    Write-Host (CropString $Tenant.TenantId 20 -ForcetoMaxLen) -ForegroundColor $highlighted -NoNewline
                    Write-Host " | AppId: $(CropString $Tenant.AppId 8 -ForcetoMaxLen) | LastChecked: $(CropString $Tenant.LastChecked.ToString() 12 -ForcetoMaxLen) | AdminAppId: $(CropString $Tenant.AdminAppId 8 -ForcetoMaxLen) | AdminAppCert: $(CropString $Tenant.AdminAppCertThumbprint 8 -ForcetoMaxLen)..." -ForegroundColor $highlighted
                }
            } # Has tenants list
            Write-Host "+---------------------------------------------------------------------------------------------------------+"
            Write-Host "Selected Tenant: " -NoNewline; Write-Host $settings.TenantId -ForegroundColor Green
            Write-Host "[A] Add a Tenant                          " -NoNewline
            Write-Host "[F] Fix-up " -ForegroundColor Green -NoNewline; Write-Host "selected Tenant (Regstrd App/Cert/Needs Tenant Admin)"
            Write-Host "[R] Remove selected Tenant                [C] Check Tenants for App and Cert"
            Write-Host "[W] Browse to Entra App for Tenant        [E] Edit Tenant list CSV (manually to bulk-add)"
            Write-Host "[X] Exit to main menu"
            Write-Host "+---------------------------------------------------------------------------------------------------------+"
            $TenantsChoice = PromptForString "Select Tenant or action [X to exit]"
            If ($TenantsChoice -eq "X")
            { # Exit to main menu
                Break
            } # Exit to main menu
            If ($TenantsChoice -eq "W")
            { # browse to Entra App
                Write-Host "--------------------------------------------------------------------------------------------------------------------"
                Write-Host "Use these links to find Entra Registered Apps"
                Write-Host "--------------------------------------------------------------------------------------------------------------------"
                Write-Host "Find it here: Entra Admin > Apps > App Registrations > All apps"
                Write-Host "              https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade" -ForegroundColor Green
                Write-Host "    and here: Entra Admin > Apps > App Registrations > $($settings.AppName)"
                Write-Host "              https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($settings.AppId )/isMSAApp~/false" -ForegroundColor Green
                Write-Host "--------------------------------------------------------------------------------------------------------------------"
                PressEnterToContinue "Press <Enter> to continue." -ForegroundColor Green
            } # browse to Entra App
            If ($TenantsChoice -eq "C")
            { # Check ALL Tenants
                If ($Tenants.Count -eq 0) {
                    PressEnterToContinue "No tenants to check. Use [A] to add tenants first. Press Enter"
                    Continue # back to menu
                }
                # Check for AppCert
                If ($null -eq $AppCert)
                { # No AppCert
                    PressEnterToContinue "No AppCert for tenants to use. Use [F] (on any tenant) to fix this. Press Enter"
                    Continue # back to menu
                } # No AppCert
                Else
                {
                    Write-Host "Using AppCert Thumbprint: $(CropString $AppCert.Thumbprint 8)..."
                } # Has AppCert
                # Show a gridview and allow selection of tenants to check
                $SelectedTenants = @()
                #$SelectedTenants += $Tenants | Sort-Object TenantId
                $msg= "Select rows and click OK (Use Ctrl and Shift and Filter features to multi-select)"
                $SelectedTenants = $Tenants | Out-GridView -Title $msg -PassThru
                If (-not (AskForChoice "About to check $($SelectedTenants.Count) of $($Tenants.Count) tenants in the list.")) {
                    Continue # back to menu
                }
                $count_err = 0
                $count_t = 0
                $TenantsToFix = @()
                ForEach ($SelectedTenant in $SelectedTenants)
                { # each tenant to check
                    $count_t++
                    Write-Host "Tenant $($count_t) of $($SelectedTenants.Count): $($SelectedTenant.TenantId) " -NoNewline
                    #region Connect using AppCert
                    $TenantId = $SelectedTenant.TenantId
                    $AppName  = $settings.AppName
                    $AppId    = $SelectedTenant.AppId
                    #
                    $TenantErr =""
                    # Check for AppId
                    If ((($AppId -eq "(none)" ) -or ($AppId -eq "")) -and $TenantErr -eq "")
                    { # No AppId in settings, need to create app and cert
                        $TenantErr = "No AppId. Select this [T]enant and use [F] to fix it."
                    } # No AppId in settings, need to create app and cert
                    If ($TenantErr -eq "")
                    { # No errors, we can try to connect
                        # Connect-MgGraph using certificate
                        $TenantErr =""
                        Try {
                            Connect-MgGraph -TenantId $TenantId -ClientId $AppId -CertificateThumbprint $AppCert.Thumbprint -NoWelcome -ErrorAction Stop
                            Write-Host "OK " -ForegroundColor Green -NoNewline
                            # display tenant name
                        } Catch {
                            $TenantErr =$_.Exception.Message
                        } # Connect-MgGraph using certificate
                        #endregion Connect using AppCert
                    }
                    If ($TenantErr -eq "")
                    { # ConnectOK
                        Try {
                            $tenantDetails = Get-MgOrganization -ErrorAction Stop
                            Write-Host $tenantDetails.DisplayName -ForegroundColor Cyan
                            Disconnect-MgGraph | Out-Null
                        } Catch {
                            $TenantErr =$_.Exception.Message
                            # Disconnect
                        }
                    } # ConnectOK
                    If ($TenantErr -ne "") 
                    { # No TenantErr
                        $count_err = $count_err + 1
                        Write-Host "ERR " -ForegroundColor Yellow -NoNewline
                        Write-Host $TenantErr
                        $settings.AdminAppCertFriendlyName = $SelectedTenant.AdminAppCertFriendlyName
                        $settings.AdminAppCertThumbprint   = $SelectedTenant.AdminAppCertThumbprint
                        $settings.AdminAppId               = $SelectedTenant.AdminAppId
                        $settings.AppId                    = $SelectedTenant.AppId
                        $settings.LastChecked              = $SelectedTenant.LastChecked
                        $settings.TenantId                 = $SelectedTenant.TenantId
                        $TenantsToFix += $SelectedTenant
                    } # No TenantErr
                } # each tenant to check
                Write-Host "Done with All Tenants."
                If ($count_err -eq 0) {
                    Write-Host "No errors found in any tenants." -ForegroundColor Green
                } Else {
                    Write-Host "Errors found in $($count_err) of $($SelectedTenants.Count). " -ForegroundColor Yellow
                    If (AskForChoice "Loop through the $($count_err) tenants with errors and apply fix?")
                    { # Fix tenants with errors
                        $i = 0
                        $AlwaysFix = $false
                        ForEach ($TenantToFix in $TenantsToFix)
                        { # each tenant to fix
                            $i++
                            Write-Host "Fixing Tenant $i of $($TenantsToFix.Count): $($TenantToFix.TenantId) "
                            # Show info
                            $AppName = $settings.AppName
                            $TenantId = $TenantToFix.TenantId
                            $AdminAppId = $TenantToFix.AdminAppId
                            $AdminAppCertThumbprint = $TenantToFix.AdminAppCertThumbprint
                            $AdminAppCertFriendlyName = $TenantToFix.AdminAppCertFriendlyName
                            Write-Host "Selected Tenant: " -NoNewline
                            Write-Host $TenantId -ForegroundColor Green
                            Write-Host "------ Fix-up ----------------------------------------------------------------------------------------"
                            Write-Host "This will check for the required Microsoft Graph permissions and a certificate for the app to use."
                            Write-Host "If the app doesn't exist, it will be created. If the certificate doesn't exist, it will be created."
                            Write-Host "------------------------------------------------------------------------------------------------------"
                            If (-not $AlwaysFix)
                            { # Ask for fix
                                $fixchoice = AskForChoice -Choices ("&Fix","Fix &All tenants","&Skip this tenant","E&xit to menu") -Message "What do you want to do with this tenant $($TenantId)?" -ReturnString
                                If ($fixchoice -eq "Exit to menu") {
                                    Break # back to menu
                                }
                                If ($fixchoice -eq "Skip this tenant") {
                                    Continue # next tenant
                                }
                                If ($fixchoice -eq "Fix All tenants") {
                                    $AlwaysFix = $true
                                }
                            } # not always fix  
                            # Create app
                            <# 
                            # Automatic generation of required AppRoles based on the Microsoft Graph commands
                            $AppMgCommands = @()
                            $AppMgCommands += "Get-MgOrganization"
                            $AppMgCommands += "Get-MgAuditLogDirectoryAudit"
                            # Get roles for these commands given PermissionType and Privs needed
                            $AppRolesCommands= Get-MgCommandRoles -MgCommands $AppMgCommands -PermissionType "Application" -PrivLeastOrPrivAll "PrivAll" -PrivInclude ".Read."
                            $AppRoles = @($AppRolesCommands.Name)
                            #>
                            # Roles for Entra registered app management
                            # $AppRoles = @() 
                            # $AppRoles += "Domain.Read.All"                        # Read domain properties
                            # $AppRoles += "User.ReadWrite.All"                     # Read and update user properties
                            # $AppRoles += "Directory.Read.All"                     # Allows the app to read data in your organization's directory.
                            # #$AppRoles += "Application.Read.All"                   # Allows the app to read all applications and service principals without a signed-in user
                            # $AppRoles += "Application.ReadWrite.All"              # Allows the app to create, read, update and delete applications and service principals without a signed-in user. Does not allow management of consent grants.
                            # $AppRoles += "RoleManagement.ReadWrite.Directory"     # Allows the app to read and manage the role-based access control (RBAC) settings for your company's directory, without a signed-in user.
                            # $AppRoles += "DelegatedPermissionGrant.ReadWrite.All" # Manage app permission grants and app role assignments 
                            # Roles for Intune App management
                            $AppRoles = @()
                            $AppRoles += "DeviceManagementManagedDevices.ReadWrite.All" # devices managed by Microsoft Intune
                            $AppRoles += "DeviceManagementApps.ReadWrite.All"           # group assignments and status of apps
                            $AppRoles += "Group.ReadWrite.All"                          # group properties and memberships
                            $AppRoles += "User.Read.All"                                # user properties
                            $AppRoles += "Domain.Read.All"                              # domain properties
                            # 
                            # Check if the required AppRoles are available and the application and certificate are properly configured
                            $CheckReturnObj = CheckAppAndCert -TenantId $TenantId -AppName $AppName -AppRoles $AppRoles -PermissionType "Application" -AdminAppId $AdminAppId -AdminAppCertThumbprint $AdminAppCertThumbprint -AdminAppCertFriendlyName $AdminAppCertFriendlyName -SystemOrUser $SytemOrUser -AlwaysUseExisting $true
                            If ($CheckReturnObj.AppOK)
                            { # App and Cert are OK - Save AppId
                                $AppId = $CheckReturnObj.AppId
                                Write-Host $CheckReturnObj.Message -ForegroundColor yellow
                                # Save AppId to settings
                                $settings.AppId = $AppId
                                $settings.AdminAppId               = $CheckReturnObj.AdminAppId
                                $settings.AdminAppCertThumbprint   = $CheckReturnObj.AdminAppCertThumbprint
                                $settings.AdminAppCertFriendlyName = $CheckReturnObj.AdminAppCertFriendlyName
                                $retVal = CSVSettingsSave $settings $csvFile
                                # Save Appid to Tenants list
                                ($Tenants | Where-Object TenantId -eq $TenantId).AppId = $AppId
                                ($Tenants | Where-Object TenantId -eq $TenantId).AdminAppId               = $CheckReturnObj.AdminAppId
                                ($Tenants | Where-Object TenantId -eq $TenantId).AdminAppCertThumbprint   = $CheckReturnObj.AdminAppCertThumbprint
                                ($Tenants | Where-Object TenantId -eq $TenantId).AdminAppCertFriendlyName = $CheckReturnObj.AdminAppCertFriendlyName
                                $Tenants | Sort-Object TenantId | Export-Csv -Path $TenantsCSV -Encoding UTF8 -NoTypeInformation -Force
                            } # App and Cert are OK - Save AppId
                            Else
                            { # App and Cert are Not OK
                                Write-Host $CheckReturnObj.Message -ForegroundColor Yellow
                            } # App and Cert are Not OK
                        } # each tenant to fix
                    } # Fix tenants with errors
                }
                Start-Sleep 3
            } # Check ALL Tenants
            If ($TenantsChoice -eq "R")
            { # Remove
                if ($tenants.count -eq 1) {
                    PressEnterToContinue "You can't remove the last tenant.  Add a new tenant first <or> exit the program and delete the tenants.csv file. Press Enter to continue"
                    Continue
                }
                $TenantIdToDel = $settings.TenantId
                Write-Host "Selected Tenant: " -NoNewline
                Write-Host $TenantIdToDel -ForegroundColor Green
                If (AskForChoice "Remove this tenant?") {
                    # Remove from Tenants
                    $NewTenants = @()
                    $NewTenants += $Tenants | Where-Object { $_.TenantId -ne $TenantIdToDel }
                    # Save updated TenantsCSV
                    $NewTenants | Sort-Object TenantId | Export-Csv -Path $TenantsCSV -Encoding UTF8 -NoTypeInformation -Force
                    # Ask If they want to remove the registered app too
                    If (-not(($TenantIdToDel -eq "(none)") -or ($TenantIdToDel -eq "contoso.com"))) {
                        If (AskForChoice "Remove the registered app from this tenant?") {
                            RemoveRegisteredApp -TenantId $TenantIdToDel -AppName $settings.AppName -SystemOrUser $SystemOrUser -AdminAppID $settings.AdminAppId -AdminAppCertThumbprint $settings.AdminAppCertThumbprint -AdminAppCertFriendlyName $settings.AdminAppCertFriendlyName
                        }
                    }
                    # Select another tenant (the first tenant)
                    $SelectedTenant = $NewTenants[0]
                    # Update settings with selected tenant info
                    $settings.TenantId     = $SelectedTenant.TenantId
                    $settings.AppId        = $SelectedTenant.AppId
                    $settings.LastChecked  = $SelectedTenant.LastChecked
                    $settings.AdminAppId   = $SelectedTenant.AdminAppId
                    $settings.AdminAppCertThumbprint = $SelectedTenant.AdminAppCertThumbprint
                    $settings.AdminAppCertFriendlyName = $SelectedTenant.AdminAppCertFriendlyName
                    # Save updated settings
                    $retVal = CSVSettingsSave $settings $csvFile
                    # Update in-memory 
                    $Tenants = $NewTenants
                    Write-Host "Done with Removal"
                } Else {
                    Write-Host "Canceled"
                }
                Start-Sleep -Seconds 2 # pause 
            } # Remove
            ElseIf ($TenantsChoice -eq "A")
            { # Add a tenant
                $newTenantId = PromptForString "Enter Tenant ID or domain name to add"
                If ($newTenantId -ne "")
                { # Add the tenant
                    # first check for dupe
                    If ($Tenants | Where-Object TenantId -eq $newTenantId) {
                        Write-Host "This tenant already exists."
                        PressEnterToContinue
                        Continue
                    }
                    # add non-dupe
                    $newTenant = [PSCustomObject]@{
                        TenantId   = $newTenantId
                        AppId      = "(none)"
                        LastChecked= "(never)"
                        AdminAppId               = ""
                        AdminAppCertFriendlyName = ""
                        AdminAppCertThumbprint   = ""
                    }
                    $Tenants += @($newTenant)
                    # Save updated list
                    $Tenants | Sort-Object TenantId | Export-Csv -Path $TenantsCSV -Encoding UTF8 -NoTypeInformation -Force 
                    # Update settings with selected tenant info
                    $settings.TenantId = $newTenant.TenantId
                    $settings.AppId = $newTenant.AppId
                    $settings.LastChecked = $newTenant.LastChecked
                    $settings.AdminAppId = $newTenant.AdminAppId
                    $settings.AdminAppCertFriendlyName = $newTenant.AdminAppCertFriendlyName
                    $settings.AdminAppCertThumbprint = $newTenant.AdminAppCertThumbprint
                    # Save updated settings
                    $retVal = CSVSettingsSave $settings $csvFile
                    Write-Host "Tenant added and selected: " -NoNewline
                    Write-Host $newTenantId -ForegroundColor Green
                    Write-Host "Next, use [F] to set up the app registration and certificate for this tenant."
                    PressEnterToContinue
                }
                Else {
                    PressEnterToContinue "No tenant entered. Returning to main menu." -ForegroundColor Yellow
                }
            } # Add a tenant
            ElseIf ($TenantsChoice -eq "E")
            { # Edit tenant list CSV
                PressEnterToContinue "About to open Tenants list '$(Split-Path $TenantsCSV -Leaf)' for editing."
                # Open existing settings file for edit
                Invoke-Item $TenantsCSV
                PressEnterToContinue "Press Enter to continue after editing the Tenants list."
                $Tenants = @()
                $Tenants += Import-Csv -Path $TenantsCSV
            } # Edit tenant list CSV
            Elseif ($TenantsChoice -eq "F")
            { # Cert and App setup for Microsoft Graph
                # Show info
                $AppName = $settings.AppName
                $TenantId = $settings.TenantId
                $AdminAppId = $settings.AdminAppId
                $AdminAppCertThumbprint = $settings.AdminAppCertThumbprint
                $AdminAppCertFriendlyName = $settings.AdminAppCertFriendlyName
                Write-Host "Selected Tenant: " -NoNewline
                Write-Host $TenantId -ForegroundColor Green
                Write-Host "------ Fix-up ----------------------------------------------------------------------------------------"
                Write-Host "This will check for the required Microsoft Graph permissions and a certificate for the app to use."
                Write-Host "If the app doesn't exist, it will be created. If the certificate doesn't exist, it will be created."
                Write-Host "------------------------------------------------------------------------------------------------------"
                If (-not (AskForChoice "Proceed with checking/fixing?")) {
                    Continue # back to menu
                }
                # Create app
                <# 
                # Automatic generation of required AppRoles based on the Microsoft Graph commands
                $AppMgCommands = @()
                $AppMgCommands += "Get-MgOrganization"
                $AppMgCommands += "Get-MgAuditLogDirectoryAudit"
                # Get roles for these commands given PermissionType and Privs needed
                $AppRolesCommands= Get-MgCommandRoles -MgCommands $AppMgCommands -PermissionType "Application" -PrivLeastOrPrivAll "PrivAll" -PrivInclude ".Read."
                $AppRoles = @($AppRolesCommands.Name)
                #>
                # Roles for Intune App management
                $AppRoles = @()
                $AppRoles += "DeviceManagementManagedDevices.ReadWrite.All" # devices managed by Microsoft Intune
                $AppRoles += "DeviceManagementApps.ReadWrite.All"           # group assignments and status of apps
                $AppRoles += "Group.ReadWrite.All"                          # group properties and memberships
                $AppRoles += "User.Read.All"                                # user properties
                $AppRoles += "Domain.Read.All"                              # domain properties
                # 
                # Check if the required AppRoles are available and the application and certificate are properly configured
                $CheckReturnObj = CheckAppAndCert -TenantId $TenantId -AppName $AppName -AppRoles $AppRoles -PermissionType "Application" -AdminAppId $AdminAppId -AdminAppCertThumbprint $AdminAppCertThumbprint -AdminAppCertFriendlyName $AdminAppCertFriendlyName -SystemOrUser $SytemOrUser
                If ($CheckReturnObj.AppOK)
                { # App and Cert are OK - Save AppId
                    $AppId = $CheckReturnObj.AppId
                    Write-Host $CheckReturnObj.Message -ForegroundColor yellow
                    # Save AppId to settings
                    $settings.AppId = $AppId
                    $settings.AdminAppId               = $CheckReturnObj.AdminAppId
                    $settings.AdminAppCertThumbprint   = $CheckReturnObj.AdminAppCertThumbprint
                    $settings.AdminAppCertFriendlyName = $CheckReturnObj.AdminAppCertFriendlyName
                    $retVal = CSVSettingsSave $settings $csvFile
                    # Save Appid to Tenants list
                    ($Tenants | Where-Object TenantId -eq $TenantId).AppId = $AppId
                    ($Tenants | Where-Object TenantId -eq $TenantId).AdminAppId               = $CheckReturnObj.AdminAppId
                    ($Tenants | Where-Object TenantId -eq $TenantId).AdminAppCertThumbprint   = $CheckReturnObj.AdminAppCertThumbprint
                    ($Tenants | Where-Object TenantId -eq $TenantId).AdminAppCertFriendlyName = $CheckReturnObj.AdminAppCertFriendlyName
                    $Tenants | Sort-Object TenantId | Export-Csv -Path $TenantsCSV -Encoding UTF8 -NoTypeInformation -Force
                } # App and Cert are OK - Save AppId
                Else
                { # App and Cert are Not OK
                    Write-Host $CheckReturnObj.Message -ForegroundColor Yellow
                } # App and Cert are Not OK
            } # Cert and App setup for Microsoft Graph
            ElseIf (($TenantsChoice -as [int]) -ge 1 -and ($TenantsChoice -as [int]) -le $Tenants.Count)
            { # Select a tenant
                If ($TenantHash.ContainsKey($TenantsChoice)) {
                    $SelectedTenant = $Tenants | Where-Object { $_.TenantId -eq $TenantHash[$TenantsChoice] }
                    Write-Host "Selected Tenant: $($SelectedTenant.TenantId)" -ForegroundColor Green
                    # Update settings with selected tenant info
                    $settings.TenantId     = $SelectedTenant.TenantId
                    $settings.AppId        = $SelectedTenant.AppId
                    $settings.LastChecked  = $SelectedTenant.LastChecked
                    $settings.AdminAppId   = $SelectedTenant.AdminAppId
                    $settings.AdminAppCertThumbprint = $SelectedTenant.AdminAppCertThumbprint
                    $settings.AdminAppCertFriendlyName = $SelectedTenant.AdminAppCertFriendlyName
                    # Save updated settings
                    $retVal = CSVSettingsSave $settings $csvFile
                } Else {
                    PressEnterToContinue "Invalid selection. Returning to main menu." -ForegroundColor Yellow
                    $SelectedTenant = $null
                }
                Start-Sleep -Seconds 1 # pause 
            } # Select a tenant
            # Tenants Choice
        } While ($true) # Tenant Loop
    } # Tenants List
    If ($choice -eq "B")
    { # browse
        Invoke-Item $scriptDir
        PressEnterToContinue "Script folder opened. Press <Enter> to continue." -ForegroundColor Green
    } # browse
    If ($choice -eq "S")
    { # Change settings
        PressEnterToContinue "About to open settings file '$(Split-Path $csvFile -Leaf)' for editing."
        # Open existing settings file for edit
        Invoke-Item $csvFile
        PressEnterToContinue "Press Enter to continue after editing the settings file."
        $settings = CSVSettingsLoad $csvFile
    } # Change settings 
    If ($choice -eq "E")
    { # Setup / test email
        Do
        { # Email Menu Loop
            # Defaults
            $settings_updated = $false
            If ($null -eq $settings.EmailServer)  {$settings.EmailServer = "mail.smtp2go.com"            ; $settings_updated = $true}
            If ($null -eq $settings.EmailPort)    {$settings.EmailPort = "587"                           ; $settings_updated = $true}
            If ($null -eq $settings.EmailUseSSL)  {$settings.EmailUseSSL = "True"                        ; $settings_updated = $true}
            If ($null -eq $settings.EmailAccount) {$settings.EmailAccount = "my-username"                ; $settings_updated = $true}
            If ($null -eq $settings.EmailPassword){$settings.EmailPassword = "my-password"               ; $settings_updated = $true}
            If ($null -eq $settings.EmailFrom)    {$settings.EmailFrom = "auditlogalerts@contoso.com" ; $settings_updated = $true}
            If ($null -eq $settings.EmailTo)      {$settings.EmailTo = ""                                ; $settings_updated = $true}
            If ($settings_updated) {$retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"}
            # Display
            $DecryptedPassword = DecryptString $settings.EmailPassword
            If ($DecryptedPassword -eq "") {
                $EmailPasswordDisplay = "(not set)"
            } Else {
                $EmailPasswordDisplay = $DecryptedPassword.Substring(0,1) # show first char
                $EmailPasswordDisplay += "*" * ($DecryptedPassword.Length - 1) # show * for the rest of the chars
            }
            Write-Host "---------------- Email Settings ------------------"            
            Write-Host ""
            Write-Host "[V] EmailServer  : " -NoNewline
            Write-Host                 $settings.EmailServer -ForegroundColor Green
            Write-Host "[R] EmailPort    : " -NoNewline
            Write-Host                 $settings.EmailPort -ForegroundColor Green
            Write-Host "[U] EmailUseSSL  : " -NoNewline
            Write-Host                 $settings.EmailUseSSL -ForegroundColor Green
            Write-Host "[A] EmailAccount : " -NoNewline
            Write-Host                 $settings.EmailAccount -ForegroundColor Green
            Write-Host "[P] EmailPassword: " -NoNewline
            Write-Host                 $EmailPasswordDisplay -ForegroundColor Green
            Write-Host "[F] EmailFrom    : " -NoNewline
            Write-Host                 $settings.EmailFrom -ForegroundColor Green
            Write-Host "[T] EmailTo           : " -NoNewline
            Write-Host                 $settings.EmailTo -ForegroundColor Green -NoNewline
            Write-Host                 " (for no email leave blank, for multiple addresses use commas)"
            Write-Host "[M] EmailEmptyReport  : " -NoNewline
            Write-Host                 $settings.EmailEmptyReport -ForegroundColor Green
            Write-Host "[S] Send a test message " -ForegroundColor Yellow
            Write-Host "[X] Exit" 
            Write-Host "-----------------------------------------------"
            # Edit settings
            $choice = PromptForString "Choice [X to exit]"
            $setting = ""
            If ($choice -eq "V") {$setting="EmailServer"}
            If ($choice -eq "R") {$setting="EmailPort"}
            If ($choice -eq "U") {$setting="EmailUseSSL"}
            If ($choice -eq "A") {$setting="EmailAccount"}
            If ($choice -eq "P") {$setting="EmailPassword"}
            If ($choice -eq "F") {$setting="EmailFrom"}
            If ($choice -eq "T") {$setting="EmailTo"}
            If ($setting -ne "")
            { # edit setting
                $encrypt = $Setting -in "EmailPassword"
                If ($encrypt) {
                    $OldSSetting = DecryptString $settings.$setting
                }
                Else {
                    $OldSSetting = $settings.$setting
                }
                Write-Host "------------------------------" 
                $Newsetting = PromptForString "     $setting" -defaultValue $OldSSetting
                If ($Newsetting -ne $OldSSetting) {
                    If ($encrypt) {
                        $settings.$setting = EncryptString $Newsetting
                    }
                    Else {
                        $settings.$setting = $Newsetting
                    }
                    $retVal = CSVSettingsSave $settings $csvFile
                    # Save Setting
                    Write-Host "Updated '$setting' from '$OldSSetting' to '$Newsetting'. Saved to CSV: $retVal" -ForegroundColor Green
                }
            } # edit setting
            If ($choice -eq "S")
            { # Send test email
                $EmailTo = PromptForString "Send test email to (blank to cancel)" -defaultValue $Settings.EmailTo
                If ($EmailTo -eq "") {Continue}
                $cred = New-Object System.Management.Automation.PSCredential($settings.EmailAccount,(ConvertTo-SecureString (DecryptString $settings.EmailPassword) -AsPlainText -Force)  )
                $smtpParams = @{
                    SmtpServer  = $settings.EmailServer
                    Port        = [int]$settings.EmailPort
                    UseSsl      = $true
                    Credential  = $cred
                    From        = $settings.EmailFrom
                    To          = $EmailTo.Split(",").Trim()
                    Subject     = "Test Email"
                    Body        = "Hello from $($settings.AppName)!"
                    } # smtpParams
                Try {
                    $WpSaved = $WarningPreference; $WarningPreference = 'SilentlyContinue'
                    Send-MailMessage @smtpParams -ErrorAction Stop
                    $WarningPreference = $WpSaved
                    Write-Host "Test email sent successfully to $($EmailTo)" -ForegroundColor Green
                    PressEnterToContinue "Look for the test message. Press Enter to return to the menu."
                } Catch {
                    Write-Host "Error sending test email: $_" -ForegroundColor Red
                    PressEnterToContinue "That didn't work. Check your email settings and try again. Press Enter."
                }
            } # Send test email
        } until (($choice -eq "X") -or $AutoMenuChoice) # Email Menu Loop
        $choice = ""
    } # Setup / test email
    If ($choice -in "P")
    { # Publish to Tenants
        # assume we don't want to skip these questions
        $recheckpkgs_skipquestion = $false
        $showmenu_publish_skipquestion = $false
        $publish_skipquestion = $false
        $republish_skipquestion = $false
        # check for Tenants
        If ($Tenants.Count -eq 0) {
            PressEnterToContinue "No tenants. Use [T] to add tenants first. Press Enter"
            Continue # back to menu
        }
        Write-Host "Select tenants from popup list:"
        $SelectedTenants = $Tenants | Out-GridView -PassThru
        If ($SelectedTenants.Count -eq 0) {
            PressEnterToContinue "No tenants to check. Use [T] to add tenants first. Press Enter"
            Continue # back to menu
        }
        $count_t = 0
        ForEach ($SelectedTenant in $SelectedTenants)
        { # each tenant to check
            $count_t++
            Write-Host "Tenant $($count_t) of $($SelectedTenants.Count): " -NoNewline
            Write-Host $SelectedTenant.TenantId -ForegroundColor Cyan
        } # each tenant to check
        if (-not(AskForChoice "Publish to $($SelectedTenants.Count) tenant(s) in the list."))
        {
            Continue # back to menu
        }
        # $pkgs = $null
        $count_t = 0
        ForEach ($SelectedTenant in $SelectedTenants)
        { # each tenant to check
            $count_t++
            Write-Host "Tenant $($count_t) of $($SelectedTenants.Count): $($SelectedTenant.TenantId)" -ForegroundColor Cyan
            #region Connect using AppCert
            $TenantId = $SelectedTenant.TenantId
            $AppId    = $SelectedTenant.AppId
            #$AppName  = $SelectedTenant.AppName
            # Check for AppCert
            If ($null -eq $AppCert)
            { # No AppCert
                PressEnterToContinue "  No AppCert. Select this [T]enant, then use [F] to fix it. <Press Enter>"
                Continue # back to menu
            } # No AppCert
            # Check for AppId
            If ($AppId -eq "(none)")
            { # No AppId in settings, need to create app and cert
                PressEnterToContinue "  No AppId in settings. Select this [T]enant and use [F] to fix it. Press Enter."
                Continue # back to menu
            } # No AppId in settings, need to create app and cert
            # Connect-MgGraph using certificate
            $ConnectOK = $false
            Write-Host "  Connect-MgGraph -TenantId $TenantId -ClientId $(CropString $AppId 8)... -CertificateThumbprint $(CropString $AppCert.Thumbprint 8)... -NoWelcome"
            Try {
                Connect-MgGraph -TenantId $TenantId -ClientId $AppId -CertificateThumbprint $AppCert.Thumbprint -NoWelcome -ErrorAction Stop
                Write-Host "  Connected OK" -ForegroundColor Green
                $ConnectOK = $true
            } Catch {
                Write-Host "Error connecting to Microsoft Graph with certificate" -ForegroundColor Yellow
                Write-Host "Error details: $_" -ForegroundColor Red
            } # Connect-MgGraph using certificate
            If (-not $ConnectOK) {
                PressEnterToContinue "That didn't work. Use [T] to select this tenant,then [F] to fix it. Press Enter."
                # Set current tenant in settings to make it easier for user to fix the problem
                $settings.TenantId = $SelectedTenant.TenantId
                $settings.AppId = $SelectedTenant.AppId
                $settings.LastChecked = $SelectedTenant.LastChecked
                $retVal = CSVSettingsSave $settings $csvFile
                Break
            } # back to menu If connection failed
            #endregion Connect using AppCert
            # display tenant name
            $tenantDetails = Get-MgOrganization
            $ThisDate =(Get-Date)  #.ToUniversalTime()
            Write-Host "  Tenant name: " -NoNewline
            Write-Host $tenantDetails.DisplayName -ForegroundColor Green
            Write-Host "          Now: " -NoNewline
            Write-Host $ThisDate -ForegroundColor Green
            Write-Host " Last checked: " -NoNewline
            # Convert to Datetime
            $lastChecked = [DateTime]::MinValue # set $lastChecked default value If parsing fails
            If ([DateTime]::TryParse($SelectedTenant.LastChecked, [ref]$lastChecked)) {
                $hrsAgo = "[$(((Get-Date).Subtract($lastChecked).TotalHours.ToString("0.0"))) hrs ago]"
                Write-Host $SelectedTenant.LastChecked $hrsAgo -ForegroundColor Green
            } Else {
                Write-Host "   No LastChecked date: '$($SelectedTenant.LastChecked)'. Defaulting to $($settings.Hrs1stCheck) hours ago." -ForegroundColor Yellow
                # make sure the string is a valid number
                $Hrs1stCheck = 24 # default fallback
                If (-not [double]::TryParse($settings.Hrs1stCheck, [ref]$Hrs1stCheck)) {
                    Write-Host "Failed to parse Hrs1stCheck: '$($settings.Hrs1stCheck)'. Defaulting to 24 hours." -ForegroundColor Yellow
                }
                $lastChecked = $ThisDate.AddHours(-$Hrs1stCheck) # default to x hours ago If parsing fails
            }
            #region Tenant Actions
            if ($pkgs)
            {
                if ($recheckpkgs_skipquestion) {
                    Write-Host "Not selecting different packages" -NoNewline
                    Write-Host " (for this session)" -ForegroundColor Cyan
                    $recheckpkgs = $false
                } # skip question
                else {
                    Write-Host "$($pkgs.count) packages have already been selected and checked."
                    $choice1 = AskForChoice "Select different packages for publishing?" -choices ("&Yes","&No","&Always no for this session") -defaultChoice 0
                    if ($choice1 -eq 0) {
                        $recheckpkgs = $true
                    } # yes
                    elseif ($choice1 -eq 1) {
                        $recheckpkgs = $false
                    } # no 
                    else {
                        $recheckpkgs = $false
                        $recheckpkgs_skipquestion = $true
                    } # always no
                } # ask question
                if ($recheckpkgs)
                { # re-check packages
                    $pkgs=$null
                }
            } # has pkgs
            if (-not $pkgs)
            { # no local package list yet
                # if (0 -eq (AskForChoice "No local packages checked yet. Use [C]heck before publishing (otherwise package update status will be unknowable). Check now?"))
                # { # No, don't check now (Note: this is kind of dumb because the hash checking isn't the slow part)
                #     Write-Host "Skipping."
                #     $bCheckAllPackages,$pkgs_ret=PackagesLocalUpdateandCheck #-GetHash $false
                #     $pkgs=@($pkgs_ret)
                #     Start-sleep 1
                # } # Yes, check now
                # else {
                    $bCheckAllPackages,$pkgs_ret=PackagesLocalUpdateandCheck #-GetHash $false
                    $pkgs=@($pkgs_ret)
                # }
            } # no local package list yet
            $OrgValues = @{} #hashtable
            $OrgValues.Add("TenantName"             , $SelectedTenant.TenantId)
            $OrgValues.Add("AppPublisherClientID"   , $SelectedTenant.AppId)
            $OrgValues.Add("PublishToGroupIncluded" , "IntuneApp Windows Users")
            $OrgValues.Add("PublishToGroupExcluded" , "IntuneApp Windows Users Excluded")
            Write-Host "               TenantName : $($OrgValues.TenantName)" -ForegroundColor Yellow
            #Write-Host "      AgentLocalLogFolder : $($OrgValues.LogFolder)"
            Write-Host "   PublishToGroupIncluded : $($OrgValues.PublishToGroupIncluded)"
            Write-Host "   PublishToGroupExcluded : $($OrgValues.PublishToGroupExcluded)"
            Write-Host "     AppPublisherClientID : $($OrgValues.AppPublisherClientID)"
            if ($OrgValues."AppPublisherClientID" -eq "")
            {
                Write-Host "ERR: AppPublisherClientID is missing for this Org. Suggestion: Use menu option [O]rg prep to fix up this TenantName." -ForegroundColor Red;Start-sleep  3; continue
            }
            #region modules
            $checkver=$true
            $modules=@()
            $modules+="IntuneWin32App"
            $modules+="Microsoft.Graph.Devices.CorporateManagement"
            $modules+="Microsoft.Graph.Groups"
            $modules+="Microsoft.Graph.Users"
            $modules+="Microsoft.Graph.Authentication"
            $modules+="Microsoft.Graph.Identity.DirectoryManagement"
            # $modules+="Microsoft.PowerShell.ConsoleGuiTools" # for Out-ConsoleGridView (PS7 only)
            ForEach ($module in $modules)
            { 
                Write-Host "Loadmodule $($module)..." -NoNewline ; $lm_result=LoadModule $module -checkver $checkver; Write-Host $lm_result
                if ($lm_result.startswith("ERR")) {
                    Write-Host "ERR: Load-Module $($module) failed. Suggestion: Open PowerShell $($PSVersionTable.PSVersion.Major) as admin and run: Install-Module $($module)";Start-sleep  3; Return $false
                }
            }
            #endregion modules
            Write-Host "[Connect-MgGraph] Connecting to Tenant: $($OrgValues.TenantName) [You may see a sign-on popup]" -ForegroundColor Yellow
            $AppRoles = @()
            $AppRoles += "DeviceManagementManagedDevices.ReadWrite.All" # devices managed by Microsoft Intune
            $AppRoles += "DeviceManagementApps.ReadWrite.All"           # group assignments and status of apps
            $AppRoles += "Group.ReadWrite.All"                          # group properties and memberships
            $AppRoles += "User.Read.All"                                # user properties
            $AppRoles += "Domain.Read.All"                              # domain properties
            if (-not (Get-Command -Name Connect-MgGraph -ErrorAction SilentlyContinue)) {
                Write-Host "Connect-MgGraph is NOT available. You may need to install the Microsoft Graph module:"
                Write-Host 'Install-Module Microsoft.Graph -Scope CurrentUser'
                PressEnterToContinue
                exit
            }
            # Check if we are already connected
            while ($true) {
                # Check if already connected to Microsoft Graph
                $mgContext = Get-MgContext
                if ($mgContext -and $mgContext.TenantId)
                { # already connected
                    if (Get-MgDomain -DomainId $SelectedTenant.TenantId -ErrorAction SilentlyContinue)
                    { # already connected to the right tenant
                        Write-Host "Already connected to Microsoft Graph for tenant $($SelectedTenant.TenantId)." -ForegroundColor Green
                        break # continue with this connection
                    } # already connected to the right tenant
                    else
                    { # connected but to the wrong tenant
                        Write-Host "Connected to Microsoft Graph, but not the right tenant: $($SelectedTenant.TenantId)." -ForegroundColor Yellow
                        $tenantDomain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
                        Write-Host "Connect-MgGraph is connected via [$($mgContext.AppName)] Account [$($mgContext.Account)] Tenant Domain: " -NoNewline
                        Write-Host $tenantDomain -ForegroundColor Green
                        $response = AskForChoice "Choice: " -Choices @("&Use this connection","&Disconnect and try again","E&xit") -ReturnString
                        # If the user types 'exit', break out of the loop
                        if ($response -eq 'Disconnect and try again') {
                            Write-Host "Disconnect-MgGraph..."
                            Disconnect-MgGraph | Out-Null
                            PressEnterToContinue "Done. Press <Enter> to connect again."
                            Continue # loop again
                        }
                        elseif ($response -eq 'exit') {
                            return
                        }
                        else { # on to next step
                            break # continue with this connection
                        }
                    } # connected but to the wrong tenant
                } # already connected
                else
                { # not connected, try to connect
                    Write-Host "Connect-MgGraph not connected. Connecting now..."
                    PressEnterToContinue "Open a browser to an admin session on the desired tenant and press Enter."
                    Connect-MgGraph -Scopes $AppRoles -NoWelcome
                    # Confirm connection
                    $mgContext = Get-MgContext
                    if ($mgContext) {
                        Write-Host "Now connected to Microsoft Graph as $($mgContext.Account)"
                        $tenantDomain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
                        Write-Host "Tenant Domain: $tenantDomain" -ForegroundColor Green
                    } else {
                        Write-Error "Connect-MgGraph: Failed"
                    }
                } # not connected, try to connect
            } # while true forever loop
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
                # clear entries (in case we've looped around after unpublishing)
                $pkgs = @($pkgs | Where-Object PublicationStatus -ne "Package Missing") # remove any intune-only apps, they will be added by discovery
                ForEach ($pkg in $pkgs) # set the remainder to unpublished
                { # each pkg
                    $pkg.PublishedAppId = ""
                    $pkg.PublishedDate = ""
                    $pkg.PublicationStatus = "Unpublished"
                    $pkg.Required_Org = ""
                    $pkg.Required_Pkg = ""
                } # each pkg
                # Get List of apps
                $IntuneApps = Get-MgDeviceAppManagementMobileApp -All -ErrorAction Ignore
                $IntuneApps = $IntuneApps | Where-Object {$_.AdditionalProperties."@odata.type" -in ("#microsoft.graph.win32LobApp")}
                Write-Host "Published apps: " -NoNewline
                Write-Host $IntuneApps.Count -ForegroundColor Yellow
                # If subset of apps to publish, filter the IntuneApps list
                if ($bCheckAllPackages -eq $false)
                {
                    $IntuneApps = $IntuneApps | Where-Object DisplayName -in $pkgs.AppName
                    Write-Host "Filtered Apps: " -NoNewline
                    Write-Host $IntuneApps.Count -ForegroundColor Yellow
                }
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
                $msg= "[$($OrgValues.TenantName)] Select rows and click OK (Use Ctrl and Shift and Filter features to multi-select)"
                # Note: Out-GridView filtering doesn't work in PS7. So we can use Out-ConsoleGridView instead, but it's probably not worth it because it's not as good.
                #ps5
                if ($publish_skipquestion) {
                    Write-Host "Not showing app selection popup - choosing everything" -NoNewline
                    Write-Host " (for this session)" -ForegroundColor Cyan
                    $pkgselects = $pkgchoices
                } # skip question
                else {
                    $pkgselects =  @($pkgchoices | Out-GridView -PassThru -Title $msg)
                } # show question
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
                    if ($publish_skipquestion) {
                        Write-Host "Always publish" -NoNewline
                        Write-Host " (for this session)" -ForegroundColor Cyan
                        $action = 1 # publish
                    } # skip question
                    else {
                        $msg= "Select an action for these $($pkgselects.count) apps"
                        $actionchoices = @("E&xit","&Publish","&Required","&Not Required","&Unpublish","&Always Publish for this session")
                        $action=AskForChoice -message $msg -choices $actionchoices -defaultChoice 1 -showmenu:$false
                        Write-Host "Action : $($actionchoices[$action].Replace('&',''))"
                        if ($action -eq 5) {
                            $action = 1 # publish
                            $publish_skipquestion = $true
                        }
                    } # ask question
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
                        if ((-not $publish_skipquestion) -and (-not (AskForChoice)))
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
                            if ($republish_skipquestion) {
                                Write-Host "Skippping already up to date apps" -NoNewline
                                Write-Host " (for this session)" -ForegroundColor Cyan
                                $choice2 = 0
                                # Update to exclude Published
                                $pkgselects = $pkgselects | Where-Object PublicationStatus -ne "Published"
                                # convert selects to a bunch of objects (with all the properties)
                                $pkgselect_objs = $pkgs | Where-Object AppName -in $pkgselects.AppName
                            } # skip question
                            else {
                                $choice2 = AskForChoice "Skip $($pkg_published.Count) apps that are already up to date? Yes=Skip, No=Re-publish" -choices ("&Yes skip","&No republish","&Always yes for this session") -defaultChoice 0
                                if (($choice2 -eq 0) -or ($choice2 -eq 2))
                                {
                                    if ($choice2 -eq 2)
                                    {
                                        $republish_skipquestion = $true
                                    }
                                    # Update to exclude Published
                                    $pkgselects = $pkgselects | Where-Object PublicationStatus -ne "Published"
                                    # convert selects to a bunch of objects (with all the properties)
                                    $pkgselect_objs = $pkgs | Where-Object AppName -in $pkgselects.AppName
                                }
                            } # ask question
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
                                # Write-host "Note: if this isn't working you may make a one-time adjustment to the IntuneApp Publisher app"
                                # Write-host "      Entra > Applications > App registrations > All applications > [IntuneApp Publisher] > Authentication > Allow public client flows: Yes"
                                # Write-host "      https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Authentication/appId/$($OrgValues.AppPublisherClientID)"
                                # PressEnterToContinue
                            }
                            # This can fail in PS7 (without the DeviceCode option): The embedded WebView2 browser cannot be started because a runtime component cannot be loaded. For troubleshooting details, see https://aka.ms/msal-net-webview2 
                            # Download and install from Microsoft (Look for the Evergreen Standalone Installer (x64)): https://developer.microsoft.com/en-us/microsoft-edge/webview2/
                            $connect_try = $true # assume we need to connect
                            # if ($AuthToken) { # existing token found (could be multiple)
                            #     Write-Host "Connect-MSIntuneGraph: Token AuthToken found." -ForegroundColor Yellow
                            #     if (($AuthToken.ExpiresOn-(Get-Date)).TotalHours -gt 0) {
                            #         $token_claims = Get-TokenDetailsFromHeader $AuthToken
                            #         if ($token_claims.TenantId -eq (Get-MgContext).TenantId) {
                            #             Write-Host "Connect-MSIntuneGraph: Token is valid for this Org. Using existing token." -ForegroundColor Yellow
                            #             $connect_try = $false
                            #         } else {
                            #             Write-Host "Connect-MSIntuneGraph: Token ($($token_claims.User)) is NOT valid for this Org ($($OrgValues.TenantName)). Reconnecting." -ForegroundColor Yellow
                            #             $connect_try = $true
                            #         }
                            #     }
                            # } # existing token found
                            Remove-Variable -Name AuthToken -ErrorAction Ignore
                            if ($connect_try) {
                                if ($DeviceCode) {
                                    Write-Host "[Connect-MSIntuneGraph] Connecting to Tenant: $($OrgValues.TenantName) with DeviceCode [You may see a sign-on popup <OR> subsequent directions for web sign-on]" -ForegroundColor Yellow
                                    #$AuthToken = Connect-MSIntuneGraph -TenantID $OrgValues.TenantName -ClientID $OrgValues.AppPublisherClientID -RedirectUri "https://login.microsoftonline.com/common/oauth2/nativeclient" -DeviceCode
                                    $AuthToken = Connect-MSIntuneGraph -TenantID $SelectedTenant.TenantId -ClientID $SelectedTenant.AppId -DeviceCode
                                }
                                Else {
                                    Write-Host "[Connect-MSIntuneGraph] Connecting to Tenant: $($OrgValues.TenantName) [You may see a sign-on popup <OR> subsequent directions for web sign-on]" -ForegroundColor Yellow
                                    # $AuthToken = Connect-MSIntuneGraph -TenantID $OrgValues.TenantName -ClientID $OrgValues.AppPublisherClientID -RedirectUri "https://login.microsoftonline.com/common/oauth2/nativeclient"
                                    $AuthToken = Connect-MSIntuneGraph -TenantID $SelectedTenant.TenantId -ClientID $SelectedTenant.AppId -ClientCert $AppCert
                                }
                            }
                            if ($AuthToken)
                            {
                                #Write-Host "Connected OK for: $(($AuthToken.ExpiresOn-(Get-Date)).TotalHours.toString("0.#")) hrs"
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
                                Write-Host "  PublishToGroupIncluded : $($OrgValues.PublishToGroupIncluded)" -NoNewLine
                                Write-Host  $publish_option_msg -foregroundcolor Cyan
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
                                }
                                $verbosepackager = $false
                                # Optional args
                                if($IntuneWinAppUtilPath) {$SplatArgs.IntuneWinAppUtilPath = $IntuneWinAppUtilPath}
                                # Create intunewin
                                $IntuneWinFile = New-IntuneWin32AppPackage @SplatArgs -Verbose:$verbosepackager 
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
                            #Try {
                                # IntuneWin32App v1.4.4 and prior (https://github.com/MSEndpointMgr/IntuneWin32App/blob/master/ReleaseNotes.md)
                            #    $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "W10_1809"
                            #}
                            #catch {
                                $RequirementRule = $null
                            #}
                            #if (-not $RequirementRule) {
                                # IntuneWin32App v1.4.5 and later
                                $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "AllWithARM64" -MinimumSupportedWindowsRelease "W10_1809"
                            #}
                            $AdditionalRequirementRule = New-IntuneWin32AppRequirementRuleScript -ScriptFile "$($pkg.Fullpath)\IntuneUtils\intune_requirements.ps1" -StringOutputDataType -StringComparisonOperator equal -StringValue "REQUIREMENTS_MET" -ScriptContext $pkg.SystemOrUser
                            # Convert image file to icon
                            $IntuneIcon = New-IntuneWin32AppIcon -FilePath "$($pkg.Fullpath)\intune_icon.png"
                            # Install and Uninstall commands
                            $InstallCommandLine   = "Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $($intune_install_cmd) -quiet"
                            $UninstallCommandLine = "Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $($intune_uninstall_cmd) -quiet"
                            # Create intunewin zip file in temp folder along with in-mem script files for intune: end
                            #### AppDescription
                            if ($pkg.AppDescription) {
                                $AppDescription=($pkg.AppDescription -split "`r?`n") -join "`r`n " # normalize newlines
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
                            if (('' -ne $pkg.InformationURL) -and ($null -ne $pkg.InformationURL) -and (-not ($pkg.InformationURL -match $pattern))) {
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
                                $strReturn,$MgGroup = MgGroupCreate $groupname
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
                                    $strReturn,$MgGroup = MgGroupCreate $groupname
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
                            $strReturn,$MgGroup = MgGroupCreate $groupname
                            Write-Host $strReturn
                            if (-not $MgGroup)
                            {
                                Write-Host "Couldn't find group with that name. App will be available, but will not reference the group." -ForegroundColor Red
                                PressEnterToContinue
                            }
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
                                $strReturn,$MgGroup = MgGroupCreate $groupname
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
                    #$Orglist[$choice].Packages = $pkgscount.count
                    #$Orglist[$choice]."Last Publish Date" = get-date -format "yyyy-MM-dd_HH:mm:ss"
                    if ($apps_touched_count -gt 0)
                    { # something changed
                        #$Orglist[$choice]."Last Publish Count" = $apps_touched_count
                    } # something changed
                    # Do
                    # { # try exporting
                    #     Try {
                    #         $orglist | Export-Csv $orglistcsv -NoTypeInformation -Encoding $utf8Encoding
                    #         Break
                    #     }
                    #     Catch {
                    #         Write-Host "Couldn't export to CSV, make sure it's not open/locked: $(Split-Path $orglistcsv -Leaf)"
                    #         PressEnterToContinue
                    #     }
                    # } # try exporting
                    # Until ($true)
                } # apps selected
                #endregion update orgcsv
                Write-Host "Check apps at the Intune Windows Apps (Admin center):"
                Write-Host "https://intune.microsoft.com/?ref=AdminCenter#view/Microsoft_Intune_DeviceSettings/AppsWindowsMenu/~/windowsApps" -ForegroundColor Green
                #$retVal=
                if ($showmenu_publish_skipquestion) {
                    Write-Host "Done with $($SelectedTenant.TenantId) and not re-checking tenant" -NoNewline
                    Write-Host " (for this session)" -ForegroundColor Cyan
                } # skip question
                else {
                    $showmenu_publish = AskForChoice -message "Done. Re-check Tenant for these apps? [No = Done with $($SelectedTenant.TenantId)]" -choices ("&Yes","&No","&Always no for this session") -defaultChoice 1
                    if ($showmenu_publish -eq 2) { # always no
                        $showmenu_publish = $false
                        $showmenu_publish_skipquestion = $true
                    }
                    elseif ($showmenu_publish -eq 1) { # no
                        $showmenu_publish = $false
                    }
                    else { # yes
                        $showmenu_publish = $true
                    }
                } # ask question
            } until (-not $showmenu_publish)
            # Disconnect from Connect-MSIntuneGraph
            Disconnect-MgGraph -ErrorAction Ignore | Out-Null
            Remove-Variable -Name AuthToken -ErrorAction Ignore
            #endregion Tenant Actions


            # Update LastChecked in settings
            $SelectedTenant.LastChecked = $ThisDate
            ($Tenants | Where-Object TenantId -eq $TenantId).LastChecked = $ThisDate
            $Tenants | Sort-Object TenantId | Export-Csv -Path $TenantsCSV -Encoding UTF8 -NoTypeInformation -Force
            If ($SelectedTenant.TenantId -eq $settings.TenantId)
            { # also update settings If this tenant is the one in settings
                $settings.LastChecked = $ThisDate
            }
        } # each tenant to check
        If (-not $ConnectOK)
        { # Not connected - A failure happened
            Continue # back to menu If connection failed
        } # Not connected
        Write-Host "Done with $($SelectedTenants.Count) Tenant(s)" -ForegroundColor Green
        Start-Sleep 3
    } # Publish to Tenants
} until (($choice -eq "X") -or $AutoMenuChoice) # loop until exit
#region    ---- Transcript Save
$TranscriptsFolder = "$($scriptDir)\Transcripts"
if (-Not(Test-Path -Path $TranscriptsFolder -PathType Container)) {
    New-Item -Path $TranscriptsFolder -ItemType Directory -Force | Out-Null
}
$MaxTranscripts = 1000 # keep last 1000 transcripts, delete older ones (default)
If (-not [double]::TryParse($settings.MaxTranscripts, [ref]$MaxTranscripts)) {
    Write-Host "Failed to parse MaxTranscripts: '$($settings.MaxTranscripts)'. Defaulting to 1000 transcripts." -ForegroundColor Yellow
}
$retObj = FolderPruneToCount -Folder $TranscriptsFolder -MaxCount $MaxTranscripts -Filter "*_transcript.txt"
if ($retObj.CountPruned -gt 0) {
    Write-Host "Pruned $($retObj.CountPruned) old transcript(s) ($($retObj.PrunedMsg)) to keep only the most recent $MaxTranscripts transcripts." -ForegroundColor Yellow
}
Write-Host "Done"
# If ($autoMenuChoice -ne "") {
#     Write-Host "$($scriptName) -AutoMenuChoice $($AutoMenuChoice) (5s)"
#     Start-Sleep 5
# }
Stop-Transcript | Out-Null
$date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$TranscriptTarget = "$($TranscriptsFolder)\$($scriptBase)_$($date)_transcript.txt"
New-Item (Split-Path $TranscriptTarget -Parent) -ItemType Directory -Force | Out-Null # Make folder
Move-Item $TranscriptTemp $TranscriptTarget -Force
Copy-item $TranscriptTarget "$($scriptDir)\$($scriptBase) Transcript.txt" -Force # also copy to script folder
#endregion ---- Transcript Save
