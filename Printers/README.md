# PrinterManager  
Printer Manager Readme  
  
Overview  
Use Printer Manager to automatically set up a standard list of printers on your PCs.  
Printer Manager is Intune and script friendly and designed to work within the IntuneApp system.  
  
   
Printer Manager main menu  
  
The program uses 3 key components, all added via the Printer Manager main menu.  
  
PrinterManager PrintersToAdd.csv  
A list of printers to add to PCs.  
  
PrinterManager PrintersToRemove.csv   
An (optional) list of obsolete printers to remove from PCs.  
  
IntuneApp\Drivers  
A folder of drivers used to install the added printers.  
Both x64 and ARM65 drivers can be included.  
Setup Steps  
Download the package and copy it to a central area.  
Right-click and run PrinterManager (as Admin).cmd to start the main menu.   
  
Note: The 2 main CSV files will be created if they don’t exist.  
Note: To facilitate different printer lists for different groups, use multiple copies of the package in different folders and update the lists independently:  
Printers (Accounting Group)  
Printers (Executive Group)  
  
Main Menu  
--------------- Printer Manager Menu ------------------  
[S] Setup all the CSV printers (to this PC)  PC <-- CSV  
[O] Setup one CSV printer (to this PC)       PC <-- CSV  
[U] Update a driver to the \Drivers folder   PC --> CSV  
[A] Add a local printer to CSV list          PC --> CSV  
[N] Uninstall the CSV listed printers        PC (X) CSV  
[R] Local printer deletion                   PC (X)  
[D] Local driver deletion                    PC (X)  
[P] Local port deletion                      PC (X)  
[E] Edit CSV Files manually                  CSV  
[T] Detect if PC has CSV printers already    CSV  
[I] Prep intune_settings.csv with these printers (for IntuneApp)  
[X] Exit  
  
Add a Printer  
On a PC with the printer already installed use menu choice A.  
[A] Add a local printer to CSV list            
This will add the printer to the CSV and copy the drivers to the Drivers folder.  
The printer is now included in the package and will be distributed to other PCs  
Repeat adding as many printers as needed.  
  
Edit the CSV files  
To fine tune your list use menu choice E  
[E] Edit CSV Files manually  
This will allow you to edit the list of printers.  
Here you can also adjust the IP numbers if they change.  
  
PrinterManager PrintersToAdd.csv  
  
Printer	Contoso Room 101 Copier	Printer display name  
Driver-x64	HP Universal\prnbrcl1.inf	<Menu option [A] handles this>  
Driver-ARM64	HP Universal\armbrc1.inf	<Menu option [A] handles this>  
Port	192.168.53.60	<Menu option [A] handles this>  
Model		<optional helpful model info>  
URL		<optional helpful url>  
Settings		<Menu option [A] handles this>  
Location	Room 101	<optional helpful info displayed by Windows>  
  
Settings column  
Settings are for keywords that control the default settings (color, duplexing, etc) for the installed printer.  
If the settings value is empty, the driver defaults will be used.  
During the Add a Printer process you will be asked to choose from a list of default combinations of settings.  
This list can be adjusted.  
  
PrinterManager Settings.csv  
Description	Settings  
Default	  
LetterColor	Papersize=Letter,Collate=False,Color=True  
LetterGreyscale	Papersize=Letter,Collate=False,Color=False  
LetterColorDuplex	Papersize=Letter,Collate=False,Color=True,DuplexingMode=TwoSidedLongEdge  
LetterGreyscaleDuplex	Papersize=Letter,Collate=False,Color=False,DuplexingMode=TwoSidedLongEdge  
A4Color	Papersize=A4,Collate=False,Color=True  
  
Summary of Settings  
Settings are in the form: key=value,key=value,…  
See here for a full list of these values: Link  
Key	Value  
Papersize	Letter or A4  
DuplexingMode	TwoSidedLongEdge  
Collate	True or False  
Color	True or False  
  
Prep for Intune  
If you are planning on distributing this package using the IntuneApp app package system, use menu choice I  
[I] Prep intune_settings.csv with these printers (for IntuneApp)  
  
This will make the necessary changes to the intune_settings.csv file so that Intune detection and installation will work properly in the IntuneApp system.  
Essentially it puts the lists of printers in the app variables section of that csv file.  
  
A note about ARM drivers  
The package is CPU aware. If you add a printer from an ARM machine, the driver will be added to the ARM driver folder and its own ARM column in the CSV.  
If you want the printer to work in both types of CPUs, use A to add the printer from both PC types to get both driver packages. But you will have two CSV rows. Use the values from both driver columns to merge the two CSV rows into a single row.   
  
Manual installation of the printers  
Copy the package folder to a target PC.  
Right-click and run PrinterManager (as Admin).cmd to get to the main menu.   
Use menu choice S or menu choice O to install the printers.  
[S] Setup all the CSV printers (to this PC)  
[O] Setup one CSV printer (to this PC)  
  
Use menu choice N to Uninstall the printers.  
[N] Uninstall the CSV listed printers          
Scripted installation of the printers  
We recommend using the IntuneApp app package system as the easiest way of distributing the printer package.  
Alternatively, use the -mode S command line to automate installations.  
  
PrinterManager.ps1 -mode S  
This will automatically make the menu choice S and install the printers.  
  
PrinterManager.ps1 -mode N  
This will automatically make the menu choice N and uninstall the printers.  
  
PrinterManager.ps1 -mode T  
This will automatically make the menu choice T to detect if the printers are installed.  
  
  
  
  
  
  
  
