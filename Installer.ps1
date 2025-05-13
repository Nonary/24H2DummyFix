# Installer.ps1
# This script creates a scheduled task that runs 24H2DummyFix.ps1 every 2 minutes indefinitely,
# using schtasks.exe directly.

# Define the task name
$taskName = "24H2DummyFix"

# Get the directory where Installer.ps1 is located
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Define the full path to 24H2DummyFix.ps1
$monitorScript = Join-Path $scriptDirectory "24H2DummyFix.ps1"

# Check if the monitor script exists
if (-Not (Test-Path -Path $monitorScript)) {
    Write-Error "24H2DummyFix.ps1 not found in $scriptDirectory"
    exit 1
}

# Build the command that will run the monitor script with a hidden window
$taskCommand = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$monitorScript`""

# (Optional) Define a start time one minute from now to ensure the task starts in the future.
$startTime = (Get-Date).AddMinutes(1).ToString("HH:mm")

# Remove any existing task with the same name
schtasks.exe /Delete /TN "$taskName" /F | Out-Null

# Create the task:
# /SC MINUTE   --> Schedule type "minute"
# /MO 2        --> Modifier: every 2 minutes
# /ST          --> Start time (HH:mm format)
# /RL HIGHEST  --> Run with highest privileges
# /F           --> Force creation (overwrite if exists)
schtasks.exe /Create /SC MINUTE /MO 2 /ST $startTime /TN "$taskName" /TR "$taskCommand" /RL HIGHEST /F

if ($LASTEXITCODE -eq 0) {
    Write-Output "Scheduled task '$taskName' created successfully."

    # Start the task immediately
    schtasks.exe /Run /TN "$taskName" | Out-Null
    Write-Output "Scheduled task '$taskName' started."
} else {
    Write-Error "Failed to create scheduled task '$taskName'."
}
