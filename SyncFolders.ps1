# Define the script parameters: SourcePath, ReplicaPath, and LogFilePath
# These are the folder paths for the source and replica, and the path for the log file.
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

    # Get the current date and time for timestamping log entries
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"  # Combine timestamp and message

    # Output log message to the console
    Write-Host $logMessage

    # Append log message to the log file
    Add-Content -Path $LogFilePath -Value $logMessage
}

# Function to synchronize files between source and replica folders
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

    # Get a list of all files in the source folder, including subfolders
    $sourceFiles = Get-ChildItem -Recurse -File -Path $Source
    foreach ($file in $sourceFiles) {
        # Get the relative path of the file (for maintaining folder structure)
        $relativePath = $file.FullName.Substring($Source.Length)
        # Create the full path to the file in the replica folder
        $replicaFile = Join-Path $Replica $relativePath

        # Check if the file doesn't exist in the replica, or if it was modified in the source
        if (!(Test-Path -Path $replicaFile) -or ($file.LastWriteTime -gt (Get-Item $replicaFile).LastWriteTime)) {
            # Copy the file from source to replica, overwriting if necessary
            Copy-Item -Path $file.FullName -Destination $replicaFile -Force
            # Log the file copy operation
            Log-Action "Copied file: $($file.FullName) to $replicaFile"
        }
    }

    # Get a list of all files in the replica folder
    $replicaFiles = Get-ChildItem -Recurse -File -Path $Replica
    foreach ($file in $replicaFiles) {
        # Get the relative path of the file in the replica
        $relativePath = $file.FullName.Substring($Replica.Length)
        # Create the full path to the corresponding file in the source folder
        $sourceFile = Join-Path $Source $relativePath

        # If the file exists in the replica but not in the source, delete it
        if (!(Test-Path -Path $sourceFile)) {
            Remove-Item -Path $file.FullName  # Remove the file
            # Log the file deletion
            Log-Action "Removed file: $($file.FullName)"
        }
    }
}

# Start the synchronization process by calling the Sync-Folders function
# It will copy new/modified files and remove those no longer present in the source folder
Sync-Folders -Source $SourcePath -Replica $ReplicaPath

# Log the completion of the synchronization process
Log-Action "Synchronization completed successfully."
