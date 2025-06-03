# Uses RF 20 (visually transparent quality)
# Uses x264 slow preset (better compression)
# Audio is copied if compatible (or defaults to 160kbps AAC)
# Requires HandBrakeCLI installed and in PATH
# Requires PowerShell 5.1 or later

# --- CONFIGURATION ---
$handbrake = "HandBrakeCLI.exe"   # Path to HandBrakeCLI.exe
$inputDir = "H:\DTS Backup\Adrienne Lee\VHS-Orig" # Folder with original MP4s
$outputDir = "H:\DTS Backup\Adrienne Lee\VHS"     # Folder for compressed MP4s
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$outputDir\compression_log_$timestamp.txt"

# Create output dir if it doesn't exist
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Get files
$files = Get-ChildItem -Path $inputDir -Filter *.mp4
$total = $files.Count
$count = 0

# Initialize log
"Compression Log - $timestamp" | Out-File $logFile
"Original Folder: $inputDir" >> $logFile
"Output Folder:   $outputDir" >> $logFile
"" >> $logFile

# Process each file
foreach ($file in $files) {
    $count++
    $inputFile = $file.FullName
    $outputFile = Join-Path $outputDir $file.Name

    Write-Host ""
    Write-Host "[$count / $total] Compressing: $($file.Name)" -ForegroundColor Cyan

    # Run HandBrakeCLI
    & $handbrake -i "$inputFile" -o "$outputFile" `
        -e x264 -q 20 --encoder-preset slow -f mp4 -a 1 -E copy -B 160

    # Get sizes
    $origSize = [Math]::Round((Get-Item $inputFile).Length / 1GB, 2)
    $newSize  = [Math]::Round((Get-Item $outputFile).Length / 1GB, 2)
    $sizeDiff = [Math]::Round($origSize - $newSize, 2)

    # Log entry
    "$($file.Name)`tOriginal: $origSize GB`tCompressed: $newSize GB`tSaved: $sizeDiff GB" >> $logFile
}

Write-Host "`n✅ Done! Log saved to: $logFile" -ForegroundColor Green
