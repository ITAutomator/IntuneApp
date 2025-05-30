#region .NET
############ Add a .NET Framework type: namespace Resoultion class Displays
$pinvokeCode = @" 
using System; 
using System.Runtime.InteropServices; 
using System.Collections.Generic;
namespace Resolution 
{ 
    [StructLayout(LayoutKind.Sequential)] 
    public struct DEVMODE1 
    { 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmDeviceName; 
        public short dmSpecVersion; 
        public short dmDriverVersion; 
        public short dmSize; 
        public short dmDriverExtra; 
        public int dmFields; 
        public short dmOrientation; 
        public short dmPaperSize; 
        public short dmPaperLength; 
        public short dmPaperWidth; 
        public short dmScale; 
        public short dmCopies; 
        public short dmDefaultSource; 
        public short dmPrintQuality; 
        public short dmColor; 
        public short dmDuplex; 
        public short dmYResolution; 
        public short dmTTOption; 
        public short dmCollate; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmFormName; 
        public short dmLogPixels; 
        public short dmBitsPerPel; 
        public int dmPelsWidth; 
        public int dmPelsHeight; 
        public int dmDisplayFlags; 
        public int dmDisplayFrequency; 
        public int dmICMMethod; 
        public int dmICMIntent; 
        public int dmMediaType; 
        public int dmDitherType; 
        public int dmReserved1; 
        public int dmReserved2; 
        public int dmPanningWidth; 
        public int dmPanningHeight; 
    }; 
	
	[Flags()]
	public enum DisplayDeviceStateFlags : int
	{
		/// <summary>The device is part of the desktop.</summary>
		AttachedToDesktop = 0x1,
		MultiDriver = 0x2,
		/// <summary>The device is part of the desktop.</summary>
		PrimaryDevice = 0x4,
		/// <summary>Represents a pseudo device used to mirror application drawing for remoting or other purposes.</summary>
		MirroringDriver = 0x8,
		/// <summary>The device is VGA compatible.</summary>
		VGACompatible = 0x10,
		/// <summary>The device is removable; it cannot be the primary display.</summary>
		Removable = 0x20,
		/// <summary>The device has more display modes than its output devices support.</summary>
		ModesPruned = 0x8000000,
		Remote = 0x4000000,
		Disconnect = 0x2000000
	}
	[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
	public struct DISPLAY_DEVICE 
	{
		  [MarshalAs(UnmanagedType.U4)]
		  public int cb;
		  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)]
		  public string DeviceName;
		  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)]
		  public string DeviceString;
		  [MarshalAs(UnmanagedType.U4)]
		  public DisplayDeviceStateFlags StateFlags;
		  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)]
		  public string DeviceID;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)]
		  public string DeviceKey;
	}
    class User_32 
    { 
        [DllImport("user32.dll")] 
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
        [DllImport("user32.dll")] 
        public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 
		[DllImport("user32.dll")]
		public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);
        public const int ENUM_CURRENT_SETTINGS = -1; 
        public const int CDS_UPDATEREGISTRY = 0x01; 
        public const int CDS_TEST = 0x02; 
        public const int DISP_CHANGE_SUCCESSFUL = 0; 
        public const int DISP_CHANGE_RESTART = 1; 
        public const int DISP_CHANGE_FAILED = -1; 
    } 
    public class Displays
    {
		public static IList<string> GetDisplayNames()
		{
			var returnVals = new List<string>();
			for(var x=0U; x<1024; ++x)
			{
				DISPLAY_DEVICE outVar = new DISPLAY_DEVICE();
				outVar.cb = (short)Marshal.SizeOf(outVar);
				if(User_32.EnumDisplayDevices(null, x, ref outVar, 1U))
				{
					returnVals.Add(outVar.DeviceName);
				}
			}
			return returnVals;
		}
		
		public static string GetCurrentResolution(string deviceName)
        {
            string returnValue = null;
            DEVMODE1 dm = GetDevMode1();
            if (0 != User_32.EnumDisplaySettings(deviceName, User_32.ENUM_CURRENT_SETTINGS, ref dm))
            {
                returnValue = dm.dmPelsWidth + "," + dm.dmPelsHeight;
            }
            return returnValue;
        }
		
		public static IList<string> GetResolutions()
		{
			var displays = GetDisplayNames();
			var returnValue = new List<string>();
			foreach(var display in displays)
			{
				returnValue.Add(GetCurrentResolution(display));
			}
			return returnValue;
		}
		
        private static DEVMODE1 GetDevMode1() 
        { 
            DEVMODE1 dm = new DEVMODE1(); 
            dm.dmDeviceName = new String(new char[32]); 
            dm.dmFormName = new String(new char[32]); 
            dm.dmSize = (short)Marshal.SizeOf(dm); 
            return dm; 
        } 
    }
} 
"@
Add-Type $pinvokeCode
#endregion .NET
#region Functions
Function GetDisplayMonitorResolutions {
    $res = [Resolution.Displays]::GetResolutions()
    $res_str = @()
    $res_str +=  $res | ForEach-Object {if ($_) {([string]$_).Replace(",","x")}}
    $res_str
}
Function GetDisplayMonitors{
    $strReturn = @()
    try {
        $MonsObj = Get-WmiObject WmiMonitorID -Namespace root\wmi -ErrorAction Stop  |  
            ForEach-Object {
                [PSCustomObject]@{
                Manufacturer   = [System.Text.Encoding]::ASCII.GetString($_.ManufacturerName).Trim(0x00)
                Name           = [System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName).Trim(0x00)
                Serial         = [System.Text.Encoding]::ASCII.GetString($_.SerialNumberID).Trim(0x00)
            }
        }
        $strReturn += $MonsObj | ForEach-Object {"$($_.Name) [Serial $($_.Serial)]"}
    }
    Catch {
        $strReturn += "[Monitor model detection requires run as admin]"
    }
    
    $strReturn
}
Function GetDisplayControllers {
    $controllers = @()
    $controllers += Get-WmiObject win32_videocontroller | Select-Object -ExpandProperty caption
    $controllers
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
Function IsLocalAdmin
{ ## if the user is in the local admins group
  $null -ne (whoami /groups /fo csv |
  ConvertFrom-Csv |
  Where-Object { $_.SID -eq "S-1-5-32-544" })
}
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
        # is this an AzureAD Admin that's enabled?
        if (($domainname -eq "AzureAD") -and (-not ($locadmin_info.Enabled)))
        {
            #$azadmins += $user1
        }
    }
}
Function RegGet ($keymain, $keypath, $keyname)
{
    #########
    ## $ver=RegGet "HKCR" "Word.Application\CurVer"
    ## $ver=RegGet "HKLM" "System\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections"
    #########
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
#endregion Functions
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName}
################################ Main Code Area
$scriptName     = "PC Info.ps1"
#$scriptVer      = "v2023-11-20"
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
################################
Write-Host "$($scriptName) $($scriptVer)" -ForegroundColor Yellow
Write-Host "  Gathering registry info..."
## Read Teamviewer ID from registry
$tvid = RegGet "HKLM" "SOFTWARE\WOW6432Node\TeamViewer" "ClientID"
If ($tvid -eq "") {$tvid = RegGet "HKLM" "SOFTWARE\TeamViewer" "ClientID"}
$tvaccnt = RegGet "HKLM" "SOFTWARE\WOW6432Node\TeamViewer" "OwningManagerAccountName"
If ($tvaccnt -eq "") {$tvaccnt = RegGet "HKLM" "SOFTWARE\TeamViewer" "OwningManagerAccountName"}
$TeamviewerID = [string]$tvid
If (($null -ne $tvaccnt) -and ($tvaccnt -ne "")) {$TeamviewerID +=" ($($tvaccnt))"}
Write-Host "  Gathering network info..."
# Networks
$networks=@()
$NetConnectionProfiles = Get-NetConnectionProfile | Sort-Object InterfaceIndex
ForEach ($NetConnectionProfile in $NetConnectionProfiles)
{
    $NetIPAddress        = Get-NetIPAddress -InterfaceIndex $NetConnectionProfile.InterfaceIndex -AddressFamily IPV4
    $NetAdapter          = Get-NetAdapter   -InterfaceIndex $NetConnectionProfile.InterfaceIndex
    #
    $network =    $NetIPAddress.IPAddress
    $network += " $($NetConnectionProfile.InterfaceAlias) $($NetConnectionProfile.Name) ($($NetConnectionProfile.NetworkCategory))"
    $network += " [$($NetAdapter.MacAddress)]"
    #
    $networks += $network
}
Write-Host "  Gathering disk info..."
# Disks
$disks=@()
$Getdisks = Get-disk | Sort-Object Number
ForEach ($Getdisk in $Getdisks)
{
    $disk = $Getdisk.FriendlyName
    $disk += " " + ($Getdisk.Size / 1GB).ToString("0.# GB")+""
    #
    $volumes = $Getdisk | Get-Partition | Get-Volume | Where-Object DriveLetter -ne $null
    ForEach ($volume in $volumes)
    {
        $disk += " [" + $volume.DriveLetter.ToString().ToUpper() + ": "
        $disk += ($volume.SizeRemaining / 1GB).ToString("#.# GB")+" free of "
        $disk += ($volume.Size / 1GB).ToString("#.# GB")+"]"
    }
    $disks += $disk
}
Write-Host "  Gathering public ip info..."
# Public IP
$PublicIP_Info = Invoke-RestMethod http://ipinfo.io/json -UseBasicParsing
Write-Host "  Gathering fast boot and notification info..."
# Windows settings
[string]$reg_hiberbootenabled = RegGet "HKLM" "SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled"
[string]$reg_toastenabled     = RegGet "HKCU" "SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled"
if ($reg_hiberbootenabled -eq "") {$reg_hiberbootenabled = "(blank)"}
if ($reg_toastenabled -eq "")     {$reg_toastenabled     = "(blank)"}
##
if ($reg_hiberbootenabled -eq "1") {$reg_hiberbootenabled_desc="Warning: Fast Boot is enabled"} else {$reg_hiberbootenabled_desc="OK: Fast Boot is disabled (shutdown same as restart)"}
if ($reg_toastenabled -eq "0") {$reg_toastenabled_desc="Warning: System notifications are disabled for current user"} else {$reg_toastenabled_desc="OK: System notifications are enabled for current user"} 
Write-Host "  Gathering last boot info..."
# PC boot
$pc = Get-WmiObject win32_operatingsystem | Select-Object CSName, @{N="LastBootUpTime";E={[System.Management.ManagementDateTimeConverter]::ToDateTime($_.LastBootUpTime)}}
$days_fromstartup = ((Get-Date)-($pc.LastBootUpTime)).TotalDays
Write-Host "  Gathering local admin info..."
# Local Admins
$localuser = "$($env:userdomain)\$($env:username)" 
$localadmins = LocalAdmins
$IsLocalAdmin = if (IsLocalAdmin) {"YES"} else {"NO"}
$IsAdmin      = if (IsAdmin)      {"YES"} else {"NO"}
Write-Host "  Gathering azure ad info..."
# Azure Info
$dsregcmd = dsregcmd /status | Where-Object { $_ -match ' : ' } | ForEach-Object { $_.Trim() } | ConvertFrom-String -PropertyNames 'Name','Value' -Delimiter ' : '
Write-Host "  Gathering computer info..."
# PC Info
$computerInfo = Get-ComputerInfo
if ($computerInfo.BiosSerialNumber)
{$sn = $computerInfo.BiosSerialNumber}
else
{$sn = $computerInfo.BiosSeralNumber} # oddly was misspelled up to recent versions of windows
Write-Host "  Gathering display info..."
# Display
$dispctrls  = GetDisplayControllers
$dispmons   = GetDisplayMonitors
$dispmonres = GetDisplayMonitorResolutions
$displayinfo = "$($dispctrls -join ", "):$($dispmons -join ", "):$($dispmonres -join ", ")"
Write-Host "  Gathering winget info..."
# winget
Try {$wingetver = & winget -v}
Catch {$wingetver = "(none)"}
Write-Host "  Gathering bitlocker info..."
# BitLocker
$OSDrive = $env:SystemDrive
# $bitlocker = Get-BitLockerVolume -MountPoint $OSDrive # requires elevation
$bitlocker = (New-Object -ComObject Shell.Application).NameSpace($OSDrive).Self.ExtendedProperty('System.Volume.BitLockerProtection')
if ($bitlocker -eq 1) {$bitlockerstatus = "Encrypted"}
elseif ($bitlocker -eq 3) {$bitlockerstatus = "Encryption in progress"}
else {$bitlockerstatus = "Not encrypted"}
$bitlockerstatus += " $($OSDrive) ($($bitlocker))"
Write-Host "Done gathering info."
####    
$objProps = [ordered]@{
    Computername  = $computerInfo.CsName
    ComputerSN    = $sn
    OSInfo        = "$($computerInfo.OsName) ($($computerInfo.OSDisplayVersion)) v$($computerInfo.OsVersion) $($computerInfo.OsArchitecture)"
    Model         = "$($computerInfo.CsManufacturer) $($computerInfo.CsModel)"
    CPU           = $computerinfo.CsProcessors[0].Name + " (" + $computerinfo.CsProcessors[0].NumberOfCores + "C)"
    Memory        = ($computerInfo.CsTotalPhysicalMemory / 1GB).ToString("#.# GB")
    Disks         = $Disks -join ", "
    Bitlocker     = $bitlockerstatus
    Display       = $displayinfo
    Networks      = $networks -join ", "
    PublicIP      = $PublicIP_Info.ip
    PublicIP_Loc  = "$($PublicIP_Info.city) $($PublicIP_Info.region) $($PublicIP_Info.postal) $($PublicIP_Info.country) [$($PublicIP_Info.org)]"
    TeamviewerID  = $TeamviewerID
    Domain        = $env:userdomain
    Winget        = $wingetver
    User          = $localuser
    LocalAdmins   = $localadmins -join ", "
    IsLocalAdmin  = $IsLocalAdmin
    IsAdminNow    = $IsAdmin
    #AZADAccount   = ($dsregcmd | Where-Object -Property Name -eq "Executing Account Name").Value
    AZADJoined    = ($dsregcmd | Where-Object -Property Name -eq "AzureAdJoined").Value
    DeviceId      = ($dsregcmd | Where-Object -Property Name -eq "DeviceId").Value
    TenantName    = ($dsregcmd | Where-Object -Property Name -eq "TenantName").Value
    TenantId      = ($dsregcmd | Where-Object -Property Name -eq "TenantId").Value
    Shutdown      = "$($reg_hiberbootenabled), $($reg_hiberbootenabled_desc)"
    Notifications = "$($reg_toastenabled), $($reg_toastenabled_desc)"
    LastBootUpTime= $pc.LastBootUpTime.tostring("g")
    LastBootDaysAgo= "$($days_fromstartup.tostring("0.#")) days ago"
    }
$infoObject = New-Object -TypeName psobject -Property $objProps
$out_info = ($infoObject | Out-String).Trim()
$out_separator =  "-----------------------------------------------------------------------------"
$out_header = "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
$out_lines=@()
$out_lines+=$out_separator
$out_lines+=$out_header
$out_lines+=$out_separator
$out_lines+=$out_info
$out_lines+=$out_separator
$out_lines | Write-Host
### Drop a report in the downloads folder
$folder_downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$date = get-date -format "yyyy-MM-dd_HH-mm-ss"
$file = "$($folder_downloads)\PC Info $($date).txt"
# write file
$out_lines | Out-File $file
#################################################
Read-Host -Prompt "Report saved to Downloads folder.  Press Enter to exit and open that file."
# open file
Invoke-Item $file