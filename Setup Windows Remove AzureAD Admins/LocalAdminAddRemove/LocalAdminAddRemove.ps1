###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main 
Param ## provide a comma separated list of switches
	(
    [string] $action = "Menu", # No argument = show a menu of choices
    [string] $localuser = "$($env:userdomain)\$($env:username)" # No argument = show a menu of choices
	)
Function LocalAdmins
{
    ## Show Local admins
    $administratorsAccount = Get-WmiObject Win32_Group -filter "LocalAccount=True AND SID='S-1-5-32-544'" 
    $administratorQuery = "GroupComponent = `"Win32_Group.Domain='" + $administratorsAccount.Domain + "',NAME='" + $administratorsAccount.Name + "'`"" 
    $locadmins_wmi = Get-WmiObject Win32_GroupUser -filter $administratorQuery | Select-Object PartComponent
    $locadmins = @()
    $azadmins = @()
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
        $domainname = $user1.Split("\")[0]
        $accountname = $user1.Split("\")[1]
        $locadmin_info = Get-LocalUser $accountname -ErrorAction SilentlyContinue
        if ($locadmin_info)
        {
            if (-not ($locadmin_info.Enabled))
            {
                #$Status = " [Disabled]"
            }
        }
        $count +=1
        $locadmins+="$($user1)$($Status)"
        Write-Output "$($user1)$($Status)"
        #### is this an AzureAD Admin that's enabled?
        if (($domainname -eq "AzureAD") -and (-not ($locadmin_info.Enabled)))
        {
            #$azadmins += $user1
        }
        ####
    }
}
Function Show-Notification
{
    # Shows a toast notification (Note: only shows to the current user)
    # Show-Notification -ToastTitle $ttl -ToastText $txt (Toast notifcations are limited to 6 lines of 45 chars)
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle, # 2 lines of text, long lines will get split automatically at 45 chars or use a `n to split manually
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText   # 4 lines of text (or 6 if there's no title)
    )
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text|Where-Object {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text|Where-Object {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($ToastText)) > $null
    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)
    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "PowerShell"
    $Toast.Group = "PowerShell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)
    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}
### Main function header - Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
# Get-Command -module ITAutomator  ##Shows a list of available functions

#######################
## Main Procedure Start
#######################

$quiet=$true
Write-Host "-----------------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Add / remove current user as local admin."
Write-Host ""
$ShowMenu=($action -eq "Menu")
Do
{ # Choice of Action
    If ($ShowMenu)
    { # User wanted a menu
        # Gather info
        $localadmins=LocalAdmins
        if ($localadmins -contains "$localuser" ) {$IsLocalAdmin ="Yes"} else {$IsLocalAdmin ="No"} 
        if ($warning -eq "") {$warning_text = "OK"} Else {$warning_text = $warning}
        # Gather info
        Write-Host "-----------------------------------------------------------------------------------"
        Write-Host "                             Local User: $($localuser)" -NoNewline
        if ($localuser -eq "$($env:userdomain)\$($env:username)") {
            Write-Host ""}
        Else {
            Write-Host " (running user is $($env:userdomain)\$($env:username))"
        }
        Write-Host "                           IsLocalAdmin: $($IsLocalAdmin)"
        Write-Host ""
        Write-Host "Choose an action for " -NoNewline
        Write-Host $scriptName -ForegroundColor Green
        Write-Host "Note: Can be passed as an option eg: $($scriptName) -Action AdminAdd"
        Write-Host ""
        Write-Host "A AdminAdd           to add local admin rights indefinitely."
        Write-Host "R AdminRemove        to remove local admins."
        Write-Host "X Exit"
        Write-Host "-----------------------------------------------------------------------------"
        $choices=@("&AdminAdd","Admin&Remove","E&xit")
        $choice = AskForChoice -Message "Choice?" -Choices $choices -DefaultChoice 2 -ReturnString
        If ($choice -eq "Exit") {
            Start-Sleep 1
            Exit        
        }
        $DoAction=$choice
    } # User wanted a menu
    Else
    { # No menu
        $DoAction=$Action
    } # No menu
    ### Respond to DoAction
    Write-Host "$($scriptName) -action $($DoAction) -Localuser $($Localuser)" -ForegroundColor Yellow -NoNewline
    Write-Host " [running user is $($env:userdomain)\$($env:username)]"
    ### Respond to DoAction
    if ($DoAction -eq "AdminRemove")
    { #AdminRemove
        $removed=$false
        If (-not(IsAdmin))
        { # elevate
            Write-Host "This action must be run as admin.  Elevating..."
            Start-Sleep 2
            # rebuild the argument list
            $argumentlist ="-ExecutionPolicy Bypass -File `"$($scriptFullname)`" -Action $($DoAction) -Localuser $($localuser)"
            # rebuild the argument list
            Try
            {
                Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
            }
            Catch {
                Write-Host "Failed to start PowerShell Elevated" -ForegroundColor Yellow
                Start-Sleep 3
                #Throw "Failed to start PowerShell elevated"
            }
        } # elevate
        Else
        { #Isadmin
            $local_folder="$($env:ALLUSERSPROFILE)\$($scriptBase)"
            If (Test-Path $local_folder)
            {# exists
                Write-Host "Removing: $($local_folder)'"
                Remove-Item $local_folder -Recurse -Force
            }
            Write-Host "AdminRemove: $localuser" -ForegroundColor Yellow
            Remove-LocalGroupMember -Group "Administrators" -Member "$localuser" -ErrorAction Ignore
            $removed=$true
        } #Isadmin
        if (($localuser -eq "$($env:userdomain)\$($env:username)") -and $removed)
        { # only notify if this is running as the current user
            Write-Host "Sending toast notification."
            $ttl = ""
            $txt = ""
            $ttl += "Your Local Admin access has been removed.`n"
            $ttl += "`n"
            $txt += "Username: $localuser`n"
            $txt += "By: $($scriptName)`n"
            $txt += "`n"
            $txt += "$($Globals.msg_footer)`n"
            Show-Notification  -ToastTitle $ttl -ToastText $txt
            Start-Sleep 3
        }# only notify if this is running as the current user
    } #AdminRemove
    if ($DoAction -eq "AdminAdd")
    { #AdminAdd
        If (-not(IsAdmin))
        { # elevate
            Write-Host "This action must be run as admin.  Elevating..."
            Start-Sleep 2
            # rebuild the argument list
            $argumentlist ="-ExecutionPolicy Bypass -File `"$($scriptFullname)`" -Action $($DoAction) -Localuser $($localuser)"
            # rebuild the argument list
            Try
            {
                Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
            }
            Catch {
                Write-Host "Failed to start PowerShell Elevated" -ForegroundColor Yellow
                Start-Sleep 3
                #Throw "Failed to start PowerShell elevated"
            }
            #Exit
        } # elevate
        Else
        { #Isadmin
            Write-Host "AdminAdd: $localuser" -ForegroundColor Yellow
            Add-LocalGroupMember -Group "Administrators" -Member "$localuser" -ErrorAction Ignore
            Start-Sleep 3
        } #Isadmin
    } #AdminAdd
} # Choice of Action
Until (-not ($ShowMenu))
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done. (Admin changes take effect on next logon.) "
PauseTimed -secs 3 -quiet