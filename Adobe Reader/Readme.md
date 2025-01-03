# IntuneApp  

## Adobe Reader

### About this package

- *Adobe Reader* is the free PDF reader from Adobe.  
- This app installs the winget package with ID `Adobe.Acrobat.Reader.64-bit`  
- This app only installs if machine has no other version of Adobe Acrobat installed, since that would be a preferred paid version.  

### *Adobe Standard* vs *Adobe Pro*  

*Adobe Standard* and *Adobe Pro* are the paid versions of this product (same codebase though).  

*Adobe Reader* can

- Open, read, and print PDF files, including passworded files.
- Sign and E-Sign documents

*Adobe Reader* can't

- Adjust page order (although this can be done be printing pages to PDF)
- Edit the content of a page

## IntuneApp Publishing System

This app was packaged for compatibility with the *IntuneApp* Publishing System. It can also be installed\:

- automatically by other package delivdery systems using  
  `Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File IntuneUtils\intune_install.ps1 -quiet`  
- manually by double-clicking `intune_command.cmd`  

Information about the *IntuneApp* Publishing System  

- See here for the *IntuneApp* readme: (readme.md) <https://github.com/ITAutomator/IntuneApp>  
- See here for the *IntuneApp* blog post (blog): <https://www.itautomator.com/intuneapp>  
- See here for the *IntuneApp* admin guide: (pdf) <https://github.com/ITAutomator/IntuneApp/blob/main/Readme%20IntuneApp.pdf>  
- Is this code used for [a business](https://github.com/ITAutomator/IntuneApp/blob/main/LICENSE)? Become a sponsor: https://github.com/sponsors/ITAutomator  
