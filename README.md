# Folder Synchronization Script

This PowerShell script synchronizes two folders: a `source` folder and a `replica` folder. The script ensures that the `replica` folder is an exact mirror of the `source` folder after synchronization, meaning any changes in the `source` folder (file creation, modification, or deletion) are reflected in the `replica` folder. Additionally, the script logs all file operations (creation, copying, deletion) both to the console and a log file.

## Features
- One-way synchronization from `source` to `replica`: The `replica` folder will match the `source` folder after the script runs.
- Copies new or modified files from the `source` folder to the `replica` folder.
- Deletes files from the `replica` folder that no longer exist in the `source` folder.
- Logs all operations (file creation, modification, deletion) to the console and a specified log file.
- Supports folder paths and log file path as command-line arguments.
- Checks for the existence of the `source` folder and exits gracefully if it is not found.

## Requirements
- PowerShell 5.0 or higher.

## Usage

### Running the Script

To run the script, provide the paths for the `source` folder, `replica` folder, and log file as command-line arguments.

```powershell
.\SyncFolders.ps1 -SourcePath "C:\Path\To\Source" -ReplicaPath "C:\Path\To\Replica" -LogFilePath "C:\Path\To\Log\sync.log"
