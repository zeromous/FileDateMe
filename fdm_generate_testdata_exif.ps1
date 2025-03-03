param (
    [int]$number = 20,
    [string]$directoryPath = "testdata"
)


# Check if the directory exists
if (-not (Test-Path -Path $directoryPath)) {
    Write-Output "Directory does not exist: $directoryPath, creating its parent directory."
    New-Item -ItemType Directory -Path $directoryPath -Force | Out-Null
}
# Convert relative path to absolute path
$directoryPath = Resolve-Path -Path $directoryPath


# Prompt to clean up the directory if it exists
if (Test-Path -Path $directoryPath) {
    $cleanupResponse = Read-Host "The directory $directoryPath already exists. Do you want to clean it up before generating data? (y/N)"
    if ($cleanupResponse -eq "y" -or $cleanupResponse -eq "Y") {
        $confirmCleanupResponse = Read-Host "Are you really sure you want to clean up the directory $directoryPath? This will delete all files in the directory. (y/N)"
        if ($confirmCleanupResponse -eq "y" -or $confirmCleanupResponse -eq "Y") {
            Remove-Item -Path $directoryPath -Recurse -Force
            Write-Output "Directory $directoryPath has been cleaned up."
        } else {
            Write-Output "Cleanup aborted."
        }
    } else {
        Write-Output "Cleanup aborted."
    }
}

# Prompt to create the directory if it does not exist
if (-not (Test-Path -Path $directoryPath)) {
    $createDirResponse = Read-Host "The directory $directoryPath does not exist. Do you want to create it? (y/N)"
    if ($createDirResponse -eq "y" -or $createDirResponse -eq "Y") {
        New-Item -ItemType Directory -Path $directoryPath -Force | Out-Null
        Write-Output "Directory $directoryPath has been created."
    } else {
        Write-Output "Directory creation aborted. Exiting script."
        exit
    }
}

$numberOfImages = $number

if ($numberOfImages -ge 1000) {
    Write-Warning "The number of images is too high. Please specify a number less than 1000."
    exit
}

# Load the System.Drawing.Common assembly
Add-Type -AssemblyName System.Drawing

# Function to generate a random image
function Generate-RandomImage {
    param (
        [string]$filePath,
        [int]$width,
        [int]$height,
        [string]$format
    )

    # Create a bitmap
    $bitmap = New-Object Drawing.Bitmap $width, $height

    # Create a random number generator
    $random = New-Object System.Random

    # Fill the bitmap with random colors
    for ($x = 0; $x -lt $width; $x++) {
        for ($y = 0; $y -lt $height; $y++) {
            $color = [Drawing.Color]::FromArgb($random.Next(256), $random.Next(256), $random.Next(256))
            $bitmap.SetPixel($x, $y, $color)
        }
    }

    # Save the bitmap to a file
    #$bitmap.Save($filePath)
    #>$bitmap.Dispose()

    #
    # Save the bitmap to a file in the specified format
    if ($format -eq "jpg") {
        $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    } else {
        $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $bitmap.Dispose()

}

# Function to set the "Date Taken" metadata
function Set-DateTakenMetadata {
    param (
        [string]$filePath,
        [datetime]$dateTaken,
        [string]$format
    )

    $dateTakenString = $dateTaken.ToString("yyyy:MM:dd HH:mm:ss")
    $exiftoolPath = "exiftool" # Assuming exiftool is in your PATH

    #JPG has different EXIF formatting
    if ($format -eq "jpg") {
        $command = "$exiftoolPath -DateTimeOriginal='$dateTakenString' -CreateDate='$dateTakenString' -overwrite_original $filePath"
    } else {
        $command = "$exiftoolPath -CreationTime='$dateTakenString' -overwrite_original $filePath"
    }

    Invoke-Expression $command

}


# Generate a random datetime between 2000 and 2025
$startDate = [datetime]"2000-01-01"
$endDate = [datetime]"2025-02-01"
# To be used for random date at file generation
$dateRange = ($endDate - $startDate).Days

# Create a directory for the images
$imageDirectory = $directoryPath



if (-not (Test-Path -Path $imageDirectory)) {
    New-Item -ItemType Directory -Path $imageDirectory -Force | Out-Null
}


# Generate the specified number of images
for ($i = 1; $i -le $numberOfImages; $i++) {
    $width = Get-Random -Minimum 32 -Maximum 512
    $height = Get-Random -Minimum 32 -Maximum 512
    $extension = if (Get-Random -Minimum 0 -Maximum 2) { "jpg" } else { "png" }

    $randomSalt = $(Get-Random -Minimum 1 -Maximum 8)
    if ($randomSalt -eq 1) {
        $randomPart = "--"
    } 
    elseif ($randomSalt -eq 2) {
        $randomPart = "__"
    } 
    elseif ($randomSalt -eq 3) {
        $randomPart = "-"
    } 
    elseif ($randomSalt -eq 4) {
        $randomPart = "_"
    } 
    elseif ($randomSalt -eq 5) {
        $randomPart = "$(Get-Random -Minimum 0 -Maximum 9999)"
    } 
    else {
        $randomPart = ""
    }

    $dateTaken = $startDate.AddDays($(Get-Random -Minimum 0 -Maximum $dateRange))
    $formattedDate = $dateTaken.ToString("yyyyMMdd")



    $randomSalt = $(Get-Random -Minimum 1 -Maximum 10)
    

    if ($randomSalt -lt 2) {
        # Generate a unique "Date Taken" for each image ~20% of the time
        # This is to test the double date removal feature in FileDateMe21.ps1
        
        $fileName = "IMG_" + "{0:D6}" -f $i + "_" + $randomPart + "_" + $formattedDate + "." + $extension
    } 
    else {
        $fileName = "IMG_" + "{0:D6}" -f $i + "_" + $randomPart + "_" + "." + $extension
    }
    

    $filePath = Join-Path -Path $imageDirectory -ChildPath $fileName

    #Generate-RandomImage -filePath $filePath -width $width -height $height
    Generate-RandomImage -filePath $filePath -width $width -height $height -format $extension

    
    $randomSalt = $(Get-Random -Minimum 1 -Maximum 10)

    #Set Metadata for only ~90% of the images generated
    if ($randomSalt -lt 8) {
        Set-DateTakenMetadata -filePath $filePath -dateTaken $dateTaken -format $extension    
        Write-Output "updated Metadata for $fileName"
    }
    else {
        Write-Output "NO MetaDada was updated."
    }


    Write-Output "Generated $fileName with dimensions $width x $height and Date Taken $dateTaken"

}

Write-Output "Generated $numberOfImages random images in $imageDirectory"