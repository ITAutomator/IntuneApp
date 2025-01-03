# IntuneApp  

## Adobe Acrobat Reader

### About this package

- *Acrobat Reader* is the free PDF reader from Adobe.  
- This installs the winget package with ID `Adobe.Acrobat.Reader.64-bit`  
- This only installs if no other version of *Acrobat* installed, since that would be a preferred paid version.  

### *Acrobat Reader* vs *Acrobat Standard* vs *Acrobat Pro*  

- *Acrobat Reader* is free from Adobe.  
- *Acrobat Standard* and *Acrobat Pro* are the paid versions of this product.  
  The paid products are subscriptions that allow license activation on up to 2 simultaneous computers.  
  Adobe has discontinued one-time purchase of its software.  

*Acrobat Reader* can

- Open, read, and print PDF files, including passworded files.
- Sign and E-Sign documents

*Acrobat Standard* does all the above plus these features

- Adjust page order (although this can be done be printing pages to PDF)
- Edit the content of a page
- Recogize text

*Acrobat Pro* does all the above plus these features

- Mac compatibility
- Redact to remove sensitive information

Detailed comparison can be found [on Adobe's website](https://www.adobe.com/acrobat/pricing/compare-versions.html).

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
