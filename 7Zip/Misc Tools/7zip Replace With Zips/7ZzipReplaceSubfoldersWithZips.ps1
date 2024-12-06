#####
## To enable scripts (must be done once per machine), Run powershell 'as admin' then type
##    Set-ExecutionPolicy Unrestricted
## To run as a scheduled task, in the actions tab use this example
##    Start program: powershell.exe  Argument: C:\myscripts\myscript.ps1
#####

#################### Transcript Open
$Transcript = [System.IO.Path]::GetTempFileName()               
Start-Transcript -path $Transcript | Out-Null
#################### Transcript Open

### Script Variables
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
####

########################################################################
#### User variables: Edit these according to your needs
########################################################################

$folder = $scriptDir                          ## uncomment to zip files in script folder
# $folder = "C:\BackupCopy\Latest"  ## uncomment to zip files in specified folder

## ---------- Edit the lines below to customize includes and excludes
$includes  = @("*.pst") #outlook archives
##$includes += @("*.qbw") #quickbooks files
##$includes += @("*.bak") #backup files
##$includes += @("*.iso") #disk images - not sure about this one
#$includes  = @() ## Use this to include all

###
$excludes  = @("!Zip")
#$excludes += @("*.txt","*.log")
#$excludes += @("*.7z","*.rar","*.zip","*.7z.*","*.zip.*")  ## don't recompress zipped files
# $excludes  = @() ## Use this to exclude nothing

$zip_ext  = "7z"   #  "7z" or "zip"
$zipsplit = "500m" # zipsplit Indicate how to split up a big zip (e.g. "600m" means 600 mb, "" means no splitting)

# possible locations of 7-zip program
$zipexe1="C:\Program Files\7-Zip\7z.exe"
$zipexe2="C:\Program Files (X86)\7-Zip\7z.exe"

# interactive mode? ($true=prompts user , $false=proceed without asking (meant for scheduled tasks)
$interactive = $true
$error_pause = $false
$keep_n_logs   = 10
$pause_secs    = 3

########################################################################
## Version History
##
## v2.1 (2018-06-03)
## - Added collision detection with split too
##
## v2.0 (2018-05-01)
## - Initial version with split capabilities
##
########################################################################
write-host "------------------------------------------------------------------------------------"
write-host "$($scriptName)      Computer:$($env:computername) User:$($env:username)  PSver:$($PSVersionTable.PSVersion.Major)"
write-host "v2.1"
write-host ""
write-host "Replaces subfolders with $($zip_ext) files (using 7zip)"
write-host ""
write-host ""
write-host "  Folder   : $($folder)"
write-host "  Format   : $($zip_ext)"
write-host "  Split    : $($zipsplit)"
write-host ""
write-host "  AskUser  : $($interactive)"
write-host ""
write-host "------------------------------------------------------------------------------------"
if ($PSVersionTable.PSVersion.Major -lt 3) 
    {
    $message="This program requires Powershell 3 and above."
    write-host $message
    write-host "------------------------------------------------------------------------------------"
    $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("E&xit"); $choices = $host.ui.PromptForChoice("",$message, $choices,0)
    Exit
    }

write-host " ... getting folder list ..."
$entries = Get-ChildItem $folder -Directory -Exclude $excludes 
$entriescount = $entries.count
##
$zipexe = $zipexe2
if (!(Test-Path $zipexe2)) {$zipexe = $zipexe1}
if (!(Test-Path $zipexe))
    {
    $message="'$($zipexe)' not found.  Download from 'http://www.7-zip.org/download.html'"
    write-host $message
    write-host "------------------------------------------------------------------------------------"
    $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("E&xit"); $choices = $host.ui.PromptForChoice("",$message, $choices,0)
    Exit
    }
if ($entriescount -eq 0)
    {
    $message="No matching files found"
    write-host $message
    write-host "------------------------------------------------------------------------------------"
    if ($interactive) {
        $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("E&xit"); $choices = $host.ui.PromptForChoice("",$message, $choices,0)
        }
    }
else
{
$processed=0
$message="$entriescount Entries. Continue?"
if ($interactive) {
    $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes","&No","&List Only")
    [int]$defaultChoice = 0
    $choiceRTN = $host.ui.PromptForChoice($caption,$message, $choices,$defaultChoice)
    } else {$choiceRTN=0}
if ($choiceRTN -eq 1)
    { "Aborting" }
else   
    {
    if ($choiceRTN -eq 1) 
        {
        ####
        $message = "Verbose Mode"
        $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Show zip percentages","Zip &Quietly")
        $choices = $host.ui.PromptForChoice("",$message, $choices,0)
        if ($choices -eq 0)
            {$supress=$false}
        else
            {$supress=$true}
        ###
        }
    if (!($interactive)) {$choiceLoop=1} ## interactive=false implies yes to all
    $i=0        
    foreach ($x in $entries)
    {
        $i++
        write-host "-----" $i of $entriescount $x
        if ($choiceRTN -eq 2) 
            {
            ### Just list
            }
        else
            { ## Zip
            if ($choiceLoop -ne 1)
                {
                $message="Process entry "+$i+"?"
                $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes","Yes to &All","&No","No and E&xit")
                [int]$defaultChoice = 1
                $choiceLoop = $host.ui.PromptForChoice($caption,$message, $choices,$defaultChoice)
                }
            if (($choiceLoop -eq 0) -or ($choiceLoop -eq 1))
                {
                $processed++
                ## -----------------------------------------------------------
                ## ------------- Code for entry $x :START
                $target = "$($x.Parent.FullName)\!Zip\$($x.Name).$($zip_ext)"

                ####################
                ### https://sevenzip.osdn.jp/chm/cmdline/index.htm
                $SplatArgs = @()
                $SplatArgs += "a"                      # Add to Archive
                $SplatArgs += $target
                $SplatArgs += $x.FullName
                $SplatArgs += "-sdel"                  # Delete files after compression
                if ($zipsplit -ne "")
                    {
                    $SplatArgs += "-v$($zipsplit)"         # split size
                    }
                # --- zip
                if ($supress)
                    {& $zipexe @SplatArgs | Out-Null}
                else
                    {& $zipexe @SplatArgs}
                # --- results
                switch ($LASTEXITCODE) {
                    0 {$rb_result = "OK."; break}
                    1 {$rb_result = "Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed."; break}
                    2 {$rb_result = "Fatal error."; break}
                    7 {$rb_result = "Command Line Error."; break}
                    8 {$rb_result = "Not enough memory for operation."; break}
                    255 {$rb_result = "Stopped by user."; break}
                    default {$rb_result = "Unknown error. https://sevenzip.osdn.jp/chm/cmdline/index.htm"; break}
                }
                if ($LASTEXITCODE -ne 0)
                    {
                    write-warning ("EXIT CODE: " + $LASTEXITCODE + " ("+ $rb_result + ")")
                    if ($interactive -and $error_pause)
                        {
                        $choices = [System.Management.Automation.Host.ChoiceDescription[]] @("Error Encountered - Press Enter to continue")
                        $choices = $host.ui.PromptForChoice("",$message, $choices,0)
                        }
                    }
                #if ($LASTEXITCODE -gt 1)
                #{
                #    $ErrOut=123; write-host ("Failed with exit code $LASTEXITCODE");Start-Sleep -Seconds 3;# Exit($ErrOut)
                #}
                ## ------------- Code for entry $x :END
                ## -----------------------------------------------------------
                }
            if ($choiceLoop -eq 2)
                {
                write-host ("Entry "+$i+" skipped.")
                ##break
                }
            
            if ($choiceLoop -eq 3)
                {
                write-host "Aborting."
                Exit
                }
            }
        }
    }
}
write-host "------------------------------------------------------------------------------------"
$message ="Done. " +$processed+" of "+$entriescount+" entries processed. Press [Enter] to exit."
#################### Transcript Save
Stop-Transcript | Out-Null
$date = get-date -format "yyyy-MM-dd_HH-mm-ss"
$TranscriptTarget = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+"_"+$date+"_log.txt"
$TranscriptAll    = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+"_*_log.txt"
If (Test-Path $TranscriptTarget) {Remove-Item $TranscriptTarget -Force}
Move-Item $Transcript $TranscriptTarget -Force
write-host "Log: $(Split-Path $TranscriptTarget -leaf)"
## delete all transcripts but n
$transcripts =@(get-childitem -path $TranscriptAll | #All files matching search
    where-object { -not $_.PSIsContainer } |  #that are not folders
    sort-object -Property $_.LastWriteTime -Descending   #sort by modified
    )
$deletethis = $transcripts.Length
while ($deletethis -gt $keep_n_logs) {$deletethis--;Remove-Item ($transcripts[$deletethis].fullname) -Force} 
## delete all transcripts but n
#################### Transcript Save
write-host "-----Done: $($scriptName) ---------------------------------------------------"
Start-Sleep -Seconds $pause_secs
if ($interactive) {$choices = [System.Management.Automation.Host.ChoiceDescription[]] @("E&xit"); $choices = $host.ui.PromptForChoice("",$message, $choices,0)}
