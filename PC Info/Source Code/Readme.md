www.itautomator.com   
### PC Info Readme 

<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/PCInfo/MainScreen.png alt="screenshot" width="500"/>

## Overview
Shows all kinds of useful information about the PC and User<br>
Run as user (not as admin)

### To Run

> Important: DO NOT RUN RANDOM CODE FROM THE INTERNET.  Yes, that's what you are doing here.  Make sure you know what the code contains.  Also, in a managed environment, these actions my ring alarm bells.

Method 1: Press _Windows-R_ (Run) and paste:

    powershell -executionpolicy bypass Invoke-Expression (Invoke-WebRequest https://raw.githubusercontent.com/ITAutomator/pcinfo/main/PC%20Info.ps1 -UseBasicParsing).Content

Method 2: Open Powershell and paste

    Invoke-Expression ((Invoke-WebRequest https://raw.githubusercontent.com/ITAutomator/pcinfo/main/PC%20Info.ps1 -UseBasicParsing).Content)

Method 3: Download the Ps1 and run
Download from here: [PC Info.ps1](https://raw.githubusercontent.com/ITAutomator/PCInfo/main/PC%20Info.ps1)

## Information Returned

### Fast Boot
Most IT pros think this should be 0 (Off). Windows is 1 (On) by default.<br>
If Fast Boot is on for a computer, it means that shut down is the same as hibernation. In this case a shut down is not as good as a restart for applying updates etc. 
Turn this off to go back to a slower but safer shutdown.  The speed benefit is negligible anyway if an SSD is installed.
<br>
#### To turn off fast startup (hiberbootenabled) manually <br>
Note: This is a system setting and will require admin access to change. <br>

> Press Win+R > Type "control" (Opens control panel) > Type "power buttons" (Click Change what the power buttons do) > look for *Turn on faststartup* > Untick this box

![image](https://github.com/ITAutomator/PCInfo/assets/135157036/4c81e4c5-65ec-4fed-9c01-7e7fdbcb18e5)


### Notifications
Most IT pros think this should be 1.

If this is 0, it means that the user has opted out from all system notifications, regardless of source.
