@echo off
:: Uninstall.bat
:: This script deletes the HybridGPUMonitorTask scheduled task

:: Define the task name
set taskName=HybridGPUMonitorTask

:: Check for Administrator privileges
NET SESSION >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /B
)

:: Attempt to stop the task if it's running
schtasks /End /TN "%taskName%" >nul 2>&1

:: Delete the scheduled task
schtasks /Delete /TN "%taskName%" /F

if %errorLevel% == 0 (
    echo Scheduled task '%taskName%' has been successfully deleted.
) else (
    echo Failed to delete scheduled task '%taskName%'. It may not exist.
)
