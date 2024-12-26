
# Printer Manager Readme

See Github to download and for details: [https://github.com/ITAutomator/IntuneApp/tree/main/Printers](https://github.com/ITAutomator/IntuneApp/tree/main/Printers)

## Overview

Use Printer Manager to automatically set up a standard list of printers on your PCs. It works by ingesting printer drivers from a working PC and then packaging it for distribution. It handles both Intel and ARM drivers.

Printer Manager is Intune and script friendly and designed to work within the IntuneApp system.

---

## Printer Manager Main Menu

The program uses 3 key components, all added via the Printer Manager main menu:

- **PrinterManager PrintersToAdd.csv**  
  A list of printers to add to PCs.

- **PrinterManager PrintersToRemove.csv**  
  An (optional) list of obsolete printers to remove from PCs.

- **IntuneApp\Drivers**  
  A folder of drivers used to install the added printers.  
  Both x64 and ARM65 drivers can be included.

---

## Setup Steps

1. Download the package and copy it to a central area.
2. Right-click and run `PrinterManager (as Admin).cmd` to start the main menu.

> **Note:** The 2 main CSV files will be created if they don’t exist.  
> **Note:** To facilitate different printer lists for different groups, use multiple copies of the package in different folders and update the lists independently:
> - Printers (Accounting Group)
> - Printers (Executive Group)

---

## Main Menu

```
--------------- Printer Manager Menu ------------------

[S] Setup all the CSV printers (to this PC)  PC <-- CSV
[O] Setup one CSV printer (to this PC)       PC <-- CSV
[V] Update a driver to the \Drivers folder   PC --> CSV
[A] Add a local printer to CSV list          PC --> CSV
[U] Uninstall the CSV listed printers        PC (X) CSV
[R] Local printer deletion                   PC (X)
[D] Local driver deletion                    PC (X)
[P] Local port deletion                      PC (X)
[E] Edit CSV Files manually                  CSV
[T] Detect if PC has CSV printers already    CSV
[I] Prep intune_settings.csv with these printers (for IntuneApp)
[X] Exit
```

---

### Add a Printer

On a PC with the printer already installed, use menu choice `A`.

- **[A] Add a local printer to CSV list**  
  This will add the printer to the CSV and copy the drivers to the Drivers folder.  
  The printer is now included in the package and will be distributed to other PCs.  
  Repeat adding as many printers as needed.

---

### Edit the CSV Files

To fine-tune your list, use menu choice `E`.

- **[E] Edit CSV Files manually**  
  This will allow you to edit the list of printers.  
  Here you can also adjust the IP numbers if they change.

---

### CSV File Format: PrinterManager PrintersToAdd.csv

| Printer           | Printer display name | Driver-x64             | Driver-ARM64            | Port          | Model                  | URL                   | Settings              | Location   |
|--------------------|----------------------|-------------------------|--------------------------|---------------|------------------------|-----------------------|-----------------------|------------|
| Contoso Room 101 Copier | `<Menu option [A] handles this>` | `HP Universal\prnbrcl1.inf` | `HP Universal\armbrc1.inf` | `192.168.53.60` | `<optional helpful model info>` | `<optional helpful url>` | `<Menu option [A] handles this>` | Room 101 |

---

### Settings Column

Settings control the default settings (color, duplexing, etc.) for the installed printer. If the settings value is empty, the driver defaults will be used. During the "Add a Printer" process, you will be asked to choose from a list of default combinations of settings. This list can be adjusted.

---

### CSV File Format: PrinterManager Settings.csv

| Description           | Settings                                    | Default |
|------------------------|---------------------------------------------|---------|
| LetterColor           | `Papersize=Letter,Collate=False,Color=True` |         |
| LetterGreyscale       | `Papersize=Letter,Collate=False,Color=False`|         |
| LetterColorDuplex     | `Papersize=Letter,Collate=False,Color=True,DuplexingMode=TwoSidedLongEdge` |         |
| LetterGreyscaleDuplex | `Papersize=Letter,Collate=False,Color=False,DuplexingMode=TwoSidedLongEdge` |         |
| A4Color               | `Papersize=A4,Collate=False,Color=True`     |         |

---

### Summary of Settings

Settings are in the form: `key=value,key=value,…`

- **Papersize:** `Letter` or `A4`
- **DuplexingMode:** `TwoSidedLongEdge`
- **Collate:** `True` or `False`
- **Color:** `True` or `False`

---

## Prep for Intune

If you are planning on distributing this package using the IntuneApp app package system, use menu choice `I`.

- **[I] Prep intune_settings.csv with these printers (for IntuneApp)**  
  This will make the necessary changes to the `intune_settings.csv` file so that Intune detection and installation will work properly in the IntuneApp system. Essentially, it puts the lists of printers in the app variables section of that CSV file.

---

### A Note About ARM Drivers

The package is CPU aware. If you add a printer from an ARM machine, the driver will be added to the ARM driver folder and its own ARM column in the CSV.  
To make the printer work on both types of CPUs, use `A` to add the printer from both PC types to get both driver packages. Then merge the two CSV rows into a single row.

---

### Manual Installation of the Printers

1. Copy the package folder to a target PC.
2. Right-click and run `PrinterManager (as Admin).cmd` to get to the main menu.  
3. Use menu choice `S` or `O` to install the printers:
   - **[S] Setup all the CSV printers (to this PC)**
   - **[O] Setup one CSV printer (to this PC)**

4. Use menu choice `U` to uninstall the printers:
   - **[U] Uninstall the CSV listed printers**

---

### Scripted Installation of the Printers

We recommend using the IntuneApp app package system for easy distribution of the printer package. Alternatively, use the `-mode` command-line options to automate installations:

- **Install:** `PrinterManager.ps1 -mode S`
- **Uninstall:** `PrinterManager.ps1 -mode U`
- **Detect:** `PrinterManager.ps1 -mode T`

---

## More Information

- See also: [https://www.itautomator.com/intuneapp](https://www.itautomator.com/intuneapp)  
- See also: [https://github.com/ITAutomator/IntuneApp](https://github.com/ITAutomator/IntuneApp)
