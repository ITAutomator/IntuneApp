
<#
WinGet Testing.ps1
This script adds winget to the path if needed.  It searches for it in C:\Program Files\WindowsApps.

Note about error 0x8a15000f Data required by the source is missing

If you are seeing results like this:
>winget install --id Test.Test
Failed when searching source: winget
An unexpected error occurred while executing the command:
0x8a15000f : Data required by the source is missing
>winget -v
v1.10.340

This error:
- Can happen if winget is run as different user
- Usually this is in a scenario when the user is not a local admin, so the run as is used to elevate the session
- The other user must open the Microsoft Store app (once) which can only be done in an interactive logon
- Users that are local admins will not get this error (even running as different user)
- Sessions running in SYSTEM context with no user (scheduled tasks, services) do not get this error

#>

$exe = "winget.exe"
$exe_search = "C:\Program Files\WindowsApps"
Write-Host "Checking path for [$($exe)]."
Write-Host "Will update path if found in [$($exe_search)]"
# check if in path
$exe_path = Get-Command $exe -ErrorAction Ignore | Select-Object -First 1 -Property Path -ExpandProperty Path
if ($exe_path)
{
    Write-Host "Found in path: $($exe_path)"
}
else
{
	Write-Host "Not in path: $($exe)"
    $exe_path = Resolve-Path "$($exe_search)\*\$($exe)" | Select-Object -First 1 -Property Path -ExpandProperty Path
    if ($exe_path)
    { # change path to include exe
        $exe_folder = Split-Path $exe_path -Parent
	    $env:Path = "$env:Path;$($exe_folder)"
        Write-Host "Found here (added to path): $($exe_folder)"
    }
}