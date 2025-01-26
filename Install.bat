@echo off
:: Installer.bat
:: This script elevates privileges and runs installer.ps1

:: Check for Administrator privileges
NET SESSION >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /B
)

:: Run the installer.ps1 script located in the same directory
powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0installer.ps1"
