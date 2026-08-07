# tools/stitch_frames.ps1 — stitch N individual PNG frames into a horizontal spritesheet.
#
# Usage:
#   powershell -File tools/stitch_frames.ps1 -InputPattern "characters/bosses/luxar/luxar_idle_east_f*.png" `
#              -Output "characters/bosses/luxar/luxar_idle_east.png"
#
# Sprite sheet layout expected by luxar.gd et al: single row, N columns, all frames same size.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$InputPattern,
    [Parameter(Mandatory=$true)] [string]$Output
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Resolve input files, sort by name (relies on zero-padded f00, f01, ...)
$frames = Get-ChildItem -Path $InputPattern | Sort-Object Name
if ($frames.Count -eq 0) {
    Write-Error "No frames matched pattern: $InputPattern"
    exit 1
}

# Assume all frames share dimensions with the first one.
$first = [System.Drawing.Image]::FromFile($frames[0].FullName)
$w = $first.Width
$h = $first.Height
$first.Dispose()

$sheet = New-Object System.Drawing.Bitmap ($w * $frames.Count), $h
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

for ($i = 0; $i -lt $frames.Count; $i++) {
    $img = [System.Drawing.Image]::FromFile($frames[$i].FullName)
    if ($img.Width -ne $w -or $img.Height -ne $h) {
        Write-Warning "Frame $($frames[$i].Name) size $($img.Width)x$($img.Height) does not match first frame ${w}x${h}; drawing at 0,0."
    }
    $g.DrawImage($img, ($i * $w), 0, $w, $h)
    $img.Dispose()
}

$g.Dispose()

# Ensure output dir exists
$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$sheet.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()

$outFile = Get-Item $Output
Write-Host "stitched $($frames.Count) frames -> $Output  ($($outFile.Length) bytes, $($w * $frames.Count)x$h)"
