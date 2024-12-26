
# Printer Manager Readme

## Overview

Use Printer Manager to automatically set up a standard list of printers on your PCs.

Printer Manager is Intune and script friendly and designed to work within the IntuneApp system.
![image](https://github.com/user-attachments/assets/f4f85559-853d-4814-82cb-85be2ac488b7)


---

## Printer Manager Main Menu

The program uses three key components, all added via the Printer Manager main menu:

1. **PrinterManager PrintersToAdd.csv**  
   A list of printers to add to PCs.

2. **PrinterManager PrintersToRemove.csv**  
   An (optional) list of obsolete printers to remove from PCs.

3. **IntuneApp/Drivers**  
   A folder of drivers used to install the added printers.  
   Both x64 and ARM64 drivers can be included.

---

## Setup Steps

1. Download the package and copy it to a central area.
2. Right-click and run `PrinterManager (as Admin).cmd` to start the main menu.

**Notes:**
- The two main CSV files will be created if they don’t exist.
- To facilitate different printer lists for different groups, use multiple copies of the package in different folders and update the lists independently:
  - Printers (Accounting Group)
  - Printers (Executive Group)

---

## Main Menu Options

```
--------------- Printer Manager Menu ------------------
[S] Setup all the CSV printers (to this PC)   PC <-- CSV
[O] Setup one CSV printer (to this PC)        PC <-- CSV
[V] Update a driver to the /Drivers folder    PC --> CSV
[A] Add a local printer to CSV list           PC --> CSV
[U] Uninstall the CSV listed printers         PC (X) CSV
[R] Local printer deletion                    PC (X)
[D] Local driver deletion                     PC (X)
[P] Local port deletion                       PC (X)
[E] Edit CSV Files manually                   CSV
[T] Detect if PC has CSV printers already     CSV
[I] Prep intune_settings.csv with these printers (for IntuneApp)
[X] Exit
```

---

## Adding a Printer

1. On a PC with the printer already installed, use menu choice **A**.
2. This will add the printer to the CSV and copy the drivers to the `/Drivers` folder.
3. The printer is now included in the package and will be distributed to other PCs.
4. Repeat the process for as many printers as needed.

---

## Editing the CSV Files

To fine-tune your list, use menu choice **E**.

- Adjust the list of printers.
- Modify IP numbers if they change.

### Example: PrinterManager PrintersToAdd.csv

| Field            | Example Value                     |
|-------------------|-----------------------------------|
| **Printer**       | Contoso Room 101 Copier          |
| **Driver-x64**    | HP Universal\prnbrcl1.inf        |
| **Driver-ARM64**  | HP Universal\armbrc1.inf         |
| **Port**          | 192.168.53.60                    |
| **Model**         | (optional helpful model info)    |
| **URL**           | (optional helpful URL)           |
| **Settings**      |                                  |
| **Location**      | Room 101                         |

---

## PrinterManager Settings.csv

### Example:

| Description               | Settings                                   |
|---------------------------|-------------------------------------------|
| **LetterColor**           | Papersize=Letter,Collate=False,Color=True |
| **LetterGreyscale**       | Papersize=Letter,Collate=False,Color=False|
| **LetterColorDuplex**     | Papersize=Letter,Color=True,DuplexingMode=TwoSidedLongEdge |

### Summary of Settings

- Settings are in the form: `key=value,key=value,…`
- Full list of values can be found [here](#).

| Key            | Example Values       |
|-----------------|----------------------|
| **Papersize**   | Letter or A4         |
| **Color**       | True or False        |
| **Collate**     | True or False        |

---

## Prepping for Intune

Use menu choice **I** to prepare `intune_settings.csv` with these printers for IntuneApp.

This will make the necessary changes to `intune_settings.csv` for Intune detection and installation.

---

## ARM Driver Notes

- The package is CPU-aware. If you add a printer from an ARM machine, the driver will be added to the ARM driver folder.
- For compatibility with both CPU types, use **A** to add printers from both PC types. Then merge the two rows in the CSV.

---

## Manual Installation

1. Copy the package folder to a target PC.
2. Right-click and run `PrinterManager (as Admin).cmd`.
3. Use menu choices **S** or **O**:
   - **S**: Setup all CSV printers on this PC.
   - **O**: Setup one CSV printer on this PC.

### Uninstall Printers

Use menu choice **U** to uninstall the CSV-listed printers.

---

## Scripted Installation

We recommend using the IntuneApp system for distribution. Alternatively, use command-line options:

- `PrinterManager.ps1 -mode S`  
  Installs all CSV printers.

- `PrinterManager.ps1 -mode U`  
  Uninstalls all CSV printers.

- `PrinterManager.ps1 -mode T`  
  Detects if printers are already installed.
