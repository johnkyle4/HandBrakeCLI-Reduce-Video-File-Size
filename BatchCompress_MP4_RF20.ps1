# Uses RF 20 (visually transparent quality)
# Uses x264 slow preset (better compression)
# Audio is copied if compatible (or defaults to 160kbps AAC)
# Requires HandBrakeCLI installed and in PATH
# Requires PowerShell 5.1 or later

param(
    [Parameter(Mandatory = $true)][string]$handbrake,
    [Parameter(Mandatory = $true)][string]$inputDir,
    [Parameter(Mandatory = $true)][string]$outputDir
)

# --- VALIDATION ---
if (!(Test-Path $handbrake)) {
    Write-Error "HandBrakeCLI not found at path: $handbrake"
    exit 1
}
if (!(Test-Path $inputDir)) {
    Write-Error "Input folder does not exist: $inputDir"
    exit 1
}
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$outputDir\compression_log_$timestamp.txt"
$logData = @()

$files = Get-ChildItem -Path $inputDir -Filter *.mp4
$total = $files.Count
$count = 0
$startTime = Get-Date

Write-Host "`n🎬 Starting batch compression of $total file(s)...`n"

foreach ($file in $files) {
    $inputFile = $file.FullName
    $outputFile = Join-Path $outputDir $file.Name
    $count++

    if (Test-Path $outputFile) {
        Write-Host "[$count / $total] Skipping already compressed: $($file.Name)" -ForegroundColor Yellow
        continue
    }

    Write-Host "[$count / $total] Compressing: $($file.Name)" -ForegroundColor Cyan

    $fileStart = Get-Date

    & $handbrake -i "$inputFile" -o "$outputFile" `
        -e x264 -q 20 --encoder-preset slow -f mp4 -a 1 -E copy -B 160

    $origSize = [Math]::Round((Get-Item $inputFile).Length / 1GB, 2)
    $newSize  = [Math]::Round((Get-Item $outputFile).Length / 1GB, 2)
    $saved    = [Math]::Round($origSize - $newSize, 2)

    $elapsed = (Get-Date) - $fileStart
    $avgTime = (($elapsed.TotalSeconds) * $count) / $count
    $remaining = [TimeSpan]::FromSeconds($avgTime * ($total - $count))

    Write-Host "    ⏱️ Time: $($elapsed.ToString("mm\:ss")) | Remaining: $($remaining.ToString("hh\:mm\:ss"))"
    Write-Host "    📦 Saved: $saved GB"

    $logData += [PSCustomObject]@{
        Filename     = $file.Name
        OriginalGB   = $origSize
        CompressedGB = $newSize
        SavedGB      = $saved
    }
}

$logData = $logData | Sort-Object -Property SavedGB -Descending

"Compression Log - $timestamp" | Out-File $logFile
"HandBrakeCLI Path: $handbrake" >> $logFile
"Original Folder: $inputDir" >> $logFile
"Output Folder:   $outputDir" >> $logFile
"" >> $logFile

$logData | ForEach-Object {
    "$($_.Filename)`tOriginal: $($_.OriginalGB) GB`tCompressed: $($_.CompressedGB) GB`tSaved: $($_.SavedGB) GB"
} >> $logFile

$totalElapsed = (Get-Date) - $startTime
Write-Host "`n✅ All done in $($totalElapsed.ToString("hh\:mm\:ss"))"
Write-Host "📝 Log saved to: $logFile" -ForegroundColor Green
