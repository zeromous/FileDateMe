# FileDateMe2.ps1 

## Purpose
Windows Powershell Script to rename photo image files based on the "Date Taken" image metadata (if available)

### v2.1 2025-03-01   
by: Zeromous

##  Usage Supported: Windows 10, Windows 11

Careful with this! Use Backup or DryRun and make changes with caution!   

Usage: `.\FileDateMe2.ps1 -directoryPath <path> [-dryRun] [-backup] [-nometa-use-mdate] [-quiet] [-yes]`  
  
`>>> Directory Path is Required <<<`

Script will *only* match/change JPEG, JPG or PNG files in a directory.  
Files that do not have a "Date Taken" metadata will be skipped and can use `[-nometa-use-mdate]` to use the modified date.  

`>>> WARNING <<<<`
> `-yes` will automatically rename the files without asking for confirmation  
> This script will also remove any spaces, double underscores/hyphens and further instances of the calculated 
> datestamp found in the original filename.
 
# Default Usage:
- Preview Mode is Default but will ask if you wish to proceed with changes
- This script will rename the files in the specified directory based on the "Date Taken" metadata of the image files.  This is useful when moving older photos without a date prefix on the filename, and where cdate and mdate are not reliable.
- Files without Data Taken metadata will be skipped and need to be manually renamed.

# Version 2.1 Changes:
- Added -dryRun switch to enable preview mode: proposed changes, report only
- Added -quiet switch to disable verbose output (still requires -yes for silent confirmation)
- Added -backup switch to create a timestamped backup directory before renaming
- Added -nometa-use-mdate switch to use the modified date if Date Taken metadata is not available
- Added logging to a log file in the directory
- Added a report at the end of the script
