# Determine the path of the currently running script and set the working directory to that path
$path = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $path

# Load helper functions or configurations if any (assuming Helpers.ps1 exists)
. .\Helpers.ps1 -n 24H2DummyFix

# Load settings from a JSON file located in the same directory as the script
$settings = Get-Settings

# Function to send messages to a named pipe
function Send-PipeMessage {
    param (
        [string]$pipeName,
        [string]$message
    )
    Write-Debug "Attempting to send message to pipe: $pipeName"

    try {
        # Check if the named pipe exists
        $pipeExists = Get-ChildItem -Path "\\.\pipe\" | Where-Object { $_.Name -eq $pipeName }
        Write-Debug "Pipe exists check: $($pipeExists.Length -gt 0)"
        
        if ($pipeExists.Length -gt 0) {
            $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $pipeName, [System.IO.Pipes.PipeDirection]::Out)
            Write-Debug "Connecting to pipe: $pipeName"
            
            try {
                $pipe.Connect(3000) # Timeout in milliseconds
                $streamWriter = New-Object System.IO.StreamWriter($pipe)
                Write-Debug "Sending message: $message"
                
                $streamWriter.WriteLine($message)
                $streamWriter.Flush()
            }
            catch {
                Write-Warning "Failed to send message to pipe: $_"
            }
            finally {
                try {
                    $streamWriter.Dispose()
                    $pipe.Dispose()
                    Write-Debug "Resources disposed successfully."
                }
                catch {
                    Write-Debug "Error during disposal: $_"
                }
            }
        }
        else {
            Write-Debug "Pipe not found: $pipeName"
        }
    }
    catch {
        Write-Warning "An error occurred while sending pipe message: $_"
    }
}


# Function to handle specific error detection and service restart
function Handle-DuplicateOutputError {

    Write-Host "Detected that Sunshine could not start due to display issues, forcing dummy plug configuration."

    & "..\MonitorSwitcher.exe" -load:..\Dummy.xml

}
function Monitor-LogFile {
    param (
        [string]$logFilePath
    )

    Write-Host "Starting to monitor log file: $logFilePath"

    while ($true) {
        if (Test-Path $logFilePath) {
            try {
                # Get initial file properties
                $fileInfo = Get-Item $logFilePath
                $initialCreationTime = $fileInfo.CreationTime

                # Open the log file for reading with shared read/write access
                $fileStream = [System.IO.File]::Open($logFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $streamReader = New-Object System.IO.StreamReader($fileStream)

                # Seek to the end of the file to start monitoring new entries
                $streamReader.BaseStream.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null

                while ($true) {
                    if (-not (Test-Path $logFilePath)) {
                        Write-Host "Log file has been deleted. Waiting for recreation..."
                        break
                    }

                    $line = $streamReader.ReadLine()
                    if ($line) {
                        Process-LogLine -line $line
                    }
                    else {
                        Start-Sleep -Milliseconds 500

                        # Check if the log file still exists
                        if (-not (Test-Path $logFilePath)) {
                            Write-Host "Log file deleted. Breaking loop."
                            break
                        }

                        # Check if the file has been recreated (new CreationTime)
                        $currentFile = Get-Item $logFilePath -ErrorAction SilentlyContinue
                        if (-not $currentFile -or $currentFile.CreationTime -ne $initialCreationTime) {
                            Write-Host "Log file recreated or modified. Reopening..."
                            break
                        }

                        # Check if the file has been truncated
                        if ($fileStream.Length -lt $streamReader.BaseStream.Position) {
                            Write-Host "Log file truncated. Resetting to start."
                            $streamReader.BaseStream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
                        }
                    }
                }
            }
            catch {
                Write-Warning "An error occurred while monitoring the log file: $_"
            }
            finally {
                if ($streamReader) { $streamReader.Close(); $streamReader.Dispose() }
                if ($fileStream) { $fileStream.Close(); $fileStream.Dispose() }
            }
        }
        else {
            Write-Warning "Log file not found at path: $logFilePath. Retrying in 5 seconds..."
        }

        Start-Sleep -Seconds 5 # Wait before retrying to open the log file
    }
}

# Function to process each log line
function Process-LogLine {
    param (
        [string]$line
    )

    # Define patterns to detect relevant log entries
    $duplicateOutputErrorPattern = "Error: Failed to locate an output device"
    

    if ($line -match $duplicateOutputErrorPattern) {
        Handle-DuplicateOutputError
    }
}

# Main Execution Flow
function Start-Monitoring {
    # Determine the log file path
    $sunshineDirectory = $settings.sunshineDirectory
    if (-not $sunshineDirectory) {
        Write-Error "sunshineDirectory is not defined in settings.json."
        return
    }

    $logFilePath = Join-Path -Path $sunshineDirectory -ChildPath "config\sunshine.log"


    # Start monitoring the log file in a loop to ensure continuous monitoring
    while ($true) {
        try {
            Monitor-LogFile -logFilePath $logFilePath
        }
        catch {
            Write-Warning "An error occurred while monitoring the log file: $_"
            Start-Sleep -Seconds 5  # Wait before retrying
        }
    }
}
Start-Logging

# Start the monitoring process
Start-Monitoring

Stop-Logging

Remove-OldLogs
