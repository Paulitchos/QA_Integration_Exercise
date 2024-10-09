# Define the script parameters: SourcePath, ReplicaPath, and LogFilePath
param (
    [string]$SourcePath,
    [string]$ReplicaPath,
    [string]$LogFilePath
)

# Function to log messages to both console and log file
function Log-Action {
    param (
        [string]$Message  # Message to log
    )

    # Check if the log file exists; if not, create it and log its creation
    if (!(Test-Path -Path $LogFilePath)) {
        # Create the log file and write a log entry indicating its creation
        New-Item -Path $LogFilePath -ItemType File
        $creationTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogFilePath -Value "$creationTime - Log file created"
    }

    # Get the current date and time for timestamping log entries
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"  # Combine timestamp and message

    # Output log message to the console
    Write-Host $logMessage

    # Append log message to the log file
    try {
        Add-Content -Path $LogFilePath -Value $logMessage
    } catch {
        Write-Host "ERROR: Unable to write to log file. Please check permissions."
    }
}

# Function to synchronize files and directories between source and replica folders
function Sync-Folders {
    param (
        [string]$Source,   # Source folder path
        [string]$Replica   # Replica folder path
    )

    # Check if the source folder exists
    if (!(Test-Path -Path $Source)) {
        # Log error if source folder is not found
        Log-Action "ERROR: Source folder does not exist: $Source"
        exit 1  # Exit the script with an error code
    }

    # If the replica folder doesn't exist, create it
    if (!(Test-Path -Path $Replica)) {
        New-Item -ItemType Directory -Path $Replica
        Log-Action "Created replica folder: $Replica"  # Log folder creation
    }

    # Get a list of all items in the source folder, including subfolders
    $sourceItems = Get-ChildItem -Recurse -Force -Path $Source
    foreach ($item in $sourceItems) {
        # Get the relative path of the item (for maintaining folder structure)
        $relativePath = $item.FullName.Substring($Source.Length)
        # Create the full path to the item in the replica folder
        $replicaItem = Join-Path $Replica $relativePath

        # If the item is a directory
        if ($item.PSIsContainer) {
            # Ensure the directory exists in the replica
            if (!(Test-Path -Path $replicaItem)) {
                New-Item -ItemType Directory -Path $replicaItem
                Log-Action "Created directory: $replicaItem"  # Log directory creation
            }
        } else {  # If the item is a file
            # Ensure the directory for the file exists in the replica
            $replicaDir = Split-Path -Path $replicaItem -Parent
            if (!(Test-Path -Path $replicaDir)) {
                New-Item -ItemType Directory -Path $replicaDir
                Log-Action "Created directory: $replicaDir"  # Log directory creation
            }

            # Check if the file doesn't exist in the replica, or if it was modified in the source
            if (!(Test-Path -Path $replicaItem) -or ($item.LastWriteTime -gt (Get-Item $replicaItem).LastWriteTime)) {
                # Copy the file from source to replica, overwriting if necessary
                try {
                    Copy-Item -Path $item.FullName -Destination $replicaItem -Force
                    # Log the file copy operation
                    Log-Action "Copied file: $($item.FullName) to $replicaItem"
                } catch {
                    Log-Action "ERROR: Unable to copy file $($item.FullName) to $replicaItem. $_"
                }
            }
        }
    }

    # Get a list of all files in the replica folder
    $replicaItems = Get-ChildItem -Recurse -Force -Path $Replica
    foreach ($item in $replicaItems) {
        # Get the relative path of the item in the replica
        $relativePath = $item.FullName.Substring($Replica.Length)
        # Create the full path to the corresponding item in the source folder
        $sourceItem = Join-Path $Source $relativePath

        # If the item exists in the replica but not in the source, delete it
        if (!(Test-Path -Path $sourceItem)) {
            try {
                Remove-Item -Path $item.FullName -Force  # Remove the item
                # Log the item deletion
                Log-Action "Removed item: $($item.FullName)"
            } catch {
                Log-Action "ERROR: Unable to remove item $($item.FullName). $_"
            }
        }
    }
}

# Start the synchronization process by calling the Sync-Folders function
# It will copy new/modified files and remove those no longer present in the source folder
Sync-Folders -Source $SourcePath -Replica $ReplicaPath

# Log the completion of the synchronization process
Log-Action "Synchronization completed successfully."
