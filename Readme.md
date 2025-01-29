
## Overview
This script is designed to resolve an issue introduced in the Windows 24H2 update, where the Display API changes prevent **DXGI** from initializing if the primary monitor is powered off or disconnected. By monitoring **Sunshine**'s logs, the script detects when DXGI fails and automatically activates a dummy plug, ensuring you can start a remote stream without physically turning on your display.

---

## The Problem
With the 24H2 update, Microsoft introduced breaking changes to the Windows Display API. As a result, **DXGI** will fail entirely if the currently selected display is offline or disconnected. Because **Sunshine** cannot run scripts *before* DXGI initializes, you cannot start a remote streaming session until the monitor is powered back on. 

Prior to 24H2, this was not an issue—DXGI would not fail, and the **MonitorSwapper** script could automatically switch the display to a dummy plug.

---

## The Workaround Solution
This script monitors Sunshine’s logs. If it detects a failure caused by the 24H2 changes, the script will **forcefully activate the dummy plug**, enabling you to start streaming again without physically turning on the monitor.

### Prerequisites
- **Sunshine** installed.
- Administrator rights on your device.
- Ability to install software and run basic scripts.

---

## Step-by-Step Guide

### Step 1: Download and Extract
1. Download the script from the releases page.
2. Extract the ZIP file **into the same folder** where **MonitorSwapper** is currently installed.

### Step 2: Install the Script
1. After extraction, locate the **Install.bat** file.
2. Double-click **Install.bat** to set up the monitoring script.

### Step 3: Confirm the Extraction  
1. After extracting the zip file, you should see a new folder named *24H2DummyFix* inside the *MonitorSwapper* folder.  
2. If this folder is missing, the extraction was not done correctly.  
3. Do not overwrite any files in MonitorSwapper. If you get overwrite warnings, you might be copying individual files from inside the zip instead of extracting the entire *24H2DummyFix* folder.

### Step 4: Adjust sunshine directory path in Settings (if required)
If you installed Sunshine in a different directory than the default, then you will need to edit the sunshineDirectory property in the settings.json file, make sure to escape the backslashes.

---

## Important Notes
- **Background Task Installation**: This script creates a continuously running PowerShell process to monitor Sunshine's log files in real time.
- **Applies Only to 24H2 with Deep-Sleep Monitors**: This workaround is specifically needed if you are on the 24H2 update and use monitors (e.g., LG C series TVs) that enter deep sleep. It may not be necessary for machines not affected by these changes.

---

## Troubleshooting
Additional troubleshooting steps will be added here as issues are reported.
