## FileDateMe2.ps1 - Rename photo image files based on the "Date Taken" image metadata if available
#  v2.1 2025-03-01   
#  by: Zeromous
#
#  Supported: Windows 10, Windows 11
#
# Careful with this! Use Backup or DryRun and make changes with caution!
# Usage: .\FileDateMe2.ps1 -directoryPath <path> [-dryRun] [-backup] [-nometa-use-mdate] [-quiet] [-yes] 
# >>> Directory Path is Required <<<
# - Script will *only* match/change JPEG, JPG or PNG files in a directory
# - Files that do not have a "Date Taken" metadata will be skipped and can use [-nometa-use-mdate] to use the modified date
#
# >>> WARNING <<<<
# > `-yes` will automatically rename the files without asking for confirmation
# > This script will also remove any spaces, double underscores/hyphens and further instances of the calculated 
# > datestamp found in the original filename.
# 
# Default Usage:
# - Preview Mode is Default
# - This script will rename the files in the specified directory based on the "Date Taken" metadata of 
# the image files.  This is useful when moving older photos without a date prefix on the filename, and
# where cdate and mdate are not reliable.
# - Files without Data Taken metadata will be skipped and need to be manually renamed.
# 
# Version 2.1 Changes:
# - Added -dryRun switch to enable preview mode: proposed changes, report only
# - Added -quiet switch to disable verbose output (still requires -yes for silent confirmation)
# - Added -backup switch to create a timestamped backup directory before renaming
# - Added -nometa-use-mdate switch to use the modified date if Date Taken metadata is not available
# - Added logging to a log file in the directory
# - Added a report at the end of the script
#
##--------------------------------------------------------------

param (
    [string]$directoryPath,
    [switch]$yes,
    [switch]$dryRun,
    [switch]$quiet,
    [switch]$backup,
    [switch]$nometaUseMdate
)

# Disable only verbose output if quiet is specified
$verbose = -not $quiet

# Check if the directory path is provided
if (-not $directoryPath) {
    Write-Output "No directory path specified. Exiting."
    exit
}

# Check if the directory exists
if (-not (Test-Path -Path $directoryPath)) {
    Write-Output "Directory does not exist: $directoryPath"
    exit
}

# Create a Shell.Application COM object
$shell = New-Object -ComObject Shell.Application

# Get all image files in the directory
$files = Get-ChildItem -Path $directoryPath -File | Where-Object { $_.Extension -match "jpg|jpeg|png" }

# Create a log file
$logFile = Join-Path -Path $directoryPath -ChildPath "FileDateMe2.log"
"Script started at $(Get-Date)" | Out-File -FilePath $logFile -Append

function Log {
    param (
        [string]$message
    )
    $message | Out-File -FilePath $logFile -Append
    if ($verbose) {
        Write-Output $message
    }
}

# Create backup directory if backup switch is specified
$backupDir = ""
if ($backup) {
    $backupDir = Join-Path -Path $directoryPath -ChildPath ("_fdm.bk." + (Get-Date -Format "yyyyMMdd_HHmmss"))
    if (-not $dryRun) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    Log "Backup directory created: $backupDir"
}

# Initialize counters
$totalFiles = 0
$renamedFiles = 0
$skippedFiles = 0
$backupFiles = 0

function ProcessFile {
    param (
        [System.IO.FileInfo]$file,
        [switch]$rename,
        [switch]$countOnly
    )

    # Increment total files counter
    if (-not $countOnly) {
        $script:totalFiles++
    }

    # Get the folder object
    $folder = $shell.Namespace($file.DirectoryName)

    # Get the file item
    $fileItem = $folder.ParseName($file.Name)

    # Get the "Date Taken" property (property index 12)
    $dateTaken = $folder.GetDetailsOf($fileItem, 12)

    if ($dateTaken -and $dateTaken -ne "") {
        try {
            # Remove non-numeric characters except hyphens
            $dateTaken = $dateTaken -replace '[^\d]', '-' # Remove non-numeric characters
            $dateTaken = $dateTaken -replace '^-', '' # Remove non-numeric characters
            $testOut = $dateTaken

            #Parse the bad Window Date Taken format
            $testOut = $dateTaken.Split('---')[0] 
            $my_month = $testOut.Split('--')[0]
            $testOut = $dateTaken -split '--'

            $parts = $testOut -split ' '
            if ($parts.Length -ge 3) {

                if ($parts[0].Length -ge 2 ) {
                    $my_month = $parts[0]
                } else {
                    $my_month = "0" + $parts[0]
                }

                if ($parts[1].Length -ge 2) {
                    $my_day = $parts[1]
                } else {
                    $my_day = "0" + $parts[1]
                }

                $my_year = $parts[2]

                $formattedDate = "$my_year$my_month$my_day"
            } else {
                Log "Data Not Formatted Correctly for file: $($file.Name)"
                if (-not $countOnly) {
                    $script:skippedFiles++
                }
                return
            }

            Log "Formatted Date: $formattedDate for file: $($file.Name)"
        } catch {
            Log "File: $($file.Name) has an unrecognized 'Date Taken' format: $formattedDate"
            if (-not $countOnly) {
                $script:skippedFiles++
            }
            return
        }
    } elseif ($nometaUseMdate) {
        # Use the modified date if Date Taken metadata is not available and -nometa-use-mdate is specified
        $modifiedDate = $file.LastWriteTime
        $formattedDate = $modifiedDate.ToString("yyyyMMdd")
        Log "Using Modified Date: $formattedDate for file: $($file.Name)"
    } else {
        Log "File: $($file.Name) does not have a 'Date Taken' metadata."
        if (-not $countOnly) {
            $script:skippedFiles++
        }
        return
    }

    # Remove any spaces in the original filename
    $originalFileName = $file.Name -replace " ", ""

    # Remove any instances of the formatted date in the original filename
    $originalFileName = $originalFileName -replace $formattedDate, ""

    # Remove any double underscores in the original filename
    $originalFileName = $originalFileName -replace "__", "_"

    # Create the new file name by prepending the formatted date
    $newFileName = "$formattedDate"+"_"+"$originalFileName"
    $newFileName = $newFileName -replace "__", "_"
    $newFileName = $newFileName -replace "--", "-"

    # Get the full path of the new file name
    $newFilePath = Join-Path -Path $directoryPath -ChildPath $newFileName

    if ($rename) {
        if (-not $dryRun) {
            # Backup the file if backup switch is specified
            if ($backup) {
                Copy-Item -Path $file.FullName -Destination $backupDir -Force
                Log "File: $($file.Name) backed up to $backupDir"
                $script:backupFiles++
            }

            # Rename the file
            Rename-Item -Path $file.FullName -NewName $newFilePath -Force
            Log "File: $($file.Name) has been renamed to $newFileName"
            $script:renamedFiles++
        } else {
            Log "Dry Run: File: $($file.Name) would be renamed to $newFileName"
        }
    } else {
        Log "Preview: $($file.Name) will be renamed to $newFileName"
    }
}

# First pass: Preview or Dry Run
foreach ($file in $files) {
    ProcessFile -file $file -countOnly
}

# Second pass: Actual renaming if confirmed
if (-not $yes -and -not $dryRun) {
    $confirmation = Read-Host "Do you want to proceed with renaming the files? (y/n)"
    if ($confirmation -eq 'y') {
        foreach ($file in $files) {
            ProcessFile -file $file -rename
        }
        Log "Files have been renamed successfully."
    } else {
        Log "No changes were made."
    }
} elseif ($yes -or $dryRun) {
    foreach ($file in $files) {
        ProcessFile -file $file -rename
    }
    Log "Files have been renamed successfully."
}

if ($backup) {
    Log "Don't forget to review and clean up files in $backupDir if satisfied."
}

# Report summary
Log "Total files processed: $totalFiles"
Log "Files renamed: $renamedFiles"
Log "Files skipped: $skippedFiles"
Log "Total backup files processed: $backupFiles"

Log "Script ended at $(Get-Date)"