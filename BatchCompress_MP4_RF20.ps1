# Uses RF 20 (visually transparent quality)
# Uses x264 slow preset (better compression)
# Audio is copied if compatible (or defaults to 160kbps AAC)
# Requires HandBrakeCLI installed and in PATH
# Requires PowerShell 5.1 or later

# --- CONFIGURATION ---
$handbrake = "C:\HandBrakeCLI\HandBrakeCLI.exe"   # Path to HandBrakeCLI.exe
$inputDir = "C:\Input"                            # Folder with original MP4s
$outputDir = "C:\Output"                          # Folder for compressed MP4s
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$outputDir\compression_log_$timestamp.txt"
$logData = @()

# Create output dir if it doesn't exist
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Get all MP4 files to process
$files = Get-ChildItem -Path $inputDir -Filter *.mp4
$total = $files.Count
$count = 0
$startTime = Get-Date

Write-Host "`n🎬 Starting batch compression of $total file(s)...`n"

foreach ($file in $files) {
    $inputFile = $file.FullName
    $outputFile = Join-Path $outputDir $file.Name
    $count++

    # Skip file if it already exists
    if (Test-Path $outputFile) {
        Write-Host "[$count / $total] Skipping already compressed: $($file.Name)" -ForegroundColor Yellow
        continue
    }

    Write-Host "[$count / $total] Compressing: $($file.Name)" -ForegroundColor Cyan

    # Start timer
    $fileStart = Get-Date

    # Run HandBrakeCLI
    & $handbrake -i "$inputFile" -o "$outputFile" `
        -e x264 -q 20 --encoder-preset slow -f mp4 -a 1 -E copy -B 160

    # File size info
    $origSize = [Math]::Round((Get-Item $inputFile).Length / 1GB, 2)
    $newSize  = [Math]::Round((Get-Item $outputFile).Length / 1GB, 2)
    $saved    = [Math]::Round($origSize - $newSize, 2)

    # Time tracking
    $elapsed = (Get-Date) - $fileStart
    $avgTime = (($elapsed.TotalSeconds) * $count) / $count
    $remaining = [TimeSpan]::FromSeconds($avgTime * ($total - $count))

    Write-Host "    ⏱️ Time: $($elapsed.ToString("mm\:ss")) | Remaining: $($remaining.ToString("hh\:mm\:ss"))"
    Write-Host "    📦 Saved: $saved GB"

    # Append to log array
    $logData += [PSCustomObject]@{
        Filename     = $file.Name
        OriginalGB   = $origSize
        CompressedGB = $newSize
        SavedGB      = $saved
    }
}

# Sort log by largest savings
$logData = $logData | Sort-Object -Property SavedGB -Descending

# Write to log file
"Compression Log - $timestamp" | Out-File $logFile
"Original Folder: $inputDir" >> $logFile
"Output Folder:   $outputDir" >> $logFile
"" >> $logFile

$logData | ForEach-Object {
    "$($_.Filename)`tOriginal: $($_.OriginalGB) GB`tCompressed: $($_.CompressedGB) GB`tSaved: $($_.SavedGB) GB"
} >> $logFile

$totalElapsed = (Get-Date) - $startTime
Write-Host "`n✅ All done in $($totalElapsed.ToString("hh\:mm\:ss"))"
Write-Host "📝 Log saved to: $logFile" -ForegroundColor Green
