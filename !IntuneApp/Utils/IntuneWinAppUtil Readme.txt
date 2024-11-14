IntuneWinAppUtil Readme.txt

https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

Use the Microsoft Win32 Content Prep Tool to pre-process Windows Classic apps. The packaging tool converts application installation files into the .intunewin format. The packaging tool also detects the parameters required by Intune to determine the application installation state. After you use this tool on your apps, you will be able to upload and assign the apps in the Microsoft Intune console.

Normally, AppPublish.ps1 uses the built-in IntuneWinAppUtil.exe that gets installed with the module.
However, 1.8.5 introduced a crash bug. So if AppsPublish.ps1 sees IntuneWinAppUtil.exe in this folder (of any version), it will be used instead.
