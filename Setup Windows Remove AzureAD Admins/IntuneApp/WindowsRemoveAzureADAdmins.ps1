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
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {Write-Host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
######################
$OS= Get-OSVersion
Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username OS:"+ $OS[1]+" PSver:"+($PSVersionTable.PSVersion.Major)) 
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host "Removes AzureAD users from (local) Administrators group."
Write-Host "-----------------------------------------------------------------------------"
###
Write-Host "Local Admin Accounts on this machine:"
## Vulnerable account names
$vuln_accounts=@()
$vuln_accounts+="Administrator"
$vuln_accounts+="Admin"
$vuln_accounts+="Admin1"
$vuln_accounts+="User"
$vuln_accounts+="User1"
$vuln_accounts+="Scanner"
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
            $Status = " [Disabled]"
        }
    }
    if ($Status -eq "")
    {
        if ($vuln_accounts -contains $accountname)
        {
            $Status = " [Vulnerable account name]"
            $account_warnings += 1
            $msg_accounts+=",$($accountname)"
        }
    }
    $count +=1
    $locadmins+="$($user1)$($Status)"
    Write-Host "  Admin $($count): $($user1)$($Status)"
    #### is this an AzureAD Admin that's enabled?
    if (($domainname -eq "AzureAD") -and (-not ($locadmin_info.Enabled)))
    {
        $azadmins += $user1
    }
    ####
}
Write-Host "-----------------------------------------------------------------------------"
## Vulnerable
if ($account_warnings -eq 0)
{
    Write-Host "OK: No local admin accounts have vulnerable names."
}
else
{
    $msg_accounts = $msg_accounts.Trim(",")
    $ErrCode,$ErrMsg = ErrorMsg -ErrCode 202 -ErrMsg "Check Vulnerable account names: $($msg_accounts)"
}
## LocalAdmins
if ($azadmins.count -eq 0)
{
    Write-Host "OK: No AzureAD accounts are local admin"
}
Else
{
    Write-Host "Will Remove from Administrators:"
    ForEach ($azadmin in $azadmins) {
        Write-Host  "  $($azadmin)" -ForegroundColor Yellow
    }
    Write-Host "-----------------------------------------------------------------------------"
}
if ($azadmins.count -gt 0)
{
    if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
    If (-not(IsAdmin)) {
        $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
    }
    Write-Host "Removing from Administrators: (Effective for NEXT logon)"
    ForEach ($azadmin in $azadmins) {
        Write-Host  "  $($azadmin) [REMOVED AS ADMIN]"
        Remove-LocalGroupMember -Group "Administrators" -Member $azadmin -Confirm:$False
    }
}
#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}