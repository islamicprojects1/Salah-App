# Copy sound files from assets/sounds to android/res/raw for Android notifications
# Run: .\copy_sounds_to_raw.ps1

$ErrorActionPreference = "Stop"
$srcDir = "assets/sounds"
$dstDir = "android/app/src/main/res/raw"

# Mapping for special names (e.g. "Takbir 1.mp3" -> "takbir_1.mp3")
$mappings = @{
    "Takbir 1.mp3" = "takbir_1.mp3"
}

if (-not (Test-Path $srcDir)) {
    Write-Host "ERROR: Source folder '$srcDir' not found." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    Write-Host "Created $dstDir" -ForegroundColor Green
}

$copied = 0
Get-ChildItem -Path $srcDir -Filter "*.mp3" -ErrorAction SilentlyContinue | ForEach-Object {
    $dstName = $mappings[$_.Name]
    if (-not $dstName) {
        $dstName = $_.Name.ToLower().Replace(" ", "_")
    }
    $dstPath = Join-Path $dstDir $dstName
    Copy-Item -Path $_.FullName -Destination $dstPath -Force
    Write-Host "Copied: $($_.Name) -> $dstName" -ForegroundColor Cyan
    $copied++
}

if ($copied -eq 0) {
    Write-Host "No .mp3 files found in $srcDir" -ForegroundColor Yellow
    Write-Host "Add your sound files to assets/sounds/ and run this script again." -ForegroundColor Yellow
} else {
    Write-Host "`nDone. $copied file(s) copied to $dstDir" -ForegroundColor Green
    Write-Host "Rebuild the app for Android to use custom notification sounds." -ForegroundColor Gray
}
