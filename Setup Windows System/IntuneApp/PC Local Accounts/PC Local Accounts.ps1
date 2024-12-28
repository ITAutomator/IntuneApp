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
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {Write-Host "Err 99: Couldn't find ITAutomator.psm1";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host ("$scriptName        Computer:$env:computername User:$env:username PSver:"+($PSVersionTable.PSVersion.Major))
Write-host "Mode: $($mode)"
Write-Host ""
Write-Host " Create local accounts: " -NoNewline
Write-Host "$($scriptBase).csv" -ForegroundColor Green
Write-Host "Disable named accounts: " -NoNewline
Write-Host "$($scriptBase) (To Disable).csv" -ForegroundColor Green
Write-Host ""
Write-Host "In the CSV, use the EncryptionKey column to obfuscate the password as follows:"
Write-Host "-----------------------------------------------------------------------------"
Write-Host " Use (without the quote marks) For This "
Write-Host "------------------------------ ----------------------------------------------"
Write-Host "                   '<Encrypt>' (with the angle brackets) to interactively enter a key and get the obfuscated password."
Write-Host "                    '<Random>' to generate a random, unique password, different on every computer (pw value is ignored)"
Write-Host "           'my_encryption_key' to use this key against an obfuscated password"
Write-Host "                            '' to use the password as-is without obfuscation"
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Passwords in CSV are obfuscated but not encrypted (unless <Random> is used)."
Write-Host "DELETE AND PURGE THE CSV AFTER RUNNING."
Write-Host "-----------------------------------------------------------------------------"
If (-not(IsAdmin))
    {
    $ErrOut=101; Write-Host "Err $ErrOut : This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)";Start-Sleep -Seconds 3; Exit($ErrOut)
    }
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
####### Users to Create
Write-Host "Users to Create"
Write-Host "---------------"
$csvFile = "$($scriptDir)\$($scriptBase).csv"
if (-not (Test-Path ($csvFile))) { ######### Template
    '"Username","DisplayName","Description","Groups","EncryptionKey","Password","Comment"' | Add-Content $csvFile
}
$csvFile=@(Import-Csv $csvFile)
$icount = 0
ForEach ($entry in $csvFile) {
    $icount += 1
    Write-Host "$($icount): " -NoNewline
    Write-Host $entry.Username -ForegroundColor Green -NoNewline
    Write-Host " $($entry.Description) [Groups: $($entry.Groups)]"
    $Description = $entry.Description
    $MaxLen = 48
    if ($Description.Length -gt $MaxLen) {
        Write-Host "Warning: Max Description length ($($MaxLen) exceeded) and will be cropped" -ForegroundColor Yellow
        Write-Host "Before: $($Description)"
        $Description = CropString -StringtoCrop $Description -MaxLen $MaxLen
        Write-Host " After: $($Description)"
        Start-Sleep 5
    }
    # Remove the existing user
    if (Get-LocalUser -Name $entry.Username -ErrorAction SilentlyContinue) {
        Remove-LocalUser -Name $entry.Username
    }
    # get the password
    if ($entry.EncryptionKey -eq "") {
        $password = $entry.Password
    }
    elseif ($entry.EncryptionKey -eq "<Random>") {
        # Define the character set (uppercase, lowercase, numbers, special characters)
        $charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()'
        $passwordLength = 15
        # Generate a random password
        $password = -join ((1..$passwordLength) | ForEach-Object { $charset[(Get-Random -Minimum 0 -Maximum $charset.Length)] })
    }
    elseif ($entry.EncryptionKey -eq "<Encrypt>") { # prompt to create an EncryptionKey
        if ($mode_auto) {
            Write-Host "Warning: EncryptionKey is set to <Encrypt>, but the script is non-interactive.  Run intractively to correct this."
            $password = $entry.Password
        }
        else {
            Write-Host "About to encrypt password: " -NoNewline
            Write-host $entry.Password -ForegroundColor Green
            $encryptkey = Read-Host "Enter any encyption key to obfuscate password in CSV (5 to 10 character string)"
            $passwordencrypted = EncryptString $entry.Password -KeyAsString $encryptkey
            Write-Host "Put these values in the CSV file:"
            Write-Host "---------------------------------"
            Write-Host "     Password : " -NoNewline
            Write-host $passwordencrypted -ForegroundColor Green
            Write-Host "EncryptionKey : " -NoNewline
            Write-host $encryptkey -ForegroundColor Green
            Write-Host "---------------------------------"
            $password = $entry.Password
            PressEnterToContinue
        } # interactive
    } # encrypt
    else { # use the EncryptionKey from the CSV
        $password = DecryptString $entry.Password -KeyAsString $entry.EncryptionKey
    } # haskey
    $passwordsecstring = ConvertTo-SecureString $password -AsPlainText -Force
    # Create the local user
    New-LocalUser -Name $entry.Username -Password $passwordsecstring -FullName $entry.DisplayName -Description $Description -AccountNeverExpires | Out-Null
    # Optional: Add the user to a group (e.g., Administrators)
    $groups = @($entry.Groups -split ",")
    ForEach ($group in $groups){
        Add-LocalGroupMember -Group $group -Member $entry.Username
    }
}
Write-Host "---------------"
####### Users to Disable
Write-Host "Users to Disable"
Write-Host "----------------"
$csvFile = "$($scriptDir)\$($scriptBase) (To Disable).csv"
if (-not (Test-Path ($csvFile))) { ######### Template
    '"Username"' | Add-Content $csvFile
}
$csvFile=@(Import-Csv $csvFile)
$icount = 0
ForEach ($entry in $csvFile) {
    $icount += 1
    Write-Host "$($icount): $($entry.Username)" -NoNewline
    $acct = Get-LocalUser $entry.Username -ErrorAction SilentlyContinue
    if ($null -eq $acct) {Write-Host " ... Not found [OK]"}
    else {$acct|Disable-LocalUser; Write-Host " ... Disabled [OK]"}
}
Write-Host "---------------"
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

## Show Local admins (report only)
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
}
if ($account_warnings -eq 0)
{
    Write-Host "OK: No vulnerable local admin accounts"
}
else
{
    $msg_accounts=$msg_accounts.Trim(",")
    $ErrCode,$ErrMsg=ErrorMsg -ErrCode 202 -ErrMsg "Vulnerable local admin accounts: $($msg_accounts)"
}

#######################
## Main Procedure End
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "Done"
if ($mode_auto) {PauseTimed -quiet} else {PauseTimed}
Return