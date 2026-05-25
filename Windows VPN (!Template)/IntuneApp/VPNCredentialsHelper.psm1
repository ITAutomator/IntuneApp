<#
	Set-VpnConnectionUsernamePassword - by Paul Stancer.
	Huge thanks to Jeff Winn for the DotRas project (https://dotras.codeplex.com/) which showed me the way, 
	and did all the really hard work.
#>
$code=@' 
    using System;
    using System.Runtime.InteropServices;

    public class VPNCredentialsHelper
    {
        private const int SUCCESS = 0;
        private const int ERROR_ACCESS_DENIED = 5;

        private const int UNLEN = 256;// Defines the maximum length of a username.
        private const int PWLEN = 256;// Defines the maximum length of a password.
        private const int DNLEN = 15;// Defines the maximum length of a domain name.

        [Flags]
        private enum RASCM
        {
            None = 0x0,
            UserName = 0x1,
            Password = 0x2,
            Domain = 0x4
        }

        [DllImport("rasapi32.dll", CharSet = CharSet.Unicode)]
        private static extern int RasGetErrorString(
            int uErrorValue,
            [In, Out] string lpszErrorString,
            int cBufSize);

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 4)]
        private struct RASCREDENTIALS
        {
            public int size;
            public RASCM options;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = UNLEN + 1)]
            public string userName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = PWLEN + 1)]
            public string password;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = DNLEN + 1)]
            public string domain;
        }

        [DllImport("rasapi32.dll", CharSet = CharSet.Unicode)]
        private static extern int RasSetCredentials(
            string lpszPhonebook,
            string lpszEntryName,
            IntPtr lpCredentials,
            [MarshalAs(UnmanagedType.Bool)] bool fClearCredentials);

        public static bool SetCredentials(string entryName, string domain, string username, string password)
        {
            var credentials = new RASCREDENTIALS() { userName = username, password = password, domain = domain ?? string.Empty, options = RASCM.Domain | RASCM.UserName | RASCM.Password };

            int size = Marshal.SizeOf(typeof(RASCREDENTIALS));

            IntPtr pCredentials = IntPtr.Zero;
            try
            {
                credentials.size = size;

                pCredentials = Marshal.AllocHGlobal(size);
                Marshal.StructureToPtr(credentials, pCredentials, true);

                int ret = RasSetCredentials(null, entryName, pCredentials, false);

                switch (ret)
                {
                    case SUCCESS:
                        return true;
                    case ERROR_ACCESS_DENIED:
                        throw new UnauthorizedAccessException();
                    default:
                        throw ProcessRASException(ret);
                }
            }
            finally
            {
                if (pCredentials != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(pCredentials);
                }
            }
        }

        private static Exception ProcessRASException(int errorCode)
        {
            try
            {
                string buffer = new string('\x00', 512);

                int ret = RasGetErrorString(errorCode, buffer, buffer.Length);
                if (ret == SUCCESS)
                    return new RASException(errorCode, buffer.Substring(0, buffer.IndexOf('\x00')));
            }
            catch (EntryPointNotFoundException)
            {
            }

            return new RASException(errorCode, "RAS Error code: " + errorCode.ToString());
        }

        public class RASException: Exception
        {
            public RASException(int errCode, string message):base(message)
            {
                RASErrorCode = errCode;
            }

            public int RASErrorCode { get; private set; }
        }
    }
'@ 

function Set-VpnConnectionUsernamePassword {

	param 
	( 
		##[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,HelpMessage='What connection name would you set the credentials?')]
		[ValidateLength(3,255)]
		[string]$connectionname, 
		##[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
		[ValidateLength(0,15)]
		[string]$domain, 
		##[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
		[ValidateLength(0,255)]
		[string]$username, 
		##[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
		[ValidateLength(0,255)]
		[string]$password
	) 

    Add-Type -TypeDefinition $code -IgnoreWarnings 

    Try
    {
        [VPNCredentialsHelper]::SetCredentials($connectionname, $domain, $username, $password)
    }
    Catch [System.UnauthorizedAccessException]
    {
        write-host "You do not have permissions to change the credentials" -ForegroundColor Red
    }
    Catch
    {
        write-host $_.Exception.Message -ForegroundColor Red
    }
}
export-modulemember -function Set-VpnConnectionUsernamePassword