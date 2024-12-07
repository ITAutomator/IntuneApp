Function Remove-LockedFile
{ #Remove-LockedFile
   param(
    [parameter(Mandatory=$true)]
	[string] $path
    )

# the code below has been used from
#    https://blogs.technet.com/b/heyscriptingguy/archive/2013/10/19/weekend-scripter-use-powershell-and-pinvoke-to-remove-stubborn-files.aspx
# with inspiration from
#    http://www.leeholmes.com/blog/2009/02/17/moving-and-deleting-really-locked-files-in-powershell/
# and error handling from
#    https://blogs.technet.com/b/heyscriptingguy/archive/2013/06/25/use-powershell-to-interact-with-the-windows-api-part-1.aspx

Add-Type @'
    using System;
    using System.Text;
    using System.Runtime.InteropServices;
       
    public class Posh
    {
        public enum MoveFileFlags
        {
            MOVEFILE_DELAY_UNTIL_REBOOT         = 0x00000004
        }
 
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, MoveFileFlags dwFlags);
        
        public static bool MarkFileDelete (string sourcefile)
        {
            return MoveFileEx(sourcefile, null, MoveFileFlags.MOVEFILE_DELAY_UNTIL_REBOOT);         
        }
    }
'@

    $path = (Resolve-Path $path -ErrorAction Stop).Path
    try 
    {Remove-Item $path -ErrorAction Stop}
    catch
    {
        $deleteResult = [Posh]::MarkFileDelete($path)
        if ($deleteResult -eq $false)
        {
            throw (New-Object ComponentModel.Win32Exception) # calls GetLastError
        } 
        else
        {
            # write-host "(Delete of $path failed: $($_.Exception.Message)  Deleting at next boot.)"
        }
    }
} # Remove-LockedFile

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
if ((Test-Path("$scriptDir\ITAutomator.psm1"))) {Import-Module "$scriptDir\ITAutomator.psm1" -Force} else {write-host "Err: Couldn't find ITAutomator.psm1";return}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################

#Set folder paths and grab font files from the repo

$fonts = Get-ChildItem -Path $scriptDir -Include '*.ttf', '*.otf' -Recurse

Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host ""
Write-Host "Install Fonts:"
###
$count=0
foreach ($font in $fonts)
{
    $count += 1
    Write-Host "$($count)) $($font.Name)"
}
###
Write-Host ""
Write-Host ""
if ($quiet) {Write-Host ("<<-quiet>>")}
Write-host "--------------------------"
## If script requires admin
If (-not(IsAdmin))
{# Elevate
    #ErrorMsg -Fatal -ErrCode 101 -ErrMsg "This script requires Administrator priviledges, re-run with elevation (right-click and Run as Admin)"
    # rebuild the argument list
    foreach($k in $MyInvocation.BoundParameters.keys)
    {
        switch($MyInvocation.BoundParameters[$k].GetType().Name)
        {
            "SwitchParameter" {if($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
            "String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
            "Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
            "Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
        }
    }
    $argumentlist ="-File `"$($scriptFullname)`" $($argsString)"
    # rebuild the argument list
    Write-Host "Restarting as elevated powershell.exe -File `"$($scriptname)`" $($argsString)"
    Try
    {
        Start-Process -FilePath "PowerShell.exe" -ArgumentList $argumentlist -Wait -verb RunAs
    }
    Catch {
        $exitcode=110; Write-Host "Err $exitcode : This script requires Administrator priviledges, re-run with elevation"
        Throw "Failed to start PowerShell elevated"
    }
    Exit
}# Elevate
#
$fontFolder = "$([Environment]::GetFolderPath("Windows"))\Fonts"
if (Test-Path $fontFolder)
{ # font folder exists
    #------------ 
    #[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    #$FontsBefore = (New-Object System.Drawing.Text.InstalledFontCollection).Families
    #Write-Host "Fonts Before ($($fontFolder)): $($FontsBefore.Count)"
    #------------
    Write-Host "Windows fonts before this routine ($($fontFolder)): $((Get-ChildItem -Path $fontfolder -File | Measure-Object).Count)"
    Write-host "--------------------------"
    Write-Host "FontsToAdd" -ForegroundColor Yellow
    Write-host "--------------------------"$count = 0
    # Process each font contained in the source directory
    foreach ($font in $fonts)
    { # each font to add
        $count += 1
        Write-Host "$($count)) $($font.Name)" -NoNewline
        $targetFontPath = Join-Path $fontFolder $font.Name
        if (Test-Path $targetFontPath)
        {
            Write-Host " OK (Already exists)" -ForegroundColor Green -NoNewline
        }
        else
        {
            Copy-Item $font.FullName -Destination $targetFontPath -Force
            Write-Host " OK (Copied)" -ForegroundColor Green -NoNewline
        }
        # Set the registry
        Try
        {
        Add-Type -AssemblyName PresentationCore
        $fontdata = New-Object -TypeName Windows.Media.GlyphTypeface -ArgumentList $font.FullName
        $fontface = $($fontdata.Win32FaceNames.Values).Replace("Regular","")
        if ($fontface.Trim() -eq "")
            {$fontname = "$($fontdata.Win32FamilyNames.Values)"}
        else
            {$fontname = "$($fontdata.Win32FamilyNames.Values) $($fontdata.Win32FaceNames.Values)"}
        }
        Catch {$fontname=$font.name -replace ($font.Extension), ""}
        # what type of font
        if     ($font.extension -eq ".otf") {$fonttype = "OpenType"}
        elseif ($font.extension -eq ".ttf") {$fonttype = "TrueType"}
        $regpath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        $regname = "$($fontname) ($($fonttype))"  #DMSerifDisplay-Regular.ttf -> DMSerifDisplay-Regular (TrueType)
        # remove any key values with this font file
        $regvalues = @((Get-ItemProperty $regpath).psobject.properties | where {$_.value -like $font.Name}|select name,value)
        ForEach ($regvalue in $regvalues)
        {
            Remove-ItemProperty -Path $regpath -Name $regvalue.name -Force
            Write-Host " (REG_DEL $($regvalue.name))" -NoNewline
        }
        # remove any key values with this font file
        New-ItemProperty -Path $regpath -Name $regname -Value $font.name -Type String -Force | Out-Null
        Write-Host " (REG_ADD $($regname))" -NoNewline
        # Set the registry
        Write-Host " Installed" -ForegroundColor Yellow
    } # each font to add
    ############# cleanup
    if (Test-Path "$($scriptDir)\FontsToRemove.csv")
    { #FontsToRemove.csv
        Write-host "--------------------------"
        Write-Host "FontsToRemove.csv" -ForegroundColor Yellow
        Write-host "--------------------------"
        $csvdata=Import-Csv -Path "$($scriptDir)\FontsToRemove.csv"
        $fonts_remove=$csvdata.FontsToRemove
        $count=0
        foreach ($font_remove in $fonts_remove)
        { # each font to remove
            if ($font_remove -ne "")
            { # font not blank
                $count += 1
                Write-Host "$($count)) Remove $($font_remove)" -NoNewline
                $targetFontPath = Join-Path $fontFolder $font_remove
                if (Test-Path $targetFontPath)
                {
                    Remove-LockedFile $targetFontPath
                    Write-Host " OK (Removed)" -ForegroundColor Green -NoNewline
                }
                else
                {
                    Write-Host " OK (Already removed)" -ForegroundColor Green -NoNewline
                }
                # remove any key values with this font file
                $regvalues = @((Get-ItemProperty $regpath).psobject.properties | where {$_.value -like $font_remove}|select name,value)
                ForEach ($regvalue in $regvalues)
                {
                    Remove-ItemProperty -Path $regpath -Name $regvalue.name -Force
                    Write-Host " (REG_DEL $($regvalue.name))" -NoNewline
                }
                # remove any key values with this font file
                Write-Host " Uninstalled" -ForegroundColor Yellow
            } # each font to remove
        } # font not blank
    } # FontsToRemove.csv
} # font folder exists
Write-host "--------------------------"
Write-Host "Windows fonts after this routine ($($fontFolder)): $((Get-ChildItem -Path $fontfolder -File | Measure-Object).Count)"
    
Write-Host "Done."
Start-Sleep 3

#$FontsAfter = (New-Object System.Drawing.Text.InstalledFontCollection).Families
#$FontsAfter | Where-Object Name -Match "Lato"
#Write-Host "Fonts After : $($FontsAfter.Count)"