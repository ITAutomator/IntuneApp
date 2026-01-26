function winget_lines_clean
{
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline)]
    [String[]]$lines
  )
if ($input.Count -gt 0) { $lines = $PSBoundParameters['Value'] = $input }
  $bInPreamble = $true
  foreach ($line in $lines) {
    if ($bInPreamble){
      if ($line -like "Name*") {
        $bInPreamble = $false
      }
    }
    if (-not $bInPreamble) {
        Write-Output $line
    }
  }
}
function winget_lines_to_obj
{
  # Note:
  #  * Accepts input only via the pipeline, either line by line, 
  #    or as a single, multi-line string.
  #  * The input is assumed to have a header line whose column names
  #    mark the start of each field
  #    * Column names are assumed to be *single words* (must not contain spaces).
  #  * The header line is assumed to be followed by a separator line
  #    (its format doesn't matter).
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)] [string] $InputObject
  )
  begin {
    Set-StrictMode -Version 1
    $lineNdx = 0
  }
  process {
    $lines = 
      if ($InputObject.Contains("`n")) { $InputObject.TrimEnd("`r", "`n") -split '\r?\n' }
      else { $InputObject }
    foreach ($line in $lines) {
      ++$lineNdx
      if ($lineNdx -eq 1) { 
        # header line
        $headerLine = $line 
      }
      elseif ($lineNdx -eq 2) { 
        # separator line
        # Get the indices where the fields start.
        $fieldStartIndices = [regex]::Matches($headerLine, '\b\S').Index
        # Calculate the field lengths.
        $fieldLengths = foreach ($i in 1..($fieldStartIndices.Count-1)) { 
          $fieldStartIndices[$i] - $fieldStartIndices[$i - 1] - 1
        }
        # Get the column names
        $colNames = foreach ($i in 0..($fieldStartIndices.Count-1)) {
          if ($i -eq $fieldStartIndices.Count-1) {
            $headerLine.Substring($fieldStartIndices[$i]).Trim()
          } else {
            $headerLine.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
          }
        } 
      }
      else {
        # data line
        $oht = [ordered] @{} # ordered helper hashtable for object constructions.
        $i = 0
        foreach ($colName in $colNames) {
          $oht[$colName] = 
            if ($fieldStartIndices[$i] -lt $line.Length) {
              if ($fieldLengths[$i] -and $fieldStartIndices[$i] + $fieldLengths[$i] -le $line.Length) {
                $line.Substring($fieldStartIndices[$i], $fieldLengths[$i]).Trim()
              }
              else {
                $line.Substring($fieldStartIndices[$i]).Trim()
              }
            }
          ++$i
        }
        # Convert the helper hashable to an object and output it.
        [pscustomobject] $oht
      }
    }
  }
}
Function winget_init
{ # initializes global settings for winget (accepts agreements)
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() # change from IBM437/SingleByte to utf-8/Double-Byte (for global character sets to work)
  winget search dummyapp --accept-source-agreements | Out-Null  # weird way to accept agreements  
}
Function winget_verb_to_obj ($verb="list", $Appid="")
{ # converts winget list and search to powershell object array
    $wgcommand = "winget $($verb)"
    If ($Appid -ne "")
    {
        If ($Appid.contains(".")) { # id is passed
            $wgcommand += " --id $($Appid) --exact"
        }
        else { # name is passed
            $wgcommand += " --name `"$($Appid)`""
        }
    }
    $wglines = Invoke-Expression $wgcommand
    $wgobjs = @()
    $wgobjs += $wglines | winget_lines_clean  | # filter out progress-display lines
        winget_lines_to_obj          | # parse output into objects
        Sort-Object Id               | # sort by the ID property (column)
    Select-Object Name,Id,@{N='Version';E={$_.Version.Replace("> ","")}},Available,Source # Version fixup
    Return $wgobjs
}
function Get-VCRedistVersion
{
    # Function to get current VC++ Redistributable version from registry
    $regKeys = @(
        "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$platform",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\$platform"
    )
    foreach ($key in $regKeys) {
        if (Test-Path $key) {
            try {
                $ver = Get-ItemProperty -Path $key | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
                if ($ver) {
                    # Match and remove all non-digit characters at the beginning of the string
                    $cleanVer = $ver -replace '^[^0-9]+', ''
                    return [Version]$cleanVer
                }
            } catch {}
        }
    }
    return $null
}
Function winget_install
{
	if (IsAdmin)
	{ #isadmin
		# install the Microsoft Visual C++ Redistributable for Visual Studio 2015, 2017, and 2019.
        # https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170
        #
        # Define minimum required version for Visual C++ Redistributable
        $minVersion = [Version]"14.0.0.0"
        # Check current version
        $currentVersion = Get-VCRedistVersion
        if ($currentVersion -and $currentVersion -ge $minVersion) {
            $msg = "Microsoft Visual C++ Redistributable already installed (version $currentVersion)."
            [string]$result="OK - $($msg)"
        } else {
            # Determine architecture (supports x64 and ARM64)
            $arch = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture.ToLower()
            if ($arch -like "*arm*") {
                $platform = "ARM64"
            } elseif ($arch -like "*64*") {
                $platform = "x64"
            } else {
                $platform = "x86"
            }
            # Set download URL and installer path
            switch ($platform) {
                "ARM64" {
                    $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.arm64.exe"
                }
                "x64" {
                    $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
                }
                default {
                    return "ERR - Unsupported architecture: $platform. Skipping Visual C++ Redistributable install."
                }
            }
            Write-Host "Installing Microsoft Visual C++ Redistributable ($platform) from ($($vcRedistUrl))..."
            # Ensure TLS 1.2 for web downloads
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $installerName = ($vcRedistUrl -split "/")[-1]
            $tempInstaller = "$env:TEMP\$installerName"
            # Download the installer
            Invoke-WebRequest -Uri $vcRedistUrl -OutFile $tempInstaller -UseBasicParsing
            # Silently install
            Start-Process -FilePath $tempInstaller -ArgumentList "/install", "/quiet", "/norestart" -Wait
            # Cleanup
            Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
            # Verify installation
            $newVersion = Get-VCRedistVersion
            if ($newVersion -and $newVersion -ge $minVersion) {
                $msg = "Successfully installed VC++ Redistributable ($platform) version $newVersion."
                [string]$result="OK - $($msg)"
            } else {
                $msg = "Installation of VC++ Redistributable failed. Please check manually."
                [string]$result="ERR - $($msg)"
            }
        }
	} #isadmin
	else
	{ #noadmin
		[string]$result="ERR - Update winget by installing Microsoft Visual C++ Redistributable failed due to non-elevation."
	} #noadmin
    return $result
}
Function winget_core ($WingetMin ="1.6")
{ # verifies existence of winget.  updates if needed.
    # if lt $WingetMin , upgrades winget
    # leave $WingetMin  blank to not upgrade winget
    # [string]$result=winget_core -minver "1.6.2721"
    $strPassInfo=""
    for ($pass = 1; $pass -le 3; $pass++)
    { # loop looking for winget
        $wgc = get-command winget -ErrorAction Ignore
        if ($wgc)
        { # has winget, check if old
            Try { # run winget
                $version = winget -v
            }
            Catch {$version="v0.0.0"} # error means v0
            if ($null -eq $version) {$version="v0.0.0"}
            if ("" -eq $version) {$version="v0.0.0"}
            $version = $version.Replace("v","")
            if (($WingetMin  -ne "") -and ((GetVersionFromString $version) -lt (GetVersionFromString $WingetMin)))
            { # update needed
				[string]$result=winget_install
                $result+="['winget -v' returned v$($version) but v$($WingetMin) or higher is needed]"
			}
            else
            { # no update needed
                [string]$result="OK - no update needed v$($version). Path:$($wgc.source)$($strPassInfo)"
                Break # Done with For loop (no other passes needed)
            } # no update needed
        } # has winget
        else
        { # no winget
            if (IsAdmin)
            { #isadmin, try 1 path fix 2 install
                If ($pass -eq 1)
                { # Pass 1 - try adding a path
                    $strPassInfo=" PassInfo:PathAdjust"
                    $ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*__8wekyb3d8bbwe"
                    if ($ResolveWingetPath)
                    { # change path to include winget.exe (for this session) to try again in for loop pass 2
                        $WingetPath = $ResolveWingetPath[-1].Path
                        $env:Path = $WingetPath + ";" + $env:Path
                    } # change path to include winget.exe (for this session) to try again in for loop pass 2    
                }
                elseif ($pass -eq 2)
                { # Pass 2 - try to install winget (on top of old version)
                    $strPassInfo=" PassInfo:WingetInstallNeeded"
					[string]$result=winget_install
                }
                else
                { # Pass 3 - give up
                    [string]$result="ERR - Needs winget and is elevated, but there's no way to install winget if the OS doesn't include it. Try searching for App Installer in the store. Pass:$($pass) User:$($env:USERNAME) Path:$($env:Path)"
                }
            } #isadmin
            else
            { #no admin
                [string]$result="ERR - Needs winget but isn't elevated. Pass:$($pass)"
                Break 
            } #no admin
        } # no winget
    } # loop twice looking for winget
    Return $result
}
Function WingetList ($WingetMin = "1.6")
{ # Returns winget list (installed apps) as objects
    <#
    Usage:
    $app_objs = WingetList
    #>
    $retObj = $null
    [string]$result=winget_core -minver $WingetMin
    If (-not $result.StartsWith("OK"))
    { # winget itself is err        
        Write-Host "Winget itself had a problem: $($result)"
    } # winget itself is err
    Else
    { # winget is OK
        winget_init # initialize winget (approve)
        $retObj = winget_verb_to_obj "list"
    } # winget is OK
    Return $retObj
}
Function WingetAction ($WingetMin = "1.6",$WingetVerb = "list", $WingetApp="appname", $SystemOrUser="System",$WingetAppMin="")
{ # winget intune actions
    <#
    Usage:
    $intReturnCode,$strReturnMsg = WingetAction -WingetMin "2.2" -WingetVerb "list" -WingetApp "Myapp"
    #>
    $intReturnCode = 0
    $strReturnMsg = ""
    # set winget scope options:--scope user,--scope machine, or nothing
    if ($SystemOrUser -eq "")
    {$strScope = ""}
    Elseif ($SystemOrUser -eq "user")
    {$strScope = " --scope $($SystemOrUser)"}
    Else # translate all else incl system to machine
    {$strScope = " --scope Machine"}
    # get version
    [string]$result=winget_core -minver $WingetMin
    If (-not $result.StartsWith("OK"))
    { # winget itself is err        
        $intReturnCode=301
        $strReturnMsg = "Winget itself had a problem: $($result)"
    } # winget itself is err
    Else
    { # winget is OK
        winget_init
        if ($Wingetverb -eq "list")
        { #verb:list
            if ($WingetApp.Contains(".")){ # exact match (by id)
                $Winget_command = "list","--id",$WingetApp,"--exact"
            }
            else { # name match
                $Winget_command = "list","--name",$WingetApp
            }
            $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            #  (https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md)
            # exitcode: -1978335212=APPINSTALLER_CLI_ERROR_NO_APPLICATIONS_FOUND
            # Any installed package found?
            $detect = $Winget_return -like "*$($WingetApp)*"
            if ($detect) 
            { # winget detected a version
                if ($WingetAppMin -eq "")
                { # detect any version
                    $intReturnCode=0
                    $strReturnMsg="OK $($intReturnCode): Winget app ($($WingetApp)) detected: $($detect) [$winget ($Winget_command)]"
                } # detect any version
                Else
                { # detect at or above min
                    $Winget_return = @(winget_verb_to_obj -verb "list" -Appid $WingetApp)
                    if (-not $Winget_return.Version)
                    { # no version from winget
                        $intReturnCode=99
                        $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) detected, but no version info from winget ($($detect)) to compare with minver ($($WingetAppMin)) [winget $($Winget_command)]"
                    }
                    else
                    { # has version from winget
                        if ($Winget_return.count -ne 1) {
                            $intReturnCode=98
                            $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) detected multiple times [winget $($Winget_command)]"
                        }
                        else {
                            $detect = $Winget_return.Version
                            if ((GetVersionFromString $Winget_return.Version) -lt (GetVersionFromString $WingetAppMin))
                            { # ver too low
                                $intReturnCode=99
                                $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) detected, but version is too low ($($detect)) compared to minver ($($WingetAppMin)) [winget $($Winget_command)]"
                            } # ver too low
                            else
                            { # ver is ok
                                $intReturnCode=0
                                $strReturnMsg="OK $($intReturnCode): Winget app ($($WingetApp)) detected ($($detect)) at or above minver ($($WingetAppMin)) [winget $($Winget_command)]"
                            } # ver is ok
                        }
                    } # has version from winget
                } # detect at or above min
            } # winget detected a version
            else
            { # winget detected nothing
                $intReturnCode=99
                $strReturnMsg="ERR $($intReturnCode): Winget app ($($WingetApp)) not detected [winget $($Winget_command)]"
            } # winget detected nothing
        } #verb:list
        elseif ($Wingetverb -eq "install")
        { # winget install
            $Winget_command = "install","--id",$WingetApp,"--exact","--accept-package-agreements"
            #$exitcode,$Winget_return,$stderr=StartProc "winget" $Winget_command
            $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            # exitcode: (https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md)
            # exitcode: 0=OK 	-1978335216=APPINSTALLER_CLI_ERROR_NO_APPLICABLE_INSTALLER
            $chkresults = ($Winget_return -like "*Successfully installed*") -or ($Winget_return -like "*Found an existing package already installed*")
            if ($chkresults)
            { # 1st install ok
                $intReturnCode=0
                $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app installed. [$($Winget_command)]"
            } # 1st install ok
            else
            { # 1st install failed
                if ($strScope -eq "")
                { # 2nd install can't be tried
                        $intReturnCode = 385
                        $strReturnMsg="ERR $($intReturnCode): Winget app [$($WingetApp)] not installed. Winget err: $($exitcode) [winget $($Winget_command)]"
                } # 2nd install can't be tried
                else
                { # 2nd install attempt, without scope
                    $Winget_command = "install","--id",$WingetApp,"--exact","--accept-package-agreements"
                    $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
                    $chkresults = (($Winget_return -like "*Successfully installed*") -or ($Winget_return -like "*Found an existing package already installed*"))
                    if (-not $chkresults) {
                        $intReturnCode = 385
                        $strReturnMsg="ERR $($intReturnCode): Winget app [$($WingetApp)] not installed (even with $($strScope) option removed). Winget err: $($exitcode) [winget $($Winget_command)]"
                        $winget_lines = $winget_return |  Where-Object {$_.Trim() -ne ""} | Where-Object { -not ($_ -match '^\s')} # remove blanks
                        $winget_msgs = @("`r`n[winget $($Winget_command -join " ")]") + $winget_lines + @("[winget returned:$($exitcode)]") # header and footer added
                        $strReturnMsg += $winget_msgs -join "`r`n" # append as a long string with crlfs
                    }
                    else {
                        $intReturnCode=0
                        $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app installed (with $($strScope) option removed). [$($Winget_command)]"
                    }
                } #2nd install attempt, without scope
            } # 1st install failed
        } # winget install
        elseif ($Wingetverb -eq "uninstall")
        { # winget uninstall
            $Winget_command = @()
            if ($WingetApp.Contains(".")){ # exact match (by id)
                $Winget_command = "uninstall","--id",$WingetApp,"--disable-interactivity","--silent","--force"
            }
            else { # name match
                $Winget_command = "uninstall","--name",$WingetApp,"--disable-interactivity","--silent","--force"
            }
            if ($SystemOrUser -ne "") {
                $Winget_command += "--scope"
                If ($SystemOrUser -eq "user") {
                    $Winget_command += "user"}
                Else { # translate all else incl system to machine
                    $Winget_command += "machine"}
            }
            #1603 means elevation needed, -1978335212 means app not found
            $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
            #Successfully uninstalled or No installed package found matching input criteria are OK results
            if (($exitcode  -eq 0) -or ($exitcode -eq -1978335212))
            { # 1st uninstall ok
                $intReturnCode=0
                $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app uninstalled. [$($Winget_command)]"
            } # 1st uninstall ok
            else
            { # 2nd uninstall attempt, without scope
				$Winget_command = @()
				if ($WingetApp.Contains(".")){ # exact match (by id)
					$Winget_command = "uninstall","--id",$WingetApp,"--disable-interactivity","--silent","--force"
				}
				else { # name match
					$Winget_command = "uninstall","--name",$WingetApp,"--disable-interactivity","--silent","--force"
				}
				#1603 means elevation needed, -1978335212 means app not found
                $Winget_return,$retStatus,$exitcode = StartProcAsJob "winget" $Winget_command -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 300
                if ($exitcode  -eq 0)
                { # 2nd uninstall ok
                    $intReturnCode=0
                    $strReturnMsg="OK $($intReturnCode): Winget [$($WingetApp)] app uninstalled (with $($strScope) option removed). [$($Winget_command)]"
                } # 2nd uninstall ok
                else
                { # 2nd uninstall attempt, without scope
                    $intReturnCode = 378
                    $strReturnMsg="ERR $($intReturnCode): Winget app [$($WingetApp)] not uninstalled (with $($strScope) option removed). Winget err: $($exitcode) [winget $($Winget_command)]"
                } # 2nd uninstall attempt, without scope
            } # 2nd uninstall attempt, without scope
        }  # winget uninstall
        else
        {
            $intReturnCode=182
            $strReturnMsg="Err $($intReturnCode) : Winget verb unhandled by this code: $($Wingetverb)"
        }
        # Winget verb package 
    } # winget is OK
    Return $intReturnCode,$strReturnMsg
}

Function GetVersionFromString($Version)
{
    # Safely turns a string into a version
    # If it's already a version return it
    # If it's a string with a whole number append .0 to make it a usable version
    If ($null -eq $Version) {Return [version]"0.0.0.0"}
    If (($Version).GetType().Name -eq "Version")
    {
        Return $Version
    }
    $strVersion = [string]$Version # convert to string
    if ($strVersion -eq "") {$strVersion="0.0.0.0"} # empty so 0.0
    if (-1 -eq $strVersion.IndexOf(".")) {$strVersion+=".0"} # no dot so append a .0
    try {
        $retVersion = [version]$strVersion
    }
    catch {
        $retVersion = [version]"0.0.0.0"
    }
    Return $retVersion
}

function StartProcAsJob_Function {
    # not to be called directly: called by StartProc as a ScriptBlock argument
    Param ($xcmd, $xargs)
    & $xcmd $xargs
    Write-Output "LASTEXITCODE:$($LASTEXITCODE)"
}
function StartProcAsJob {
    Param (
        $xcmd,
        $xargs,
        $TimeoutSecs = 300,
        $StopProcOnTimeout = $false,
        $ShowOutputToHost=$true
        )
    <# Usage:
    $retOutput,$retStatus,$retExitCode = StartProcAsJob "winget" "-v" -ShowOutputToHost $True -StopProcOnTimeout $False -TimeoutSecs 20 
    Write-Host "  retOutput: $($retOutput)"
    Write-Host "  retStatus: $($retStatus)"
    Write-Host "retExitCode: $($retExitCode)"
    Note: $xargs can be a string, or an array of strings expected as arguments (if quotes and spaces are involved)
    $xcmd = "winget"
    $xargs = "list","Workspot Client"
	# To test, break here and run this command:
    & $xcmd $xargs
    #>
    $retStatus = ""
    $retExitCode = 0
    $retOutput = $null
    # show header
    if ($ShowOutputToHost) {Write-Host "--- StartProcAsJob: $($xcmd) $($xargs) [Timeout: $($TimeoutSecs), StopProcOnTimeout: $($StopProcOnTimeout)]"}
    # check that xcmd exists
    if (-not (get-command $xcmd -ErrorAction Ignore))
    {
        $retStatus = "Err [JobState:<none>, Get-Command failed :$($xcmd)]"
        Return $retOutput,$retStatus,$retExitCode
    }
    # Start a job
    $job = Start-Job -Name "Powershell StartProcAsJob Function" -ScriptBlock ${Function:StartProcAsJob_Function} -ArgumentList $xcmd, $xargs
    $outindex = 0
    Do
    { #Loop while running (or timeout)
        if ($job.JobStateInfo.State -eq "Running")
        {
            if (([DateTime]::Now - $job.PSBeginTime).TotalSeconds -gt $TimeoutSecs) {
                break
            }
            Start-Sleep -Milliseconds 200 #breathe
        }
        #region show output
        $outsofar = $job.ChildJobs[0].Output
        if ($ShowOutputToHost) {$outsofar[$outindex..$outsofar.Count] | Out-Host} # show incremental lines of output
        $outindex = $outsofar.Count
        #endregion show output
    } While ($job.JobStateInfo.State -eq "Running")
    # must parse the return object contents before Remove-job deletes the object.
    $retOutput = $job.ChildJobs[0].Output | Where-Object {-not $_.StartsWith("LASTEXITCODE:")} | ForEach-Object {[string]$_}
    $retExitCodeLine = $job.ChildJobs[0].Output | Where-Object {$_.StartsWith("LASTEXITCODE:")} | ForEach-Object {[string]$_}
    # Parse exit code if a line was found
    if ($retExitCodeLine) { # convert to int
        $retExitCode = try {[int]$retExitCodeLine.Replace("LASTEXITCODE:","")} Catch {}
    }
    if ($job.state -notin "Stopped","Completed")
    {
        if ($StopProcOnTimeout)
        {
            $retStatus = "Err [JobState:$($job.state), Timeout:$($TimeoutSecs), Stopped:Yes]"
            $job | Stop-Job
        }
        else
        {
            $retStatus = "Err [JobState:$($job.state), Timeout:$($TimeoutSecs), Stopped:No - job allowed to continue]"
        }
    }
    else
    {
        $retStatus = "OK [Secs:$(([DateTime]::Now - $job.PSBeginTime).TotalSeconds)]"
        $job | Remove-job
    }
    Return $retOutput,$retStatus,$retExitCode
}
$intReturnCode,$strReturnMsg = WingetAction -WingetMin "2.2" -WingetVerb "list" -WingetApp "Paint"
Write-Host "ReturnCode: $($intReturnCode) Message: $($strReturnMsg)"